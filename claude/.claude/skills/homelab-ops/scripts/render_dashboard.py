#!/usr/bin/env python3
"""Render the homelab sweep into a self-contained HTML dashboard.

Reads the labeled block output of sweep.sh on stdin and writes one standalone
HTML file (inline CSS/JS, no external requests). Overwrite-in-place each run.

Usage:
  bash sweep.sh dockerhost-1 | python3 render_dashboard.py \
       --out /path/Homelab/Health/dashboard.html --host dockerhost-1 \
       --generated "2026-06-08 14:50" [--history-dir /path/Homelab/Health]
"""
import argparse
import glob
import html
import os
import re
import sys


def parse(text):
    blocks, current = {}, None
    for line in text.splitlines():
        if line.startswith("### "):
            current = line[4:].strip()
            blocks[current] = []
        elif current is not None:
            blocks[current].append(line)
    return blocks


def classify(name, state, status, unhealthy, restarting):
    if name in unhealthy:
        return "unhealthy", "Unhealthy"
    if name in restarting or state == "restarting":
        return "restarting", "Restarting"
    if "(healthy)" in status:
        return "healthy", "Healthy"
    if state == "running":
        return "running", "Running"
    return "stopped", state.capitalize() or "Stopped"


def uptime_of(status):
    s = re.sub(r"\s*\((un)?healthy\)\s*$", "", status).strip()
    return re.sub(r"^Up\s+", "", s) if s.lower().startswith("up") else s


STATUS_COLOR = {
    "healthy": "#5fbf63", "running": "#5b8fd6", "unhealthy": "#e5615a",
    "restarting": "#d6a93b", "stopped": "#9a9a9a",
}


def render(blocks, host, generated, history):
    host_lines = [l for l in blocks.get("HOST", []) if l.strip()]
    uptime_line = next((l for l in host_lines if "up" in l and "load" in l), "")
    m = re.search(r"up\s+(.*?),\s+\d+ user", uptime_line)
    uptime = m.group(1) if m else ""
    load = ""
    lm = re.search(r"load average:\s*(.*)$", uptime_line)
    if lm:
        load = lm.group(1)

    unhealthy = {l.strip() for l in blocks.get("HEALTH_UNHEALTHY", []) if l.strip()}
    restarting = {l.strip() for l in blocks.get("RESTARTING", []) if l.strip()}
    counts = {}
    for l in blocks.get("RESTART_COUNTS", []):
        if "|" in l:
            n, c = l.split("|", 1)
            counts[n.strip()] = c.strip()

    containers = []
    for l in blocks.get("CONTAINERS", []):
        if l.count("|") < 3:
            continue
        name, state, status, image = l.split("|", 3)
        cls, label = classify(name, state, status, unhealthy, restarting)
        containers.append({
            "name": name, "state": state, "status": status, "image": image,
            "cls": cls, "label": label, "uptime": uptime_of(status),
            "restarts": counts.get(name, "0"),
        })
    # Problems first, then by name.
    order = {"unhealthy": 0, "restarting": 1, "stopped": 2, "running": 3, "healthy": 4}
    containers.sort(key=lambda c: (order[c["cls"]], c["name"]))

    total = len(containers)
    running = sum(1 for c in containers if c["cls"] in ("running", "healthy"))
    issues = sum(1 for c in containers if c["cls"] in ("unhealthy", "restarting", "stopped"))

    disk = []
    for l in blocks.get("DISK", []):
        parts = re.split(r"\s{2,}", l.strip())
        if len(parts) >= 5 and parts[0] != "TYPE":
            disk.append(parts)

    # Cards
    cards = []
    for c in containers:
        color = STATUS_COLOR[c["cls"]]
        rc = f'<span class="rc">restarts {html.escape(c["restarts"])}</span>' if c["restarts"] not in ("0", "") else ""
        cards.append(f"""
      <div class="card" data-name="{html.escape(c['name'].lower())}">
        <div class="card-top">
          <span class="dot" style="background:{color}"></span>
          <span class="cname">{html.escape(c['name'])}</span>
          <span class="badge" style="background:{color}1a;color:{color}">{html.escape(c['label'])}</span>
        </div>
        <div class="image">{html.escape(c['image'])}</div>
        <div class="meta"><span>up {html.escape(c['uptime'])}</span>{rc}</div>
      </div>""")

    disk_cards = "".join(
        f"""<div class="disk-card"><div class="dk">{html.escape(d[0])}</div>
        <div class="dv">{html.escape(d[3])}</div>
        <div class="dr">{html.escape(d[4])} reclaimable</div></div>"""
        for d in disk
    )

    hist_html = ""
    if history:
        items = "".join(
            f'<li><a href="{html.escape(os.path.basename(p))}">{html.escape(os.path.basename(p))}</a></li>'
            for p in history
        )
        hist_html = f'<section class="history"><h2>Recent reports</h2><ul>{items}</ul></section>'

    verdict = ("All systems healthy" if issues == 0
               else f"{issues} container{'s' if issues != 1 else ''} need attention")
    verdict_color = "#5fbf63" if issues == 0 else "#e5615a"

    legend_items = [
        ("healthy", "Healthy", "probe passing"),
        ("running", "Running", "no healthcheck"),
        ("unhealthy", "Unhealthy", "probe failing"),
        ("restarting", "Restarting", ""),
        ("stopped", "Stopped", ""),
    ]
    legend = "".join(
        f'<span class="lg"><span class="dot" style="background:{STATUS_COLOR[k]}"></span>'
        f'{html.escape(lab)}{(" <em>" + html.escape(desc) + "</em>") if desc else ""}</span>'
        for k, lab, desc in legend_items
    )

    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Homelab Health — {html.escape(host)}</title>
<style>
  :root {{ --bg:#16161a; --card:#1f1f25; --fg:#e8e6e3; --muted:#928c84; --line:#2c2c33; --accent:#e0564e; }}
  * {{ box-sizing:border-box; margin:0; padding:0; }}
  body {{ font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; background:var(--bg); color:var(--fg); padding:2rem; }}
  .wrap {{ max-width:1100px; margin:0 auto; }}
  header {{ display:flex; justify-content:space-between; align-items:baseline; flex-wrap:wrap; gap:.5rem; border-bottom:2px solid var(--accent); padding-bottom:.75rem; margin-bottom:1.25rem; }}
  h1 {{ font-size:1.4rem; }}
  h1 .host {{ color:var(--accent); }}
  .gen {{ color:var(--muted); font-size:.85rem; }}
  .verdict {{ font-weight:600; margin:.25rem 0 1rem; }}
  .hostmeta {{ color:var(--muted); font-size:.85rem; margin-bottom:1.25rem; }}
  .stats {{ display:grid; grid-template-columns:repeat(3,1fr); gap:1rem; margin-bottom:1.5rem; }}
  .stat {{ background:var(--card); border:1px solid var(--line); border-radius:10px; padding:1rem 1.25rem; }}
  .stat .n {{ font-size:2rem; font-weight:700; }}
  .stat .l {{ color:var(--muted); font-size:.8rem; text-transform:uppercase; letter-spacing:.04em; }}
  .search {{ width:100%; padding:.6rem .8rem; border:1px solid var(--line); border-radius:8px; font-size:.95rem; margin-bottom:1rem; background:var(--card); color:var(--fg); }}
  .search::placeholder {{ color:var(--muted); }}
  .search:focus {{ outline:none; border-color:var(--accent); }}
  .legend {{ display:flex; flex-wrap:wrap; gap:1.1rem; font-size:.8rem; color:var(--fg); margin-bottom:1.1rem; align-items:center; }}
  .legend .lg {{ display:inline-flex; align-items:center; gap:.4rem; }}
  .legend em {{ color:var(--muted); font-style:normal; }}
  .hint {{ position:relative; cursor:help; border-bottom:1px dotted var(--muted); }}
  .hint .tip {{ visibility:hidden; opacity:0; position:absolute; left:0; top:150%; z-index:20; width:330px; background:#2a2a31; color:var(--fg); border:1px solid var(--line); border-radius:8px; padding:.6rem .75rem; font-size:.76rem; font-weight:400; line-height:1.4; box-shadow:0 6px 20px rgba(0,0,0,.45); transition:opacity .12s ease; pointer-events:none; }}
  .hint:hover .tip {{ visibility:visible; opacity:1; }}
  .grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:.75rem; }}
  .card {{ background:var(--card); border:1px solid var(--line); border-radius:10px; padding:.85rem 1rem; }}
  .card-top {{ display:flex; align-items:center; gap:.5rem; }}
  .dot {{ width:10px; height:10px; border-radius:50%; flex:0 0 auto; }}
  .cname {{ font-weight:600; font-size:.95rem; flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }}
  .badge {{ font-size:.68rem; font-weight:600; padding:.15rem .45rem; border-radius:20px; }}
  .image {{ color:var(--muted); font-size:.78rem; margin:.4rem 0 .35rem; font-family:ui-monospace,monospace; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }}
  .meta {{ font-size:.78rem; color:var(--fg); display:flex; justify-content:space-between; }}
  .rc {{ color:var(--accent); font-weight:600; }}
  h2 {{ font-size:1rem; margin:1.75rem 0 .75rem; }}
  .disk {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(180px,1fr)); gap:.75rem; }}
  .disk-card {{ background:var(--card); border:1px solid var(--line); border-radius:10px; padding:.8rem 1rem; }}
  .disk-card .dk {{ color:var(--muted); font-size:.78rem; text-transform:uppercase; letter-spacing:.04em; }}
  .disk-card .dv {{ font-size:1.3rem; font-weight:700; }}
  .disk-card .dr {{ color:var(--muted); font-size:.74rem; }}
  .history ul {{ list-style:none; columns:2; }}
  .history a {{ color:var(--accent); text-decoration:none; font-size:.85rem; }}
  footer {{ color:var(--muted); font-size:.75rem; margin-top:2rem; border-top:1px solid var(--line); padding-top:.75rem; }}
</style></head>
<body><div class="wrap">
  <header>
    <h1>Homelab Health <span class="host">{html.escape(host)}</span></h1>
    <span class="gen">generated {html.escape(generated)}</span>
  </header>
  <div class="verdict" style="color:{verdict_color}">{verdict}</div>
  <div class="hostmeta">uptime {html.escape(uptime)} &nbsp;·&nbsp; <span class="hint">load {html.escape(load)}<span class="tip">Load average over the last 1, 5, and 15 minutes: the number of processes competing for CPU. Compare to your core count: 1.0 per core means one core fully busy. It also counts tasks blocked on disk or network I/O, not just CPU.</span></span></div>
  <div class="stats">
    <div class="stat"><div class="n">{total}</div><div class="l">Containers</div></div>
    <div class="stat"><div class="n" style="color:#5fbf63">{running}</div><div class="l">Up</div></div>
    <div class="stat"><div class="n" style="color:{'#9a9a9a' if issues==0 else '#e5615a'}">{issues}</div><div class="l">Need attention</div></div>
  </div>
  <div class="legend">{legend}</div>
  <input class="search" placeholder="Filter containers…" oninput="filt(this.value)">
  <div class="grid" id="grid">{''.join(cards)}</div>
  <h2>Disk</h2>
  <div class="disk">{disk_cards}</div>
  {hist_html}
  <footer>Generated by the homelab-ops skill. Read-only snapshot. Refresh by running another sweep.</footer>
</div>
<script>
  function filt(q) {{
    q = q.toLowerCase();
    for (const c of document.querySelectorAll('.card'))
      c.style.display = c.dataset.name.includes(q) ? '' : 'none';
  }}
</script>
</body></html>"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--host", default="dockerhost-1")
    ap.add_argument("--generated", default="")
    ap.add_argument("--history-dir", default="")
    args = ap.parse_args()

    blocks = parse(sys.stdin.read())
    history = []
    if args.history_dir:
        history = sorted(glob.glob(os.path.join(args.history_dir, "health-*.md")), reverse=True)[:10]

    out = render(blocks, args.host, args.generated, history)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"dashboard written: {args.out}")


if __name__ == "__main__":
    main()
