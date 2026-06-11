# GOVERNANCE.md · the ledger's mechanics

This repository is the milestone system. Every unit of work, decision, and gate is a
file under `milestones/`; every status change is a commit; the git history is the audit
trail. Provenance: seeded from the Private Alpha Implementation Plan v0.1 (draft, June
2026), itself grounded in CIS PRD v0.2 and Hub Operations PRD v0.1.

## Entry schema

Front matter per `milestones/schema.json`. Fields: `id` (immutable), `title`, `wave`
(D, R, W0..W6, G, P), `kind` (step, decision, ratification, gate, practice), `owner`,
`status`, `detail` (briefed or seeded), `depends_on` (ids, or a wave token like `W1`
meaning the coarse edge: that whole wave verified), `decision_refs`, `success_state`,
`verification` (`ci:<job>`, `human:<role>`, or `counsel`), optional `activates`
(dashed edges: switch behavior on, never block build), gates add `requires_steps`
and `requires_decisions`, blocked entries add `blocked_reason`.

## Status lifecycle

`pending -> in_progress -> review -> done -> verified`, with `blocked` reachable from
any state (reason required). Two rules carry the audit property: a step may not leave
`pending` until every expanded parent is `verified`; and `done` (merged) is distinct
from `verified` (success_state demonstrated by the named verification on the merged
commit, or an approving review by the named human role on the status-flip commit).
Only `verified` unlocks dependents. Status changes occur only by editing the milestone
file in the same PR as the work, so graph state and code state cannot diverge.

## Validation

`scripts/validate.py` runs on every push and PR (`.github/workflows/milestone-validate.yml`):
schema, unique ids, filename-id match, dependency resolution including wave tokens,
acyclicity, gating, human ownership of D and R entries. It regenerates
`milestones/index.json` and `milestones/STATUS.md`; on main these are committed back.
`milestone-validate` is a required check; so are the verification jobs named across
the ledger as they come into existence (see `docs/VERIFICATION.md`).

## Seeded detail

Entries marked `detail: seeded` (W3.1\u2013W3.7, W4.1\u2013W4.7) carry summary scope only.
Their full briefs are authored at the wave-boundary step (W3.0, W4.0) and must pass
validation before any work on them begins. This is deliberate: detail is produced at
the boundary where it is real rather than invented early.

## Amending the plan

The plan and this ledger are versioned together. Adding, splitting, or retiring a step
is a PR like any other, reviewed by a human owner; the history of the plan is part of
the audit trail of the build. Any change that lowers a CROPS phase target is named as a
regression in the PR, never absorbed silently (CIS \u00a717 discipline).
