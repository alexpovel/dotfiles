{ config, pkgs, ... }:

let
  # Found this out debugging and digging with `builtins.trace (pkgs.lib.attrNames config)`. No idea where `config.home` comes from.
  home = config.home.homeDirectory;
  shellStartupDir = "${home}/Code";

  ssh = {
    agentDuration = "12h";
    key = rec {
      type = "ed25519";
      priv = "~/.ssh/id_${type}";
      pub = "${priv}.pub";
    };
  };
in
{
  home = {
    stateVersion = "23.11";

    activation = {
      # Creates a file, so place after `writeBoundary`; https://nix-community.github.io/home-manager/options.xhtml#opt-home.activation
      createTerminalStartDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${shellStartupDir}
      '';
    };

    file = {
      ".config" = {
        source = ./home/.config;
        recursive = true;
      };
      ".ipython" = {
        source = ./home/.ipython;
        recursive = true;
      };
      ".config/ghostty/config" = {
        text = ''
          # keybind = global:ctrl+grave_accent=toggle_quick_terminal
          # quick-terminal-animation-duration = 0

          font-size = 20
          command = "${pkgs.lib.getExe pkgs.fish}"
        '';
      };
      ".ignore" = {
        # General-purpose ignore file. For example, this can be picked up by `rg`:
        # https://github.com/BurntSushi/ripgrep/blob/f1d23c06e30606b2428a4e32da8f0b5069e81280/GUIDE.md#L184
        # and `fd`:
        # https://github.com/sharkdp/fd/blob/29936f0fbae1e52984ab582b2b2c98685d6ad638/README.md#L263
        # ⚠️ These have `.gitignore` semantics.
        text = ''
          .DS_Store
          .Trash
          Applications
          Desktop
          Documents
          Downloads
          Library
          Movies
          Music
          Pictures
          Public
          .git/
        '';
      };
    };

    packages = import ./packages/lists/personal.nix { inherit pkgs; };
  };

  programs = {
    direnv = {
      enable = true;
    };

    fd = {
      enable = true;

      hidden = true;
    };

    fzf = {
      enable = true;

      fileWidgetCommand = "${pkgs.fd}/bin/fd --hidden";
      fileWidgetOptions = [
        "--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :100 {}'"
      ];
    };

    git = {
      enable = true;
      userName = "Alex Povel";
      userEmail = "git@alexpovel.de";

      aliases = {
        a = "add";
        ap = "add --patch";
        c = "commit";
        ca = "commit --all";
        cano = "commit --amend --no-edit";
        cl = "!f() { git clone \"$1\" $(git-url-extract-path \"$1\"); }; f"; # Sort into owner/repo format
        cli = "clean --interactive";
        d = "diff";
        dog = "log --decorate --oneline --graph --pretty=format:'%C(auto)%h%d %s %C(240)- %cr %C(240)- %an'";
        doga = "dog --all";
        dogaf = "doga --first-parent";
        dogf = "dog --first-parent";
        ds = "diff --staged";
        p = "push";
        pl = "pull --prune";
        pla = "pull --all --prune";
        rb = "rebase";
        rbi = "rebase --interactive";
        s = "status --short --branch";
        subfull = "submodule update --init --recursive";
        sw = "switch";
        swd = "sw --detach";

        # 'What does force-pushing the current branch to its upstream (overwriting it)
        # change to the PR of that upstream against main?'; similar to
        # https://stackoverflow.com/a/52512813/11477374 . `@{u}`: upstream branch.
        check-if-force-pushing-ruins-my-life = "!f() { git range-diff main HEAD $(git rev-parse @{u}); }; f";
      };

      delta = {
        enable = true;

        options = {
          hyperlinks = true;
          light = false; # set to true if you're in a terminal w/ a light background color (e.g. the default macOS terminal)
          navigate = true; # use n and N to move between diff sections
          syntax-theme = "Coldark-Dark";
        };
      };

      ignores = [
        # General-purpose, low-false positive items.
        # https://git-scm.com/docs/gitignore#_pattern_format
        ".DS_Store"
        ".dev/" # In-repo temporary experiments
      ];

      extraConfig = {
        commit = {
          gpgsign = true;
        };
        core = {
          autocrlf = false;
          eol = "lf";
          editor = "code --wait";
          fsmonitor = true;
        };
        gpg = {
          format = "ssh";

          ssh = {
            allowedSignersFile = "~/.ssh/allowed_signers";
          };
        };
        merge = {
          conflictstyle = "diff3";
        };
        pull = {
          rebase = true;
        };
        push = {
          autoSetupRemote = true;
        };
        rebase = {
          updateRefs = true;
        };
        rerere = {
          enabled = true;
        };
        user = {
          signingKey = ssh.key.pub;
        };
      };
    };

    go = {
      enable = true;
    };

    home-manager = {
      # Let Home Manager install and manage itself.
      enable = true;
    };

    nix-index = {
      enable = true;
    };

    ripgrep = {
      enable = true;

      arguments = [
        "--smart-case"
        "--hidden"
      ];
    };

    ssh = {
      enable = true;

      addKeysToAgent = ssh.agentDuration;
      compression = true;
      includes = [
        # Place add. config files here. Allows for non-Nix managed, throw-away configs.
        "dynamic.d/*"
      ];
    };

    starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        right_format = "$time";
        time = {
          disabled = false;
          format = "[$time]($style)";
        };

        kubernetes = {
          disabled = false;
        };

        git_status = {
          ahead = "\${count}a";
          behind = "\${count}b";
          conflicted = "\${count}c";
          deleted = "\${count}d";
          diverged = "\${ahead_count}/\${behind_count}D";
          modified = "\${count}m";
          renamed = "\${count}r";
          staged = "\${count}s";
          stashed = "\${count}S";
          untracked = "\${count}u";
          up_to_date = "✓";
        };
      };
    };

    vim = {
      enable = true;
    };

    vscode = {
      enable = true;
    };

    zoxide = {
      enable = true;
    };

    fish = {
      # Things like starship and fzf integration only start working if home-manager manages fish.
      enable = true;

      plugins = [
        {
          name = "autopair";
          src = pkgs.fetchFromGitHub {
            owner = "jorgebucaran";
            repo = "autopair.fish";
            rev = "4d1752ff5b39819ab58d7337c69220342e9de0e2";
            sha256 = "sha256-qt3t1iKRRNuiLWiVoiAYOu+9E7jsyECyIqZJ/oRIT1A=";
          };
        }
      ];

      functions = {
        backup_history = {
          body = ''
            echo "Running history backup"

            set --local BACKUP_SRC "$HOME/.local/share/fish/fish_history"
            set --local BACKUP_DST "$HOME/Nextcloud/.backup/fish_history/$(hostname)/.fish_history"

            if test -e "$BACKUP_SRC"
                mkdir -p "$(dirname $BACKUP_DST)"
                cp "$BACKUP_SRC" "$BACKUP_DST"
            end
          '';
          description = "Backup fish history";
        };

        init_ssh = {
          body = ''
            if not test -f ${ssh.key.priv}
              ssh-keygen -t ${ssh.key.type} -f ${ssh.key.priv}
              and echo "Run \`ssh-keygen -c\` to set comment on new key"
            end

            if not string match -q -- "*"(cat ${ssh.key.pub})"*" (ssh-add -L)
              echo -n "(Hit Return to skip adding ssh key to agent) "
              and ssh-add -t '${ssh.agentDuration}' ${ssh.key.priv}
            end
          '';
          description = "Generate (if necessary) and add SSH key ${ssh.key.pub} to agent";
        };

        kubectl_expand = {
          description = "Provides kubectl command with current context and namespace";
          body = ''
            set --local result "kubectl"

            # Only fetch once, expensive call
            set --local config (kubectl config view --minify --output=json 2>/dev/null)

            if test $status -eq 0
              set --local current_context (echo $config | jq --raw-output '.["current-context"] // empty')
              if test -n "$current_context"
                set --append result "--context='$current_context'"
              end

              # Assumption: due to `--minify`, there is only one context
              set --local current_namespace (echo $config | jq --raw-output '.contexts[0].context.namespace // empty')
              if test -n "$current_namespace"
                set --append result "--namespace='$current_namespace'"
              end
            end

            echo (string join " " -- $result)
          '';
        };

        ppc = {
          description = "Pretty-print previous command line and output to clipboard";
          body = ''
            set --local prev_cmd $history[1]
            if test -n "$prev_cmd"
              set --local prompt "\$ $prev_cmd"
              set --append prompt (eval $prev_cmd 2>&1)
              string join \n -- $prompt | fish_clipboard_copy
            end
          '';
        };
      };

      shellInit = ''
        # Target of `go install`:
        # https://pkg.go.dev/cmd/go#hdr-Compile_and_install_packages_and_dependencies
        fish_add_path $(go env GOBIN)
      '';

      interactiveShellInit = ''
        set fish_greeting # Disable greeting

        # Manual setup required: we keep a default shell of `/bin/zsh` for login shells.
        # This breaks Ghostty if we don't help it.
        # https://ghostty.org/docs/features/shell-integration#manual-shell-integration-setup
        if test -n "$GHOSTTY_RESOURCES_DIR"
            builtin source "$GHOSTTY_RESOURCES_DIR"/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
        end

        # Completions
        if not test -f ~/.config/fish/completions/docker.fish
          docker completion fish > ~/.config/fish/completions/docker.fish
        end

        # Custom functions. Note that event handlers cannot live in the functions/
        # directory, as auto-sourcing does not work for them
        # (https://fishshell.com/docs/current/language.html#event-handlers). So define
        # some thin wrappers which handle the event here, while keeping the function
        # definitions in the functions/ directory.

        function init_ssh_event_handler --on-event="fish_preexec" --wraps "init_ssh"
          set --local cmd (string trim -- $argv)

          # Only fire on commands requiring ssh keys
          if not string match --quiet --regex '^(git|ssh) ' -- $cmd
            return
          end

          init_ssh
        end

        function backup_history_event_handler --on-event="fish_exit" --wraps "backup_history"
          backup_history
        end
      '';

      shellAliases = {
        cat = "bat";
        l = "eza --long --header --all --all"; # `all` twice gives `.` and `..`
        rr = "git rev-parse --show-toplevel 2>/dev/null || pwd"; # Get current git repo's root, if possible; can be used as `cd $(rr)`, `z `rr`` etc.
      };

      shellAbbrs = {
        c = "cargo";
        d = "docker";
        g = "git";
        k = {
          # Expand this fully, for example to `kubectl --context=foo --namespace=bar`,
          # for easy copy-pasting around and meaningful shell history.
          function = "kubectl_expand";
        };
        m = "make";
        pi = "ipython";
        tf = "terraform";
      };
    };
  };
}
