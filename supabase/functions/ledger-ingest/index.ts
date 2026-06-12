/**
 * ledger-ingest — the signal loop's sensor.
 *
 * POST from the GitHub Action on push to main. Accepts the full index.json
 * payload, writes a ledger_snapshots event, atomically rebuilds ledger_entries,
 * and auto-opens deliberating threads for newly-seen open D/R entries.
 *
 * Auth: x-ingest-token header checked against LEDGER_INGEST_TOKEN env var.
 * Idempotent on sha: a second POST with the same sha is a no-op (200 OK).
 *
 * Schema version detection:
 *   v1 — index.json nodes have no decision_refs field (pre-W0.21)
 *   v2 — nodes include decision_refs (post-W0.21)
 * v1 is accepted; leverage views return empty results until v2 lands.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "x-ingest-token, content-type",
};

interface IndexNode {
  id: string;
  title: string;
  wave: string;
  kind: string;
  owner?: string;
  status: string;
  detail?: string;
  depends_on?: string[];
  expanded_parents?: string[];
  decision_refs?: string[];
  verification?: string;
  blocked_reason?: string;
}

interface IndexPayload {
  schema?: string;
  entries?: number;
  status_counts?: Record<string, number>;
  nodes?: IndexNode[];
  edges?: [string, string][];
  generated_at?: string;
}

interface IngestBody {
  sha: string;
  generated_at?: string;
  index: IndexPayload;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method not allowed" }), {
      status: 405, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Auth
  const token = req.headers.get("x-ingest-token");
  const expected = Deno.env.get("LEDGER_INGEST_TOKEN");
  if (!expected || token !== expected) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Parse body
  let body: IngestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid json" }), {
      status: 422, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Shape validation
  if (!body.sha || typeof body.sha !== "string") {
    return new Response(JSON.stringify({ error: "sha required" }), {
      status: 422, headers: { ...CORS, "content-type": "application/json" },
    });
  }
  if (!body.index?.nodes || !Array.isArray(body.index.nodes)) {
    return new Response(JSON.stringify({ error: "index.nodes required" }), {
      status: 422, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } }
  );

  const sha = body.sha;
  const nodes = body.index.nodes;

  // Idempotency check
  const { data: existing } = await supabase
    .from("ledger_snapshots")
    .select("id")
    .eq("sync_sha", sha)
    .limit(1);

  if (existing && existing.length > 0) {
    return new Response(JSON.stringify({
      snapshot_id: existing[0].id,
      entries_upserted: 0,
      status_counts: body.index.status_counts ?? {},
      schema_version: "idempotent",
      message: "sha already ingested",
    }), { status: 200, headers: { ...CORS, "content-type": "application/json" } });
  }

  // Schema version detection
  const hasDecisionRefs = nodes.some((n) => Array.isArray(n.decision_refs));
  const schemaVersion = hasDecisionRefs ? "v2" : "v1";

  // Resolve actor: the loop agent participant (agent role)
  // If not found, use a system sentinel approach — snapshot still recorded
  let actorId: string | null = null;
  const { data: agentPart } = await supabase
    .from("loop_participants")
    .select("id")
    .eq("role", "agent")
    .limit(1);
  if (agentPart && agentPart.length > 0) {
    actorId = agentPart[0].id;
  } else {
    // Create a bootstrap agent participant if none exists
    const { data: newAgent } = await supabase
      .from("loop_participants")
      .insert({
        display_name: "ledger-ingest",
        role: "agent",
        auth_user_id: null,
      })
      .select("id")
      .single();
    if (newAgent) actorId = newAgent.id;
  }

  if (!actorId) {
    return new Response(JSON.stringify({ error: "could not resolve actor" }), {
      status: 500, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Write snapshot
  const statusCounts = body.index.status_counts ??
    nodes.reduce((acc: Record<string, number>, n) => {
      acc[n.status] = (acc[n.status] ?? 0) + 1;
      return acc;
    }, {});

  const { data: snapshot, error: snapErr } = await supabase
    .from("ledger_snapshots")
    .insert({
      actor: actorId,
      sync_sha: sha,
      entry_count: nodes.length,
      status_counts: statusCounts,
      payload: body.index,
      citation: "contract:governance§validation",
    })
    .select("id")
    .single();

  if (snapErr || !snapshot) {
    return new Response(JSON.stringify({ error: "snapshot insert failed", detail: snapErr?.message }), {
      status: 500, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Atomically rebuild ledger_entries via upsert
  const now = new Date().toISOString();
  const upsertRows = nodes.map((n) => ({
    id: n.id,
    title: n.title,
    wave: n.wave,
    kind: n.kind,
    owner: n.owner ?? null,
    status: n.status,
    detail: n.detail ?? null,
    depends_on: n.depends_on ?? [],
    expanded_parents: n.expanded_parents ?? [],
    decision_refs: n.decision_refs ?? [],
    verification: n.verification ?? null,
    blocked_reason: n.blocked_reason ?? null,
    last_synced_at: now,
    sync_sha: sha,
  }));

  const { error: upsertErr } = await supabase
    .from("ledger_entries")
    .upsert(upsertRows, { onConflict: "id", ignoreDuplicates: false });

  if (upsertErr) {
    return new Response(JSON.stringify({ error: "ledger_entries upsert failed", detail: upsertErr.message }), {
      status: 500, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Auto-open deliberating threads for newly seen open D/R entries
  const openDecisions = nodes.filter(
    (n) => n.kind === "decision" || n.kind === "ratification"
  ).filter((n) => n.status !== "done" && n.status !== "verified");

  let threadsOpened = 0;
  for (const d of openDecisions) {
    // Check if a live thread already exists
    const { data: existing } = await supabase
      .from("decision_threads")
      .select("id")
      .eq("decision_id", d.id)
      .not("state", "in", '("recorded","superseded")')
      .limit(1);

    if (!existing || existing.length === 0) {
      const { error: threadErr } = await supabase
        .from("decision_threads")
        .insert({
          decision_id: d.id,
          state: "deliberating",
          visibility: "public",
          opened_by: actorId,
        });
      if (!threadErr) threadsOpened++;
    }

    // Auto-resolve decision-kind blockers whose decision is now recorded
    if (d.status === "done" || d.status === "verified") {
      await supabase
        .from("blockers")
        .update({ state: "resolved", resolution_note: "decision recorded in ledger" })
        .eq("entry_id", d.id)
        .eq("kind", "decision")
        .eq("state", "open");
    }
  }

  return new Response(JSON.stringify({
    snapshot_id: snapshot.id,
    entries_upserted: nodes.length,
    status_counts: statusCounts,
    schema_version: schemaVersion,
    threads_opened: threadsOpened,
  }), { status: 200, headers: { ...CORS, "content-type": "application/json" } });
});
