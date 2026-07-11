# PRISM Evaluation Questionnaire — Deployment Guide

## Project Structure

```
Evaluation Web/
  index.html    ← the full evaluation tool (HTML + CSS + JS)
  setup.sql     ← Supabase table schema
```

---

## Part 1: Set Up Supabase

1. Go to [supabase.com](https://supabase.com) and sign in (free tier is fine).
2. Click **"New project"** → give it a name (e.g. `prism-eval`) → set a database password → pick a region close to you → click **Create**.
3. Wait ~2 minutes for the project to spin up.
4. In the left sidebar, click **SQL Editor**.
5. Paste the contents of `setup.sql` into the editor and click **Run**. This creates the `responses` table.
6. Go to **Settings → API** (in the left sidebar). Copy these two values:
   - **Project URL** — looks like `https://xxxxxxxx.supabase.co`
   - **anon public key** — starts with `eyJ...`

---

## Part 2: Connect Supabase to the Form

1. Open `index.html` in a text editor.
2. Find these two lines near the top:

   ```js
   const SUPABASE_URL  = "YOUR_SUPABASE_URL";
   const SUPABASE_ANON = "YOUR_SUPABASE_ANON_KEY";
   ```

3. Replace them with your actual values:

   ```js
   const SUPABASE_URL  = "https://xxxxxxxx.supabase.co";
   const SUPABASE_ANON = "eyJhbGciOiJIUzI1NiIs...";
   ```

4. Save the file.

---

## Part 3: Deploy to Vercel

### Option A — Drag & Drop (fastest)

1. Go to [vercel.com](https://vercel.com) and sign in (free tier is fine).
2. Click **"Add New → Project"**.
3. Select the **"Upload"** tab.
4. Drag the entire `Evaluation Web` folder onto the upload area.
5. Vercel will detect it as a static site. Click **Deploy**.
6. Done — you'll get a live URL like `https://prism-eval.vercel.app`.

### Option B — Git + Auto-Deploy

1. Create a new GitHub repo and push this folder to it.
2. On Vercel, click **"Add New → Project"**.
3. Import the GitHub repo.
4. Leave all settings as defaults (Framework = `Other`, Build Command = empty).
5. Click **Deploy**. Vercel will auto-deploy on every push.

---

## Part 4: Custom Domain (optional)

1. In your Vercel project dashboard, go to **Settings → Domains**.
2. Add your custom domain and follow the DNS instructions.

---

## Viewing Responses

1. Go to your Supabase dashboard → **Table Editor**.
2. Open the `responses` table to see all submitted answers.
3. Each row contains the respondent info, all 44 Likert answers (as JSON), and optional comments.

---

## How It Works

- The form is a single static `index.html` — no build step, no framework.
- On submit, the JS calls `supabaseClient.from('responses').insert(...)` to save the response.
- Supabase Row-Level Security allows anonymous inserts but blocks reads (so respondents can't see others' data).
