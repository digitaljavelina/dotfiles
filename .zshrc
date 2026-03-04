# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew environment (Apple Silicon) — do this once
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Secrets file
source ~/.env

export OPENAI_API_KEY=${OPENAI_API_KEY}

# rbenv init
eval "$(rbenv init - zsh)"

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(1password sudo web-search copybuffer copypath dirhistory history macos jsontools docker docker-compose)

# oh-my-zsh bootstrap (must come after plugins/theme definitions)
source "$ZSH/oh-my-zsh.sh"
source /opt/homebrew/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# User aliases
alias code="open -a 'Cursor'"
alias restart="source ~/.zshrc"
alias you='yt-dlp -f "b[ext=mp4]" -N 16 -o "~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/%(title)s.%(ext)s" --cookies-from-browser chrome'
alias yolo='claude --dangerously-skip-permissions'

# Edit this file with Cursor
alias zshrc='code ~/.zshrc'

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/michaelhenry/.lmstudio/bin"
# End of LM Studio CLI section


# Added by Antigravity
export PATH="/Users/michaelhenry/.antigravity/antigravity/bin:$PATH"

# Claude Code output tokens
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000

# ***Begin Fabric***
# YouTube alias for Fabric
yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] youtube-link"
        echo "Use the '-t' flag to get the transcript with timestamps."
        return 1
    fi

    transcript_flag="--transcript"
    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi
    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}

# Define the base directory for Obsidian notes
obsidian_base="/Users/michaelhenry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Fabric"

# Ensure the Obsidian directory exists
mkdir -p "$obsidian_base"

# Loop through all directories in the ~/.config/fabric/patterns directory
for pattern_dir in ~/.config/fabric/patterns/*; do
    # Only process directories, not files
    if [ ! -d "$pattern_dir" ]; then
        continue
    fi
    
    # Get the pattern name (directory name)
    pattern_name=$(basename "$pattern_dir")

    # Remove any existing alias with the same name
    unalias "$pattern_name" 2>/dev/null

    # Define a function dynamically for each pattern
    eval "
    $pattern_name() {
        local title=\"\$1\"
        local date_stamp=\$(date +'%Y-%m-%d')
        
        # Check if a title was provided
        if [ -n \"\$title\" ]; then
            # If a title is provided, save to file with input from stdin
            local output_path=\"\$obsidian_base/\${date_stamp}-\${title}.md\"
            fabric --pattern \"$pattern_name\" -o \"\$output_path\"
        else
            # If no title is provided, use --stream to stdout
            fabric --pattern \"$pattern_name\" --stream
        fi
    }
    "
done
# ***End Fabric***

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/michaelhenry/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Cipher commands
export OLLAMA_BASE_URL=http://localhost:11434
alias cipher='cipher -a ~/.cipher/cipher.yml'


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
