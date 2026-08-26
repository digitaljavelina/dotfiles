# Homebrew environment (Apple Silicon) — do this once
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# rbenv init
eval "$(rbenv init - zsh)"

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(1password sudo web-search copybuffer copypath dirhistory history macos jsontools docker docker-compose)

# oh-my-zsh bootstrap (must come after plugins/theme definitions)
source "$ZSH/oh-my-zsh.sh"
# source /opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# User aliases
alias code="open -a 'Visual Studio Code'"
alias restart="source ~/.zshrc"
alias you='yt-dlp -f "b[ext=mp4]" -N 16 -o "~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/%(title)s.%(ext)s" --cookies-from-browser chrome'
alias zshrc='code ~/.zshrc'

# Claude Code aliases
alias yolo='claude --dangerously-skip-permissions'
alias syncsettings='~/.dotfiles/scripts/sync-claude-settings.sh'

# VISUAL/EDITOR (point to a wrapper that runs `code -w` or your preferred editor)
export EDITOR="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code -w"

# Ruby gems (optional; compute once per login)
if command -v ruby >/dev/null 2>&1; then
  GEM_HOME_CACHED="${XDG_CACHE_HOME:-$HOME/.cache}/gem_home"
  if [[ -r "$GEM_HOME_CACHED" ]]; then
    GEM_HOME="$(<"$GEM_HOME_CACHED")"
  else
    GEM_HOME="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)" && \
    { mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"; print -r -- "$GEM_HOME" >| "$GEM_HOME_CACHED"; }
  fi
  [[ -n "$GEM_HOME" ]] && export PATH="$PATH:$GEM_HOME/bin"
fi

# Homebrew cask defaults (optional)
export HOMEBREW_CASK_OPTS="--appdir=/Applications --fontdir=/Library/Fonts"

export PATH="$HOME/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/michaelhenry/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# zoxide
eval "$(zoxide init zsh)"

# eza
alias ls="eza --icons --group-directories-first -ll"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/michaelhenry/.local/bin:PATH"
export PATH="$PATH:/Users/michaelhenry/.lmstudio/bin"
# End of LM Studio CLI section


# lmstudio environment variables in claude code
# export ANTHROPIC_BASE_URL=http://localhost:1234
# export ANTHROPIC_AUTH_TOKEN=lmstudio

# 1Password SSH agent forwarding
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

#Faceless Video Presets Directory
export FACELESS_PRESETS_DIR="$HOME/Obsidian/projects/faceless-video/presets"

# Firecrawl: routed cloud-first, self-hosted fallback. ~/bin/firecrawl shims the
# real CLI and picks a backend per command via ~/bin/fc_router.py -- cloud until
# credits reach the reserve, then the self-hosted instance on dockerhost-1
# (Tailscale). Both are stowed from ~/.dotfiles/bin/.
#
# Deliberately NOT exporting FIRECRAWL_API_URL: the shim reads it as "the caller
# wants this exact backend" and skips routing entirely. Pin a single run instead:
#   firecrawl scrape <url> --api-url "$FIRECRAWL_SELF_HOSTED_URL"
export FIRECRAWL_SELF_HOSTED_URL="http://100.93.17.61:3002"

# Self-hosted gaps. agent/browser/interact/credit-usage have no local
# implementation, so the router always sends those to cloud. The three below
# degrade quietly rather than erroring, so force cloud yourself when routed
# local and you need them: --api-url https://api.firecrawl.dev
#   - no Fire-engine, so anti-bot / proxied sites fail
#   - no LLM provider, so json/extract formats fail
#   - waitFor is hardcoded to 0 (no env var exists to change it), so
#     client-rendered SPAs return the pre-hydration shell unless you wait.
#     Harmless on server-rendered pages. Cap is timeout/2, timeout defaults 60000.
alias fcs='firecrawl scrape --wait-for 8000'

# docx2md-pick — convert Word docs to Markdown without typing paths.
# Opens a native file picker (multi-select allowed), runs docx2md --clean on
# each, and writes the notes to the vault Inbox. Pass a folder to send them
# somewhere else: docx2md-pick ~/Desktop
docx2md-pick() {
  local dest="${1:-$HOME/Obsidian/Inbox}"

  command -v docx2md >/dev/null || {
    echo "docx2md-pick: docx2md not on PATH" >&2; return 1; }
  [ -d "$dest" ] || {
    echo "docx2md-pick: no such directory: $dest" >&2; return 1; }

  local picked
  picked=$(osascript <<'OSA'
set theFiles to choose file with prompt "Pick .docx file(s) to convert" of type {"org.openxmlformats.wordprocessingml.document"} with multiple selections allowed
set out to ""
repeat with f in theFiles
	set out to out & (POSIX path of f) & linefeed
end repeat
return out
OSA
  ) || { echo "docx2md-pick: cancelled" >&2; return 1; }

  [ -n "$picked" ] || { echo "docx2md-pick: nothing picked" >&2; return 1; }

  local n=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    docx2md "$f" --clean -o "$dest" && n=$((n+1))
  done <<< "$picked"

  echo "docx2md-pick: converted $n file(s) into $dest"
}
