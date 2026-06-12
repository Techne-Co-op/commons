# cis-repo-seed v0.1

The executable scaffold for building the RegenHub, LCA Common Information System and
Hub Operations surface on GitHub Pages + Supabase, by LLM agents under human direction.

Provenance: generated from the Private Alpha Implementation Plan v0.1 (draft), grounded
in CIS PRD v0.2 and Hub Operations PRD v0.1. Status: draft for review; nothing here is
ratified; all 70 ledger entries are honestly `pending` or `in_progress`.

## What this contains

- `AGENTS.md` \u00b7 the operating contract every executing agent reads first
- `GOVERNANCE.md` \u00b7 the ledger's mechanics: schema, lifecycle, validation
- `milestones/` \u00b7 70 entries (steps, decisions, ratifications, gate, practice;
  67 seeded + W0.19–W0.22 added June 2026),
  plus generated `index.json` and `STATUS.md`
- `milestones/schema.json` \u00b7 machine-readable front-matter schema
- `scripts/validate.py` \u00b7 working validator (tested against this seed)
- `scripts/gen_seed.py` \u00b7 regenerates the seed from plan data; source of truth
- `docs/decisions/` \u00b7 deliberation briefs D1\u2013D10, R1, R2, all `open`
- `docs/VERIFICATION.md` \u00b7 contract cards for the named CI jobs
- `docs/CONVENTIONS.md` \u00b7 SQL, RLS, event-envelope, and vocabulary rules
- `docs/citations.md` \u00b7 draft-bylaws and grant citation register (D7)
- `docs/SECRETS.md` \u00b7 secret names and custody (names only, never values)
- `.github/` \u00b7 milestone-validate workflow and PR template

## Bootstrap (human steps, in order)

1. Decide D3 (record it in `docs/decisions/D3.md`), create the org/repo, push this seed.
2. Apply branch protection; require `milestone-validate`.
3. Proceed per `AGENTS.md`: the first agent-executable step is W0.1's agent half,
   then W0.2 wires this scaffold into CI.

Validate locally: `pip install -r scripts/requirements.txt && python scripts/validate.py`
