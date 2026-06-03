# -----------------------------------------------------
# Martin's environment & path
# Loaded after ml4w defaults (00-30 range)
# -----------------------------------------------------

# Extra PATH entries
# fish_add_path ~/.local/bin
# fish_add_path ~/go/bin

# bun
set --export BUN_INSTALL "$HOME/.bun"
fish_add_path $BUN_INSTALL/bin

# Preferred editor
# set -gx EDITOR nvim
# set -gx VISUAL $EDITOR
