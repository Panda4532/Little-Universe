# Little Universe — Birthday Gift Website

A dark, cinematic, personalized digital birthday (or anniversary, Valentine's, graduation, wedding) gift builder. Someone writes a message, uploads photos, picks a theme and a soundtrack, and publishes a link that opens into a fullscreen animated experience for the recipient — no account needed on their end.

## What this actually is

This is **one self-contained HTML file** (`index.html`) — no framework, no build step, no `npm install`. All the HTML, CSS and JavaScript live in that single file. It talks directly to a [Supabase](https://supabase.com) project for real accounts, a real database, and real file storage.

```
your-repo/
├── index.html            ← the entire website
├── supabase-schema.sql   ← run this once in Supabase to set up your database
└── README.md
```

## Features

- Email/password signup, login, logout (real Supabase Auth — passwords are hashed by Supabase, never touch your code)
- Optional "Continue with Google" sign-in
- Dashboard: create, edit, duplicate, delete, and publish multiple gifts
- 7-step editor: recipient + occasion, messages, photos, soundtrack, theme, preview, publish
- 9 visual themes, each with its own colors and opening line
- Occasion picker (Birthday, Anniversary, Valentine's Day, Graduation, Wedding) — wording throughout the gift adjusts automatically
- Real photo uploads (JPG/PNG/WEBP, up to 10) stored in Supabase Storage, used as a cinematic crossfading background
- Real MP3/WAV/OGG background music upload, or a pasted streaming link instead
- Local template-based "AI" writing assistant (see [Known Limitations](#known-limitations))
- A panda greeter that welcomes the *recipient* by name and occasion before the gift opens
- Autosave with a "Saving… / Saved" indicator
- Publish → shareable link (`yoursite.com/#gift=<id>`) that works on **any device, no login required** — this is a real cross-device link backed by the database, not a local-only demo link
- View counter on published gifts
- Mobile-responsive editor (the phone preview is hidden while you're actively filling out the form, so it doesn't crowd out the fields — it reappears once you reach the Preview/Publish steps)

## Requirements

- A free [Supabase](https://supabase.com) account
- A free [GitHub](https://github.com) account
- A free [Vercel](https://vercel.com) account

No local dev environment, Node.js, or command line is required to run this — it's one HTML file.

## Setup

### 1. Create your Supabase project
Go to [supabase.com](https://supabase.com) → New Project. Pick a name and a database password (save the password somewhere).

### 2. Run the database schema
In your Supabase project: **SQL Editor → New query** → paste the entire contents of `supabase-schema.sql` → **Run**.

This one-time step creates:
- a `gifts` table (one row per gift, private to its owner until published)
- a `gift_photos` table (ordered photos belonging to a gift)
- Row Level Security policies, so users can only ever see their own drafts, and anyone can only see a gift once it's published
- a public `gift-media` Storage bucket for photos and uploaded songs
- a safe `increment_gift_views` function so view counts can go up without exposing anything else

### 3. Get your API keys
Supabase Dashboard → **Project Settings → API**. Copy the **Project URL** and the **anon public** key.

### 4. Paste your keys into `index.html`
Open `index.html`, find these two lines near the top of the `<script>` tag, and replace the placeholders:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_PROJECT_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_PUBLIC_KEY';
```

The anon key is safe to expose in client-side code — it only ever does what your Row Level Security policies allow.

### 5. Deploy
- Push `index.html` (and `supabase-schema.sql`, `README.md` for reference) to a GitHub repo.
- In Vercel: **Add New → Project** → import that repo → **Deploy**. No build command or framework settings needed — Vercel serves it as a static site automatically.

### 6. (Optional) Turn on Google sign-in
This needs a one-time setup in both Google Cloud Console (free, no billing required) and your Supabase project's Auth provider settings. Ask me if you want the step-by-step again — we walked through it earlier in this project.

## How the data works

| Table / bucket | Holds |
|---|---|
| `gifts` | name, occasion, theme, messages, "little things," soundtrack link, publish status, view count |
| `gift_photos` | each uploaded photo's URL, storage path, and order |
| `gift-media` (Storage) | the actual photo and audio files |

Every table has Row Level Security turned on:
- **Owners** can do anything with their own gifts (edit, delete, upload photos).
- **Anyone** (no login) can only ever `SELECT` a gift that has `published = true` — drafts are never publicly reachable.

## Publishing & sharing

Clicking **Publish** or **Share** sets `published = true` on that gift and gives you a link like:

```
https://yoursite.vercel.app/#gift=3fa85f64-5717-4562-b3fc-2c963f66afa6
```

Opening that link — on any device, any browser, no account — fetches just that one published gift from Supabase and runs the fullscreen recipient experience. Unpublishing (from the editor's Publish step) makes the link stop working again.

## Known Limitations

Things that are intentionally simple right now, so you know what you're looking at:

- **Profile and Settings pages are placeholders.** They show a short message but don't yet let you change your name, email, or password from the UI. (Supabase itself supports all of this — the pages just aren't wired up.)
- **No "Forgot password" flow yet.** Supabase supports password resets, but there's no page in this build for it yet.
- **The "AI" writing assistant is not real AI.** It picks from a small set of local text templates based on the relationship/tone you choose. It's clearly labeled as such in the UI. Wiring up a real AI model would need a server-side API route so your key isn't exposed in the browser — this single-file version doesn't have a backend to put that on.
- **Free Supabase projects pause after 7 days of no activity.** If your site seems to stop working after a week of nobody visiting it, just open your Supabase dashboard once to wake the project back up.
- **Google sign-in needs its own setup** in Google Cloud Console before that button will work (see above).

## Troubleshooting

**Blank screen, nothing loads at all**
Almost always a JavaScript error before the page ever draws itself. Open the browser Console (F12) and look for a red error — the site itself will also show a plain-English error banner instead of a blank screen if something's misconfigured (like a leftover placeholder key, or two conflicting declarations of the same variable).

**Share link says the gift "isn't available"**
That gift's `published` column is still `false` in the database. Open it from your dashboard and hit **Publish** or **Share** again, and wait for the "✓ Published" confirmation before sending the link.

**Uploads fail**
Check that `supabase-schema.sql` actually ran successfully and that the `gift-media` bucket exists under **Storage** in your Supabase dashboard and is marked **Public**.

---

Made with ❤️ by Tushar Goyal
