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

# 1Password SSH agent forwarding
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Local secrets (API keys, etc). Real values live in ~/.secrets.zsh (chmod 600,
# outside this repo, never committed). 1Password is the source of truth; if the
# file is missing or a key rotates, re-materialize it with:
#   printf 'export OPENROUTER_API_KEY=%q\n' "$(op read 'op://Personal/OpenRouter API Key/notesPlain')" > ~/.secrets.zsh && chmod 600 ~/.secrets.zsh
[[ -f ~/.secrets.zsh ]] && source ~/.secrets.zsh

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

# content-ideas skill: keep brand/ and research/ in the vault
export CONTENT_HOME="/Users/michaelhenry/Obsidian/Projects/YouTube/content-ideas"

#ccimg for pasting clipboard image content to cc in ssh
# ccimg            -> send clipboard image to the remote box
# ccimg shot.png   -> send an existing file instead
  ccimg() {
    local host="${CCIMG_HOST:-dockerhost-1}"
    local dir="${CCIMG_DIR:-inbox}"
    local src base

    if [ -n "$1" ]; then
      [ -f "$1" ] || { echo "ccimg: no such file: $1" >&2; return 1; }
      src="$1"
    else
      command -v pngpaste >/dev/null 2>&1 || {
        echo "ccimg: needs pngpaste — brew install pngpaste" >&2; return 1; }
      src="/tmp/ccimg-$(date +%Y%m%d-%H%M%S).png"
      pngpaste "$src" 2>/dev/null || {
        echo "ccimg: no image on the clipboard" >&2; return 1; }
    fi

    base=$(basename "$src")
    ssh "$host" "mkdir -p ~/$dir" || return 1
    scp -q "$src" "$host:$dir/$base" || return 1

    printf '~/%s/%s\n' "$dir" "$base"
    printf '~/%s/%s' "$dir" "$base" | pbcopy   # path now on your clipboard
  }



# wmclean — strip AI watermark characters from whatever is on the clipboard.
# Copy from a chat window, run wmclean, then paste. Runs locally; the
# dockerhost-1 service is not involved.
wmclean() {
  local script in out err

  script=$(command ls -d "$HOME"/.claude/plugins/cache/watermarks-remover/watermarks-remover/*/service/scripts/clean_text.py 2>/dev/null | sort -V | tail -1)
  [ -n "$script" ] || {
    echo "wmclean: clean_text.py not found. Is the watermarks-remover plugin installed?" >&2; return 1; }

  in=$(mktemp -t wmclean-in) || return 1
  out=$(mktemp -t wmclean-out) || return 1
  err=$(mktemp -t wmclean-err) || return 1

  pbpaste > "$in"
  [ -s "$in" ] || {
    echo "wmclean: no text on the clipboard" >&2; rm -f "$in" "$out" "$err"; return 1; }

  if python3 "$script" "$in" -o "$out" 2>"$err"; then
    pbcopy < "$out"          # only replace the clipboard on success
    cat "$err" >&2           # e.g. removed=2 replaced=1 len 46->44
  else
    echo "wmclean: failed, clipboard left untouched" >&2
    cat "$err" >&2
    rm -f "$in" "$out" "$err"; return 1
  fi

  rm -f "$in" "$out" "$err"
}

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

# pdf2md-pick — convert PDFs to Markdown without typing paths.
# Opens a native file picker (multi-select allowed) and runs pdf2md on each,
# writing the notes to the vault Inbox. Pass a folder to send them elsewhere:
# pdf2md-pick ~/Desktop
pdf2md-pick() {
  local dest="${1:-$HOME/Obsidian/Inbox}"

  command -v pdf2md >/dev/null || {
    echo "pdf2md-pick: pdf2md not on PATH" >&2; return 1; }
  [ -d "$dest" ] || {
    echo "pdf2md-pick: no such directory: $dest" >&2; return 1; }

  local picked
  picked=$(osascript <<'OSA'
set theFiles to choose file with prompt "Pick PDF(s) to convert" of type {"com.adobe.pdf"} with multiple selections allowed
set out to ""
repeat with f in theFiles
	set out to out & (POSIX path of f) & linefeed
end repeat
return out
OSA
  ) || { echo "pdf2md-pick: cancelled" >&2; return 1; }

  [ -n "$picked" ] || { echo "pdf2md-pick: nothing picked" >&2; return 1; }

  local n=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    pdf2md "$f" -o "$dest" && n=$((n+1))
  done <<< "$picked"

  echo "pdf2md-pick: converted $n file(s) into $dest"
}
