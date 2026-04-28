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
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
