#!/usr/bin/env python3
"""loop_probe.py — D12 loop probe: verify v_decision_leverage integrity.

Three assertions:
  1. Existence    — view returns at least one row
  2. Column shape — no row has null id, decision_status, or thread_state
  3. Staleness    — no decision_thread in deliberating state older than STALE_DAYS

Exit 0: all assertions pass.
Exit 1: one or more assertions fail (CI-blocking).
Exit 2: environment error (missing env vars, network failure).

Environment variables required:
  CIS_REST          — Supabase REST base URL (no trailing slash)
  CIS_ANON_KEY      — Supabase anon key (read-only, sufficient for public views)

Optional:
  STALE_DAYS        — staleness threshold in days (default: 14)
  PROBE_OUTPUT      — path to write JSON report (default: stdout only)
"""

import json
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone, timedelta

# ── config ────────────────────────────────────────────────────────────────────

REST     = os.environ.get("CIS_REST", "").rstrip("/")
ANON_KEY = os.environ.get("CIS_ANON_KEY", "")
STALE_DAYS = int(os.environ.get("STALE_DAYS", "14"))
PROBE_OUTPUT = os.environ.get("PROBE_OUTPUT", "")

if not REST or not ANON_KEY:
    print("FATAL: CIS_REST and CIS_ANON_KEY must be set", file=sys.stderr)
    sys.exit(2)

HEADERS = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Accept": "application/json",
}


def get(path: str) -> list:
    url = f"{REST}{path}"
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        raise RuntimeError(f"HTTP {e.code} from {url}: {body}") from e
    except urllib.error.URLError as e:
        raise RuntimeError(f"Network error fetching {url}: {e.reason}") from e


# ── assertions ────────────────────────────────────────────────────────────────

def assert_existence(rows: list) -> dict:
    """View must return at least one row."""
    passed = len(rows) > 0
    return {
        "name": "existence",
        "description": "v_decision_leverage returns at least one row",
        "passed": passed,
        "detail": f"{len(rows)} rows returned" if passed else "view returned 0 rows — loop has no visible decisions",
    }


def assert_column_shape(rows: list) -> dict:
    """No row may have null id, decision_status, or thread_state."""
    required = ["id", "decision_status", "thread_state"]
    bad = [
        r.get("id", "<no id>")
        for r in rows
        if any(r.get(col) is None for col in required)
    ]
    passed = len(bad) == 0
    return {
        "name": "column_shape",
        "description": "All rows have non-null id, decision_status, thread_state",
        "passed": passed,
        "detail": "OK" if passed else f"Null required column in rows: {bad}",
        "failing_ids": bad if not passed else [],
    }


def assert_staleness(rows: list) -> dict:
    """No decision_thread in deliberating state older than STALE_DAYS."""
    stale_ids = []
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=STALE_DAYS)

    # Fetch decision_threads for all decision entries in the view
    decision_ids = [r["id"] for r in rows if r.get("id")]
    if not decision_ids:
        return {
            "name": "staleness",
            "description": f"No deliberating thread older than {STALE_DAYS} days",
            "passed": True,
            "detail": "No decision IDs to check",
        }

    id_filter = ",".join(f'"{d}"' for d in decision_ids)
    threads = get(f"/decision_threads?decision_id=in.({','.join(decision_ids)})&state=eq.deliberating&select=id,decision_id,created_at")

    for t in threads:
        created_raw = t.get("created_at", "")
        try:
            # Postgres returns e.g. "2026-06-13T03:33:08.240339+00:00"
            created = datetime.fromisoformat(created_raw.replace("+00:00", "+00:00"))
            if created < cutoff:
                stale_ids.append({
                    "thread_id": t["id"],
                    "decision_id": t["decision_id"],
                    "created_at": created_raw,
                    "age_days": (now - created).days,
                })
        except (ValueError, TypeError):
            pass  # unparseable timestamp — skip

    passed = len(stale_ids) == 0
    return {
        "name": "staleness",
        "description": f"No deliberating thread older than {STALE_DAYS} days",
        "passed": passed,
        "detail": "OK" if passed else f"{len(stale_ids)} stale thread(s) found",
        "stale_threads": stale_ids if not passed else [],
    }


# ── main ──────────────────────────────────────────────────────────────────────

def main() -> int:
    run_at = datetime.now(timezone.utc).isoformat()
    results = []
    env_error = None

    try:
        rows = get("/v_decision_leverage")
    except RuntimeError as e:
        print(f"FATAL: could not fetch v_decision_leverage: {e}", file=sys.stderr)
        sys.exit(2)

    # Run assertions
    for fn in [assert_existence, assert_column_shape, assert_staleness]:
        try:
            result = fn(rows)
        except RuntimeError as e:
            result = {
                "name": fn.__name__.replace("assert_", ""),
                "passed": False,
                "detail": f"Error during check: {e}",
            }
        results.append(result)

    # Build report
    passed_all = all(r["passed"] for r in results)
    report = {
        "probe": "loop_probe",
        "run_at": run_at,
        "stale_threshold_days": STALE_DAYS,
        "passed": passed_all,
        "row_count": len(rows),
        "assertions": results,
    }

    report_json = json.dumps(report, indent=2)
    print(report_json)

    if PROBE_OUTPUT:
        with open(PROBE_OUTPUT, "w") as f:
            f.write(report_json)

    # GitHub Actions annotation
    if not passed_all:
        for r in results:
            if not r["passed"]:
                print(f"::error::loop_probe [{r['name']}] FAILED — {r['detail']}", file=sys.stderr)
    else:
        print("::notice::loop_probe: all assertions passed", file=sys.stderr)

    return 0 if passed_all else 1


if __name__ == "__main__":
    sys.exit(main())
