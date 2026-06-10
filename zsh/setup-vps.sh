#!/usr/bin/env bash
# VPS zsh setup - Ubuntu
# Copy to the VPS and run:   bash setup-vps.sh
# Idempotent: safe to run multiple times.
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

log()  { echo -e "${GREEN}▸${RESET} $*"; }
note() { echo -e "${YELLOW}note:${RESET} $*"; }
head() { echo -e "\n${BOLD}${CYAN}=== $* ===${RESET}"; }

# ---------------------------------------------------------------------------
head "apt packages"
# ---------------------------------------------------------------------------
sudo apt-get update -qq
# bat is packaged as 'batcat' on Ubuntu (avoid conflict with bacula-console)
# fd-find is 'fdfind' similarly; we alias both below.
sudo apt-get install -y zsh fzf bat fd-find ripgrep curl git unzip build-essential

# eza: in Ubuntu 24.04+ official repos; otherwise install from GitHub release.
if ! command -v eza &>/dev/null; then
    if apt-cache show eza &>/dev/null 2>&1; then
        sudo apt-get install -y eza
    else
        log "eza not in apt, installing from GitHub release..."
        EZA_VER=$(curl -sf https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep '"tag_name"' | cut -d'"' -f4)
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)  EZA_ARCH="x86_64-unknown-linux-gnu" ;;
            aarch64) EZA_ARCH="aarch64-unknown-linux-gnu" ;;
            *)       echo "Unknown arch $ARCH; skip eza" && true ;;
        esac
        if [[ -n "${EZA_ARCH:-}" ]]; then
            curl -sSfL "https://github.com/eza-community/eza/releases/download/${EZA_VER}/eza_${EZA_ARCH}.tar.gz" \
                | tar -xz -C /tmp eza
            install -Dm755 /tmp/eza "$HOME/.local/bin/eza"
        fi
    fi
fi

# ---------------------------------------------------------------------------
head "zoxide  (smart cd)"
# ---------------------------------------------------------------------------
if ! command -v zoxide &>/dev/null; then
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
else
    note "zoxide already installed at $(command -v zoxide)"
fi

# ---------------------------------------------------------------------------
head "oh-my-posh  (prompt)"
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
if ! command -v oh-my-posh &>/dev/null; then
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
else
    note "oh-my-posh already installed at $(command -v oh-my-posh)"
fi

# ---------------------------------------------------------------------------
head "zsh plugins  (autosuggestions, syntax-highlight, history-search)"
# ---------------------------------------------------------------------------
ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGINS"

for PLUGIN in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
    PLUGIN_DIR="$ZSH_PLUGINS/$PLUGIN"
    if [[ -d "$PLUGIN_DIR/.git" ]]; then
        log "$PLUGIN — updating"
        git -C "$PLUGIN_DIR" pull --quiet --ff-only
    else
        log "$PLUGIN — cloning"
        git clone --depth=1 "https://github.com/zsh-users/$PLUGIN" "$PLUGIN_DIR"
    fi
done

# ---------------------------------------------------------------------------
head "oh-my-posh config  (zen theme)"
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.config/ohmyposh"
cat > "$HOME/.config/ohmyposh/zen.toml" << 'TOML'
console_title_template = '{{ .Shell }} in {{ .Folder }}'
version = 3
final_space = true

[secondary_prompt]
  template = '❯❯ '
  foreground = 'magenta'
  background = 'transparent'

[transient_prompt]
  template = '❯ '
  background = 'transparent'
  foreground_templates = ['{{if gt .Code 0}}red{{end}}', '{{if eq .Code 0}}magenta{{end}}']

[[blocks]]
  type = 'prompt'
  alignment = 'left'
  newline = true

  [[blocks.segments]]
    template = '{{ .Path }}'
    foreground = 'blue'
    background = 'transparent'
    type = 'path'
    style = 'plain'

    [blocks.segments.properties]
      cache_duration = 'none'
      style = 'full'

  [[blocks.segments]]
    template = ' {{ .HEAD }}{{ if or (.Working.Changed) (.Staging.Changed) }}*{{ end }} <cyan>{{ if gt .Behind 0 }}⇣{{ end }}{{ if gt .Ahead 0 }}⇡{{ end }}</>'
    foreground = 'p:grey'
    background = 'transparent'
    type = 'git'
    style = 'plain'

    [blocks.segments.properties]
      branch_icon = ''
      cache_duration = 'none'
      commit_icon = '@'
      fetch_status = true

[[blocks]]
  type = 'rprompt'
  overflow = 'hidden'

  [[blocks.segments]]
    template = '{{ .FormattedMs }}'
    foreground = 'yellow'
    background = 'transparent'
    type = 'executiontime'
    style = 'plain'

    [blocks.segments.properties]
      cache_duration = 'none'
      threshold = 5000

[[blocks]]
  type = 'prompt'
  alignment = 'left'
  newline = true

  [[blocks.segments]]
    template = '❯'
    background = 'transparent'
    type = 'text'
    style = 'plain'
    foreground_templates = ['{{if gt .Code 0}}red{{end}}', '{{if eq .Code 0}}magenta{{end}}']

    [blocks.segments.properties]
      cache_duration = 'none'
TOML

# ---------------------------------------------------------------------------
head ".zshrc"
# ---------------------------------------------------------------------------
cat > "$HOME/.zshrc" << 'ZSH'
# ---------------------------------------------------------------------------
# VPS zsh config — standalone (no OMZ framework)
# ---------------------------------------------------------------------------

# PATH: local binaries first
path=("$HOME/.local/bin" $path)
export PATH

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS    # Deduplicate: newer entry wins
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY           # All sessions share history in real time
setopt HIST_IGNORE_SPACE       # Leading space = don't save (useful for secrets)
setopt EXTENDED_HISTORY        # Save timestamps

# ---------------------------------------------------------------------------
# Shell options
# ---------------------------------------------------------------------------
setopt AUTO_CD                 # Type a dir name to cd into it
setopt NO_BEEP
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# Ctrl+W stops at slash/dot/dash (not just spaces)
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# ---------------------------------------------------------------------------
# Completions
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings'     format '%F{red}-- no matches: %d --%f'
zstyle ':completion:*:git-checkout:*' sort false

# ---------------------------------------------------------------------------
# Plugins
# ---------------------------------------------------------------------------
ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"

[[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax highlighting must be sourced BEFORE history-substring-search
[[ -f "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

[[ -f "$ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] && \
    source "$ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh"

# ---------------------------------------------------------------------------
# FZF (fuzzy find: Ctrl+R history, Ctrl+T files, Alt+C cd)
# ---------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
    export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
    export FZF_CTRL_R_OPTS='--sort --exact'
fi

# ---------------------------------------------------------------------------
# Zoxide (smart cd)
# ---------------------------------------------------------------------------
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ---------------------------------------------------------------------------
# Prompt (oh-my-posh with zen theme; same as local machine)
# ---------------------------------------------------------------------------
if command -v oh-my-posh &>/dev/null; then
    eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
fi

# ---------------------------------------------------------------------------
# Key bindings
# ---------------------------------------------------------------------------
# Up/Down: history substring search (type prefix, arrow filters)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# Ctrl+Space: accept autosuggestion (alternative to →)
bindkey '^ '   autosuggest-accept
# Alt+.: insert last argument of previous command
bindkey '^[.'  insert-last-word
# Ctrl+Right / Ctrl+Left: word jump
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
# Ctrl+Backspace / Ctrl+Delete: kill word
bindkey '^H'      backward-kill-word
bindkey '^[[3;5~' kill-word

# Double-Esc: prepend/strip sudo (like OMZ sudo plugin)
_sudo-toggle() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N _sudo-toggle
bindkey '^[^[' _sudo-toggle

# ---------------------------------------------------------------------------
# Plugin config
# ---------------------------------------------------------------------------
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
ZSH_AUTOSUGGEST_USE_ASYNC=1

ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[comment]='fg=240'

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=yellow,fg=black,bold'
HISTORY_SUBSTRING_SEARCH_FUZZY=1

# ---------------------------------------------------------------------------
# Ubuntu binary aliases (bat/fd are renamed on Debian/Ubuntu)
# ---------------------------------------------------------------------------
command -v batcat  &>/dev/null && alias bat=batcat
command -v fdfind  &>/dev/null && alias fd=fdfind

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias c='clear'
alias ..='cd ..'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gst='git stash'
alias gsp='git stash && git pull'
alias gfo='git fetch origin'
alias gcheck='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------
gmain() { git checkout main && git pull }

ZSH
# end .zshrc

# ---------------------------------------------------------------------------
head "Change default shell to zsh"
# ---------------------------------------------------------------------------
if [[ "$(getent passwd "$(whoami)" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    log "Changing shell to zsh (enter your password if prompted)..."
    chsh -s "$(command -v zsh)"
else
    note "Shell is already zsh"
fi

echo ""
echo -e "${BOLD}${GREEN}Done!${RESET}"
echo "Open a new SSH session to start using zsh."
