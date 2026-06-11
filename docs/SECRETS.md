# SECRETS.md · names and custody, never values

No secret value ever enters this repository, an agent context, a fixture, or a log.
This file names the secrets, where they live, and who holds them.

| name | lives in | holder | consumed by |
|---|---|---|---|
| SUPABASE_ACCESS_TOKEN | GitHub Actions secrets | human admin | db-verify, functions-deploy |
| SUPABASE_PROJECT_REF | GitHub Actions secrets | human admin | db-verify |
| SUPABASE_ANON_KEY | Actions secrets; public by design in the built bundle | human admin | portal build |
| SUPABASE_SERVICE_ROLE_KEY | Supabase function env only | human admin | edge functions |
| EMAIL_PROVIDER_API_KEY (per D4) | Supabase function env | human admin | email-send |
| ANTHROPIC_API_KEY | Supabase function env | human admin | nou-gateway (W1.7) |
| MERCURY_API_TOKEN (read-only) | Supabase function env | human admin | mercury-ingest (W3.4) |

Rotation, revocation, and any key custody beyond this table are human acts recorded as
events, never agent acts. The anon key is the only secret that is public by design; its
safety is exactly the completeness of RLS (ci:rls-audit).
