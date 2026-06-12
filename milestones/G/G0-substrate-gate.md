---
id: G0
title: "substrate gate"
wave: G
kind: gate
owner: "composite"
status: pending
detail: briefed
depends_on: []
decision_refs: []
requires_steps: [W0.1, W0.2, W0.3, W0.4, W0.5, W0.6, W0.7, W0.8, W0.9, W0.10, W0.11, W0.12, W0.13, W0.14, W0.15, W0.16, W0.17, W0.18, W0.19, W0.20, W0.21, W0.22]
requires_decisions: [D1, D3, D4, D5, D6, D7, D10]
success_state: >-
  Every W0 step and every decision that gates W0 work is verified: security floor passes (all tables RLS-enabled and forced, default-deny, citations present, zero probe leaks per ci:rls-audit); migration pipeline applies clean on shadow; portal deploys to Pages; email rail confirmed; grammar lint green; signal loop live; export restore proven. Human attestation: organizer confirms security floor and substrate integrity before W1 begins.
verification: "composite: ci:rls-audit + ci:db-verify + ci:portal-build + ci:grammar-lint + human:organizer"
---

## Brief

The substrate gate closes Wave 0 and authorizes Wave 1 to begin. It is the security floor: before any member data is stored, every security constraint must be proven. The gate requires all 22 W0 steps to be verified and all decisions that have blocked W0 work to be decided. Human attestation from an organizer is required — this gate cannot be passed by CI alone.

The security floor assertion: every table in the public schema has row-level security enabled and forced; default-deny is the baseline; every policy carries a citation comment; the anonymous probe and cross-member probe both return denied on all protected tables. This is not checked once at W0.6 and forgotten — the gate asserts it holds across the complete substrate.

## Plain language

The bar Wave 0 must clear before member data is stored and Wave 1 begins.
