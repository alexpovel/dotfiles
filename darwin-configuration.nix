{ config, pkgs, ... }:

{
  # Auto upgrade nix package and the daemon service.
  services = {
    nix-daemon = {
      enable = true;
    };
  };

  nix = {
    package = pkgs.nix;
    settings = {
      "extra-experimental-features" = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true; # VSCode, ...
    };
  };

  programs = {
    zsh = {
      # Create /etc/zshrc that loads the nix-darwin environment.
      # Very important. Only once this is activated do you get a shell with everything set up.
      enable = true;
    };

    bash = {
      # Some tools might have `/bin/bash` hard-coded, so help get Nix into those.
      enable = true;
    };
  };

  fonts = {
    fontDir.enable = true;

    fonts = [
      (pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
        ];
      })
    ];
  };

  homebrew = {
    enable = true;

    casks = [
      "calibre"
      "discord"
      "docker"
      "firefox"
      "google-chrome"
      "joplin"
      "linearmouse"
      "nextcloud"
      "raycast"
      "signal"
      "vlc"
    ];

    masApps = {
      # These are all special snowflakes, and installation might fail here for various
      # reasons which can only be resolved in the App Store GUI. It's still convenient
      # to have them listed here for reference, and guaranteeing their installation.
      "Wireguard" = 1451685025;
      "Telegram" = 747648890;
    };
  };

  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;

    activationScripts = {
      postUserActivation = {
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
