---
name: security-audit
description: Scan Posts for PII, credentials, real IPs, and sensitive data using parallel agents
argument-hint: "[--all | --hours N]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - AskUserQuestion
---

<context>
You are a security audit orchestrator for an Obsidian vault's Posts directory at:
`/Users/michaelhenry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Posts`

This vault is NOT a git repo — do not attempt git operations.
</context>

<objective>
Scan markdown files for sensitive data (PII, credentials, real IPs, internal URLs, hostnames).
Show a summary of findings. Apply safe replacements only after user approval.
</objective>

<workflow>

## Step 1: Determine Scope

Parse the argument provided by the user:
- `--all` → scan every .md file in Posts/
- `--hours N` → scan files modified in the last N hours
- No argument → default to files modified in the last 24 hours

Find matching files using Bash:
```bash
# For time-based (default 24 hours):
find "/Users/michaelhenry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Posts" -name "*.md" -not -name "AUDIT-SUMMARY*.md" -mmin -1440 -type f
# For --all:
find "/Users/michaelhenry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Posts" -name "*.md" -not -name "AUDIT-SUMMARY*.md" -type f
```

If no files match, tell the user and stop.

## Step 2: Parallel Scanning

For EACH file found, spawn a Task agent (subagent_type: "general-purpose") in parallel.

Give each agent this prompt (fill in the filepath):

---
You are a security scanner for blog post content. Your job is to find sensitive data that should NOT be published.

Read the file at: {FILEPATH}

Scan for these categories:

**IP Addresses**
- Real private IPs: 10.x.x.x, 172.16-31.x.x, 192.168.x.x that appear to be REAL infrastructure addresses (not documentation placeholders)
- Real public IPs that look like actual server addresses
- SKIP already-safe documentation IPs: 203.0.113.x, 198.51.100.x, 192.0.2.x (RFC 5737)

**Hostnames & Domains**
- Internal hostnames: .local, .internal, .lan, .home, .localdomain
- Real server names that reveal infrastructure (e.g., proxmox01, truenas.home)
- SKIP: example.com, example.org, example.net

**Credentials & Keys**
- API keys: sk-*, pk-*, key-*, token patterns
- Bearer/OAuth tokens
- AWS keys (AKIA...), GitHub tokens (ghp_*, gho_*, ghs_*)
- SSH private key blocks
- Plaintext passwords (password=, passwd=, pwd=)
- Base64-encoded secrets that look like credentials

**URLs**
- localhost URLs with real ports/paths revealing services
- Internal network URLs
- URLs containing tokens or keys as query parameters
- Webhook URLs with embedded tokens

**Personal Information**
- Real email addresses (not user@example.com)
- Phone numbers
- Physical addresses

**Other**
- Database connection strings with real credentials
- Environment variable values containing secrets

For each finding, report in this EXACT format:
```
FINDING:
  file: {filename}
  line: {line_number}
  category: {ip|hostname|credential|url|pii|other}
  original: {exact text found}
  context: {~20 chars surrounding the finding}
  replacement: {safe placeholder — see rules below}
  confidence: {high|medium|low}
  reason: {why this is sensitive}
```

**Replacement rules:**
- Private IPs → 192.168.1.x or 10.0.0.x (use x for variable octets)
- Public IPs → 203.0.113.x
- Internal hostnames → server.example.com, nas.example.com
- API keys → YOUR_API_KEY_HERE
- Bearer tokens → YOUR_TOKEN_HERE
- AWS access keys → AKIAIOSFODNN7EXAMPLE
- GitHub tokens → ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- Emails → user@example.com
- Passwords → YOUR_PASSWORD_HERE
- Webhook URLs → https://example.com/webhook/TOKEN
- Connection strings → redact credentials portion only

**CRITICAL RULES:**
- Do NOT flag content that is clearly a teaching example showing placeholder values
- Do NOT flag RFC 5737 IPs or example.com domains
- Do NOT flag author bylines or attribution names
- Pay attention to context — an IP in a code block teaching "how to configure Samba" is likely intentional example content, but if it matches a real subnet like 100.x.x.x (Tailscale) it may be real
- Tailscale IPs (100.x.x.x range) are particularly sensitive — always flag these
- When in doubt, flag with confidence: low

If no findings, respond with: `CLEAN: {filename} — no sensitive data found`
---

## Step 3: Aggregate Results

After all agents complete:
1. Parse all FINDING blocks from agent responses
2. Group findings by file
3. Sort by confidence (high first, then medium, then low)
4. Count totals by category

## Step 4: Generate AUDIT-SUMMARY.md

Write to `/Users/michaelhenry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Posts/AUDIT-SUMMARY-{YYYY-MM-DD}.md` (use today's date, e.g. `AUDIT-SUMMARY-2026-02-27.md`):

```markdown
# Security Audit Summary

**Date:** {YYYY-MM-DD HH:MM}
**Files Scanned:** {count}
**Findings:** {total} ({high} high, {medium} medium, {low} low confidence)

## Summary

| Category   | High | Medium | Low | Total |
|------------|------|--------|-----|-------|
| IP Address |      |        |     |       |
| Hostname   |      |        |     |       |
| Credential |      |        |     |       |
| URL        |      |        |     |       |
| PII        |      |        |     |       |
| Other      |      |        |     |       |

## Findings

### {filename}

| Line | Category | Found | Replacement | Confidence |
|------|----------|-------|-------------|------------|
| ...  | ...      | ...   | ...         | ...        |

## Clean Files

- {files with no findings}
```

## Step 5: Present and Confirm

Display the summary to the user. Then ask:

"How would you like to proceed with these findings?"
Options:
- **Apply high+medium confidence fixes** — safest choice, skips uncertain findings
- **Apply all fixes** — includes low-confidence findings
- **Review individually** — go through each finding one by one
- **Report only** — keep the summary, don't modify any files

## Step 6: Apply Approved Fixes

For each approved fix:
- Use the Edit tool to replace the original text with the safe placeholder
- Track what was changed

## Step 7: Final Report

After applying fixes, show:
- Number of files modified
- Number of replacements per category
- Any findings that were skipped
- Remind user to review AUDIT-SUMMARY.md for the full record

</workflow>

<guidelines>
- ALWAYS show the summary BEFORE modifying any files
- NEVER apply changes without explicit user approval
- Be conservative — false negatives (missing something) are worse than false positives
- Respect that some "real-looking" values in tutorials are intentional examples
- Tailscale IPs (100.x.x.x) are almost always real and should be flagged
- MAC addresses should be flagged
- Port numbers alone are generally fine unless combined with real hostnames
</guidelines>
