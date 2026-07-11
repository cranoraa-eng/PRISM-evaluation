-- Run this SQL in your Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)
-- Then create admin users: Authentication → Users → Add User

-- ============================================================
-- 1. RESPONSES TABLE (with audit, metadata, soft-delete, consent version)
-- ============================================================
create table if not exists responses (
  id               uuid primary key,
  submitted_at     timestamptz not null default now(),
  respondent_name  text,
  respondent_age   int,
  respondent_sex   text,
  respondent_user_type text not null,
  consent_given    boolean not null default false,
  consent_date     timestamptz,
  consent_version  text default 'v1.0',
  answers          jsonb not null default '{}'::jsonb,
  comments         text,

  -- Quality & audit metadata
  device_info      jsonb,
  user_agent       text,
  ip_address       inet,
  session_id       uuid,
  time_taken_sec   int,
  survey_version   text default '1.0',
  locale           text default 'en',
  timings          jsonb,
  response_started_at timestamptz,

  -- Soft-delete & retention
  deleted_at       timestamptz,
  deleted_by       uuid,
  anonymized_at    timestamptz,
  retain_until     timestamptz generated always as (submitted_at + interval '3 years') stored
);

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

-- Drop existing policies to recreate
drop policy if exists "Allow anonymous inserts" on responses;
drop policy if exists "Allow authenticated reads only" on responses;
drop policy if exists "Allow authenticated deletes only" on responses;

-- Allow anonymous inserts only (respondents submitting the form)
create policy "Allow anonymous inserts"
  on responses
  for insert
  to anon
  with check (true);

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
