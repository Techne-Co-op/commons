#!/usr/bin/env python3
"""milestone-validate: the ledger's own gatekeeper.

Validates every file under milestones/ against the schema, resolves
dependencies (including coarse wave tokens), rejects cycles, enforces
status gating, and regenerates milestones/index.json and milestones/STATUS.md.

Exit code 0 only when the ledger is coherent. Run: python scripts/validate.py
Requires: PyYAML (scripts/requirements.txt).
"""
import os, re, sys, json, glob

try:
    import yaml
except ImportError:
    print("FATAL: PyYAML missing. pip install -r scripts/requirements.txt")
    sys.exit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MS = os.path.join(ROOT, "milestones")

KINDS = {"step", "decision", "ratification", "gate", "practice"}
STATUSES = ["pending", "in_progress", "blocked", "review", "done", "verified"]
DETAILS = {"briefed", "seeded"}
WAVES = ["D", "R", "W0", "W1", "W2", "G", "W3", "W4", "W5", "W6", "P"]
WAVE_TOKEN = re.compile(r"^W[0-6]$")
REQUIRED = ["id", "title", "wave", "kind", "owner", "status", "detail",
            "depends_on", "decision_refs", "success_state", "verification"]

errors, warnings = [], []
def err(msg): errors.append(msg)
def warn(msg): warnings.append(msg)

def parse_front_matter(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("---"):
        err(f"{path}: missing front matter"); return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        err(f"{path}: unterminated front matter"); return None
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as e:
        err(f"{path}: YAML parse error: {e}"); return None

def load():
    nodes, paths = {}, {}
    GENERATED = {"STATUS.md", "README.md"}
    for path in sorted(glob.glob(os.path.join(MS, "**", "*.md"), recursive=True)):
        if os.path.basename(path) in GENERATED:
            continue
        rel = os.path.relpath(path, ROOT)
        fm = parse_front_matter(path)
        if fm is None: continue
        for k in REQUIRED:
            if k not in fm: err(f"{rel}: missing field '{k}'")
        i = fm.get("id")
        if not i: continue
        if i in nodes: err(f"{rel}: duplicate id {i} (also in {paths[i]})")
        base = os.path.basename(path)
        if not (base.startswith(i + "-") or base == i + ".md"):
            err(f"{rel}: filename must begin with its id ({i}-...)")
        if fm.get("kind") not in KINDS: err(f"{rel}: kind '{fm.get('kind')}' not in {sorted(KINDS)}")
        if fm.get("status") not in STATUSES: err(f"{rel}: status '{fm.get('status')}' invalid")
        if fm.get("detail") not in DETAILS: err(f"{rel}: detail '{fm.get('detail')}' invalid")
        if fm.get("wave") not in WAVES: err(f"{rel}: wave '{fm.get('wave')}' invalid")
        if fm.get("status") == "blocked" and not fm.get("blocked_reason"):
            err(f"{rel}: blocked status requires blocked_reason")
        if fm.get("kind") in ("decision", "ratification") and str(fm.get("owner", "")).strip() == "agent":
            err(f"{rel}: decisions and ratifications are human-owned; owner must not be 'agent'")
        if fm.get("kind") == "gate":
            for k in ("requires_steps", "requires_decisions"):
                if k not in fm: err(f"{rel}: gate missing '{k}'")
        nodes[i] = fm; paths[i] = rel
    return nodes, paths

def expand_token(tok, nodes, self_id):
    if tok in nodes: return [tok]
    if WAVE_TOKEN.match(tok):
        ids = [i for i, n in nodes.items()
               if n.get("wave") == tok and n.get("kind") == "step" and i != self_id]
        if not ids: err(f"{self_id}: wave token {tok} expands to nothing")
        return ids
    err(f"{self_id}: dependency '{tok}' resolves to no id or wave token")
    return []

def build_graph(nodes, paths):
    parents = {}
    for i, n in nodes.items():
        ps = []
        for tok in n.get("depends_on") or []:
            ps += expand_token(str(tok), nodes, i)
        for d in n.get("decision_refs") or []:
            d = str(d)
            if d not in nodes:
                err(f"{paths[i]}: decision_ref '{d}' unknown")
            elif nodes[d].get("kind") not in ("decision", "ratification"):
                err(f"{paths[i]}: decision_ref '{d}' is not a decision or ratification")
            else:
                ps.append(d)
        if n.get("kind") == "gate":
            for r in (n.get("requires_steps") or []) + (n.get("requires_decisions") or []):
                r = str(r)
                if r not in nodes: err(f"{paths[i]}: gate requires unknown id '{r}'")
                else: ps.append(r)
        for tok in n.get("activates") or []:
            if str(tok) not in nodes:
                err(f"{paths[i]}: activates unknown id '{tok}'")
        parents[i] = sorted(set(ps))
    return parents

def check_cycles(parents):
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {i: WHITE for i in parents}
    def dfs(i, stack):
        color[i] = GRAY; stack.append(i)
        for p in parents[i]:
            if p not in color: continue
            if color[p] == GRAY:
                err("cycle: " + " <- ".join(stack + [p])); continue
            if color[p] == WHITE: dfs(p, stack)
        color[i] = BLACK; stack.pop()
    for i in parents:
        if color[i] == WHITE: dfs(i, [])

def check_gating(nodes, parents, paths):
    order = {s: n for n, s in enumerate(STATUSES)}
    for i, n in nodes.items():
        st = n.get("status")
        if st in ("pending", "blocked"): continue
        unmet = [p for p in parents[i] if nodes.get(p, {}).get("status") != "verified"]
        if unmet:
            err(f"{paths[i]}: status '{st}' but unverified parents: {', '.join(unmet)}")

def emit(nodes, parents):
    ids = sorted(nodes, key=lambda i: (WAVES.index(nodes[i]["wave"]), i))
    edges = []
    for i in ids:
        for p in parents[i]:
            edges.append([p, i])
    counts = {s: 0 for s in STATUSES}
    for n in nodes.values(): counts[n["status"]] += 1
    index = {"schema": "milestones/schema.json", "entries": len(ids),
             "status_counts": counts,
             "nodes": [{"id": i, "title": nodes[i]["title"], "wave": nodes[i]["wave"],
                        "kind": nodes[i]["kind"], "owner": nodes[i]["owner"],
                        "status": nodes[i]["status"], "detail": nodes[i]["detail"],
                        "depends_on": nodes[i].get("depends_on") or [],
                        "expanded_parents": parents[i],
                        "verification": nodes[i]["verification"]} for i in ids],
             "edges": edges}
    with open(os.path.join(MS, "index.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, indent=1)
    lines = ["# STATUS", "",
             f"entries {len(ids)} \u00b7 " + " \u00b7 ".join(f"{s} {counts[s]}" for s in STATUSES if counts[s]),
             "", "Generated by scripts/validate.py. Do not edit by hand.", ""]
    for w in WAVES:
        ws = [i for i in ids if nodes[i]["wave"] == w]
        if not ws: continue
        lines.append(f"## {w}")
        lines.append("")
        for i in ws:
            n = nodes[i]
            lines.append(f"- `{i}` \u00b7 {n['status']} \u00b7 {n['title']} \u00b7 owner: {n['owner']} \u00b7 verify: {n['verification']}")
        lines.append("")
    with open(os.path.join(MS, "STATUS.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

def main():
    nodes, paths = load()
    if nodes:
        parents = build_graph(nodes, paths)
        if not errors:
            check_cycles(parents)
            check_gating(nodes, parents, paths)
        if not errors:
            emit(nodes, parents)
    for w in warnings: print("WARN:", w)
    if errors:
        for e in errors: print("ERROR:", e)
        print(f"\nmilestone-validate: FAIL ({len(errors)} error(s) across {len(nodes)} entries)")
        sys.exit(1)
    print(f"milestone-validate: OK \u00b7 {len(nodes)} entries \u00b7 graph acyclic \u00b7 gating consistent \u00b7 index.json and STATUS.md regenerated")

if __name__ == "__main__":
    main()
