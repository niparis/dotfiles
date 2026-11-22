# dotfiles

Nix-darwin + home-manager config for Nicolas's Macs. Declarative system settings,
Homebrew casks/brews, and dotfile symlinks, applied via flakes.

## New Mac

1. Install Determinate Nix:
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
2. Clone this repo to `~/code/niparis/dotfiles` (or anywhere; `rebuild.sh` symlinks it to `~/.dotfiles`).
3. Run `./rebuild.sh`. On a fresh Mac it installs nix-darwin via `nix run` on the first activation; later runs use `darwin-rebuild`. It skips the Homebrew guard until Homebrew exists.
4. Re-run `./rebuild.sh` after Homebrew is available to install the declared brews and casks.

### Studio (Mac Studio, user `nicolas`)

1. Install Determinate Nix (sudo password required):
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
2. Clone the repo:
   `git clone git@github.com:niparis/dotfiles.git ~/code/niparis/dotfiles`
3. First activation (no darwin-rebuild yet):
   `cd ~/code/niparis/dotfiles && ./rebuild.sh`
   (uses `sudo nix run ...#darwin-rebuild`; may prompt for sudo)
4. After Homebrew is installed:
   `cd ~/code/niparis/dotfiles && ./rebuild.sh`
