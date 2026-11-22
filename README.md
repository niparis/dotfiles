# dotfiles

Nix-darwin + home-manager config for Nicolas's Macs. Declarative system settings,
Homebrew casks/brews, and dotfile symlinks, applied via flakes.

## New Mac

1. Install Determinate Nix:
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
2. Clone this repo to `~/code/niparis/dotfiles` (or anywhere; `rebuild.sh` symlinks it to `~/.dotfiles`).
3. Run `./rebuild.sh`. On a fresh Mac it installs nix-darwin via `nix run` on the first activation; later runs use `darwin-rebuild`. It skips the Homebrew guard until Homebrew exists.
4. Re-run `./rebuild.sh` after Homebrew is available to install the declared brews and casks.

The flake is currently built for host `mac` and user `nicolasparis`. A second Mac (e.g. Mac Studio, user `nicolas`) needs a new `darwinConfigurations` entry and `home-manager.users.nicolas`; proposed change tracked separately.
EOF