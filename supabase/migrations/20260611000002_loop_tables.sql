-- Decision–Blocker Signal Loop · core tables
-- All DDL follows docs/CONVENTIONS.md: snake_case, REA in comments,
-- event envelope on mutating tables, RLS cite-as-you-enforce.

-- ── participants · REA: Agent ─────────────────────────────────────────────
create table public.loop_participants (
  id             uuid        primary key default gen_random_uuid(),
  auth_user_id   uuid        unique references auth.users(id),
  display_name   text        not null,
  role           text        not null check (role in ('organizer','agent','observer')),
  created_at     timestamptz not null default now()
);
comment on table public.loop_participants is
  'REA: Agent · anchor: contract:agents§preamble · loop process identities, not CIS members';

alter table public.loop_participants enable row level security;
alter table public.loop_participants force row level security;

create policy "loop_participants_public_read" on public.loop_participants
  for select using (true);
comment on policy "loop_participants_public_read" on public.loop_participants is
  'contract:agents§preamble · participant directory is public (display_name and role only)';

create policy "loop_participants_self_update" on public.loop_participants
  for update using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());
comment on policy "loop_participants_self_update" on public.loop_participants is
  'contract:agents§preamble · participants may update their own display_name';

create policy "loop_participants_organizer_manage" on public.loop_participants
  for all using (app.has_role('organizer'))
  with check (app.has_role('organizer'));
comment on policy "loop_participants_organizer_manage" on public.loop_participants is
  'contract:agents§5 · organizers manage participant roster (invite-only, W0.5 pattern)';


-- ── ledger snapshots · REA: Event ─────────────────────────────────────────
create table public.ledger_snapshots (
  id             uuid        primary key default gen_random_uuid(),
  actor          uuid        not null references public.loop_participants(id),
  occurred_at    timestamptz not null default now(),
  sync_sha       text        not null,
  entry_count    int         not null,
  status_counts  jsonb       not null,
  payload        jsonb       not null,
  citation       text        not null default 'contract:governance§validation'
);
comment on table public.ledger_snapshots is
  'REA: Event · anchor: contract:governance§validation · one row per index.json ingest';

alter table public.ledger_snapshots enable row level security;
alter table public.ledger_snapshots force row level security;

create policy "ledger_snapshots_public_read" on public.ledger_snapshots
  for select using (true);
comment on policy "ledger_snapshots_public_read" on public.ledger_snapshots is
  'contract:governance§validation · snapshots are public; same posture as index.json';

create policy "ledger_snapshots_service_insert" on public.ledger_snapshots
  for insert with check (auth.role() = 'service_role');
comment on policy "ledger_snapshots_service_insert" on public.ledger_snapshots is
  'contract:governance§validation · only service role (ledger-ingest function) may write';


-- ── ledger entries · derived cache · NON-CANONICAL ────────────────────────
create table public.ledger_entries (
  id                text        primary key,
  title             text        not null,
  wave              text        not null,
  kind              text        not null,
  owner             text,
  status            text        not null,
  detail            text,
  depends_on        jsonb       not null default '[]',
  expanded_parents  jsonb       not null default '[]',
  decision_refs     jsonb       not null default '[]',
  verification      text,
  blocked_reason    text,
  first_seen_at     timestamptz not null default now(),
  last_synced_at    timestamptz not null,
  sync_sha          text        not null
);
comment on table public.ledger_entries is
  'derived mirror of milestones/index.json · NON-CANONICAL · rebuilt on each ledger_snapshots ingest';

alter table public.ledger_entries enable row level security;
alter table public.ledger_entries force row level security;

create policy "ledger_entries_public_read" on public.ledger_entries
  for select using (true);
comment on policy "ledger_entries_public_read" on public.ledger_entries is
  'contract:governance§validation · mirror of public ledger; no private rows';

create policy "ledger_entries_service_write" on public.ledger_entries
  for all using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');
comment on policy "ledger_entries_service_write" on public.ledger_entries is
  'contract:governance§validation · only service role may rebuild the mirror';


-- ── decision threads · REA: Event-bearing process record ──────────────────
create table public.decision_threads (
  id              uuid        primary key default gen_random_uuid(),
  decision_id     text        not null references public.ledger_entries(id),
  state           text        not null default 'deliberating'
    check (state in ('deliberating','ready_to_record','recorded','superseded')),
  visibility      text        not null default 'public'
    check (visibility in ('public','restricted')),
  recorded_pr_url text,
  recorded_at     timestamptz,
  opened_by       uuid        not null references public.loop_participants(id),
  created_at      timestamptz not null default now(),
  constraint recorded_requires_pr
    check (state <> 'recorded' or recorded_pr_url is not null),
  constraint one_live_thread
    unique (decision_id, state) deferrable initially deferred
);
comment on table public.decision_threads is
  'REA: Event-bearing process record · anchor: contract:agents§5 · deliberation state, never the decision itself';

alter table public.decision_threads enable row level security;
alter table public.decision_threads force row level security;

create policy "decision_threads_public_read" on public.decision_threads
  for select using (visibility = 'public');
comment on policy "decision_threads_public_read" on public.decision_threads is
  'draft-bylaws:§18.1 · public repo, public deliberation; restricted rows per §18.2';

create policy "decision_threads_organizer_write" on public.decision_threads
  for all using (app.has_role('organizer'))
  with check (app.has_role('organizer'));
comment on policy "decision_threads_organizer_write" on public.decision_threads is
  'contract:agents§5 · only organizers move decision process state';

create policy "decision_threads_service_auto_open" on public.decision_threads
  for insert with check (auth.role() = 'service_role' and state = 'deliberating');
comment on policy "decision_threads_service_auto_open" on public.decision_threads is
  'contract:governance§validation · ledger-ingest may auto-open deliberating threads on D/R entry discovery';


-- ── deliberation notes ────────────────────────────────────────────────────
create table public.deliberation_notes (
  id          uuid        primary key default gen_random_uuid(),
  thread_id   uuid        not null references public.decision_threads(id),
  author      uuid        not null references public.loop_participants(id),
  kind        text        not null default 'comment'
    check (kind in ('comment','proposal','question','counsel_note')),
  body        text        not null,
  created_at  timestamptz not null default now()
);
comment on table public.deliberation_notes is
  'REA: Event · anchor: contract:agents§5 · deliberation notes within a decision thread';

alter table public.deliberation_notes enable row level security;
alter table public.deliberation_notes force row level security;

create policy "deliberation_notes_thread_read" on public.deliberation_notes
  for select using (
    exists (
      select 1 from public.decision_threads t
      where t.id = thread_id and t.visibility = 'public'
    )
  );
comment on policy "deliberation_notes_thread_read" on public.deliberation_notes is
  'draft-bylaws:§18.1 · notes visible when thread is public';

create policy "deliberation_notes_participant_insert" on public.deliberation_notes
  for insert with check (author = app.current_participant_id());
comment on policy "deliberation_notes_participant_insert" on public.deliberation_notes is
  'contract:agents§5 · participants write their own notes; envelope captures attribution';

create policy "deliberation_notes_own_update" on public.deliberation_notes
  for update using (author = app.current_participant_id())
  with check (author = app.current_participant_id());
comment on policy "deliberation_notes_own_update" on public.deliberation_notes is
  'contract:agents§5 · authors may edit their own notes';


-- ── leanings · non-binding signals ────────────────────────────────────────
create table public.leanings (
  id          uuid        primary key default gen_random_uuid(),
  thread_id   uuid        not null references public.decision_threads(id),
  participant uuid        not null references public.loop_participants(id),
  position    text        not null
    check (position in ('adopt_default','prefer_alternative','defer','need_more_information')),
  note        text,
  updated_at  timestamptz not null default now(),
  unique (thread_id, participant)
);
comment on table public.leanings is
  'REA: Event · anchor: contract:agents§5 · non-binding position signals; W4.2 owns the vote word';

alter table public.leanings enable row level security;
alter table public.leanings force row level security;

create policy "leanings_thread_read" on public.leanings
  for select using (
    exists (
      select 1 from public.decision_threads t
      where t.id = thread_id and t.visibility = 'public'
    )
  );
comment on policy "leanings_thread_read" on public.leanings is
  'draft-bylaws:§18.1 · leanings visible when thread is public';

create policy "leanings_own_upsert" on public.leanings
  for insert with check (participant = app.current_participant_id());
comment on policy "leanings_own_upsert" on public.leanings is
  'contract:agents§5 · leanings are personal signals; envelope captures revisions';

create policy "leanings_own_update" on public.leanings
  for update using (participant = app.current_participant_id())
  with check (participant = app.current_participant_id());
comment on policy "leanings_own_update" on public.leanings is
  'contract:agents§5 · participants update their own leaning only';


-- ── blockers · variety the ledger cannot see ──────────────────────────────
create table public.blockers (
  id               uuid        primary key default gen_random_uuid(),
  raised_by        uuid        not null references public.loop_participants(id),
  entry_id         text        references public.ledger_entries(id),  -- nullable: ad-hoc
  kind             text        not null
    check (kind in ('decision','dependency','external','counsel','resource','other')),
  summary          text        not null,
  detail           text,
  state            text        not null default 'open'
    check (state in ('open','acknowledged','resolved','withdrawn')),
  visibility       text        not null default 'public'
    check (visibility in ('public','restricted')),
  resolved_by      uuid        references public.loop_participants(id),
  resolved_at      timestamptz,
  resolution_note  text,
  created_at       timestamptz not null default now()
);
comment on table public.blockers is
  'REA: Event · anchor: contract:agents§7 · blocker variety the ledger cannot see; ad-hoc and ledger-echoed';

alter table public.blockers enable row level security;
alter table public.blockers force row level security;

create policy "blockers_public_read" on public.blockers
  for select using (visibility = 'public');
comment on policy "blockers_public_read" on public.blockers is
  'draft-bylaws:§18.1 · open blockers are public; restricted available per §18.2';

create policy "blockers_participant_insert" on public.blockers
  for insert with check (raised_by = app.current_participant_id());
comment on policy "blockers_participant_insert" on public.blockers is
  'contract:agents§7 · any participant may raise a blocker; blocked beats improvised';

create policy "blockers_organizer_manage" on public.blockers
  for all using (app.has_role('organizer'))
  with check (app.has_role('organizer'));
comment on policy "blockers_organizer_manage" on public.blockers is
  'contract:agents§5 · organizers resolve and manage blockers';


-- ── loop events · event envelope ──────────────────────────────────────────
create table public.loop_events (
  id           uuid        primary key default gen_random_uuid(),
  actor        uuid,  -- nullable: null = system/service role action
  occurred_at  timestamptz not null default now(),
  entity       text        not null,
  entity_id    text        not null,
  prior_value  jsonb,
  payload      jsonb,
  citation     text        not null
);
comment on table public.loop_events is
  'REA: Event · anchor: contract:governance§lifecycle · audit trail per CONVENTIONS.md event envelope';

alter table public.loop_events enable row level security;
alter table public.loop_events force row level security;

create policy "loop_events_public_read" on public.loop_events
  for select using (true);
comment on policy "loop_events_public_read" on public.loop_events is
  'contract:governance§lifecycle · audit trail is public';

create policy "loop_events_service_insert" on public.loop_events
  for insert with check (auth.role() = 'service_role');
comment on policy "loop_events_service_insert" on public.loop_events is
  'contract:governance§lifecycle · only service role writes events (trigger-generated)';
