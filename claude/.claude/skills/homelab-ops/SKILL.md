---
name: homelab-ops
description: >-
  Run a read-only health sweep of the Docker homelab on dockerhost-1 and write a
  dated report into the Obsidian vault. Use this whenever Michael asks "check the
  homelab", "what's down", "homelab status", "are my containers ok", "anything
  broken on dockerhost", or wants a snapshot of running services, restart loops,
  or unhealthy containers. Use it proactively before/after homelab changes to
  capture a before/after picture. This skill only observes; it never starts,
  stops, restarts, or removes anything.
---

# Homelab Ops — container health sweep

Michael runs ~12 self-hosted services as Docker containers on a single host,
`dockerhost-1` (reachable over Tailscale). He saves a lot but rarely circles
back, so the job here is to give him a fast, trustworthy answer to "is anything
wrong?" and leave a dated artifact in the vault he can scan later.

This skill is **read-only by design**. Container actions (restart, stop, rm,
recreate) are deliberately out of scope: a status check should never be able to
take a service down. If Michael explicitly asks to restart something after
seeing the report, do that as a separate, clearly-confirmed step outside this
skill.

## Connection

The host is `dockerhost-1` (defined in `~/.ssh/config`). Everything runs over a
single SSH session via the bundled script.

**Preflight — auth can fail silently.** Michael's SSH config routes hosts
through the 1Password SSH agent, which does not always sign requests from a
non-interactive shell. If the sweep fails with
`communication with agent failed` or `Permission denied`, do not retry blindly.
Stop and tell him: SSH auth to dockerhost-1 isn't working from this environment.
The clean fix is a dedicated key for that host so it doesn't depend on the
1Password agent. Suggest adding to `~/.ssh/config`:

```
Host dockerhost-1
    HostName 100.x.y.z          # your dockerhost's Tailscale IP
    User michaelhenry
    IdentityFile ~/.ssh/homelab_ed25519
    IdentityAgent none
```

(generate with `ssh-keygen -t ed25519 -f ~/.ssh/homelab_ed25519`, then
`ssh-copy-id -i ~/.ssh/homelab_ed25519 dockerhost-1`). Diagnose before working
around it — don't silently fall back to something that masks the real problem.

## Run the sweep

Use the bundled script. It makes one SSH round-trip and prints parseable blocks,
so you don't reinvent the remote commands each time:

```bash
bash "$SKILL_DIR/scripts/sweep.sh" dockerhost-1 > /tmp/homelab-sweep.txt
```

Save the output to a temp file (as above) so the same snapshot feeds both the
markdown report and the dashboard without a second SSH round-trip. The output is
divided into labeled sections (`### CONTAINERS`, `### HEALTH_UNHEALTHY`,
`### RESTARTING`, `### RESTART_COUNTS`, `### DISK`). Parse those rather than
running ad-hoc `docker` commands, so behavior is consistent across runs.

## What counts as a problem

Lead with what's wrong, because that's the whole reason to run this. Flag, in
order of seriousness:

1. **Down** — a container that exists but is `exited`/`dead` and isn't a
   known one-shot job. These are the headline.
2. **Restarting / crash-looping** — `restarting` state, or a `RestartCount`
   that's climbed notably since the last report. A service that's "up" but
   restarting every minute is effectively down.
3. **Unhealthy** — passing Docker's healthcheck matters more than "running".
   A container can be `Up` and `unhealthy` at the same time.
4. **Disk pressure** — `docker system df` showing reclaimable space ballooning,
   or the host filling up. Worth a mention, not an alarm.

Everything healthy gets a one-line "all good" summary, not a wall of green.

## "Running" vs "Healthy" is not a problem

Docker reports two different things, and the gap between them is expected, not a
fault:

- **Running** means the container's main process is alive. That is all Docker
  knows, because the image defines no `HEALTHCHECK`. There is no probe testing
  whether the app inside actually works.
- **Healthy** means the container is running AND a defined `HEALTHCHECK` is
  currently passing (Docker periodically runs a probe inside the container, such
  as an HTTP ping or a CLI check, and it is succeeding).

So "Running" is a weaker guarantee than "Healthy", but it is NOT a defect. It
just means that image ships without a healthcheck. Do not flag a `running`
container as a problem or imply it needs fixing. The only true red flag is
`unhealthy`: a defined probe that is actively failing. A container can be `Up`
and `unhealthy` at the same time, which is worse than plain `running`.

Note `health: starting` too: a healthchecked container gets a `start_period`
grace window at boot where it is running but the probe has not passed yet. Treat
that as Running, not as a problem.

If Michael asks why something is "only Running", the answer is that its image has
no healthcheck defined. Adding one is a change to that service's compose file on
the host (out of scope for this read-only skill), not something to fix here.

## Report format

Write the report to `Homelab/Health/health-YYYY-MM-DD.md` in the vault
(`/Users/michaelhenry/Obsidian/Homelab/Health/`). If a file for today already
exists, append a new timestamped section rather than overwriting — a second sweep
the same day is usually a before/after around a change, and both are worth
keeping.

Use this structure:

```markdown
# Homelab health — YYYY-MM-DD HH:MM

**Verdict:** <one line — e.g. "All 12 containers healthy" or "1 down, 1 unhealthy">

## Needs attention
- **<container>** — <down/restarting/unhealthy>: <the specific status string>. <short so-what>

## Running (N)
<container> · <image> · up <duration>
... (compact list, one per line)

## Stopped / not running (N)
<container> · <last status>

## Disk
<one or two lines from docker system df — images/containers/volumes reclaimable>
```

If nothing needs attention, keep the "Needs attention" section but write
`- Nothing — all containers healthy.` so the structure is consistent and
greppable across daily files.

After writing, give Michael a two-line spoken-style summary in chat (verdict +
the single most important thing), and the path to the note. Don't paste the full
report back into chat; the file is the artifact.

## Refresh the dashboard

After the report, regenerate the HTML dashboard from the same sweep snapshot.
It is a single self-contained file that gets overwritten each run, showing
color-coded container cards, a summary strip, disk usage, and links to recent
reports:

```bash
python3 "$SKILL_DIR/scripts/render_dashboard.py" \
  --out "/Users/michaelhenry/Obsidian/Homelab/Health/dashboard.html" \
  --host dockerhost-1 --generated "$(date '+%Y-%m-%d %H:%M')" \
  --history-dir "/Users/michaelhenry/Obsidian/Homelab/Health" \
  < /tmp/homelab-sweep.txt
```

Give Michael the dashboard path too. If he wants to look at it, `open` it. The
dashboard is a snapshot, not live; it refreshes only when a sweep runs.

## Scope reminder

Containers only. No Proxmox node checks, no PBS backup checks, no remediation.
Those were intentionally left out to keep this fast and safe. If Michael wants
them later, that's a separate skill or an explicit expansion.
