# C4-synthetic-personas.md · Synthetic persona fixture pack

Collection artifact C4, fixture component. Provides five synthetic personas with
fake data for RLS probe suites. Paired with C7 (probe matrix). Consumed at W0.6
onward for `ci:rls-audit` probes.

**All data in this file is fake and generated for testing purposes only.**
Prefix convention: `FAKE-` on names, `fake-` on email domains, UUIDs are
deterministic test fixtures (not real user records).

---

## Persona definitions

### member-a — voting member in good standing

```
uuid:         00000000-0000-0000-0000-000000000001
display_name: FAKE-Alice Renner
email:        alice@fake-techne.coop
role:         member
class:        voting
good_standing: true
joined_at:    2026-02-06T00:00:00Z
hub:          null
notes:        Primary probe subject for own-read assertions (§18.1 scope).
              Used in cross-member denial probes (member-a cannot read member-b's record).
```

### member-b — voting member in good standing (isolation peer)

```
uuid:         00000000-0000-0000-0000-000000000002
display_name: FAKE-Ben Okafor
email:        ben@fake-techne.coop
role:         member
class:        voting
good_standing: true
joined_at:    2026-02-06T00:00:00Z
hub:          null
notes:        Used exclusively as the "other member" in cross-member isolation probes.
              member-a must not read member-b's private fields; member-b must not
              read member-a's private fields.
```

### admin-1 — operator / administrator

```
uuid:         00000000-0000-0000-0000-000000000010
display_name: FAKE-Admin Operator
email:        ops@fake-techne.coop
role:         admin
class:        operator
good_standing: true
joined_at:    2026-02-06T00:00:00Z
hub:          null
notes:        Used to verify that admin-scoped policies permit the operations they
              claim. For tables with admin-only write policies, admin-1 must succeed
              where member-a fails.
```

### applicant-1 — anonymous applicant (pre-membership)

```
uuid:         null  (anonymous — no auth session)
display_name: null
email:        null
role:         anon
class:        null
good_standing: null
notes:        Represents the Supabase `anon` role. Used for probes of the W2.2
              application insert policy — the single deliberate anon insert hole.
              Must be denied on every table except the application submissions table.
              Must be limited to the declared columns in the anon insert policy.
              Rate limiting via Edge Function wrapper is a named watch item (W2.2).
```

### liaison-1 — hub liaison (hub-scoped access)

```
uuid:         00000000-0000-0000-0000-000000000020
display_name: FAKE-Lena Marchetti
email:        lena@fake-hub.coop
role:         liaison
class:        non-voting
good_standing: true
joined_at:    2026-03-01T00:00:00Z
hub:          FAKE-Hub-001
notes:        Used to verify hub-scoped RLS policies. liaison-1 must read hub-scoped
              records for FAKE-Hub-001 and be denied access to records scoped to
              other hubs. Tests the Nou gateway cross-member denial probe at W1.7.
```

---

## Probe usage index

| Persona      | Role  | Primary probe scenarios                                          |
|--------------|-------|------------------------------------------------------------------|
| member-a     | member | own-read allowed; cross-member read denied; aggregate read allowed |
| member-b     | member | isolation peer; cross-member write denied; no admin ops          |
| admin-1      | admin  | admin write allowed; audit reads allowed; system-table access    |
| applicant-1  | anon   | anon insert (W2.2 path only); all other tables denied            |
| liaison-1    | liaison | hub-scoped read allowed; cross-hub denied; Nou gateway probe   |

---

## Fixture seed SQL (template — applied in pgTAP test setup)

The following is a template for inserting these personas into the test shadow database.
Table names are placeholders until the schema migration at W1.1 establishes the canonical
members table.

```sql
-- C4 synthetic persona seed — TEST ENVIRONMENT ONLY
-- Do not apply to any hosted project

insert into public.members (id, display_name, email, role, class, good_standing, joined_at)
values
  ('00000000-0000-0000-0000-000000000001', 'FAKE-Alice Renner', 'alice@fake-techne.coop',
   'member', 'voting', true, '2026-02-06T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000002', 'FAKE-Ben Okafor', 'ben@fake-techne.coop',
   'member', 'voting', true, '2026-02-06T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000010', 'FAKE-Admin Operator', 'ops@fake-techne.coop',
   'admin', 'operator', true, '2026-02-06T00:00:00Z'),
  ('00000000-0000-0000-0000-000000000020', 'FAKE-Lena Marchetti', 'lena@fake-hub.coop',
   'liaison', 'non-voting', true, '2026-03-01T00:00:00Z');

-- applicant-1 has no member row; probed via anon Postgres role
```

---

## Notes

- UUIDs use the `00000000-0000-0000-0000-0000000000XX` pattern to be unmistakably synthetic.
- Email domains use `fake-` prefix to prevent accidental delivery.
- The `FAKE-` prefix on display names prevents confusion with real members in logs or UI screenshots.
- This fixture pack covers the personas needed for W0.6–W2.2 probes. Extended personas
  (e.g., past-member, suspended-member, W3.x roles) are added at their respective milestones.
- Paired with C7 (probe-matrix-v0.1.html): the probe matrix defines which persona should
  succeed or fail on each table; this fixture pack provides the actual test data.

*Created at audit remediation, June 12, 2026. Update this file at each schema step that
introduces a new role or class.*
