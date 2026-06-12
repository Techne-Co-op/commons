# SUPABASE_SETUP.md · Supabase project reference

Two Supabase projects underpin the CIS. This file documents what is known and
explicitly marks what is not yet specified. It is a living document; entries are
updated as milestones are built. Addresses audit findings DF-02, DF-04, DF-07.

---

## Projects

### Main CIS project (W0.3 and onward)

| Key | Value |
|---|---|
| Project URL | Not yet provisioned (W0.3 pending) |
| Anon key | To be committed in `loop.config.js` when provisioned |
| Service role key | GitHub Actions secret `SUPABASE_SERVICE_ROLE_KEY`; Supabase function env only |
| Project ref | GitHub Actions secret `SUPABASE_PROJECT_REF` |

### Signal Loop project (live — see `loop.config.js`)

The Loop instrument runs on a separate Supabase project provisioned before the
main CIS project. It holds the decision–blocker ledger only.

| Key | Value |
|---|---|
| Project URL | `https://dgcoffcanzwsuwgpocbt.supabase.co` |
| Anon key | Public in `loop.config.js` (publishable; safety is RLS completeness) |
| Service role key | `LOOP_SERVICE_ROLE_KEY` — Supabase function env, held by Todd |
| Ingest token | `LEDGER_INGEST_TOKEN` — GitHub Actions secret + Supabase function env |

---

## Signal Loop schema (current — live project)

### `ledger_entries`

The primary table written by `ledger-ingest`. One row per milestone per ingest run.

| Column | Type | Notes |
|---|---|---|
| id | uuid | primary key |
| sha | text | git commit SHA of the push that triggered ingest |
| generated_at | timestamptz | timestamp from the ingest payload |
| milestone_id | text | milestone id from index.json (e.g. `W0.1`, `D3`) |
| status | text | status value from the milestone file |
| wave | text | wave token |
| kind | text | step \| decision \| ratification \| gate \| practice |
| is_blocker | boolean | true when kind is decision or ratification and status is not decided |
| title | text | milestone title |
| payload | jsonb | full milestone object as ingested |
| created_at | timestamptz | default now() |

**Upsert vs. append:** The `ledger-ingest` function **upserts** on `(sha, milestone_id)`.
This means: each git push produces a complete snapshot row per milestone, keyed to
the commit SHA. Historical snapshots are preserved — a new push does not overwrite
prior-SHA rows. The history of milestone states across commits is queryable. This
is the append behavior appropriate for an auditable cooperative record.

*Status: inferred from loop-sync behavior and schema observation. To be confirmed
when ledger-ingest source is checked in at W0.9.*

### `v_decision_leverage` (view)

Read by `loop.html` via the Supabase REST API (`/rest/v1/v_decision_leverage`).

**Columns (inferred from loop.html query):**

| Column | Notes |
|---|---|
| decision_id | milestone id of the open decision (e.g. `D4`) |
| decision_title | title of the decision |
| blocked_milestone_id | milestone blocked by this open decision |
| blocked_milestone_title | title of the blocked milestone |
| wave | wave of the blocked milestone |
| leverage | integer — count of milestones blocked by this decision |

**DDL (inferred; to be confirmed and committed as a migration at W0.3/W0.22):**

```sql
create or replace view public.v_decision_leverage as
select
  d.milestone_id                          as decision_id,
  d.title                                 as decision_title,
  b.milestone_id                          as blocked_milestone_id,
  b.title                                 as blocked_milestone_title,
  b.wave,
  count(*) over (partition by d.milestone_id)::int as leverage
from ledger_entries d
join lateral (
  select le.milestone_id, le.title, le.wave
  from ledger_entries le
  where le.is_blocker = false
    and le.payload->'decision_refs' ? d.milestone_id
) b on true
where d.is_blocker = true
  and d.sha = (select max(sha) from ledger_entries)
order by leverage desc, d.decision_id;
```

*Status: inferred. Actual DDL is in the Supabase dashboard. Will be committed as
a migration when W0.3 provisions the schema formally.*

**RLS policy:** The view inherits from `ledger_entries`. If `ledger_entries` has
RLS enabled and forced, the view is governed by the table's policies. For the
signal loop project, the anon key can read `v_decision_leverage` — this is
intentional; the decision-blocker state is public information.

---

## Main CIS project schema (planned — not yet provisioned)

The full schema is specified across: CIS PRD v0.2 §06, Hub Ops PRD v0.1 §04, and
C6 (schema reference card). 31 tables: 19 cooperative core + 12 Hub extensions.

Migrations will live in `supabase/migrations/<timestamp>_<slug>.sql`, authored at
their respective milestones (W0.3–W0.9, W1.1–W1.8, W2.1–W2.9, W3.1–W3.7, etc.).

Each migration: timestamped, append-only, one concern per file. Every table ships
RLS-enabled and forced in the same migration that creates it, per `docs/CONVENTIONS.md`.

---

## Edge Functions (planned)

Functions will live in `supabase/functions/` and be deployed by `ci:functions-deploy`
(W0.9). Until then, only `ledger-ingest` is live (on the loop project, not yet
checked in).

| Function | Project | Status | Milestone |
|---|---|---|---|
| ledger-ingest | loop | live (source not in repo) | W0.22 |
| hello | main | planned | W0.9 |
| email-send | main | planned | W0.11 |
| nou-gateway | main | planned | W1.7 |
| mercury-ingest | main | planned | W3.4 |

*`ledger-ingest` source must be committed to the repository at W0.22. Until then,
it is a black-box dependency — a known documentation debt.*

---

## Supabase CLI setup (for contributors at W0.3)

```bash
# Install
npm install -g supabase

# Link to project
supabase login
supabase link --project-ref <SUPABASE_PROJECT_REF>

# Apply migrations to shadow (local)
supabase db reset

# Push to hosted project (CI only — never manual)
supabase db push
```

The `db-verify` CI job (W0.4) automates this: applies migrations to a clean shadow,
runs pgTAP suites, and pushes to the hosted project on green main. Manual pushes
to the hosted project are prohibited.

---

*Maintained under human review. Entries marked "inferred" must be confirmed against
the live Supabase project and the DDL committed as migrations before W0.3 closes.*
