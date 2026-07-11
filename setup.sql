-- Run this SQL in your Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)
-- Then create an admin user: Authentication → Users → Add User

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

-- Enable Row-Level Security
alter table responses enable row level security;

-- Allow anonymous inserts only (respondents submitting the form)
create policy "Allow anonymous inserts"
  on responses
  for insert
  to anon
  with check (true);

-- Allow only authenticated users (admin) to read responses
create policy "Allow authenticated reads only"
  on responses
  for select
  to authenticated
  using (true);

-- Allow only authenticated users (admin) to delete responses
create policy "Allow authenticated deletes only"
  on responses
  for delete
  to authenticated
  using (true);
