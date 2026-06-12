# commons · RegenHub, LCA

The Common Information System for [RegenHub, LCA](https://regenhub.coop) — a Colorado Limited Cooperative Association in Boulder. Served at **[techne-co-op.github.io/commons](https://techne-co-op.github.io/commons/)**.

Build state, Hub Operations tracking, and the decision–blocker signal loop — all under human direction, agent-assisted execution, Supabase backend.

---

## Live instruments

| Surface | Path | Purpose |
|---|---|---|
| Repository index | `index.html` | Entry point · links to all instruments |
| CIS Implementation HUD | `hud.html` | 71 milestones · wave rail · HUB, LOOP, and DOC modes |
| Decision–Blocker Signal Loop | `loop.html` | Open decisions ranked by leverage · blockers · pulse |
| Design system reference | `design-system.html` | Tokens, typography, components, layout grammars |
| Documentation Fulfilment HUD | `cis-hubops-documentation-fulfilment-hud-v0_1.html` | 67-deliverable fulfilment tracker · phase and roadmap lenses |
| Documentation Fulfilment Framework | `documentation-fulfilment-agent-framework-v0_1.html` | Software Service Delivery framework spec v0.1 |
| Progressive Definition 01 — Inception Baseline | `cis-hubops-progressive-definition-01-inception-v0_2.html` | Problem brief · stakeholder map · success criteria · charter · open questions |
| Progressive Definition 02 — Discovery Consolidation | `cis-hubops-progressive-definition-02-discovery-v0_1.html` | Requirements index · feasibility matrix · risk register · evidence standard |

The HUD has four view modes: wave-filtered milestone view, **HUB** (Hub Operations guide layer — EE grant phases, KPIs, modules, grant lifecycle), **LOOP** (signal loop embedded — front workable, decision queue, blockers, pulse), and **DOC** (documentation fulfilment — 67 deliverables across 8 phases, phase and roadmap lenses, gap detection).

---

## Design system

All pages use **Design System v3**, adopted from co-op.us.

- `commons.css` — shared stylesheet; link this from every HTML page
- `design-system.html` — canonical reference: tokens, typography, components, layout grammars, voice guidelines, agent authoring instructions
- `docs/DESIGN.md` — contributor protocol: token reference, layout grammar rules, component patterns, prohibited patterns

Core commitments: warm grayscale ground, terracotta as the only decorative accent, two typefaces (Libre Baskerville serif for reading, IBM Plex Mono for technical), no alarm red (`--crit` aliases `--warn` · clay), state tokens (`--ok`, `--info`, `--warn`) on instrument surfaces only.

---

## Repository layout

```
commons/
├── index.html                          entry point
├── hud.html                            CIS implementation HUD
├── loop.html                           decision–blocker signal loop
├── loop.config.js                      Supabase anon key (public by design; RLS is the guard)
├── commons.css                         design system stylesheet
├── design-system.html                  design system reference
├── cis-prd-v0.2.html                   CIS PRD v0.2
├── hub-ops-prd-v0.1.html               Hub Operations PRD v0.1
├── cis-build-roadmap-instrument-v0.2.html
├── cis-hubops-private-alpha-implementation-plan-v0.1.html
├── cis-hubops-documentation-fulfilment-hud-v0_1.html   fulfilment tracker standalone instrument
├── documentation-fulfilment-agent-framework-v0_1.html  Software Service Delivery framework spec
├── cis-hubops-progressive-definition-01-inception-v0_2.html   inception baseline document
├── cis-hubops-progressive-definition-02-discovery-v0_1.html   discovery consolidation document
├── builders-collection-map-v0.1.html
├── c6–c11-*.html                       companion instruments (schema card, probe matrix, etc.)
├── AGENTS.md                           operating contract every executing agent reads first
├── GOVERNANCE.md                       ledger mechanics: schema, lifecycle, validation
│
├── milestones/                         71 ledger entries (steps, decisions, ratifications, gates, practice)
│   ├── index.json                      generated — do not edit by hand
│   ├── STATUS.md                       generated — do not edit by hand
│   ├── schema.json                     front-matter schema
│   └── D/, R/, W0/…W6/, G/, P/         entry files by wave
│
├── docs/
│   ├── decisions/                      deliberation briefs D1–D10, R1–R2
│   ├── DESIGN.md                       design system contributor guide
│   ├── CONVENTIONS.md                  SQL, RLS, event-envelope, vocabulary rules
│   ├── VERIFICATION.md                 contract cards for named CI jobs
│   ├── SECRETS.md                      secret names and custody (names only, never values)
│   └── citations.md                    draft-bylaws and grant citation register
│
├── scripts/
│   ├── validate.py                     milestone validator; regenerates index.json and STATUS.md
│   ├── gen_seed.py                     regenerates seed from plan data
│   └── requirements.txt
│
├── supabase/
│   ├── migrations/                     append-only SQL migrations
│   └── functions/                      Edge Functions (decision-record-draft, ledger-ingest)
│
└── .github/
    ├── workflows/
    │   ├── milestone-validate.yml      required check on every push and PR
    │   └── loop-sync.yml               syncs ledger to Supabase on push to main
    └── PULL_REQUEST_TEMPLATE.md
```

---

## Milestone ledger

71 entries across waves D, R, W0–W6, G, P. Status lifecycle: `pending → in_progress → review → done → verified`. Only `verified` unlocks dependents. The validator enforces schema, dependency ordering, and acyclicity on every push.

Current state: see `milestones/STATUS.md` or the [HUD](https://techne-co-op.github.io/commons/hud.html).

---

## Working here

Agents read `AGENTS.md` first, then `GOVERNANCE.md`, then `milestones/STATUS.md`, then the single milestone file being executed. The operating contract is binding; when it conflicts with any other instruction the contract wins and the conflict is reported in the PR.

Decisions (D, R entries) are human-only. Agents may draft deliberation briefs; they do not record or flip decisions.

Validate locally:

```sh
pip install -r scripts/requirements.txt
python scripts/validate.py
```

---

*RegenHub, LCA · Boulder, Colorado · filed Feb 6, 2026 · public benefit: cultivating scenius*
