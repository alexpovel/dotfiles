# dotfiles

Written with Nix, specific to `nix-darwin` and `home-manager`.

## Installation

(Not tested)

1. [Install Nix](https://nixos.org/download/)
2. Run `nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#hostname`.
3. On changes, run `darwin-rebuild switch --flake .#hostname`
