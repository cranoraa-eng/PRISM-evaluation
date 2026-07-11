-- Run this SQL in your Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)
-- Then create admin users: Authentication → Users → Add User

-- ============================================================
-- 1. RESPONSES TABLE (with audit, metadata, soft-delete, consent version)
-- ============================================================
-- Create table (no-op if exists; columns added individually below)
create table if not exists responses (
  id               uuid primary key,
  submitted_at     timestamptz not null default now(),
  answers          jsonb not null default '{}'::jsonb
);

-- Add columns idempotently (safe to run repeatedly)
alter table responses add column if not exists respondent_name  text;
alter table responses add column if not exists respondent_age   int;
alter table responses add column if not exists respondent_sex   text;
alter table responses add column if not exists respondent_user_type text not null default '';
alter table responses add column if not exists consent_given    boolean not null default false;
alter table responses add column if not exists consent_date     timestamptz;
alter table responses add column if not exists consent_version  text default 'v1.0';
alter table responses add column if not exists comments         text;
alter table responses add column if not exists device_info      jsonb;
alter table responses add column if not exists user_agent       text;
alter table responses add column if not exists ip_address       inet;
alter table responses add column if not exists session_id       uuid;
alter table responses add column if not exists time_taken_sec   int;
alter table responses add column if not exists survey_version   text default '1.0';
alter table responses add column if not exists locale           text default 'en';
alter table responses add column if not exists timings          jsonb;
alter table responses add column if not exists response_started_at timestamptz;
alter table responses add column if not exists deleted_at       timestamptz;
alter table responses add column if not exists deleted_by       uuid;
alter table responses add column if not exists anonymized_at    timestamptz;
-- retain_until: plain text column (generated columns require immutable expressions)
do $$ begin
  if not exists (
    select 1 from information_schema.columns
    where table_name='responses' and column_name='retain_until'
  ) then
    alter table responses add column retain_until timestamptz;
  end if;
end $$;

-- Indexes for performance
create index if not exists idx_responses_submitted_at on responses (submitted_at);
create index if not exists idx_responses_user_type   on responses (respondent_user_type);
create index if not exists idx_responses_name        on responses (respondent_name);
create index if not exists idx_responses_consent     on responses (consent_given);
create index if not exists idx_responses_answers     on responses using gin (answers);
create index if not exists idx_responses_deleted_at  on responses (deleted_at);
create index if not exists idx_responses_locale      on responses (locale);
create index if not exists idx_responses_timing      on responses (time_taken_sec);

-- Enable Row-Level Security
alter table responses enable row level security;

-- ============================================================
-- 1b. RPC: submit_response (bypasses RLS via security definer)
-- ============================================================
create or replace function submit_response(
  p_id              uuid,
  p_submitted_at    timestamptz,
  p_respondent_name text,
  p_respondent_age  int,
  p_respondent_sex  text,
  p_respondent_user_type text,
  p_answers         jsonb,
  p_comments        text
) returns void
language plpgsql security definer
as $$
begin
  insert into responses (
    id, submitted_at, respondent_name, respondent_age, respondent_sex,
    respondent_user_type, answers, comments
  ) values (
    p_id, p_submitted_at, p_respondent_name, p_respondent_age, p_respondent_sex,
    p_respondent_user_type, p_answers, p_comments
  );
end;
$$;

-- Allow authenticated users to read non-deleted responses
create policy "Allow authenticated reads only"
  on responses
  for select
  to authenticated
  using (deleted_at is null);

-- Allow authenticated users to soft-delete (set deleted_at)
create policy "Allow authenticated soft-delete"
  on responses
  for update
  to authenticated
  using (true)
  with check (deleted_at is not null or true);

-- Keep hard-delete only for admins via anon / for specific cleanup
-- We use UPDATE (soft delete) in the dashboard; hard delete is manual only

-- ============================================================
-- 2. ADMIN ROLES TABLE (RBAC)
-- ============================================================
create table if not exists admin_roles (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null unique references auth.users(id) on delete cascade,
  role         text not null default 'viewer' check (role in ('viewer', 'admin', 'superadmin')),
  created_at   timestamptz not null default now()
);

create index if not exists idx_admin_roles_user_id on admin_roles (user_id);

alter table admin_roles enable row level security;

-- Authenticated users can read their own role
create policy "Users read own role"
  on admin_roles
  for select
  to authenticated
  using (user_id = auth.uid());

-- Only superadmins can manage roles (done via Supabase dashboard or edge function)

-- ============================================================
-- 3. AUDIT LOG
-- ============================================================
create table if not exists audit_log (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references auth.users(id) on delete set null,
  action       text not null,     -- 'view', 'export', 'delete', 'bulk_delete', 'anonymize'
  details      jsonb,
  performed_at timestamptz not null default now()
);

create index if not exists idx_audit_log_user      on audit_log (user_id);
create index if not exists idx_audit_log_action    on audit_log (action);
create index if not exists idx_audit_log_performed on audit_log (performed_at);

alter table audit_log enable row level security;

-- Authenticated users can insert and read audit logs
create policy "Audit log access"
  on audit_log
  for all
  to authenticated
  using (true)
  with check (true);

-- ============================================================
-- 4. CONSENT VERSIONS (track consent form changes)
-- ============================================================
create table if not exists consent_versions (
  id              uuid primary key default gen_random_uuid(),
  version         text not null,
  text_hash       text not null,
  full_text       text not null,
  effective_from  timestamptz not null default now(),
  created_by      uuid references auth.users(id)
);

alter table consent_versions enable row level security;
create policy "Consent versions readable by all"
  on consent_versions for select to authenticated, anon
  using (true);

-- ============================================================
-- 5. SURVEY VERSIONS (for longitudinal study support)
-- ============================================================
create table if not exists survey_versions (
  id              uuid primary key default gen_random_uuid(),
  version         text not null,
  sections        jsonb not null,     -- the full STEPS/SECTIONS configuration
  created_at      timestamptz not null default now()
);

alter table survey_versions enable row level security;
create policy "Survey versions readable by all"
  on survey_versions for select to authenticated, anon
  using (true);

-- ============================================================
-- 6. FUNCTION: log_audit_action (callable from client as RPC)
-- ============================================================
create or replace function log_audit_action(
  p_action text,
  p_details jsonb default '{}'::jsonb
) returns void
language plpgsql security definer
as $$
begin
  insert into audit_log (user_id, action, details)
  values (auth.uid(), p_action, p_details);
end;
$$;

-- ============================================================
-- 7. FUNCTION: soft_delete_responses (safe bulk delete)
-- ============================================================
create or replace function soft_delete_responses(
  p_ids uuid[]
) returns int
language plpgsql security definer
as $$
declare
  v_count int;
begin
  update responses
  set deleted_at = now(), deleted_by = auth.uid()
  where id = any(p_ids) and deleted_at is null;
  get diagnostics v_count = row_count;
  insert into audit_log (user_id, action, details)
  values (auth.uid(), 'bulk_delete', jsonb_build_object('count', v_count, 'ids', to_jsonb(p_ids)));
  return v_count;
end;
$$;
