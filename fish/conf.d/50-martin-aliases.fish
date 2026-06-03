# -----------------------------------------------------
# Martin's aliases & abbreviations
# Loaded after ml4w defaults (00-30 range)
# -----------------------------------------------------

# Abbreviations expand inline — nicer than aliases for interactive use
# abbr -a g git
# abbr -a gco git checkout
# abbr -a gd git diff
# abbr -a gl git log --oneline --graph

# Apps
alias txt='gnome-text-editor'
alias text='gnome-text-editor'

# Claude Code with permission prompts skipped.
# This calls the `claude` function (functions/claude.fish), so it still
# holds the systemd sleep-inhibitor while running.
alias claudex='claude --dangerously-skip-permissions'
