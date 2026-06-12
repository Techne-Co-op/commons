-- Event envelope trigger · per CONVENTIONS.md
-- Writes audit rows to loop_events on INSERT/UPDATE/DELETE
-- Applied to: decision_threads, leanings, blockers
-- Note: actor is nullable — null means system/service role action

create or replace function app.record_event()
returns trigger
language plpgsql security definer
set search_path = public, pg_catalog
as $$
declare
  v_actor    uuid;
  v_entity   text;
  v_id       text;
  v_prior    jsonb;
  v_payload  jsonb;
  v_citation text;
begin
  -- Resolve actor: prefer JWT participant, null for service/system actions
  begin
    if auth.uid() is not null then
      select id into v_actor from public.loop_participants
      where auth_user_id = auth.uid() limit 1;
    end if;
  exception when others then
    v_actor := null;
  end;

  v_entity := TG_TABLE_NAME;

  if TG_OP = 'DELETE' then
    v_id      := OLD.id::text;
    v_prior   := to_jsonb(OLD);
    v_payload := null;
  elsif TG_OP = 'UPDATE' then
    v_id      := NEW.id::text;
    v_prior   := to_jsonb(OLD);
    v_payload := to_jsonb(NEW);
  else -- INSERT
    v_id      := NEW.id::text;
    v_prior   := null;
    v_payload := to_jsonb(NEW);
  end if;

  -- Prefer citation from the row itself if present
  begin
    v_citation := coalesce(
      (v_payload->>'citation'),
      'contract:governance§lifecycle'
    );
  exception when others then
    v_citation := 'contract:governance§lifecycle';
  end;

  insert into public.loop_events
    (actor, entity, entity_id, prior_value, payload, citation)
  values
    (v_actor, v_entity, v_id, v_prior, v_payload, v_citation);

  return coalesce(NEW, OLD);
end;
$$;
comment on function app.record_event() is
  'contract:governance§lifecycle · generic event envelope trigger per CONVENTIONS.md';

-- Attach to decision_threads
create trigger decision_threads_event_envelope
  after insert or update or delete on public.decision_threads
  for each row execute function app.record_event();

-- Attach to leanings
create trigger leanings_event_envelope
  after insert or update or delete on public.leanings
  for each row execute function app.record_event();

-- Attach to blockers
create trigger blockers_event_envelope
  after insert or update or delete on public.blockers
  for each row execute function app.record_event();
