#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  mac-migration-new-machine.sh                                           ║
# ║  Run this on your NEW Mac after cloning the dotfiles repo.              ║
# ║  Installs everything, restores configs, applies preferences.            ║
# ║                                                                         ║
# ║  Prerequisites:                                                         ║
# ║    1. Sign into iCloud (for Mac App Store installs via mas)             ║
# ║    2. Sign into the App Store app                                       ║
# ║    3. Clone dotfiles: git clone <url> ~/.dotfiles                       ║
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
  read -p "    → $1 [Y/n] " response
  [[ ! "$response" =~ ^[Nn]$ ]]
}

pause() {
  echo ""
  read -p "    → Press Enter to continue..." _
}

# ─── Preflight ────────────────────────────────────────────────────────────────

section "Preflight Checks"

if [ ! -d "$DOTFILES" ]; then
  error "Dotfiles directory not found at $DOTFILES"
  echo ""
  echo "  Clone it first:"
  echo "    git clone <your-repo-url> $DOTFILES"
  exit 1
fi
success "Dotfiles directory exists at $DOTFILES"

# Check macOS version
SW_VER=$(sw_vers -productVersion)
success "macOS $SW_VER detected"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: Xcode Command Line Tools
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 1: Xcode Command Line Tools"

step "Checking for Xcode CLT..."
if xcode-select -p &>/dev/null; then
  success "Xcode Command Line Tools already installed"
else
  step "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo ""
  warn "A dialog should appear. Click 'Install' and wait for it to finish."
  read -p "    → Press Enter once the installation is complete..." _
  success "Xcode Command Line Tools installed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: Homebrew
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 2: Homebrew"

step "Checking for Homebrew..."
if command -v brew &>/dev/null; then
  success "Homebrew already installed"
else
  step "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    success "Homebrew installed (Apple Silicon)"
  elif [ -f "/usr/local/bin/brew" ]; then
    success "Homebrew installed (Intel)"
  fi
fi

step "Installing Stow..."
brew install stow 2>/dev/null || true
success "Stow ready"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: Oh My Zsh
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 3: Oh My Zsh"

step "Checking for Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
  success "Oh My Zsh already installed"
else
  step "Installing Oh My Zsh..."
  # RUNZSH=no prevents it from launching a new shell
  RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "Oh My Zsh installed"
fi

# Back up the default .zshrc Oh My Zsh created (ours will replace it)
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$HOME/.zshrc.ohmyzsh-default"
  info "Backed up Oh My Zsh default .zshrc to .zshrc.ohmyzsh-default"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: Stow Dotfiles
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 4: Stow Dotfiles"

step "Stowing named packages..."
cd "$DOTFILES"

# Claude Code needs special handling — create the directory first
if [ -d "$DOTFILES/claude" ]; then
  step "Setting up Claude Code config..."
  if command -v claude &>/dev/null; then
    info "Claude Code already installed"
  else
    info "Claude Code not yet installed — will install in Phase 6"
    info "Creating ~/.claude/ directory structure..."
    mkdir -p "$HOME/.claude"
  fi

  # Use --adopt to handle any existing default files, then restore ours
  # IMPORTANT: git checkout reverts ALL tracked files including .stow-local-ignore,
  # so we preserve it first and restore after checkout
  cp .stow-local-ignore .stow-local-ignore.bak 2>/dev/null || true
  stow --no-folding --adopt claude 2>/dev/null || true
  git checkout -- . 2>/dev/null || true
  cp .stow-local-ignore.bak .stow-local-ignore 2>/dev/null && rm .stow-local-ignore.bak 2>/dev/null || true
  stow --no-folding claude 2>/dev/null || true
  success "Stowed claude package"
fi

# Stow any other named packages
for pkg in */; do
  pkg="${pkg%/}"
  [ "$pkg" = "claude" ] && continue
  [ "$pkg" = "LaunchAgents" ] && continue
  [ "$pkg" = "scripts" ] && continue
  [ "$pkg" = "data" ] && continue
  if [ -d "$pkg" ]; then
    stow --no-folding "$pkg" 2>/dev/null && success "Stowed package: $pkg" || warn "Package $pkg had conflicts"
  fi
done

step "Stowing root dotfiles..."
# On a fresh Mac, .zprofile exists (Homebrew installer creates it) and .zshrc
# may exist from Oh My Zsh. Use --adopt to pull these into the repo, then
# git checkout to restore our versions over the adopted defaults.
cp .stow-local-ignore .stow-local-ignore.bak 2>/dev/null || true
stow . --no-folding --adopt 2>/dev/null || true
git checkout -- . 2>/dev/null || true
cp .stow-local-ignore.bak .stow-local-ignore 2>/dev/null && rm .stow-local-ignore.bak 2>/dev/null || true
stow . --no-folding 2>/dev/null && success "Stowed root dotfiles" || warn "Root dotfiles had conflicts (check manually)"


step "Verifying symlinks..."
VERIFY_FILES=(".zshrc" ".zprofile" ".gitconfig" ".config/ghostty/config")
for f in "${VERIFY_FILES[@]}"; do
  if [ -L "$HOME/$f" ]; then
    success "$f → $(readlink "$HOME/$f")"
  elif [ -f "$HOME/$f" ]; then
    warn "$f exists but is NOT a symlink"
  else
    info "$f not present (may not be needed)"
  fi
done

if [ -L "$HOME/.claude/settings.json" ]; then
  success ".claude/settings.json → $(readlink "$HOME/.claude/settings.json")"
else
  warn ".claude/settings.json is not a symlink"
fi

step "Verifying Claude Code skills..."
SKILLS_DIR="$HOME/.claude/skills"
SKILLS_REPO="$DOTFILES/claude/.claude/skills"
if [ -d "$SKILLS_REPO" ]; then
  SKILL_COUNT=0
  SKILL_OK=0
  for skill_dir in "$SKILLS_REPO"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    ((SKILL_COUNT++))
    skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
    if [ -L "$skill_file" ]; then
      ((SKILL_OK++))
    else
      warn "Skill '$skill_name' not symlinked"
    fi
  done
  if [ "$SKILL_COUNT" -gt 0 ]; then
    success "$SKILL_OK/$SKILL_COUNT custom skills restored via stow"
  else
    info "No custom skills in dotfiles repo"
  fi
else
  info "No skills directory in dotfiles"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: Restore Fonts from iCloud Drive
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 5: Restore Fonts from iCloud Drive"

step "Ensuring Homebrew rsync is installed..."
if ! brew list rsync &>/dev/null; then
  brew install rsync
  success "rsync installed"
else
  skip "rsync already installed"
fi

FONTS_SRC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Migration/Fonts"
FONTS_DEST="$HOME/Library/Fonts"

if [ -d "$FONTS_SRC" ] && [ "$(ls -A "$FONTS_SRC" 2>/dev/null)" ]; then
  FONT_COUNT=$(ls "$FONTS_SRC" | wc -l | tr -d ' ')
  step "Restoring $FONT_COUNT fonts from iCloud Drive..."
  mkdir -p "$FONTS_DEST"
  rsync -a "$FONTS_SRC/" "$FONTS_DEST/"
  success "Fonts restored to ~/Library/Fonts"
else
  warn "No fonts found at iCloud Drive/Migration/Fonts"
  info "If you haven't run the old machine script yet, fonts will be missing"
  info "You can restore manually later: rsync -a \"$FONTS_SRC/\" \"$FONTS_DEST/\""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: Install Apps via Brewfile
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 6: Install Apps via Brewfile"

step "Installing Rosetta 2 (required for Intel-based casks)..."
if /usr/bin/pgrep oahd &>/dev/null; then
  skip "Rosetta 2 already installed"
else
  sudo softwareupdate --install-rosetta --agree-to-license
  success "Rosetta 2 installed"
fi

step "Installing from Brewfile..."
info "This may take a while — formulae, casks, fonts, and Mac App Store apps"

if [ -f "$DOTFILES/Brewfile" ]; then
  brew bundle install --file="$DOTFILES/Brewfile" 2>&1 | while IFS= read -r line; do
    echo -e "    ${DIM}$line${RESET}"
  done || true
  success "Brewfile installation complete (check output above for any failures)"
else
  error "No Brewfile found at $DOTFILES/Brewfile"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 7: Install Dev Tools & Package Managers
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 7: Dev Tools & Package Managers"

# Claude Code
step "Claude Code..."
if command -v claude &>/dev/null; then
  success "Claude Code already installed"
else
  if command -v npm &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
    success "Claude Code installed"
    info "Run 'claude' to sign in after this script completes"
  else
    warn "npm not available — install Node.js first, then: npm install -g @anthropic-ai/claude-code"
  fi
fi

# npm global packages
step "npm global packages..."
if [ -f "$DOTFILES/npm-globals.txt" ] && command -v npm &>/dev/null; then
  COUNT=$(wc -l < "$DOTFILES/npm-globals.txt" | tr -d ' ')
  info "Installing $COUNT packages..."
  xargs npm install -g < "$DOTFILES/npm-globals.txt" 2>&1 | tail -1
  success "npm global packages installed"
else
  skip "No npm-globals.txt or npm not available"
fi

# uv tools
step "Python tools (uv)..."
if [ -f "$DOTFILES/uv-tools.txt" ] && command -v uv &>/dev/null; then
  while IFS= read -r tool; do
    [ -z "$tool" ] && continue
    uv tool install "$tool" 2>/dev/null && info "Installed $tool" || warn "Failed to install $tool"
  done < "$DOTFILES/uv-tools.txt"
  success "uv tools installed"
else
  skip "No uv-tools.txt or uv not available"
fi

# pipx tools
step "Python tools (pipx)..."
if [ -f "$DOTFILES/pipx-tools.txt" ] && command -v pipx &>/dev/null; then
  while IFS= read -r line; do
    tool=$(echo "$line" | awk '{print $1}')
    [ -z "$tool" ] && continue
    pipx install "$tool" 2>/dev/null && info "Installed $tool" || warn "Failed to install $tool"
  done < "$DOTFILES/pipx-tools.txt"
  success "pipx tools installed"
else
  skip "No pipx-tools.txt or pipx not available"
fi

# pip packages
step "pip global packages..."
if [ -f "$DOTFILES/pip-globals.txt" ] && command -v pip3 &>/dev/null; then
  if confirm "Install pip global packages? (review $DOTFILES/pip-globals.txt first)"; then
    pip3 install --user -r "$DOTFILES/pip-globals.txt" 2>/dev/null || {
      warn "pip3 install failed (PEP 668 — Homebrew Python blocks global installs)"
      info "Consider moving these packages to uv-tools.txt instead"
    }
    success "pip packages step complete"
  else
    skip "pip packages — install manually later"
  fi
else
  skip "No pip-globals.txt or pip3 not available"
fi

# Ruby via rbenv
step "Ruby (rbenv)..."
if command -v rbenv &>/dev/null; then
  if [ -f "$DOTFILES/rbenv-versions.txt" ]; then
    # Extract the global version (line with * prefix)
    RUBY_VER=$(grep '^\*' "$DOTFILES/rbenv-versions.txt" 2>/dev/null | awk '{print $2}' || true)
    if [ -n "$RUBY_VER" ] && [ "$RUBY_VER" != "system" ]; then
      info "Installing Ruby $RUBY_VER (this takes a few minutes)..."
      rbenv install -s "$RUBY_VER"
      rbenv global "$RUBY_VER"
      success "Ruby $RUBY_VER installed and set as global"

      if confirm "Install gems? (github-pages covers most Jekyll gems)"; then
        gem install github-pages 2>/dev/null || {
          warn "gem install github-pages failed — install manually later"
        }
        success "github-pages gem step complete"
      fi
    else
      skip "No Ruby version to install (system Ruby only)"
    fi
  fi
else
  skip "rbenv not installed"
fi

# Rust via rustup + cargo packages
step "Rust (rustup + cargo)..."
if command -v rustup &>/dev/null; then
  success "rustup already installed"
else
  step "Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tail -3
  source "$HOME/.cargo/env" 2>/dev/null || true
  success "rustup installed (stable toolchain)"
fi

if [ -f "$DOTFILES/cargo-tools.txt" ] && command -v cargo &>/dev/null; then
  COUNT=$(wc -l < "$DOTFILES/cargo-tools.txt" | tr -d ' ')
  if [ "$COUNT" -gt 0 ]; then
    if confirm "Install $COUNT cargo packages? (compiles from source — may take a while)"; then
      while IFS= read -r tool; do
        [ -z "$tool" ] && continue
        cargo install "$tool" 2>/dev/null && info "Installed $tool" || warn "Failed to install $tool"
      done < "$DOTFILES/cargo-tools.txt"
      success "Cargo tools installed"
    else
      skip "Cargo tools — install manually later: while read tool; do cargo install \"\$tool\"; done < ~/.dotfiles/cargo-tools.txt"
    fi
  else
    skip "cargo-tools.txt is empty"
  fi
else
  skip "No cargo-tools.txt or cargo not available"
fi

# Fabric
step "Fabric AI framework..."
if command -v go &>/dev/null; then
  if ! command -v fabric &>/dev/null; then
    go install github.com/danielmiessler/fabric@latest
    success "Fabric installed"
    info "Run 'fabric --setup' to configure API keys"
  else
    success "Fabric already installed"
  fi
else
  skip "Go not installed — install Go first if you need Fabric"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 8: macOS System Preferences
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 8: macOS System Preferences"

step "Applying defaults..."

# ── Dock ──────────────────────────────────────────────────────────────────────

info "Dock..."
defaults write com.apple.dock "orientation" -string "bottom"
defaults write com.apple.dock "tilesize" -int 36
defaults write com.apple.dock "autohide" -bool true
defaults write com.apple.dock "autohide-delay" -float 0
defaults write com.apple.dock "autohide-time-modifier" -float 0.4
defaults write com.apple.dock "show-recents" -bool false
defaults write com.apple.dock "mineffect" -string "scale"
defaults write com.apple.dock "minimize-to-application" -bool true
defaults write com.apple.dock "enable-spring-load-actions-on-all-items" -bool true
defaults write com.apple.dock "show-process-indicators" -bool false
defaults write com.apple.dock "launchanim" -bool false
defaults write com.apple.dock "mru-spaces" -bool false
# Remove all apps from Dock (start fresh)
defaults write com.apple.dock "persistent-apps" -array
# Downloads folder: display as folder, view as list
defaults write com.apple.dock "persistent-others" -array-add \
  '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>'"$HOME"'/Downloads</string><key>_CFURLStringType</key><integer>0</integer></dict><key>displayas</key><integer>1</integer><key>showas</key><integer>1</integer></dict><key>tile-type</key><string>directory-tile</string></dict>'
success "Dock configured"

# ── Finder ────────────────────────────────────────────────────────────────────

info "Finder..."
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool true
defaults write com.apple.finder "AppleShowAllFiles" -bool true
defaults write com.apple.finder "ShowPathbar" -bool true
defaults write com.apple.finder "ShowStatusBar" -bool true
defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool true
defaults write com.apple.finder "ShowHardDrivesOnDesktop" -bool true
defaults write com.apple.finder "ShowMountedServersOnDesktop" -bool true
defaults write com.apple.finder "ShowRemovableMediaOnDesktop" -bool true
defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"    # List view
defaults write com.apple.finder "_FXSortFoldersFirst" -bool true
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"    # Search current folder
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool false
defaults write com.apple.finder "WarnOnICloudRemoval" -bool false
defaults write com.apple.finder "NewWindowTarget" -string "PfDe"         # New window shows Desktop
defaults write com.apple.finder "NewWindowTargetPath" -string "file://$HOME/Desktop/"
defaults write com.apple.finder "FinderSpawnTab" -bool false             # Folders open in new windows
defaults write com.apple.finder "WarnOnEmptyTrash" -bool false
defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool false
defaults write NSGlobalDomain "com.apple.springing.enabled" -bool true
defaults write NSGlobalDomain "com.apple.springing.delay" -float 0
defaults write com.apple.desktopservices "DSDontWriteNetworkStores" -bool true
defaults write com.apple.desktopservices "DSDontWriteUSBStores" -bool true
defaults write com.apple.frameworks.diskimages "skip-verify" -bool true
defaults write com.apple.frameworks.diskimages "skip-verify-locked" -bool true
defaults write com.apple.frameworks.diskimages "skip-verify-remote" -bool true
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true
# List view: calculate all sizes
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:ListViewSettings:calculateAllSizes true" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
# Desktop: icon size 32x32, text size 10
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 32" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:textSize 10" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
# Show hidden folders
chflags nohidden ~/Library 2>/dev/null || true
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true
chflags nohidden /Volumes 2>/dev/null || true  # Moved to sudo phase at end if this fails
success "Finder configured"

# ── Screenshots ───────────────────────────────────────────────────────────────

info "Screenshots..."
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture "location" "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture "show-thumbnail" -bool true
defaults write com.apple.screencapture "include-date" -bool false
defaults write com.apple.screencapture "type" -string "png"
defaults write com.apple.screencapture "disable-shadow" -bool true
success "Screenshots → ~/Desktop/Screenshots"

# ── Keyboard & Input ──────────────────────────────────────────────────────────

info "Keyboard & Input..."
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool false    # Key repeat instead of accent menu
defaults write NSGlobalDomain "AppleKeyboardUIMode" -int 3              # Full keyboard navigation
defaults write NSGlobalDomain "NSAutomaticCapitalizationEnabled" -bool false
defaults write NSGlobalDomain "NSAutomaticDashSubstitutionEnabled" -bool false
defaults write NSGlobalDomain "NSAutomaticPeriodSubstitutionEnabled" -bool false
defaults write NSGlobalDomain "NSAutomaticQuoteSubstitutionEnabled" -bool false
defaults write NSGlobalDomain "NSAutomaticSpellingCorrectionEnabled" -bool false
success "Keyboard configured"

# ── Trackpad ──────────────────────────────────────────────────────────────────

info "Trackpad..."
defaults write com.apple.AppleMultitouchTrackpad "FirstClickThreshold" -int 1
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool true
defaults write com.apple.AppleMultitouchTrackpad "Clicking" -bool true
defaults write NSGlobalDomain "com.apple.swipescrolldirection" -bool false   # Disable natural scrolling
success "Trackpad configured"

# ── General Appearance ────────────────────────────────────────────────────────

info "General appearance..."
defaults write NSGlobalDomain "AppleAccentColor" -int 0                     # Red accent color
defaults write NSGlobalDomain "AppleHighlightColor" -string "1.000000 0.733333 0.721569 Red"
defaults write NSGlobalDomain "AppleReduceDesktopTinting" -bool true        # No wallpaper tinting
defaults write NSGlobalDomain "NSRecentDocumentsLimit" -int 50
defaults -currentHost write com.apple.screensaver "idleTime" -int 0         # Disable screen saver
success "Appearance configured"

# ── Mission Control ───────────────────────────────────────────────────────────

info "Mission Control..."
defaults write com.apple.dock "expose-group-apps" -bool true
success "Mission Control configured"

# ── Safari ────────────────────────────────────────────────────────────────────

info "Safari..."
defaults write com.apple.Safari "ShowFullURLInSmartSearchField" -bool true
defaults write com.apple.Safari "AutoOpenSafeDownloads" -bool false
defaults write com.apple.Safari "IncludeDevelopMenu" -bool true
defaults write com.apple.Safari "WebKitDeveloperExtrasEnabledPreferenceKey" -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write com.apple.Safari "InstallExtensionUpdatesAutomatically" -bool true
success "Safari configured"

# ── Mail ──────────────────────────────────────────────────────────────────────

info "Mail..."
defaults write com.apple.mail "DisableReplyAnimations" -bool true
defaults write com.apple.mail "DisableSendAnimations" -bool true
defaults write com.apple.mail "DisableInlineAttachmentViewing" -bool true
defaults write com.apple.mail "PlayMailSounds" -bool false
defaults write com.apple.mail "ConversationViewSortDescending" -bool false
success "Mail configured"

# ── TextEdit ──────────────────────────────────────────────────────────────────

info "TextEdit..."
defaults write com.apple.TextEdit "RichText" -bool false
defaults write com.apple.TextEdit "SmartQuotes" -bool false
success "TextEdit configured"

# ── Activity Monitor ──────────────────────────────────────────────────────────

info "Activity Monitor..."
defaults write com.apple.ActivityMonitor "OpenMainWindow" -bool true
defaults write com.apple.ActivityMonitor "IconType" -int 5
defaults write com.apple.ActivityMonitor "ShowCategory" -int 0
defaults write com.apple.ActivityMonitor "SortColumn" -string "CPUUsage"
defaults write com.apple.ActivityMonitor "SortDirection" -int 0
success "Activity Monitor configured"

# ── Time Machine ──────────────────────────────────────────────────────────────

info "Time Machine..."
defaults write com.apple.TimeMachine "DoNotOfferNewDisksForBackup" -bool true
success "Time Machine configured"

# ── Software Update ───────────────────────────────────────────────────────────

info "Software Update..."
defaults write com.apple.SoftwareUpdate "AutomaticCheckEnabled" -bool true
defaults write com.apple.SoftwareUpdate "AutomaticDownload" -int 1
defaults write com.apple.SoftwareUpdate "CriticalUpdateInstall" -int 1
defaults write com.apple.SoftwareUpdate "ConfigDataInstall" -int 1
defaults write com.apple.commerce "AutoUpdate" -bool true
success "Software Update configured"

# ── Photos ────────────────────────────────────────────────────────────────────

info "Photos..."
defaults -currentHost write com.apple.ImageCapture "disableHotPlug" -bool true
success "Photos configured"

# ── Firewall ──────────────────────────────────────────────────────────────────

info "Firewall + Energy..."
skip "Requires sudo — will run in final phase"

# ── CD/DVD ────────────────────────────────────────────────────────────────────

info "CD/DVD (ignore all)..."
defaults write com.apple.digihub "com.apple.digihub.blank.cd.appeared" -dict-add action -int 1
defaults write com.apple.digihub "com.apple.digihub.blank.dvd.appeared" -dict-add action -int 1
defaults write com.apple.digihub "com.apple.digihub.cd.music.appeared" -dict-add action -int 1
defaults write com.apple.digihub "com.apple.digihub.dvd.video.appeared" -dict-add action -int 1
success "CD/DVD configured"

# ── Xcode ─────────────────────────────────────────────────────────────────────

info "Xcode..."
defaults write com.apple.dt.Xcode "ShowBuildOperationDuration" -bool true
success "Xcode configured"

# ── Miscellaneous ─────────────────────────────────────────────────────────────

info "Miscellaneous..."
defaults write NSGlobalDomain "NSNavPanelExpandedStateForSaveMode" -bool true
defaults write NSGlobalDomain "NSNavPanelExpandedStateForSaveMode2" -bool true
defaults write NSGlobalDomain "PMPrintingExpandedStateForPrint" -bool true
defaults write NSGlobalDomain "PMPrintingExpandedStateForPrint2" -bool true
defaults write com.apple.LaunchServices "LSQuarantine" -bool false
defaults write com.apple.CrashReporter "DialogType" -string "none"
defaults write NSGlobalDomain "NSCloseAlwaysConfirmsChanges" -bool false
success "Miscellaneous configured"

# ── Desktop Wallpaper ────────────────────────────────────────────────────────

info "Desktop wallpaper..."
WALLPAPER_SRC="$DOTFILES/Safari Desktop Picture.jpg"
if [ -f "$WALLPAPER_SRC" ]; then
  WALLPAPER_DEST="$HOME/Pictures/Safari Desktop Picture.jpg"
  mkdir -p "$HOME/Pictures"
  cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALLPAPER_DEST\""
  success "Wallpaper set from dotfiles"
else
  skip "No wallpaper image found at $WALLPAPER_SRC"
fi

# ── Restart affected processes ────────────────────────────────────────────────

step "Restarting Dock, Finder, SystemUIServer..."
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
success "Processes restarted — preferences applied"

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 9: Restore Launch Agents
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 9: Restore Launch Agents"

LAUNCH_SRC="$DOTFILES/LaunchAgents"
LAUNCH_DEST="$HOME/Library/LaunchAgents"

if [ -d "$LAUNCH_SRC" ] && [ "$(ls -A "$LAUNCH_SRC" 2>/dev/null)" ]; then
  step "Copying launch agents..."
  mkdir -p "$LAUNCH_DEST"

  for plist in "$LAUNCH_SRC"/*.plist; do
    [ -f "$plist" ] || continue
    cp "$plist" "$LAUNCH_DEST/"
    success "Restored $(basename "$plist")"
  done

  # Fix paths if username differs
  OLD_USER=$(grep -oP '(?<=/Users/)[^/]+' "$LAUNCH_SRC"/*.plist 2>/dev/null | head -1 | cut -d: -f2)
  CURRENT_USER=$(whoami)
  if [ -n "$OLD_USER" ] && [ "$OLD_USER" != "$CURRENT_USER" ]; then
    step "Fixing paths: /Users/$OLD_USER → /Users/$CURRENT_USER..."
    sed -i '' "s|/Users/$OLD_USER|/Users/$CURRENT_USER|g" "$LAUNCH_DEST"/com.*.plist 2>/dev/null
    success "Paths updated"
  fi

  step "Loading launch agents..."
  for plist in "$LAUNCH_DEST"/com.{vibelog,security-audit}.*.plist; do
    [ -f "$plist" ] || continue
    launchctl load "$plist" 2>/dev/null && success "Loaded $(basename "$plist")" || warn "Failed to load $(basename "$plist")"
  done
else
  skip "No launch agents to restore"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 10: SSH Config
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 10: SSH Config"

step "Verifying SSH config..."
if [ -L "$HOME/.ssh/config" ]; then
  success "SSH config symlinked → $(readlink "$HOME/.ssh/config")"
  info "SSH keys are managed by 1Password SSH Agent — no key files needed"
  info "Make sure 1Password is installed and SSH Agent is enabled in its settings"
elif [ -f "$HOME/.ssh/config" ]; then
  success "SSH config present (not symlinked — may have been copied manually)"
else
  warn "SSH config not found — stow may not have created ~/.ssh/config"
  info "Check that ~/.dotfiles/.ssh/config exists and re-run: cd ~/.dotfiles && stow . --no-folding"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 11: Setapp
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 11: Setapp"

if [ -f "$DOTFILES/scripts/setapp-migrate.sh" ] || [ -f "$DOTFILES/setapp-migrate.sh" ]; then
  echo ""
  echo -e "  ${DIM}Setapp notes:${RESET}"
  echo "    - Download from https://setapp.com if Homebrew cask didn't install correctly"
  echo "    - After install: disable 'Open when installed' in Setapp prefs"
  echo "    - After install: disable push notifications in Setapp prefs"
  echo ""
  if confirm "Run the Setapp migration helper now?"; then
    SETAPP_SCRIPT="$DOTFILES/scripts/setapp-migrate.sh"
    [ ! -f "$SETAPP_SCRIPT" ] && SETAPP_SCRIPT="$DOTFILES/setapp-migrate.sh"
    chmod +x "$SETAPP_SCRIPT"
    "$SETAPP_SCRIPT"
  else
    skip "Setapp — run manually later"
  fi
else
  skip "No setapp-migrate.sh found"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 12: Backblaze
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 12: Backblaze"

if ls /Applications/Backblaze.app &>/dev/null; then
  success "Backblaze is installed"
  info "Sign in — your license should inherit from your account"
  info "If not, contact Backblaze support to transfer from old machine"
else
  echo ""
  echo "  Install Backblaze:"
  echo "    1. Download from https://www.backblaze.com/cloud-backup/download"
  echo "    2. Sign in — license inherits from your account"
  echo "    3. If not, contact Backblaze support to transfer"
  echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 13: Fix Absolute Paths (if username differs)
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 13: Fix Absolute Paths"

step "Scanning for hardcoded user paths in Claude config..."
CURRENT_USER=$(whoami)
OLD_PATHS=$(grep -rn "/Users/" "$DOTFILES/claude/.claude/" "$DOTFILES/Library/Application Support/Claude/" 2>/dev/null | grep -v "/Users/$CURRENT_USER" | grep -v ".DS_Store" || true)

if [ -n "$OLD_PATHS" ]; then
  warn "Found paths with a different username:"
  echo "$OLD_PATHS" | head -10 | while IFS= read -r line; do
    echo -e "    ${DIM}$line${RESET}"
  done
  OLD_USER=$(echo "$OLD_PATHS" | grep -oP '(?<=/Users/)[^/]+' | head -1)
  if [ -n "$OLD_USER" ] && confirm "Replace /Users/$OLD_USER with /Users/$CURRENT_USER?"; then
    find "$DOTFILES/claude/.claude/" "$DOTFILES/Library/Application Support/Claude/" -type f -not -name ".DS_Store" -exec \
      sed -i '' "s|/Users/$OLD_USER|/Users/$CURRENT_USER|g" {} +
    success "Paths updated"
  fi
else
  success "No path fixes needed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 14: Claude Code Plugins
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 14: Claude Code Plugins"

echo ""
echo -e "  ${DIM}Plugins are cached binaries and must be reinstalled inside Claude Code.${RESET}"
echo -e "  ${DIM}Run 'claude' and execute these commands:${RESET}"
echo ""
echo -e "  ${BOLD}Official plugins:${RESET}"
echo "    /install commit-commands@claude-plugins-official"
echo "    /install context7@claude-plugins-official"
echo "    /install explanatory-output-style@claude-plugins-official"
echo "    /install feature-dev@claude-plugins-official"
echo "    /install frontend-design@claude-plugins-official"
echo "    /install learning-output-style@claude-plugins-official"
echo "    /install security-guidance@claude-plugins-official"
echo "    /install swift-lsp@claude-plugins-official"
echo "    /install vercel@claude-plugins-official"
echo ""
echo -e "  ${BOLD}Third-party plugins:${RESET}"
echo "    /install n8n-mcp-skills@n8n-mcp-skills"
echo "    /install taches-cc-resources@taches-cc-resources"
echo "    /install warp@claude-code-warp"
echo "    /install impeccable@impeccable"
echo "    /install skill-creator@anthropic-skills"
echo "    /install playwright-skill@anthropic-skills"
echo ""
echo -e "  ${BOLD}Project-scoped (run from within the project):${RESET}"
echo "    /install php-lsp@claude-plugins-official"
echo ""
echo -e "  ${DIM}Note: Custom skills (audit, excalidraw, firecrawl, tutorial, etc.)${RESET}"
echo -e "  ${DIM}are restored automatically by stow in Phase 4.${RESET}"
echo -e "  ${DIM}Plugin-provided skills (vercel-*, web-design-guidelines, deploy-to-vercel)${RESET}"
echo -e "  ${DIM}are recreated when you install the vercel plugin above.${RESET}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 15: Re-authenticate Services
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 15: Re-authenticate Services"

echo ""
echo -e "  ${DIM}These services need fresh authentication on the new machine:${RESET}"
echo ""
echo "    gh auth login              # GitHub CLI"
echo "    op signin                  # 1Password CLI"
echo "    aws sso login              # AWS SSO"
echo "    docker login               # Docker Hub"
echo "    npm login                  # npm registry"
echo "    fabric --setup             # Fabric API keys"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 16: Manual Steps Checklist
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 16: Manual Steps"

echo ""
echo -e "  ${BOLD}These cannot be automated and need to be done by hand:${RESET}"
echo ""
echo -e "  ${BOLD}System Settings:${RESET}"
echo "    [ ] Allow Apple Watch to unlock Mac"
echo "        System Settings → Touch ID & Password → Apple Watch"
echo "    [ ] Disable Smart Zoom on trackpad"
echo "        System Settings → Trackpad → Scroll & Zoom → uncheck Smart Zoom"
echo "    [ ] Add second finger to Touch ID"
echo "        System Settings → Touch ID & Password → Add Fingerprint"
echo "    [ ] Optimize video streaming on battery"
echo "        System Settings → Battery → Options"
echo "    [ ] Hide battery from menu bar (if desired)"
echo "        System Settings → Control Center → Battery"
echo "    [ ] Upload custom desktop wallpaper"
echo ""
echo -e "  ${BOLD}Finder:${RESET}"
echo "    [ ] Remove tags from sidebar"
echo "    [ ] Add home folder to sidebar"
echo "    [ ] Remove CDs, hard disks, Bonjour computers from sidebar"
echo "        Finder → Settings → Sidebar"
echo ""
echo -e "  ${BOLD}Mail:${RESET}"
echo "    [ ] Set 'Erase deleted messages' to Never for all accounts"
echo "        Mail → Settings → Accounts → [each] → Mailbox Behaviors"
echo ""
echo -e "  ${BOLD}Accounts & Services:${RESET}"
echo "    [ ] iMessage: enable iCloud sync"
echo "        Messages → Settings → iMessage → Enable Messages in iCloud"
echo "    [ ] Music: sign in to Apple Music"
echo "    [ ] App Store: enable auto updates + download apps from other devices"
echo "    [ ] Wallet: enable Apple Card as default (if applicable)"
echo ""
echo -e "  ${BOLD}Hardware:${RESET}"
echo "    [ ] Add printer"
echo "    [ ] Add keyboard"
echo "    [ ] Add mouse"
echo ""
echo -e "  ${BOLD}Obsidian:${RESET}"
echo "    [ ] Vault syncs from iCloud automatically"
echo "    [ ] Open vault → trust community plugins"
echo "    [ ] Reconfigure obsidian-local-rest-api (set API key)"
echo "    [ ] Enable CLI: Settings → Advanced → Command line interface"
echo "        Test: obsidian --help"
echo "        If 'command not found': sudo ln -sf /Applications/Obsidian.app/Contents/MacOS/Obsidian /usr/local/bin/obsidian"
echo ""
echo -e "  ${BOLD}Docker:${RESET}"
echo "    [ ] Start Docker Desktop"
echo "    [ ] Reconnect MCP Docker containers"
echo ""
echo -e "  ${BOLD}MCP Virtual Environments (~/.venvs/):${RESET}"
echo "    [ ] Recreate docling-mcp venv (auto-created when MCP server is configured in Claude Desktop)"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 17: Sudo Commands (grouped at end)
# ═══════════════════════════════════════════════════════════════════════════════

section "Phase 17: System Settings (requires sudo)"

echo ""
echo -e "  ${DIM}These commands need administrator privileges.${RESET}"
echo ""

if confirm "Run sudo commands now? (firewall, energy settings, unhide /Volumes)"; then
  sudo -v  # Ask for password once

  step "Enabling firewall..."
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on 2>/dev/null
  success "Firewall enabled"

  step "Setting energy/battery preferences..."
  sudo pmset -b displaysleep 5     # 5 min display sleep on battery
  sudo pmset -c displaysleep 15    # 15 min display sleep plugged in
  success "Energy settings configured"

  step "Unhiding /Volumes..."
  sudo chflags nohidden /Volumes 2>/dev/null
  success "/Volumes visible in Finder"
else
  skip "Sudo commands — run these manually later:"
  echo "    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
  echo "    sudo pmset -b displaysleep 5"
  echo "    sudo pmset -c displaysleep 15"
  echo "    sudo chflags nohidden /Volumes"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════════════════

section "Migration Complete"

echo ""
echo -e "  ${GREEN}${BOLD}Your new Mac is set up.${RESET}"
echo ""
echo -e "  ${DIM}Automated:${RESET}"
echo "    [x] Xcode CLT, Homebrew, Stow installed"
echo "    [x] Oh My Zsh installed"
echo "    [x] Dotfiles stowed (shell, git, ghostty, claude)"
echo "    [x] Brewfile apps installed (formulae, casks, fonts, mas)"
echo "    [x] Dev tools restored (npm, uv, pipx, pip, rbenv, rustup/cargo, fabric)"
echo "    [x] macOS preferences applied"
echo "    [x] Launch agents restored"
echo "    [x] Absolute paths fixed"
echo ""
echo -e "  ${DIM}Remaining:${RESET}"
echo "    [ ] Run 'claude' → sign in → install plugins (see Phase 13 output)"
echo "    [ ] Re-authenticate services (see Phase 14 output)"
echo "    [ ] Complete manual steps (see Phase 15 output)"
echo "    [ ] Verify with: open the Mac Migration Guide → Verification Checklist"
echo ""
echo -e "  ${YELLOW}Once verified, go back to the old machine and decommission it.${RESET}"
echo ""
