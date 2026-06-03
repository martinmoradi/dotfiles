# Package snapshots

Regenerate with `../snapshot.sh`.

- `pacman-explicit.txt` — all explicitly-installed packages (`pacman -Qqe`), includes AUR.
- `aur.txt` — foreign/AUR packages only (`pacman -Qqm`).

## Restore on a fresh machine

Official-repo packages (skips ones already present):

```bash
sudo pacman -S --needed - < pacman-explicit.txt
```

`pacman` will warn about the AUR entries it can't find — that's expected. Install
those with your AUR helper:

```bash
paru -S --needed - < aur.txt   # or: yay -S --needed - < aur.txt
```
