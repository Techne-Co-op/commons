# VERIFICATION.md · contract cards for the named CI jobs

Every success_state in the ledger names its verification. These cards define what each
job asserts, so building the job is itself specifiable work and a success_state is
never circular.

**Status key:**
- `LIVE` — workflow exists in `.github/workflows/` and runs on push/PR
- `PLANNED` — specification only; implemented at the named milestone step

Audit finding SF-01 (pre-build-audit-v0.1.html) noted that an earlier version of
this file read as though all jobs were live. The status markers below correct that.

---

## milestone-validate · LIVE · `.github/workflows/milestone-validate.yml`

Triggers on push and PR. Asserts: schema validity per milestones/schema.json; unique
ids; filename-id match; dependency resolution incl. wave tokens; acyclic graph; status
gating (nothing past pending with unverified parents; blocked requires reason; D/R
entries human-owned). Regenerates index.json and STATUS.md. PR-only: fails when code
paths change without a milestones/ touch.

## loop-sync · LIVE · `.github/workflows/loop-sync.yml`

Triggers on push to main when milestones/index.json changes. POSTs the index to the
ledger-ingest Supabase edge function; rebuilds ledger_entries; returns a snapshot
record. Failure is non-blocking (continue-on-error). See docs/SUPABASE_SETUP.md for
the ingest contract.

## repo-policy · PLANNED · W0.1

Asserts presence of README, GOVERNANCE.md, AGENTS.md, CODEOWNERS, PR template; reads
branch-protection settings via API and asserts required checks include
milestone-validate. Pass: all assertions green.

## db-verify · PLANNED · W0.4 (connection stage at W0.3)

Spins an ephemeral Postgres; applies all migrations in order to the clean shadow; runs
pgTAP suites under supabase/tests. On main only, after green, pushes migrations to the
hosted project. Pass: clean apply + all pgTAP green. Restore stage (W0.14): restores the
latest export snapshot into a clean database and re-runs structural assertions.

## rls-audit · PLANNED · W0.6, extended every schema step

pgTAP suite asserting: every table in schema public has rowsecurity enabled and forced;
every policy carries a citation comment matching docs/citations.md format; anonymous
probe (anon role) is denied on every protected table; cross-member probe (member B
reading member A) is denied per scope; the single sanctioned anon insert (W2.2) accepts
only its declared columns. Auth probes (W0.5): non-invited sign-up rejected; claims
present. Nou probes (W1.7): a cross-member query through the gateway is refused
identically to a direct query. Pass: zero policy gaps, zero probe leaks.

## grammar-lint · PLANNED · W0.16

Word-boundary scan of migrations, UI strings, and docs for the forbidden vocabulary in
docs/CONVENTIONS.md; allowlist entries require an inline justification comment. Pass:
no unallowlisted hits.

## functions-deploy · PLANNED · W0.9

Deploys supabase/functions from CI; smoke-calls the hello function with a test JWT and
asserts role echo; secret-scan asserts no service-role key or provider secret appears
outside function env. Pass: deploy green + smoke green + scan clean.

## portal-build / pages-deploy · PLANNED · W0.12

Builds the static portal; fails if any non-public secret is referenced; deploys to
Pages on main; asserts 200 on the alpha domain with the build SHA present, 404 SPA
fallback works on a deep link, and noindex is present. Pass: all assertions green.

## status-mirror · PLANNED · W0.18

On main after validate: POSTs milestones/index.json to the build_status ingest
function; asserts a 2xx and that the row count matches entries. Pass: mirror confirmed.

## exports-cron · PLANNED · W0.14

Scheduled on both rails; writes per-table open-format snapshots plus a full dump to
Storage; records a job_run event. Pass: artifacts present + event row written.
