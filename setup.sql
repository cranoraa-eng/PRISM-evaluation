-- ============================================================
-- PRISM Needs Analysis — Supabase Setup
-- Run this SQL in your Supabase SQL Editor
-- https://supabase.com/dashboard → SQL Editor
-- ============================================================

-- 1. CREATE TABLE
create table if not exists needs_analysis_responses (
  id                uuid primary key default gen_random_uuid(),
  submitted_at      timestamptz not null default now(),
  respondent_name   text,
  grade_subject     text not null default '',
  years_experience  text not null default '',
  comfort_level     text not null default '',
  devices           jsonb default '[]'::jsonb,
  attendance_method text,
  grading_method    text,
  materials_method  text,
  comms_method      text,
  challenge_answers jsonb default '{}'::jsonb,
  feature_answers   jsonb default '{}'::jsonb,
  top3_picks        jsonb default '[]'::jsonb,
  biggest_challenge text,
  missing_features  text,
  concerns          text
);

-- 2. INDEXES
create index if not exists idx_nar_submitted_at on needs_analysis_responses (submitted_at);
create index if not exists idx_nar_years_experience on needs_analysis_responses (years_experience);
create index if not exists idx_nar_comfort_level on needs_analysis_responses (comfort_level);

-- 3. ROW-LEVEL SECURITY
alter table needs_analysis_responses enable row level security;

-- Allow anonymous inserts (form submissions)
drop policy if exists "Allow anonymous inserts" on needs_analysis_responses;
create policy "Allow anonymous inserts"
  on needs_analysis_responses
  for insert
  to anon
  with check (true);

-- Allow authenticated reads (dashboard access)
drop policy if exists "Allow authenticated reads" on needs_analysis_responses;
create policy "Allow authenticated reads"
  on needs_analysis_responses
  for select
  to authenticated
  using (true);

-- Allow authenticated deletes (dashboard management)
drop policy if exists "Allow authenticated deletes" on needs_analysis_responses;
create policy "Allow authenticated deletes"
  on needs_analysis_responses
  for delete
  to authenticated
  using (true);

-- ============================================================
-- ADMINISTRATOR RESPONSES TABLE
-- ============================================================

-- 4. CREATE TABLE (Admin)
create table if not exists needs_analysis_admin_responses (
  id                uuid primary key default gen_random_uuid(),
  submitted_at      timestamptz not null default now(),
  respondent_name   text,
  admin_role        text not null default '',
  years_experience  text not null default '',
  comfort_level     text not null default '',
  devices           jsonb default '[]'::jsonb,
  attendance_method text,
  grading_method    text,
  materials_method  text,
  comms_method      text,
  challenge_answers jsonb default '{}'::jsonb,
  feature_answers   jsonb default '{}'::jsonb,
  top3_picks        jsonb default '[]'::jsonb,
  biggest_challenge text,
  missing_features  text,
  concerns          text
);

-- 5. INDEXES (Admin)
create index if not exists idx_nar_admin_submitted_at on needs_analysis_admin_responses (submitted_at);
create index if not exists idx_nar_admin_role on needs_analysis_admin_responses (admin_role);
create index if not exists idx_nar_admin_comfort_level on needs_analysis_admin_responses (comfort_level);

-- 6. ROW-LEVEL SECURITY (Admin)
alter table needs_analysis_admin_responses enable row level security;

-- Allow anonymous inserts (form submissions)
drop policy if exists "Allow anonymous inserts" on needs_analysis_admin_responses;
create policy "Allow anonymous inserts"
  on needs_analysis_admin_responses
  for insert
  to anon
  with check (true);

-- Allow authenticated reads (dashboard access)
drop policy if exists "Allow authenticated reads" on needs_analysis_admin_responses;
create policy "Allow authenticated reads"
  on needs_analysis_admin_responses
  for select
  to authenticated
  using (true);

-- Allow authenticated deletes (dashboard management)
drop policy if exists "Allow authenticated deletes" on needs_analysis_admin_responses;
create policy "Allow authenticated deletes"
  on needs_analysis_admin_responses
  for delete
  to authenticated
  using (true);
