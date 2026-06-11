# CONVENTIONS.md · substrate conventions

## Migrations
Timestamped, append-only, one concern per file: `supabase/migrations/<ts>_<slug>.sql`.
No manual SQL against the hosted project, ever. Every new table is created through the
RLS template below in the same migration that creates it.

## RLS template · cite-as-you-enforce
```sql
alter table public.<table> enable row level security;
alter table public.<table> force row level security;

create policy "<table>_member_own" on public.<table>
  for select using (agent_id = app.current_agent_id());
comment on policy "<table>_member_own" on public.<table> is
  'draft-bylaws:§18.1 · member reads own records';
```
Rules: default-deny (no permissive catch-alls); every policy carries a
`comment on policy` whose first token is a citation per docs/citations.md
(`draft-bylaws:§x.y` or `grant:§n`); helper functions `app.is_member()`,
`app.has_role(text)`, `app.is_self(uuid)` are the only auth predicates used in
policies, marked `stable`.

## Event envelope
Every state change is an event row. Shared columns on event tables:
`id uuid pk`, `actor uuid not null`, `occurred_at timestamptz not null default now()`,
`entity text`, `entity_id uuid`, `prior_value jsonb`, `payload jsonb`,
`citation text not null`. Mutations on enveloped tables write an audit row via the
generic `app.record_event()` trigger; pgTAP asserts prior_value capture.

## Vocabulary quarantine · enforced by ci:grammar-lint
Forbidden in this repository's schema, UI strings, and documents (word-boundary,
case-insensitive): "patronage dividend", "written notice of allocation",
"per-unit retain", "per unit retain allocation", "qualified written notice",
"nonqualified written notice", "Subchapter T" (outside this file and
docs/decisions/). "Patronage" alone survives only as a scoped internal name for
capital-account allocation under §704(b); when in doubt, write "allocation".
Allowlist: `.grammar-allow` with one term per line plus a `# why` comment.

## Naming
snake_case tables and columns; REA primitive recorded in a table comment
(`comment on table ... is 'REA: Event · anchor: draft-bylaws:§5.1'`). Derived views
are pure functions of the event log and carry `_as_of` or `_view` suffixes when
ambiguous.

## Fixtures
Synthetic only, generated, obviously fake (example.coop addresses, FAKE- prefixes).
Personas for probes: member-a, member-b, admin-1, applicant-1, liaison-1 (full pack is
collection item C4, next).
