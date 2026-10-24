#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  mac-migration-old-machine.sh                                           ║
# ║  Run this on your CURRENT Mac before migrating to a new one.            ║
# ║  Exports configs, audits installed software, and preps the dotfiles     ║
# ║  repo for deployment on the new machine.                                ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

DOTFILES="$HOME/.dotfiles"
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────

section() {
  echo ""
  echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${CYAN}  $1${RESET}"
  echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${RESET}"
}

step() {
  echo -e "\n${GREEN}  ▸ $1${RESET}"
}

info() {
  echo -e "    ${DIM}$1${RESET}"
}

warn() {
  echo -e "    ${YELLOW}⚠  $1${RESET}"
}

error() {
  echo -e "    ${RED}✖  $1${RESET}"
}

success() {
  echo -e "    ${GREEN}✔  $1${RESET}"
}

skip() {
  echo -e "    ${DIM}⊘  Skipped: $1${RESET}"
}

confirm() {
  read -p "    → $1 [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]]
}

# ─── Preflight ────────────────────────────────────────────────────────────────

section "Preflight Checks"

if [ ! -d "$DOTFILES" ]; then
  error "Dotfiles directory not found at $DOTFILES"
  echo ""
  echo "  Create it first:"
  echo "    mkdir -p $DOTFILES"
  echo "    cd $DOTFILES && git init"
  exit 1
fi
success "Dotfiles directory exists at $DOTFILES"

if ! command -v brew &>/dev/null; then
  error "Homebrew not installed. Install it first:"
  echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi
success "Homebrew is installed"

if ! command -v git &>/dev/null; then
  error "Git not installed"
  exit 1
fi
success "Git is installed"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Export Homebrew
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 1: Export Homebrew Brewfile"

step "Dumping Brewfile (formulae, casks, taps, mas apps)..."
brew bundle dump --file="$DOTFILES/Brewfile" --force
success "Brewfile exported to $DOTFILES/Brewfile"

FORMULA_COUNT=$(grep -c "^brew " "$DOTFILES/Brewfile" 2>/dev/null || echo 0)
CASK_COUNT=$(grep -c "^cask " "$DOTFILES/Brewfile" 2>/dev/null || echo 0)
MAS_COUNT=$(grep -c "^mas " "$DOTFILES/Brewfile" 2>/dev/null || echo 0)
info "$FORMULA_COUNT formulae, $CASK_COUNT casks, $MAS_COUNT Mac App Store apps"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: Export Package Manager Inventories
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 2: Export Package Manager Inventories"

# npm
step "npm global packages..."
if command -v npm &>/dev/null; then
  npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' | grep -v "^npm$" | grep -v "^corepack$" > "$DOTFILES/npm-globals.txt"
  COUNT=$(wc -l < "$DOTFILES/npm-globals.txt" | tr -d ' ')
  success "Exported $COUNT packages to npm-globals.txt"
else
  skip "npm not installed"
fi

# uv tools
step "Python tools (uv)..."
if command -v uv &>/dev/null; then
  uv tool list 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}' > "$DOTFILES/uv-tools.txt"
  COUNT=$(wc -l < "$DOTFILES/uv-tools.txt" | tr -d ' ')
  success "Exported $COUNT tools to uv-tools.txt"
else
  skip "uv not installed"
fi

# pipx
step "Python tools (pipx)..."
if command -v pipx &>/dev/null; then
  pipx list --short > "$DOTFILES/pipx-tools.txt" 2>/dev/null
  COUNT=$(wc -l < "$DOTFILES/pipx-tools.txt" | tr -d ' ')
  success "Exported $COUNT tools to pipx-tools.txt"
else
  skip "pipx not installed"
fi

# pip
step "pip global packages..."
if command -v pip3 &>/dev/null; then
  pip3 list --format=freeze 2>/dev/null | grep -v "^pip==" | grep -v "^wheel==" | grep -v "^setuptools==" > "$DOTFILES/pip-globals.txt"
  COUNT=$(wc -l < "$DOTFILES/pip-globals.txt" | tr -d ' ')
  success "Exported $COUNT packages to pip-globals.txt"
  warn "Review pip-globals.txt — some may be Homebrew formula dependencies"
else
  skip "pip3 not installed"
fi

# rbenv / gems
step "Ruby (rbenv)..."
if command -v rbenv &>/dev/null; then
  rbenv versions > "$DOTFILES/rbenv-versions.txt" 2>/dev/null
  gem list --no-versions > "$DOTFILES/ruby-gems.txt" 2>/dev/null
  RUBY_VER=$(rbenv global 2>/dev/null || echo "unknown")
  GEM_COUNT=$(wc -l < "$DOTFILES/ruby-gems.txt" | tr -d ' ')
  success "Ruby $RUBY_VER with $GEM_COUNT gems exported"
else
  skip "rbenv not installed"
fi

# cargo / rustup
step "Rust tools (rustup + cargo)..."
if command -v cargo &>/dev/null; then
  cargo install --list 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}' > "$DOTFILES/cargo-tools.txt"
  COUNT=$(wc -l < "$DOTFILES/cargo-tools.txt" | tr -d ' ')
  success "Exported $COUNT tools to cargo-tools.txt"
  if command -v rustup &>/dev/null; then
    RUST_VER=$(rustup show active-toolchain 2>/dev/null | awk '{print $1}')
    info "Active toolchain: $RUST_VER (rustup will install stable on new machine)"
  fi
else
  skip "cargo not installed"
fi

# go
step "Go binaries..."
if command -v go &>/dev/null; then
  GOBIN="$(go env GOPATH 2>/dev/null)/bin"
  if [ -d "$GOBIN" ]; then
    ls "$GOBIN" > "$DOTFILES/go-tools.txt" 2>/dev/null
    COUNT=$(wc -l < "$DOTFILES/go-tools.txt" | tr -d ' ')
    success "Exported $COUNT tools to go-tools.txt"
  else
    skip "No Go binaries found"
  fi
else
  skip "go not installed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Copy Dotfiles Into Repo
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 3: Copy Dotfiles Into Repo"

# The files in $HOME are the live copies. Copy each one into the repo so the
# commit in Phase 8 carries the current version. Git keeps the old ones.
# Claude Code config is never copied here: it holds secrets, and it is managed
# by claude-skills-private and the migrate-ai-config skill instead.
sync_dotfile() {
  local rel="$1"
  local src="$HOME/$rel"
  local dest="$DOTFILES/$rel"
  if [ ! -f "$src" ]; then
    skip "$rel not found"
  elif [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    skip "$rel unchanged"
  else
    mkdir -p "$(dirname "$dest")"
    cp -p "$src" "$dest"
    success "Copied $rel → dotfiles"
  fi
}

DOTFILE_PATHS=(
  .zshrc
  .zprofile
  .gitconfig
  .gitignore
  .pre-commit-config.yaml
  .ssh/config
  .config/ghostty/config
  "Safari Desktop Picture.jpg"
)

step "Dotfiles..."
for rel in "${DOTFILE_PATHS[@]}"; do
  sync_dotfile "$rel"
done

step "Scripts in ~/bin that the repo tracks..."
for f in "$DOTFILES"/bin/*; do
  [ -f "$f" ] || continue
  sync_dotfile "bin/$(basename "$f")"
done

step "Finder Quick Actions..."
for wf in "$DOTFILES/Library/Services/"*.workflow; do
  [ -e "$wf" ] || continue
  live="$HOME/Library/Services/$(basename "$wf")"
  if [ -d "$live" ]; then
    rsync -a --delete "$live/" "$wf/"
    success "Copied $(basename "$wf") → dotfiles"
  else
    skip "$(basename "$wf") not installed on this Mac"
  fi
done

step "Claude Desktop config (backup only, never copied back out)..."
sync_dotfile "Library/Application Support/Claude/claude_desktop_config.json"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Backup Fonts to iCloud Drive
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 4: Backup Fonts to iCloud Drive"

step "Ensuring Homebrew rsync is installed..."
if ! brew list rsync &>/dev/null; then
  brew install rsync
  success "rsync installed"
else
  skip "rsync already installed"
fi

FONTS_SRC="$HOME/Library/Fonts"
FONTS_DEST="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Migration/Fonts"

if [ -d "$FONTS_SRC" ] && [ "$(ls -A "$FONTS_SRC" 2>/dev/null)" ]; then
  FONT_COUNT=$(ls "$FONTS_SRC" | wc -l | tr -d ' ')
  step "Copying $FONT_COUNT fonts to iCloud Drive (this may take a few minutes)..."
  mkdir -p "$FONTS_DEST"
  rsync -a --delete "$FONTS_SRC/" "$FONTS_DEST/"
  success "Fonts backed up to iCloud Drive/Migration/Fonts"
  info "Wait for iCloud to sync before running the new machine script"
else
  skip "No fonts found in ~/Library/Fonts"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Backup Launch Agents
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 5: Backup Launch Agents"

step "Scanning for custom launch agents..."
LAUNCH_DIR="$HOME/Library/LaunchAgents"
LAUNCH_DEST="$DOTFILES/LaunchAgents"
mkdir -p "$LAUNCH_DEST"

CUSTOM_AGENTS=(
  "com.vibelog"
  "com.security-audit"
)

COPIED=0
for prefix in "${CUSTOM_AGENTS[@]}"; do
  for plist in "$LAUNCH_DIR"/${prefix}*.plist; do
    if [ -f "$plist" ]; then
      cp "$plist" "$LAUNCH_DEST/"
      success "Backed up $(basename "$plist")"
      ((COPIED++))
    fi
  done
done

if [ "$COPIED" -eq 0 ]; then
  skip "No custom launch agents found to backup"
else
  info "Backed up $COPIED launch agent(s) to $LAUNCH_DEST/"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: SSH Keys
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 6: SSH Keys"

step "Verifying SSH setup..."
if [ -f "$DOTFILES/.ssh/config" ]; then
  success "SSH config already in dotfiles (copied into place on new machine)"
  info "SSH keys are managed by 1Password SSH Agent — no key files to transfer"
else
  warn "SSH config not found in dotfiles — was it copied in Phase 3?"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 7: Find Untracked Apps
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 7: Find Untracked Apps"

step "Scanning /Applications for apps not in Brewfile or Setapp..."

UNTRACKED=()
BREWFILE="$DOTFILES/Brewfile"

while IFS= read -r app_path; do
  app_name=$(basename "$app_path" .app)

  # Skip Setapp apps
  [[ "$app_path" == */Setapp/* ]] && continue

  # Normalize for cask matching: lowercase, remove spaces/special chars
  normalized=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

  # Check if in Brewfile (cask or mas)
  if ! grep -qi "\"$app_name\"" "$BREWFILE" 2>/dev/null && \
     ! grep -qi "\"$normalized\"" "$BREWFILE" 2>/dev/null; then
    UNTRACKED+=("$app_name")
  fi
done < <(find /Applications -maxdepth 2 -name "*.app" 2>/dev/null; find "$HOME/Applications" -maxdepth 2 -name "*.app" 2>/dev/null)

if [ ${#UNTRACKED[@]} -gt 0 ]; then
  warn "Found ${#UNTRACKED[@]} potentially untracked app(s):"
  for app in "${UNTRACKED[@]}"; do
    echo -e "      ${DIM}- $app${RESET}"
  done

  # Write to file for reference on new machine
  UNTRACKED_FILE="$DOTFILES/untracked-apps.md"
  {
    echo "# Untracked Apps"
    echo ""
    echo "Apps found in /Applications that are not in the Brewfile or Setapp."
    echo "Review and either add to Brewfile or install manually on the new machine."
    echo ""
    echo "Generated: $(date +%Y-%m-%d)"
    echo ""
    for app in "${UNTRACKED[@]}"; do
      echo "- $app"
    done
  } > "$UNTRACKED_FILE"
  success "Saved list to $UNTRACKED_FILE"
  info "Review and add to Brewfile or note for manual install"
else
  success "All apps appear to be tracked in Brewfile or Setapp"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 8: Git Commit
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 8: Commit and Push"

step "Checking for changes..."
cd "$DOTFILES"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo ""
  git status --short
  echo ""
  if confirm "Commit all changes to dotfiles repo?"; then
    git add -A
    git commit -m "Migration export: $(date +%Y-%m-%d)

Exported Brewfile, package inventories, configs, and launch agents
for migration to new machine."
    success "Changes committed"

    if git remote get-url origin &>/dev/null; then
      if confirm "Push to remote?"; then
        git push
        success "Pushed to remote"
      fi
    else
      warn "No remote configured — push manually when ready"
    fi
  fi
else
  success "No changes to commit — dotfiles are up to date"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 9: Pre-Migration Checklist
# ═══════════════════════════════════════════════════════════════════════════════

section "Pre-Migration Checklist"

echo ""
echo -e "  ${BOLD}Before wiping this machine, verify:${RESET}"
echo ""
echo -e "  ${DIM}Automated (done by this script):${RESET}"
echo "    [x] Brewfile exported"
echo "    [x] Package manager inventories saved"
echo "    [x] Dotfiles copied into repo"
echo "    [x] Launch agents backed up"
echo "    [x] Changes committed to git"
echo ""
echo -e "  ${BOLD}Manual steps remaining:${RESET}"
echo "    [ ] 1Password installed on new machine with SSH Agent enabled"
echo "    [ ] Dotfiles repo pushed to remote (if not done above)"
echo "    [ ] Verify new machine is fully set up and working"
echo "    [ ] Obsidian CLI enabled on new machine (Settings → Advanced → CLI)"
echo "        If 'command not found': sudo ln -sf /Applications/Obsidian.app/Contents/MacOS/Obsidian /usr/local/bin/obsidian"
echo ""
echo -e "  ${BOLD}${YELLOW}Decommission (do LAST, after new machine is verified):${RESET}"
echo "    [ ] Deauthorize Find My Mac"
echo "        System Settings → Apple ID → Find My → turn off"
echo "    [ ] Deauthorize Setapp"
echo "        https://my.setapp.com → Account → Devices"
echo "    [ ] Deauthorize Backblaze"
echo "        Transfer license to new machine"
echo "    [ ] Deauthorize iTunes/Music"
echo "        Account → Authorizations → Deauthorize This Computer"
echo "    [ ] Sign out of iCloud"
echo "        System Settings → Apple ID → Sign Out"
echo "    [ ] Erase Mac (if selling/giving away)"
echo "        System Settings → General → Transfer or Reset → Erase All Content and Settings"
echo ""

section "Old Machine Export Complete"
echo ""
echo -e "  ${GREEN}Your dotfiles repo is ready. On the new machine, run:${RESET}"
echo ""
echo "    git clone <your-repo-url> ~/.dotfiles"
echo "    chmod +x ~/.dotfiles/mac-migration-new-machine.sh"
echo "    ~/.dotfiles/mac-migration-new-machine.sh"
echo ""
