# dotfiles

Nix-darwin + home-manager config for Nicolas's M1 Mac. Declarative system settings,
Homebrew casks/brews, and dotfile symlinks, applied via flakes.

- `configuration.nix` — system-level (nix-darwin): macOS defaults, Homebrew casks/brews.
- `home.nix` — user-level (home-manager): packages, shell config, dotfile symlinks
  (`home.file.*` entries link into `home/`, e.g. `home/AGENTS.md` is the global
  agent-instructions file symlinked to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, etc.)
- `flake.nix` / `flake.lock` — pinned inputs (nixpkgs, nix-darwin, home-manager, nix-homebrew).
- `home/` — files that get symlinked into `$HOME` by home-manager.

## Apply changes

```
./rebuild.sh
```

Symlinks `~/.dotfiles` to this repo, then runs `sudo darwin-rebuild switch --flake ~/.dotfiles#mac`.

## Notes

- Repo must be reachable via `~/.dotfiles` for the flake's `mkOutOfStoreSymlink` paths to resolve.
- Don't edit `home/AGENTS.md` as project docs — it's global, symlinked into every project.

See CLAUDE.md for Claude Code-specific notes.
