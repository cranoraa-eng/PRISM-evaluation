-- ============================================================
-- PRISM Needs Analysis — Supabase Setup
-- Run this ENTIRE SQL in your Supabase SQL Editor
-- https://supabase.com/dashboard → SQL Editor
-- ============================================================

-- 1. TEACHER RESPONSES TABLE
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

create index if not exists idx_nar_submitted_at on needs_analysis_responses (submitted_at);

alter table needs_analysis_responses enable row level security;

drop policy if exists "Allow anonymous inserts" on needs_analysis_responses;
create policy "Allow anonymous inserts"
  on needs_analysis_responses
  for insert
  to anon
  with check (true);

drop policy if exists "Allow authenticated reads" on needs_analysis_responses;
create policy "Allow authenticated reads"
  on needs_analysis_responses
  for select
  to authenticated
  using (true);

drop policy if exists "Allow authenticated deletes" on needs_analysis_responses;
create policy "Allow authenticated deletes"
  on needs_analysis_responses
  for delete
  to authenticated
  using (true);

-- Also allow anon reads so dashboard works without login toggle issues
drop policy if exists "Allow anon reads" on needs_analysis_responses;
create policy "Allow anon reads"
  on needs_analysis_responses
  for select
  to anon
  using (true);

-- ============================================================
-- ADMINISTRATOR RESPONSES TABLE
-- ============================================================

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

create index if not exists idx_nar_admin_submitted_at on needs_analysis_admin_responses (submitted_at);

alter table needs_analysis_admin_responses enable row level security;

drop policy if exists "Allow anonymous inserts" on needs_analysis_admin_responses;
create policy "Allow anonymous inserts"
  on needs_analysis_admin_responses
  for insert
  to anon
  with check (true);

drop policy if exists "Allow authenticated reads" on needs_analysis_admin_responses;
create policy "Allow authenticated reads"
  on needs_analysis_admin_responses
  for select
  to authenticated
  using (true);

drop policy if exists "Allow authenticated deletes" on needs_analysis_admin_responses;
create policy "Allow authenticated deletes"
  on needs_analysis_admin_responses
  for delete
  to authenticated
  using (true);

drop policy if exists "Allow anon reads" on needs_analysis_admin_responses;
create policy "Allow anon reads"
  on needs_analysis_admin_responses
  for select
  to anon
  using (true);

-- ============================================================
-- STUDENT RESPONSES TABLE
-- ============================================================

create table if not exists needs_analysis_student_responses (
  id                uuid primary key default gen_random_uuid(),
  submitted_at      timestamptz not null default now(),
  respondent_name   text,
  grade_subject     text not null default '',
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

create index if not exists idx_nar_student_submitted_at on needs_analysis_student_responses (submitted_at);

alter table needs_analysis_student_responses enable row level security;

drop policy if exists "Allow anonymous inserts" on needs_analysis_student_responses;
create policy "Allow anonymous inserts"
  on needs_analysis_student_responses
  for insert
  to anon
  with check (true);

drop policy if exists "Allow authenticated reads" on needs_analysis_student_responses;
create policy "Allow authenticated reads"
  on needs_analysis_student_responses
  for select
  to authenticated
  using (true);

drop policy if exists "Allow authenticated deletes" on needs_analysis_student_responses;
create policy "Allow authenticated deletes"
  on needs_analysis_student_responses
  for delete
  to authenticated
  using (true);

drop policy if exists "Allow anon reads" on needs_analysis_student_responses;
create policy "Allow anon reads"
  on needs_analysis_student_responses
  for select
  to anon
  using (true);
