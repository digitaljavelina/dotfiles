#!/usr/bin/env bash
# security-audit-posts.sh — Lightweight PII/credential scanner for Obsidian Posts
#
# Usage:
#   ./security-audit-posts.sh              # Scan files modified in last 24h
#   ./security-audit-posts.sh --all        # Scan all .md files
#   ./security-audit-posts.sh --watch      # Watch for changes with fswatch
#   ./security-audit-posts.sh <file.md>    # Scan a specific file
#
# This is the "fast but dumb" complement to the /security-audit Claude Code
# slash command. It uses regex patterns — fast but more false positives.
# Use /security-audit in Claude Code for intelligent, context-aware scanning.

set -euo pipefail

POSTS_DIR="/Users/michaelhenry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Posts"
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/security-audit-posts.log"
REPORT_FILE="$POSTS_DIR/AUDIT-REPORT.txt"

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Pattern Definitions ---
# Each pattern: "CATEGORY|REGEX|DESCRIPTION"
PATTERNS=(
  # Tailscale IPs (100.x.x.x) — almost always real
  'IP|100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|Tailscale IP address'

  # Private IPs that look like real infrastructure (not in code examples)
  'IP|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|Private IP (10.x.x.x)'
  'IP|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|Private IP (172.16-31.x.x)'
  'IP|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|Private IP (192.168.x.x)'

  # API Keys & Tokens
  'CREDENTIAL|sk-[a-zA-Z0-9]{20,}|OpenAI/Stripe secret key'
  'CREDENTIAL|pk-[a-zA-Z0-9]{20,}|Public API key'
  'CREDENTIAL|ghp_[a-zA-Z0-9]{36}|GitHub personal access token'
  'CREDENTIAL|gho_[a-zA-Z0-9]{36}|GitHub OAuth token'
  'CREDENTIAL|ghs_[a-zA-Z0-9]{36}|GitHub server token'
  'CREDENTIAL|AKIA[0-9A-Z]{16}|AWS access key'
  'CREDENTIAL|xox[bpras]-[0-9a-zA-Z-]{10,}|Slack token'
  'CREDENTIAL|Bearer [a-zA-Z0-9_\-\.]{20,}|Bearer token'
  'CREDENTIAL|glpat-[a-zA-Z0-9_\-]{20,}|GitLab personal access token'
  'CREDENTIAL|npm_[a-zA-Z0-9]{36}|npm access token'

  # SSH Keys
  'CREDENTIAL|BEGIN (RSA|EC|OPENSSH|DSA) PRIVATE KEY|SSH private key'
  'CREDENTIAL|BEGIN PGP PRIVATE KEY|PGP private key'

  # Passwords in config
  'CREDENTIAL|password[[:space:]]*[:=][[:space:]]*[^[:space:]]{4,}|Plaintext password'
  'CREDENTIAL|passwd[[:space:]]*[:=][[:space:]]*[^[:space:]]{4,}|Plaintext password'
  'CREDENTIAL|secret[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}|Secret value'

  # Internal hostnames
  'HOSTNAME|[a-zA-Z0-9_-]+\.(local|internal|lan|home|localdomain)\b|Internal hostname'

  # Email addresses (filtering of example.com done by safe patterns)
  'PII|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|Email address'

  # URLs with tokens/keys in query params
  'URL|https?://[^[:space:]]*[?&](token|key|api_key|apikey|secret|password|access_token)=[^[:space:]&"'"'"']+|URL with embedded credential'

  # Webhook URLs (Discord, Slack, etc.)
  'URL|https://discord(app)?\.com/api/webhooks/[0-9]+/[a-zA-Z0-9_-]+|Discord webhook URL'
  'URL|https://hooks\.slack\.com/[^[:space:]]+|Slack webhook URL'

  # Database connection strings
  'CREDENTIAL|(mongodb|postgres|mysql|redis)://[^[:space:]]+@[^[:space:]]+|Database connection string'

  # MAC addresses
  'PII|([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}|MAC address'
)

# Patterns to SKIP (safe documentation values)
SAFE_PATTERNS=(
  '203\.0\.113\.'       # RFC 5737 documentation
  '198\.51\.100\.'      # RFC 5737 documentation
  '192\.0\.2\.'         # RFC 5737 documentation
  'example\.(com|org|net)'
  'user@example'
  'YOUR_.*_HERE'
  'your_secure_'        # Common tutorial placeholder
  'yourusername'        # Common tutorial placeholder
  'yourpassword'        # Common tutorial placeholder
  'youruser'            # Common tutorial placeholder
  'AKIAIOSFODNN7EXAMPLE' # AWS example key
  'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' # AWS example secret
  'git@github\.com'     # Standard Git SSH URL, not an email
  'git@gitlab\.com'     # Standard Git SSH URL
  '100\.100\.100\.100'  # Tailscale's public DNS resolver (not sensitive)
)

# --- Functions ---

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(timestamp)] $1" >> "$LOG_FILE"
}

is_safe_match() {
  local match="$1"
  for safe in "${SAFE_PATTERNS[@]}"; do
    if echo "$match" | grep -qE "$safe"; then
      return 0  # It's safe, skip it
    fi
  done
  return 1  # Not safe, flag it
}

scan_file() {
  local filepath="$1"
  local filename
  filename=$(basename "$filepath")
  local findings=0
  local file_output=""

  for pattern_def in "${PATTERNS[@]}"; do
    IFS='|' read -r category regex description <<< "$pattern_def"

    # Use grep with extended regex, get line numbers
    while IFS=: read -r line_num match_line; do
      # Check if this match is in the safe list
      if is_safe_match "$match_line"; then
        continue
      fi

      findings=$((findings + 1))
      file_output+="$(printf "  %-12s Line %-4s %-35s %s\n" "[$category]" "$line_num" "$description" "($(echo "$match_line" | head -c 60)...)")\n"

    done < <(grep -nE "$regex" "$filepath" 2>/dev/null || true)
  done

  if [[ $findings -gt 0 ]]; then
    echo -e "${RED}${BOLD}$filename${NC} — ${RED}$findings finding(s)${NC}"
    echo -e "$file_output"
    return 1
  else
    echo -e "${GREEN}$filename${NC} — clean"
    return 0
  fi
}

scan_files() {
  local files=("$@")
  local total_files=${#files[@]}
  local dirty_files=0
  local total_findings=0
  local report_content=""

  echo -e "\n${BOLD}${CYAN}Security Audit — $(timestamp)${NC}"
  echo -e "${CYAN}Scanning $total_files file(s)...${NC}\n"

  for filepath in "${files[@]}"; do
    output=$(scan_file "$filepath" 2>&1) || dirty_files=$((dirty_files + 1))
    echo -e "$output"
    report_content+="$output\n\n"
  done

  echo -e "\n${BOLD}─────────────────────────────────────${NC}"
  if [[ $dirty_files -gt 0 ]]; then
    echo -e "${RED}${BOLD}$dirty_files of $total_files file(s) have findings${NC}"
    echo -e "${YELLOW}Run /security-audit in Claude Code for intelligent scanning + auto-fix${NC}"
  else
    echo -e "${GREEN}${BOLD}All $total_files file(s) clean${NC}"
  fi
  echo -e "${BOLD}─────────────────────────────────────${NC}\n"

  # Write report
  {
    echo "Security Audit Report — $(timestamp)"
    echo "Files scanned: $total_files"
    echo "Files with findings: $dirty_files"
    echo ""
    echo -e "$report_content"
  } > "$REPORT_FILE"

  log "Scanned $total_files files, $dirty_files with findings"
}

get_recent_files() {
  local hours="${1:-24}"
  local minutes=$((hours * 60))
  find "$POSTS_DIR" -name "*.md" \
    -not -name "AUDIT-SUMMARY*.md" \
    -not -name "AUDIT-REPORT.txt" \
    -mmin "-$minutes" \
    -type f 2>/dev/null
}

get_all_files() {
  find "$POSTS_DIR" -name "*.md" \
    -not -name "AUDIT-SUMMARY*.md" \
    -not -name "AUDIT-REPORT.txt" \
    -type f 2>/dev/null
}

resolve_fswatch() {
  # launchd runs with minimal PATH — resolve fswatch explicitly
  local bin
  bin="$(command -v fswatch 2>/dev/null || true)"
  if [[ -z "$bin" ]]; then
    if [[ -x /opt/homebrew/bin/fswatch ]]; then
      bin="/opt/homebrew/bin/fswatch"
    elif [[ -x /usr/local/bin/fswatch ]]; then
      bin="/usr/local/bin/fswatch"
    fi
  fi
  if [[ -z "$bin" ]]; then
    echo -e "${RED}fswatch not found. Install with: brew install fswatch${NC}"
    exit 1
  fi
  echo "$bin"
}

watch_mode() {
  echo -e "${BOLD}${CYAN}Watching Posts directory for changes...${NC}"
  echo -e "${CYAN}Press Ctrl+C to stop${NC}\n"

  local FSWATCH_BIN
  FSWATCH_BIN="$(resolve_fswatch)"
  echo -e "${CYAN}Using fswatch: $FSWATCH_BIN${NC}"

  log "Started watch mode (fswatch: $FSWATCH_BIN)"

  "$FSWATCH_BIN" -0 --include='\.md$' --exclude='.*' "$POSTS_DIR" | while IFS= read -r -d '' filepath; do
    # Skip audit files
    local fname
    fname=$(basename "$filepath")
    if [[ "$fname" == AUDIT-SUMMARY*.md || "$fname" == "AUDIT-REPORT.txt" ]]; then
      continue
    fi

    echo -e "\n${YELLOW}File changed: $fname${NC}"
    if ! scan_file "$filepath"; then
      # Findings detected — send macOS notification
      osascript -e "display notification \"Sensitive data found in $fname\" with title \"Security Audit\" sound name \"Basso\"" 2>/dev/null || true
    fi
  done
}

show_help() {
  cat << 'EOF'
Security Audit for Obsidian Posts
─────────────────────────────────
Usage:
  security-audit-posts.sh              Scan files modified in last 24 hours
  security-audit-posts.sh --all        Scan all .md files
  security-audit-posts.sh --hours N    Scan files modified in last N hours
  security-audit-posts.sh --watch      Watch for changes (requires fswatch)
  security-audit-posts.sh <file.md>    Scan a specific file
  security-audit-posts.sh --help       Show this help

For intelligent, context-aware scanning with auto-fix:
  Run /security-audit in Claude Code
EOF
}

# --- Main ---

mkdir -p "$LOG_DIR"

case "${1:-}" in
  --help|-h)
    show_help
    ;;
  --watch|-w)
    watch_mode
    ;;
  --all|-a)
    files=()
    while IFS= read -r f; do files+=("$f"); done < <(get_all_files)
    if [[ ${#files[@]} -eq 0 ]]; then
      echo -e "${YELLOW}No .md files found in Posts directory${NC}"
      exit 0
    fi
    scan_files "${files[@]}"
    ;;
  --hours)
    hours="${2:-24}"
    files=()
    while IFS= read -r f; do files+=("$f"); done < <(get_recent_files "$hours")
    if [[ ${#files[@]} -eq 0 ]]; then
      echo -e "${YELLOW}No .md files modified in the last ${hours} hours${NC}"
      exit 0
    fi
    scan_files "${files[@]}"
    ;;
  "")
    files=()
    while IFS= read -r f; do files+=("$f"); done < <(get_recent_files 24)
    if [[ ${#files[@]} -eq 0 ]]; then
      echo -e "${YELLOW}No .md files modified in the last 24 hours${NC}"
      exit 0
    fi
    scan_files "${files[@]}"
    ;;
  *)
    if [[ -f "$1" ]]; then
      scan_files "$1"
    else
      echo -e "${RED}File not found: $1${NC}"
      exit 1
    fi
    ;;
esac
