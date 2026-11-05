# EntreCorps Evaluations

A web app that runs peer performance reviews for **EntreCorps**, a student consulting club at the University of Illinois. It replaced four Google Forms and a hand-merged spreadsheet with one site where every member signs in, sees exactly who they need to review, and leadership watches results come in live.

**Live:** https://entre-corps-perfomance-evaluation-4.vercel.app (sign-in is limited to club members' Illinois accounts)

**In use:** Fall 2026 mid-term evaluations · 60+ members · 8 client projects

---

## The problem

Every review cycle, members filled out four separate Google Forms (Self, Manager, Upward, Leadership), typed their own names, and picked who they were reviewing from long dropdowns of the whole club. Someone then merged the responses into a spreadsheet by hand to compute scores. Names were misspelled, reviews went missing, and nobody could tell who still owed what.

## What it does

- **Sign in with Google**, restricted to `@illinois.edu`. Nobody picks their own name; the app knows who you are from your verified email.
- **A personal to-do list.** Each member's evaluations are generated from their role and project team:
  | Role | Reviews they write |
  |---|---|
  | Consultant | Self, plus an Upward review of their PM and Senior Consultant |
  | Project Manager / Senior Consultant | Self, a Manager review of each consultant, and a peer review of each other |
  | Leadership (SLT) | A review of each PM and SC on the projects they oversee |
  | External Lead (client partner) | A Manager review of each consultant on their project; never reviewed themselves |
- **Mobile-first forms** with large 1–5 rating buttons, drafts that survive a closed tab, and edits allowed until the round closes.
- **Live scoring.** Each review is averaged, grouped into Self / Manager / Upward / Leadership components by who wrote it, then combined into a role-weighted composite. If a component is missing, the remaining weights are renormalized.
- **Leadership dashboard:** a completion tracker per project, a "who still owes what" list with a copyable reminder list, a sortable scores table, per-person detail pages, a project summary chart, and CSV exports.
- **"My project" page for PMs and SCs:** their consultants' scores and comments, plus anonymous feedback about themselves that only appears once **at least 3** consultants have responded, so no single review can be traced back.
- **Admin page:** roster CSV import, projects, opening and closing rounds, editable score weights, and settings.

## How it's built

| Layer | Choice |
|---|---|
| Framework | Next.js 15 (App Router, Server Components, Server Actions), TypeScript |
| Styling | Tailwind CSS v4, custom design tokens in Illinois navy and orange |
| Database | Supabase Postgres |
| Auth | Supabase Auth with Google OAuth |
| Validation | Zod (one schema checks the form in the browser and again on the server) |
| Charts | Recharts |
| Hosting | Vercel, auto-deploying from `main` |
| Tests | Vitest |

### Security lives in the database

The browser never decides who can see what. Every table has **row-level security** policies keyed to the signed-in user's email:

- Members can read only the evaluations they wrote, and only their own email address.
- Insert policies call a SQL function, `can_evaluate()`, that checks the reviewer and reviewee's roles and shared project, so a consultant can't submit a review they weren't assigned, even from the browser console.
- Edits are only possible while a round is open.
- A trigger snapshots each person's role at submission time and enforces per-form rules (for example, Leadership is required on Upward reviews and not allowed on Manager reviews).
- Leadership-only data is served through `SECURITY DEFINER` functions that check the caller first, and signed-out visitors can't call data-returning functions at all.

### Scoring in SQL

`person_scores()` computes every member's component scores and weighted composite in one query, matching the formulas from the club's original spreadsheet. A TypeScript mirror in `src/lib/scoring.ts` is unit-tested against hand-calculated examples.

### Database migrations

The schema evolved with the club's needs, one migration at a time (`supabase/migrations/`):

| # | Change |
|---|---|
| 0001–0005 | Core schema, review-assignment rules, row-level security, scoring, completion tracking |
| 0006 | Leadership reviews scoped to staffed projects; optional "what can leadership help with?" question |
| 0007 | My project page for PMs and SCs, with the 3-response anonymity threshold |
| 0008 | "Slide Design" rating for consultants, folded into the averages |
| 0009–0010 | External Lead role for client partners, with read-only dashboard access |
| 0011 | Locked down function access after a Supabase security-advisor review |

## Testing

Before launch I ran the whole workflow against the live database as each role, with security on:

- Each role saw exactly the right to-do list.
- Blocked actions stayed blocked: reviewing someone off your project, reading others' reviews, changing weights or settings, promoting yourself to leadership, and editing after a round closed.
- Computed scores matched a hand calculation (for example, a composite of 3.84).

```bash
npm test        # scoring, form-validation and roster-parsing tests
npm run build
```

## Run it locally

```bash
npm install
cp .env.local.example .env.local   # add your Supabase URL and anon key
npm run dev                        # http://localhost:3000
```

Apply the files in `supabase/migrations/` in order to a Supabase project, and enable the Google provider in Supabase Auth. The full specification is in [`docs/BUILD_GUIDE.md`](docs/BUILD_GUIDE.md).

Member data (the roster, emails and evaluations) lives only in the database and is never committed to this repository.
