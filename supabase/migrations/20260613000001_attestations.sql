-- Interim attestation system · D11 decision (Jun 13 2026)
-- Mechanism: SHA-256 hash of canonical event payload, stored in Supabase.
-- Tamper-evident audit trail without formal key custody infrastructure.
-- Upgrade path: add a signature column when W3 key custody exists.
-- Uses pgcrypto (pre-enabled in Supabase projects).

-- ── attestations · REA: Event ─────────────────────────────────────────────
create table public.attestations (
  id             uuid        primary key default gen_random_uuid(),
  hash           text        not null unique,      -- SHA-256 hex of canonical_json
  event_type     text        not null,             -- e.g. 'member_onboarding', 'wave_gate_pass'
  subject        text        not null,             -- what/who is being attested
  payload        jsonb,                            -- freeform event data
  attested_by    text        not null,             -- organizer display_name or agent id
  attested_at    timestamptz not null default now(),
  canonical_json text        not null,             -- the exact string that was hashed
  created_at     timestamptz not null default now()
);

comment on table public.attestations is
  'REA: Event · anchor: D11 decision 2026-06-13 · interim tamper-evident attestation records. '
  'Each row''s hash = SHA-256(canonical_json). Upgrade path: add signature column at W3.';

comment on column public.attestations.canonical_json is
  'Deterministic JSON: keys sorted alphabetically — attested_at, attested_by, event_type, payload, subject. '
  'Identical inputs always produce identical canonical_json and therefore identical hash.';

alter table public.attestations enable row level security;
alter table public.attestations force row level security;

create policy "attestations_public_read" on public.attestations
  for select using (true);
comment on policy "attestations_public_read" on public.attestations is
  'Attestation records are public — audit trail must be legible to all participants.';

create policy "attestations_service_insert" on public.attestations
  for insert with check (auth.role() = 'service_role');
comment on policy "attestations_service_insert" on public.attestations is
  'Only service_role (agents, CI) may create attestations. Human-facing path: attest_event() RPC.';

-- ── attest_event · the interim attestation function ───────────────────────
-- Usage: POST /rest/v1/rpc/attest_event
-- Body:  {"p_event_type": "...", "p_subject": "...", "p_payload": {...}, "p_attested_by": "..."}
-- Returns: {"id": "<uuid>", "hash": "<sha256-hex>", "attested_at": "<iso8601>"}
--
-- Canonical JSON key order (alphabetical): attested_at, attested_by, event_type, payload, subject
-- This order is fixed — any future upgrade must preserve it to keep existing hashes valid.

create or replace function public.attest_event(
  p_event_type  text,
  p_subject     text,
  p_payload     jsonb    default '{}'::jsonb,
  p_attested_by text     default 'unknown'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_attested_at  timestamptz := now();
  v_canonical    text;
  v_hash         text;
  v_id           uuid;
begin
  -- Build canonical JSON with alphabetically sorted keys.
  -- Key order is a protocol invariant — do not reorder.
  v_canonical := jsonb_build_object(
    'attested_at', v_attested_at::text,
    'attested_by', p_attested_by,
    'event_type',  p_event_type,
    'payload',     coalesce(p_payload, '{}'::jsonb),
    'subject',     p_subject
  )::text;

  -- SHA-256 via pgcrypto
  v_hash := encode(digest(v_canonical, 'sha256'), 'hex');

  -- Insert — unique constraint on hash prevents duplicate attestations
  insert into public.attestations (hash, event_type, subject, payload, attested_by, attested_at, canonical_json)
  values (v_hash, p_event_type, p_subject, coalesce(p_payload, '{}'::jsonb), p_attested_by, v_attested_at, v_canonical)
  returning id into v_id;

  return jsonb_build_object(
    'id',          v_id,
    'hash',        v_hash,
    'attested_at', v_attested_at
  );
end;
$$;

comment on function public.attest_event is
  'D11 interim attestation: hash event payload with SHA-256, store tamper-evident record. '
  'Returns id, hash, attested_at. Duplicate inputs (same hash) raise unique violation — '
  'idempotent for retries if you check for the existing record first.';

-- ── HOWTO: verify an attestation ──────────────────────────────────────────
-- SELECT hash = encode(digest(canonical_json, 'sha256'), 'hex') AS valid
-- FROM attestations WHERE id = '<uuid>';
-- A valid attestation returns true. Any tampering with canonical_json breaks the hash.
