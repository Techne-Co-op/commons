-- Comparator views · pure functions of the tables above
-- Per CONVENTIONS.md: security invoker, explicit search_path

-- v_pulse · last sync state for page header
create or replace view public.v_pulse
  with (security_invoker = true)
as
select
  s.sync_sha,
  s.occurred_at    as synced_at,
  s.entry_count,
  s.status_counts,
  now() - s.occurred_at as age
from public.ledger_snapshots s
order by s.occurred_at desc
limit 1;
comment on view public.v_pulse is
  'comparator: last ledger sync sha, age, and status counts for the Pulse panel';


-- v_front · entries that are workable now
-- expanded_parents all done/verified AND decision_refs all recorded
create or replace view public.v_front
  with (security_invoker = true)
as
select
  e.id, e.title, e.wave, e.kind, e.owner, e.status,
  e.expanded_parents, e.decision_refs, e.verification
from public.ledger_entries e
where
  e.status not in ('done','verified')
  and e.kind = 'step'
  -- all expanded_parents must be done or verified
  and not exists (
    select 1
    from jsonb_array_elements_text(e.expanded_parents) as p(id)
    join public.ledger_entries pe on pe.id = p.id
    where pe.status not in ('done','verified')
  )
  -- all decision_refs must have a recorded thread
  and not exists (
    select 1
    from jsonb_array_elements_text(e.decision_refs) as d(id)
    where not exists (
      select 1 from public.decision_threads t
      where t.decision_id = d.id and t.state = 'recorded'
    )
  );
comment on view public.v_front is
  'comparator: steps workable now (all parents verified, all decision_refs recorded)';


-- v_decision_leverage · open decisions ranked by transitive dependent count
-- Note: decision_refs on ledger_entries is populated only after v2 ingest
-- (once validate.py includes decision_refs per W0.21). Until then, returns
-- direct-child counts only, which is still useful.
create or replace view public.v_decision_leverage
  with (security_invoker = true)
as
with recursive deps(decision_id, dependent_id, depth) as (
  -- direct dependents via decision_refs
  select
    d.id          as decision_id,
    e.id          as dependent_id,
    1             as depth
  from public.ledger_entries d
  join public.ledger_entries e
    on e.decision_refs ? d.id
  where d.kind in ('decision','ratification')
    and d.status not in ('done','verified')
  union
  -- transitive: anything that depends_on a dependent
  select
    deps.decision_id,
    e2.id,
    deps.depth + 1
  from deps
  join public.ledger_entries e2
    on e2.expanded_parents ? deps.dependent_id
  where deps.depth < 20
),
thread_state as (
  select
    decision_id,
    state,
    recorded_pr_url,
    count(*) over (partition by decision_id) as thread_count
  from public.decision_threads
  where state not in ('superseded')
)
select
  d.id,
  d.title,
  d.wave,
  d.status                          as decision_status,
  coalesce(t.state, 'no_thread')    as thread_state,
  t.recorded_pr_url,
  count(distinct deps.dependent_id) as total_gated,
  -- leanings summary
  (select jsonb_object_agg(pos, cnt)
   from (
     select l.position as pos, count(*) as cnt
     from public.leanings l
     join public.decision_threads th on th.id = l.thread_id
     where th.decision_id = d.id
     group by l.position
   ) ls
  )                                  as leanings_summary
from public.ledger_entries d
left join deps on deps.decision_id = d.id
left join thread_state t on t.decision_id = d.id
where d.kind in ('decision','ratification')
  and d.status not in ('done','verified')
group by d.id, d.title, d.wave, d.status, t.state, t.recorded_pr_url
order by total_gated desc, d.id;
comment on view public.v_decision_leverage is
  'comparator: open decisions ranked by transitive gated count (Part I §3, live)';


-- v_aging · open decisions and blockers past age thresholds
create or replace view public.v_aging
  with (security_invoker = true)
as
-- open decisions with thread age
select
  'decision'          as kind,
  d.id                as ref_id,
  d.title,
  coalesce(t.state, 'no_thread') as state,
  t.created_at        as opened_at,
  now() - t.created_at as age,
  case
    when now() - t.created_at > interval '30 days' then 'critical'
    when now() - t.created_at > interval '14 days' then 'warn'
    else 'ok'
  end                 as age_band
from public.ledger_entries d
left join public.decision_threads t
  on t.decision_id = d.id and t.state not in ('recorded','superseded')
where d.kind in ('decision','ratification')
  and d.status not in ('done','verified')
union all
-- open blockers
select
  'blocker'           as kind,
  b.id::text          as ref_id,
  b.summary           as title,
  b.state,
  b.created_at        as opened_at,
  now() - b.created_at as age,
  case
    when now() - b.created_at > interval '14 days' then 'critical'
    when now() - b.created_at > interval '7 days'  then 'warn'
    else 'ok'
  end                 as age_band
from public.blockers b
where b.state in ('open','acknowledged')
  and b.visibility = 'public'
order by age desc;
comment on view public.v_aging is
  'comparator: open decisions and blockers ranked by age with threshold bands';
