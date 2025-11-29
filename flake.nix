{
  description = "Darwin configuration";

  inputs = {
    # Cannot factor out the version number, so hard-code it
    # (https://github.com/NixOS/nix/issues/4945) (wtf?)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    srgn.url = "github:alexpovel/srgn";
    srgn.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
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
      nixpkgs-unstable,

      srgn,
      darwin,
      home-manager,

      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }:
    {
      darwinConfigurations = {
        hostname = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            pkgs-unstable = import nixpkgs-unstable {
              system = "aarch64-darwin";
            };
          };

          modules = [
            ./darwin-configuration.nix

            { nixpkgs.overlays = [ srgn.overlays.default ]; }

            home-manager.darwinModules.home-manager
            {
              home-manager.backupFileExtension = "home-manager-backup";
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = {
                pkgs-unstable = import nixpkgs-unstable {
                  system = "aarch64-darwin";
                };
              };

              # https://discourse.nixos.org/t/how-to-explicity-pass-arguments-config-and-pkgs-to-home-managers-nixos-module/16607/2
              home-manager.users.alex.imports = [ ./home.nix ];

              users.users.alex.home = "/Users/alex";
            }
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                user = "alex";

                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };

                # THIS BROKE MY SETUP, with permission denied error:
                #
                # ```
                # building the system configuration...
                # setting up Homebrew (/opt/homebrew)...
                # user defaults...
                # setting up user launchd services...
                # Homebrew bundle...
                # ==> Tapping homebrew/bundle
                # fatal: could not create work tree dir '/opt/homebrew/Library/Taps/homebrew/homebrew-bundle': Permission denied
                # Error: Failure while executing; `git clone https://github.com/Homebrew/homebrew-bundle /opt/homebrew/Library/Taps/homebrew/homebrew-bundle --origin=origin --template= --config core.fsmonitor=false` exited with 128.
                # Error: Failure while executing; `/nix/store/62dvr49jyr9qvwp7bdv9acdb5c02i2bz-brew tap homebrew/bundle` exited with 1.
                # ```

                # mutableTaps = false;
              };
            }

          ];
        };
      };
    };
}
