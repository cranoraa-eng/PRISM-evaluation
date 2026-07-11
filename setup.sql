-- Run this SQL in your Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)

create table if not exists responses (
  id              uuid primary key,
  submitted_at    timestamptz not null default now(),
  respondent_name text,
  respondent_age  int,
  respondent_sex  text,
  respondent_user_type text not null,
  consent_given   boolean not null default false,
  consent_date    timestamptz,
  answers         jsonb not null default '{}'::jsonb,
  comments        text
);

-- Enable Row-Level Security (recommended)
alter table responses enable row level security;

-- Allow anonymous inserts (needed for the public form)
create policy "Allow anonymous inserts"
  on responses
  for insert
  to anon
  with check (true);

-- Allow anonymous reads (for the admin dashboard — password-protected client-side)
create policy "Allow anonymous reads"
  on responses
  for select
  to anon
  using (true);

-- Allow authenticated reads (if using Supabase Auth)
create policy "Allow authenticated reads"
  on responses
  for select
  to authenticated
  using (true);
