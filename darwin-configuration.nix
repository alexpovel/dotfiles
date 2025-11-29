{
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  user = "alex";
in
{
  users.users = {
    "${user}" = {
      home = "/Users/${user}";
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      "extra-experimental-features" = [
        "nix-command"
        "flakes"
      ];
    };
    optimise = {
      automatic = true;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs = {
    overlays = [
      inputs.srgn.overlays.default
    ];
    config = {
      allowUnfree = true; # VSCode, ...
    };
  };

  nix-homebrew = {
    enable = true;

    inherit user;

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  home-manager = {
    backupFileExtension = "home-manager-backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      # https://discourse.nixos.org/t/pass-specialargs-to-the-home-manager-module/33068
      inherit inputs pkgs-unstable;
    };
    users = {
      "${user}" = import ./home.nix;
    };
  };

  programs = {
    zsh = {
      # Create /etc/zshrc that loads the nix-darwin environment.
      # Very important. Only once this is activated do you get a shell with everything set up.
      enable = true;
    };

    fish = {
      # Hook fish into global config as well, else might run into problems like
      # https://wiki.nixos.org/wiki/Fish#Running_fish_interactively_with_zsh_as_system_shell_on_darwin
      # and
      # https://discourse.nixos.org/t/using-fish-interactively-with-zsh-as-the-default-shell-on-macos/48402
      enable = true;
    };

    bash = {
      # Some tools might have `/bin/bash` hard-coded, so help get Nix into those.
      enable = true;
    };
  };

  fonts = {
    packages = [
      pkgs.nerd-fonts.fira-code
    ];
  };

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "zap";
    };

    taps = [
      # Gives `Error: Refusing to untap homebrew/cask because it contains the following
      # installed formulae or casks: ...` with `cleanup = "zap"` if this isn't present.
      "homebrew/cask"
    ];

    casks = [
      "calibre"
      "discord"
      "docker-desktop"
      "firefox"
      "google-chrome"
      "joplin"
      "linearmouse"
      "nextcloud"
      "signal"
      "zotero"
    ];
  };

  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;

    primaryUser = user;

    activationScripts = {
      activateSettings = {
        enable = true;
        # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
        text = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings - u";
      };
    };

    defaults = {
      dock = {
        autohide = true;
        orientation = "left";
        show-process-indicators = false;
        show-recents = false;
        static-only = true;
      };
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXEnableExtensionChangeWarning = false;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };
      NSGlobalDomain = {
        AppleFontSmoothing = 0; # https://www.reddit.com/r/apple/comments/t9qdl1/comment/hzvyq2g/
        InitialKeyRepeat = 15; # Delay before keys are repeated
        KeyRepeat = 2; # Delay between repeated keystrokes when holding down
      };
    };
  };
}
