# citations.md · section addressing register (D7)

Until R1 (bylaws ratification), every bylaw citation in policies, schema comments, and
UI uses the `draft-bylaws:` prefix against this register. At R1 a single sweep drops
the prefix and freezes addresses; any address change at ratification is recorded here
as old -> new. Grant citations use `grant:§n` against the EE grant agreement and do not
change at R1. Status of every row: draft address, not frozen.

| address | anchors (as used in the ledger and plan) |
|---|---|
| draft-bylaws:§1.1–1.4 | membership classes; admission sequence (W1.1, W1.6) |
| draft-bylaws:§1.4 | application, agreements, signatures (W0.7, W1.4, W1.6) |
| draft-bylaws:§1.9.3 | non-redeemable share option, open question (W5.0) |
| draft-bylaws:§1.13 | stock; one-per-member rule (W1.2) |
| draft-bylaws:§2.4 | notice timing windows and delivery (W0.11, W1.8) |
| draft-bylaws:§2.8, §3.15 | consents (W4.3; consent event in W1.6) |
| draft-bylaws:§5.1 | capital accounts (W3.1) |
| draft-bylaws:§18.1 | member information rights; role scopes (W0.6, W0.8, W1.1) |
| draft-bylaws:§18.2 | sensitive deliberations, restricted rows (W0.6) |
| draft-bylaws:§XV | public benefit report, guaranteed public view (W6.0) |
| grant:§2 | hub surface: seats, meetup, application, education (W2.2–W2.4, W2.8) |
| grant:§4 | KPI thresholds and computations (W2.5) |
| grant:§6 | tranches (W2.9) |

Additions follow the same pattern; a citation used in code that is absent here fails
review. Maintenance of this register is part of W0.6's convention and D7's record.

## contract: prefix (W0.22 — signal loop)

The signal loop's authority derives from the operating contract (AGENTS.md and
GOVERNANCE.md), not the draft bylaws. Loop schema citations use the `contract:` prefix.

| address | anchors |
|---|---|
| contract:agents§preamble | loop process identities and role definitions |
| contract:agents§5 | decisions and ratifications are human-only |
| contract:agents§7 | blocked beats improvised — blocker reporting discipline |
| contract:governance§lifecycle | status lifecycle and gating |
| contract:governance§validation | snapshot ingest and ledger mirror |
