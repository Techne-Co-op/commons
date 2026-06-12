---
id: D4
title: "transactional email provider"
wave: D
kind: decision
owner: "organizers"
status: done
detail: briefed
depends_on: []
decision_refs: []
success_state: >-
  One provider with API send and delivery webhooks is chosen and recorded in docs/decisions/D4.md.
verification: "human:organizers"
---

## Brief

Required because notices carry legally timed windows and delivery tracking (CIS §08, draft-bylaws §2.4); Supabase built-in mail covers auth flows only. Candidate class: Resend, Postmark, SES; no endorsement implied.

## Plain language

Which service delivers official email.

## Record

The deliberation brief and the eventual record of decision live at docs/decisions/D4.md. This ledger entry tracks status only; agents never set it.
