# COLLECTION-MAP.md · C0–C11 to repository files

Addresses audit finding DF-03. The Builder's Collection map (builders-collection-map-v0.1.html)
references artifacts C0–C11. C6–C11 are standalone HTML files on the commons site. C0–C5 are
existing repository files that predate the HTML collection. This document states the explicit
mapping so a contributor can locate every artifact.

---

## C0 — This map

`builders-collection-map-v0.1.html`

The navigational layer. Read first in any session that involves the collection.

---

## C1 — Agent operating contract

`AGENTS.md` (root of repository)

The conduct layer: session start sequence, scope constraints, escalation protocol, success
criteria. Read first every session; conflicts resolve in favour of the contract.

---

## C2 — Ledger pack

`milestones/` (entire directory tree)
`milestones/schema.json`
`scripts/gen_seed.py`
`scripts/validate.py`
`.github/workflows/milestone-validate.yml`
`.github/pull_request_template.md`
`GOVERNANCE.md`

The executable ledger. The validator (milestone-validate workflow) is live on push/PR.
See docs/VERIFICATION.md for the job contract. See milestones/schema.json for the 13-field
schema that all milestone files must satisfy.

---

## C3 — Verification contract cards

`docs/VERIFICATION.md`

What each named CI job asserts, so success_state fields are buildable and non-circular.
Every job entry now carries a LIVE or PLANNED status marker (see SF-01 remediation).

---

## C4 — Substrate conventions and fixtures

`docs/CONVENTIONS.md` — RLS template, event-envelope DDL, vocabulary quarantine list,
  citation comment format, event-envelope DDL pattern, migration conventions.

`docs/SECRETS.md` — Secret names, custody assignments, agent protocol for handling secrets.

`docs/citations.md` — Citation format registry and allowlist for policy citations.

`docs/fixtures/C4-synthetic-personas.md` — Synthetic persona fixture pack: five personas
  with fake data for RLS probe suites (member-a, member-b, admin-1, applicant-1, liaison-1).

The conventions components shipped with the repo seed. The persona fixture pack was created
at audit remediation (June 12, 2026) — the one C4 deliverable noted absent in the collection
map description.

---

## C5 — Decision surface

`docs/decisions/D1.md` through `docs/decisions/D10.md`
`docs/decisions/R1.md`, `docs/decisions/R2.md`

One deliberation brief per open item with a proposed default and a Record of decision section.
Agents improve briefs; they do not decide. D3 opens the dependency tree. All ten D-items are
now in decided status.

---

## C6–C11 — HTML collection artifacts

| ID  | Title                        | File                                |
|-----|------------------------------|-------------------------------------|
| C6  | Schema reference card        | `schema-reference-card-v0.1.html`   |
| C7  | Probe matrix                 | `probe-matrix-v0.1.html`            |
| C8  | Nou gateway spec             | `nou-gateway-spec-v0.1.html`        |
| C9  | KPI fixture pack             | `kpi-fixture-pack-v0.1.html`        |
| C10 | Wave-boundary authoring guide| `wave-boundary-guide-v0.1.html`     |
| C11 | Wave gates                   | `wave-gates-v0.1.html`              |

Gate YAML files produced by C11 live in `milestones/G/`.

---

*Maintained under human review. Update this file whenever a C-item's canonical location
changes or a new collection artifact ships.*
