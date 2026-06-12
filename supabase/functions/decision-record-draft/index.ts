/**
 * decision-record-draft — the effector's pen, never its hand.
 *
 * Authenticated organizer POSTs a decision outcome and reasoning.
 * Returns the exact markdown to carry into a PR. A human opens the PR.
 * The loop sees the decision only when the next push syncs the repository.
 *
 * Auth: Supabase magic-link session (JWT in Authorization: Bearer header).
 * Caller must be role='organizer' in loop_participants.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

interface DraftBody {
  decision_id: string;   // e.g. "D3"
  outcome: string;       // brief outcome label
  reasoning: string;     // one paragraph
  decided_by: string;    // display name(s) of decision-makers
  decided_date?: string; // ISO date, defaults to today
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

  // Auth via JWT
  const authHeader = req.headers.get("authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  if (!jwt) {
    return new Response(JSON.stringify({ error: "unauthorized: no token" }), {
      status: 401, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { authorization: `Bearer ${jwt}` } }, auth: { persistSession: false } }
  );

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } }
  );

  // Verify organizer role
  const { data: { user }, error: authErr } = await supabase.auth.getUser();
  if (authErr || !user) {
    return new Response(JSON.stringify({ error: "unauthorized: invalid token" }), {
      status: 401, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  const { data: participant } = await supabaseAdmin
    .from("loop_participants")
    .select("id, display_name, role")
    .eq("auth_user_id", user.id)
    .single();

  if (!participant || participant.role !== "organizer") {
    return new Response(JSON.stringify({ error: "forbidden: organizer role required" }), {
      status: 403, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Parse body
  let body: DraftBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "invalid json" }), {
      status: 422, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  if (!body.decision_id || !body.outcome || !body.reasoning || !body.decided_by) {
    return new Response(JSON.stringify({ error: "decision_id, outcome, reasoning, decided_by required" }), {
      status: 422, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  // Fetch decision entry
  const { data: entry } = await supabaseAdmin
    .from("ledger_entries")
    .select("id, title, wave, kind, status")
    .eq("id", body.decision_id)
    .single();

  if (!entry) {
    return new Response(JSON.stringify({ error: `decision ${body.decision_id} not found in ledger` }), {
      status: 404, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  if (entry.kind !== "decision" && entry.kind !== "ratification") {
    return new Response(JSON.stringify({ error: `${body.decision_id} is kind '${entry.kind}', not decision/ratification` }), {
      status: 422, headers: { ...CORS, "content-type": "application/json" },
    });
  }

  const decidedDate = body.decided_date ?? new Date().toISOString().slice(0, 10);
  const id = entry.id;
  const title = entry.title;

  // Generate the markdown patch for docs/decisions/<id>.md
  const markdownPatch = `---
id: ${id}
title: "${title}"
status: decided
decided_date: ${decidedDate}
decided_by: "${body.decided_by}"
ledger_entry: milestones/${entry.wave}/${id}-${title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}.md
---

# ${id} · ${title}

## Record of decision

**Outcome:** ${body.outcome}

**Decided:** ${decidedDate}
**Decided by:** ${body.decided_by}

## Reasoning

${body.reasoning}

## Prior deliberation

See decision thread in the signal loop for deliberation notes and leanings.
`;

  // Generate the ledger entry status note (patch for the milestone .md front matter)
  const ledgerPatch = `status: done
# Add to the milestone .md front matter. The ledger entry records the decision;
# the thread may be transitioned to 'recorded' once this PR URL is known.
# Front matter change: status: pending -> status: done (or verified after W0.2)
`;

  // Commit message
  const outcomeSummary = body.outcome.length > 60
    ? body.outcome.slice(0, 57) + "..."
    : body.outcome;
  const commitMessage = `decide(${id}): ${outcomeSummary}`;

  // PR checklist per .github/PULL_REQUEST_TEMPLATE.md spirit
  const prChecklist = [
    `[ ] docs/decisions/${id}.md updated with outcome and reasoning`,
    `[ ] milestones/${entry.wave}/${id}-*.md status flipped to 'done'`,
    `[ ] milestones/index.json and STATUS.md regenerated by CI (do not hand-edit)`,
    `[ ] Loop thread transitioned to 'recorded' with this PR URL after merge`,
    `[ ] No new code changes in this PR (decision record only)`,
  ];

  return new Response(JSON.stringify({
    decision_id: id,
    markdown_patch: markdownPatch,
    ledger_patch: ledgerPatch,
    commit_message: commitMessage,
    pr_checklist: prChecklist,
    drafted_by: participant.display_name,
    drafted_at: new Date().toISOString(),
    note: "This is a draft. A human must open the PR. The loop updates when the next push syncs.",
  }), { status: 200, headers: { ...CORS, "content-type": "application/json" } });
});
