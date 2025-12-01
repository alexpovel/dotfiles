{
  description = "Darwin configuration";

  inputs = {
    # Stable, base system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Unstable packages (for specific tools). Cf.
    # https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    srgn.url = "github:alexpovel/srgn";
    srgn.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    {
      darwinConfigurations =
        let
          system = "aarch64-darwin";
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          hostname = darwin.lib.darwinSystem {
            inherit system;

            # Pass all inputs to modules so we can use them there
            specialArgs = { inherit inputs pkgs-unstable; };

            modules = [
              ./darwin-configuration.nix
              inputs.home-manager.darwinModules.home-manager
              inputs.nix-homebrew.darwinModules.nix-homebrew
            ];
          };
        };
    };
}
