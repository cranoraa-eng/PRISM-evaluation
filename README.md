# PRISM — Teacher Needs Analysis Questionnaire

## Deployment Guide

### Project Structure

```
PRISM-evaluation-main/
  index.html      ← Needs analysis questionnaire (static, single-file)
  admin.html      ← Results dashboard with charts and CSV export
  setup.sql       ← Supabase table schema + RLS policies
  README.md       ← This file
```

---

## 1. Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and sign in (free tier works).
2. Click **"New project"** → name it (e.g. `prism-needs`) → set a database password → pick a region → click **Create**.
3. Wait ~2 minutes for the project to spin up.
4. In the left sidebar, click **SQL Editor**.
5. Paste the contents of `setup.sql` and click **Run**. This creates the `needs_analysis_responses` table with RLS policies.
6. Go to **Settings → API** and copy:
   - **Project URL** — `https://xxxxxxxx.supabase.co`
   - **anon public key** — starts with `eyJ...`

---

## 2. Connect Supabase to the Forms

Both `index.html` and `admin.html` already contain the Supabase URL and anon key. If you created a new project, update these values in both files:

```js
const SUPABASE_URL  = "https://your-project.supabase.co";
const SUPABASE_ANON = "your-anon-key";
```

---

## 3. Deploy to Vercel

### Option A — Drag & Drop (fastest)

1. Go to [vercel.com](https://vercel.com) and sign in.
2. Click **"Add New → Project"** → select the **"Upload"** tab.
3. Drag the project folder onto the upload area.
4. Vercel detects it as a static site. Click **Deploy**.
5. You'll get a live URL like `https://prism-needs.vercel.app`.

### Option B — Git + Auto-Deploy

1. Push this folder to a GitHub repo.
2. On Vercel, click **"Add New → Project"** → import the repo.
3. Leave settings as defaults (Framework: `Other`, Build Command: empty).
4. Click **Deploy**. Vercel auto-deploys on every push.

---

## 4. Admin Dashboard

Navigate to `admin.html` (e.g. `https://your-site.vercel.app/admin.html`) to access the dashboard.

- **Sign in** with your Supabase Auth email/password (create one in Authentication → Users).
- View response stats, charts, and export data as CSV.
- Filter by experience level, comfort level, or search terms.

---

## Questionnaire Sections

| Part | Title | Content |
|------|-------|---------|
| I | Respondent Profile | Name (optional), grade/subject, years of experience, ICT comfort level, available devices |
| II | Current Practices | 4 questions on how teachers handle attendance, grading, materials, communication |
| III | Challenges Encountered | 8-item Likert scale (1–4) on common school management challenges |
| IV | Feature Priorities | 10-item Likert scale (1–4) on proposed system features + top 3 picker |
| V | Additional Feedback | Open-ended textareas for biggest challenge, missing features, concerns |

---

## Database Schema

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key (auto-generated) |
| `submitted_at` | timestamptz | Submission timestamp |
| `respondent_name` | text | Optional name |
| `grade_subject` | text | Grade level and subject taught |
| `years_experience` | text | Teaching experience range |
| `comfort_level` | text | ICT comfort level |
| `devices` | jsonb | Array of available devices |
| `attendance_method` | text | Current attendance method |
| `grading_method` | text | Current grading method |
| `materials_method` | text | Current materials distribution method |
| `comms_method` | text | Current communication method |
| `challenge_answers` | jsonb | Likert ratings for challenges (1-4) |
| `feature_answers` | jsonb | Likert ratings for features (1-4) |
| `top3_picks` | jsonb | Array of top 3 chosen features |
| `biggest_challenge` | text | Open-ended response |
| `missing_features` | text | Open-ended response |
| `concerns` | text | Open-ended response |

---

## How It Works

- Both `index.html` and `admin.html` are single-file static pages — no build step, no framework.
- On submit, the questionnaire inserts directly into Supabase using the anon key.
- Row-Level Security allows anonymous inserts but blocks reads, so respondents cannot see others' data.
- The dashboard requires Supabase Auth login to read data.
- Charts are rendered with Chart.js (loaded from CDN).
- CSV export generates a file client-side from the filtered data.
