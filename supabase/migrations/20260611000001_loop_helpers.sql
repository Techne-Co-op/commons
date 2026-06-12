-- loop helpers · app.* functions referenced in RLS policies
-- Follows CONVENTIONS.md: stable, named with app. prefix

-- Current participant id from JWT sub → loop_participants lookup
create or replace function app.current_participant_id()
returns uuid
language sql stable security definer
set search_path = public, pg_catalog
as $$
  select id from public.loop_participants
  where auth_user_id = auth.uid()
  limit 1;
$$;
comment on function app.current_participant_id() is
  'contract:agents§preamble · resolves JWT sub to loop participant id';

-- Role check
create or replace function app.has_role(r text)
returns boolean
language sql stable security definer
set search_path = public, pg_catalog
as $$
  select exists (
    select 1 from public.loop_participants
    where auth_user_id = auth.uid()
      and role = r
  );
$$;
comment on function app.has_role(text) is
  'contract:agents§preamble · checks participant role for RLS predicates';

-- Is authenticated as any loop participant?
create or replace function app.is_loop_participant()
returns boolean
language sql stable security definer
set search_path = public, pg_catalog
as $$
  select exists (
    select 1 from public.loop_participants
    where auth_user_id = auth.uid()
  );
$$;
comment on function app.is_loop_participant() is
  'contract:agents§preamble · true when JWT maps to a registered participant';
