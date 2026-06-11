---
id: D5
title: "make.com adoption trigger"
wave: D
kind: decision
owner: "organizers"
status: pending
detail: briefed
depends_on: []
decision_refs: []
success_state: >-
  The reversal trigger is recorded in the chokepoint analysis and docs/decisions/D5.md.
verification: "human:organizers"
---

## Brief

Proposed default: not adopted in alpha. Trigger if invoked: a required integration whose first-party Edge Function cost exceeds reasonable effort and whose data remains exportable. Until then its PRD duties route to pg_cron, Edge Functions, and Actions.

## Plain language

Whether Make.com is ever adopted, and what would justify it.

## Record

The deliberation brief and the eventual record of decision live at docs/decisions/D5.md. This ledger entry tracks status only; agents never set it.
