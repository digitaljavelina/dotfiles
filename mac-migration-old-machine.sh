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

# cargo
step "Rust tools (cargo)..."
if command -v cargo &>/dev/null; then
  cargo install --list 2>/dev/null | grep -E "^[a-z]" | awk '{print $1}' > "$DOTFILES/cargo-tools.txt"
  COUNT=$(wc -l < "$DOTFILES/cargo-tools.txt" | tr -d ' ')
  success "Exported $COUNT tools to cargo-tools.txt"
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
# PHASE 3: Move Dotfiles Into Repo
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 3: Move Dotfiles Into Repo"

move_dotfile() {
  local src="$1"
  local dest="$2"
  if [ -e "$src" ] && [ ! -L "$src" ]; then
    # File exists and is NOT already a symlink (not already stowed)
    if [ -e "$dest" ]; then
      warn "$dest already exists in dotfiles — skipping (won't overwrite)"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      success "Copied $(basename "$src") → dotfiles"
    fi
  elif [ -L "$src" ]; then
    skip "$(basename "$src") is already a symlink (likely already stowed)"
  else
    skip "$(basename "$src") does not exist"
  fi
}

step "Shell config files..."
move_dotfile "$HOME/.zshrc" "$DOTFILES/.zshrc"
move_dotfile "$HOME/.zprofile" "$DOTFILES/.zprofile"

step "Git config..."
move_dotfile "$HOME/.gitconfig" "$DOTFILES/.gitconfig"

step "SSH config (host aliases + 1Password agent socket)..."
SSH_CONFIG="$HOME/.ssh/config"
SSH_DEST="$DOTFILES/.ssh/config"
if [ -f "$SSH_CONFIG" ]; then
  if [ ! -e "$SSH_DEST" ]; then
    mkdir -p "$DOTFILES/.ssh"
    cp "$SSH_CONFIG" "$SSH_DEST"
    success "Copied .ssh/config → dotfiles"
  elif [ -L "$SSH_CONFIG" ]; then
    skip ".ssh/config is already a symlink (likely already stowed)"
  else
    skip ".ssh/config already in dotfiles"
  fi
else
  skip ".ssh/config not found"
fi

step "Ghostty config..."
GHOSTTY_SRC="$HOME/.config/ghostty/config"
GHOSTTY_DEST="$DOTFILES/.config/ghostty/config"
if [ -L "$GHOSTTY_SRC" ]; then
  # Resolve the symlink to get the actual file
  GHOSTTY_REAL=$(readlink "$GHOSTTY_SRC" 2>/dev/null || readlink -f "$GHOSTTY_SRC" 2>/dev/null)
  if [ -f "$GHOSTTY_REAL" ] && [ ! -e "$GHOSTTY_DEST" ]; then
    mkdir -p "$(dirname "$GHOSTTY_DEST")"
    cp "$GHOSTTY_REAL" "$GHOSTTY_DEST"
    success "Copied ghostty config (resolved from symlink at $GHOSTTY_REAL)"
  elif [ -e "$GHOSTTY_DEST" ]; then
    skip "Ghostty config already in dotfiles"
  fi
elif [ -f "$GHOSTTY_SRC" ]; then
  move_dotfile "$GHOSTTY_SRC" "$GHOSTTY_DEST"
else
  skip "Ghostty config not found"
fi

step "Claude Code config..."
CLAUDE_DEST="$DOTFILES/claude/.claude"
if [ ! -d "$CLAUDE_DEST" ]; then
  mkdir -p "$CLAUDE_DEST"
  for item in settings.json commands skills agents hooks; do
    if [ -e "$HOME/.claude/$item" ]; then
      cp -R "$HOME/.claude/$item" "$CLAUDE_DEST/$item"
      success "Copied .claude/$item"
    fi
  done
else
  skip "Claude Code config already in dotfiles"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Backup Launch Agents
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 4: Backup Launch Agents"

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
# PHASE 5: SSH Keys
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 5: SSH Keys"

step "Verifying SSH setup..."
if [ -f "$DOTFILES/.ssh/config" ]; then
  success "SSH config already in dotfiles (will be stowed on new machine)"
  info "SSH keys are managed by 1Password SSH Agent — no key files to transfer"
else
  warn "SSH config not found in dotfiles — was it copied in Phase 3?"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Create Stow Ignore Files
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 6: Stow Configuration"

step "Creating .stow-local-ignore (root)..."
STOW_IGNORE="$DOTFILES/.stow-local-ignore"
if [ ! -f "$STOW_IGNORE" ]; then
  cat > "$STOW_IGNORE" << 'EOF'
\.DS_Store
.git
.env
^data$

# GSD plugin - auto-managed, reinstalled via /gsd:update
claude/\.claude/get-shit-done
claude/\.claude/gsd-file-manifest.json
claude/\.claude/package.json
claude/\.claude/agents/gsd-.*
claude/\.claude/commands/gsd
claude/\.claude/hooks/gsd-.*

# Non-config files (referenced by path, not symlinked)
Brewfile
npm-globals\.txt
uv-tools\.txt
pipx-tools\.txt
pip-globals\.txt
rbenv-versions\.txt
ruby-gems\.txt
cargo-tools\.txt
go-tools\.txt
mac-settings\.sh
setapp-migrate\.sh
setup\.sh
find_untracked_apps\.sh
mac-migration-old-machine\.sh
mac-migration-new-machine\.sh
LaunchAgents
scripts
LICENSE
README.*
Makefile
\.stow-local-ignore
EOF
  success "Created root .stow-local-ignore"
else
  skip ".stow-local-ignore already exists"
fi

step "Creating per-package ignore for claude..."
CLAUDE_IGNORE="$DOTFILES/claude/.stow-local-ignore"
if [ ! -f "$CLAUDE_IGNORE" ]; then
  cat > "$CLAUDE_IGNORE" << 'EOF'
\.DS_Store
EOF
  success "Created claude/.stow-local-ignore"
else
  skip "claude/.stow-local-ignore already exists"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 7: Stow Everything
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 7: Stow Dotfiles"

step "Running stow..."
cd "$DOTFILES"

# Stow named packages (directories with nested structure)
for pkg in */; do
  pkg="${pkg%/}"
  if [ -d "$pkg" ] && [ "$pkg" != "LaunchAgents" ] && [ "$pkg" != "scripts" ] && [ "$pkg" != "data" ]; then
    stow --no-folding "$pkg" 2>/dev/null && success "Stowed package: $pkg" || warn "Package $pkg had conflicts (may already be stowed)"
  fi
done

# Stow loose dotfiles (single-package mode)
stow . --no-folding 2>/dev/null && success "Stowed root dotfiles" || warn "Root dotfiles had conflicts (may already be stowed)"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 8: Find Untracked Apps
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 8: Find Untracked Apps"

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
  info "Review these and add to Brewfile or note for manual install"
else
  success "All apps appear to be tracked in Brewfile or Setapp"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 9: Git Commit
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 9: Commit and Push"

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
# PHASE 10: Pre-Migration Checklist
# ═══════════════════════════════════════════════════════════════════════════════

section "Pre-Migration Checklist"

echo ""
echo -e "  ${BOLD}Before wiping this machine, verify:${RESET}"
echo ""
echo -e "  ${DIM}Automated (done by this script):${RESET}"
echo "    [x] Brewfile exported"
echo "    [x] Package manager inventories saved"
echo "    [x] Dotfiles moved and stowed"
echo "    [x] Launch agents backed up"
echo "    [x] Changes committed to git"
echo ""
echo -e "  ${BOLD}Manual steps remaining:${RESET}"
echo "    [ ] 1Password installed on new machine with SSH Agent enabled"
echo "    [ ] Dotfiles repo pushed to remote (if not done above)"
echo "    [ ] Verify new machine is fully set up and working"
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
