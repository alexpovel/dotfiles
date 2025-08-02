{ config, pkgs, ... }:

let
  # Found this out debugging and digging with `builtins.trace (pkgs.lib.attrNames config)`. No idea where `config.home` comes from.
  home = config.home.homeDirectory;
  shellStartupDir = "${home}/Code";

  user = config.home.username;

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
          theme = dark:Monokai Pro Machine,light:Monokai Pro Light
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

    sessionPath = [
      # We install rustup manually, outside Nix - macOS + Rust via Nix is a nightmare.
      # See also https://rust-lang.github.io/rustup/installation/index.html
      "$HOME/.cargo/bin"

      # For proper Desktop integration, we install Code outside of Nix. Add the binary
      # to the path as well.
      "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/"
    ];

    sessionVariables = {
      "EDITOR" = "zed --wait";
      "PIP_DISABLE_PIP_VERSION_CHECK" = "1";
    };
  };

  programs =
    let
      vcs = {
        name = "Alex Povel";
        email = "git@alexpovel.de";
      };
    in
    {
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

      # TODO: use
      # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ghostty.enable
      # - should give better integration to get rid of manual Ghostty setup (see below)
      # ghostty = {
      #   enable = true;
      # };

      git = {
        enable = true;
        userName = vcs.name;
        userEmail = vcs.email;

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
          # https://stackoverflow.com/a/52512813/11477374 . `@{u}`: upstream branch. This
          # prints output similar to what services like GitHub or GitHub show as "changes
          # from last version" on a PR, i.e. it respects different branch states w.r.t.
          # trunk etc.
          check-if-force-pushing-ruins-my-life = "!f() { git range-diff main $(git rev-parse @{u}) HEAD; }; f";
        };

        delta = {
          enable = true;

          options = {
            hyperlinks = true;
            navigate = true; # use n and N to move between diff sections
          };
        };

        ignores = [
          # General-purpose, low-false positive items.
          # https://git-scm.com/docs/gitignore#_pattern_format
          ".DS_Store"
          ".dev/" # In-repo temporary experiments
        ];

        extraConfig = {
          branch = {
            sort = "-committerdate";
          };
          commit = {
            gpgsign = true;
            verbose = true;
          };
          column = {
            ui = "auto";
          };
          core = {
            autocrlf = false;
            eol = "lf";
            fsmonitor = true;
          };
          diff = {
            algorithm = "histogram";
            colorMoved = "plain";
            mnemonicPrefix = true;
            renames = true;
          };
          fetch = {
            prune = true;
            pruneTags = true;
          };
          gpg = {
            format = "ssh";

            ssh = {
              allowedSignersFile = "~/.ssh/allowed_signers";
            };
          };
          help = {
            autocorrect = "prompt";
          };
          init = {
            defaultBranch = "main";
          };
          merge = {
            conflictstyle = "zdiff3";
          };
          pull = {
            rebase = true;
          };
          push = {
            autoSetupRemote = true;
            followTags = true;
          };
          rebase = {
            updateRefs = true;
            autoSquash = true;
            autoStash = true;
          };
          rerere = {
            enabled = true;
            autoUpdate = true;
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

      jujutsu = {
        enable = true;

        settings = {
          user = {
            name = vcs.name;
            email = vcs.email;
          };

          core = {
            fsmonitor = "watchman";
            watchman = {
              register-snapshot-trigger = true; # cf. `jj debug watchman status`
            };
          };

          git = {
            push-new-bookmarks = true; # Just allow this by default
            private-commits = "private()"; # enable pattern of https://jj-vcs.github.io/jj/v0.29.0/FAQ/#how-can-i-avoid-committing-my-local-only-changes-to-tracked-files

            push-bookmark-prefix = "${user}/"; # NB: this becomes `templates.git_push_bookmark` in 0.31.0, https://github.com/jj-vcs/jj/releases/tag/v0.31.0
          };

          template-aliases = {
            "format_short_change_id(id)" = "id.shortest()"; # Only display the shortest possible ID
          };

          signing = {
            # Same signing behavior as git
            behavior = "own";
            backend = "ssh";
            key = ssh.key.pub;
          };

          templates = {
            # Emulate `git commit --verbose`, which is neat for e.g. IDE autocomplete
            # when writing commit messages.
            draft_commit_description = ''
              concat(
                description,
                surround(
                  "\nJJ: This commit contains the following changes:\n", "",
                  indent("JJ:     ", diff.stat(72)),
                ),
                "\nJJ: ignore-rest\n",
                diff.git(),
              )
            '';
          };

          fix = {
            # TBD if I end up needing these or if they're a gimmick. Seems cool though.
            tools = {
              rust-format = {
                command = [
                  "rustfmt"
                  "--emit"
                  "stdout"
                ];
                patterns = [ "glob:'**/*.rs'" ];
              };
              go-format = {
                command = [
                  "goimports"
                ];
                patterns = [ "glob:'**/*.go'" ];
              };
              go-mod-tidy = {
                command = [
                  "go"
                  "mod"
                  "tidy"
                ];
                patterns = [
                  "go.mod"
                  "go.sum"
                ];
              };
              keep-sorted = {
                command = [
                  "keep-sorted"
                  "-"
                ];
                patterns = [ "glob:'**/*'" ];
              };
            };
          };

          ui = {
            default-command = "log-recent";
            diff = {
              # NB: This config key becomes `diff-formatter` in 0.30.0, cf.
              # https://github.com/jj-vcs/jj/releases/tag/v0.30.0.
              tool = [
                "difft"
                "--color=always"
                "$left"
                "$right"
              ];
            };
            conflict-marker-style = "snapshot"; # I find this easier to read, default one is a diff-based one
            pager = "less --quit-if-one-screen --raw-control-chars --no-init";
          };

          aliases = {
            log-recent = [
              "log"
              "--revisions"
              "default() & recent()"
            ];
            tug = [
              # Pull the nearest bookmark to current worktree up. This helps when
              # working on "branches" in the git sense, and adding new commits to their
              # head.
              "bookmark"
              "move"
              "--from"
              "closest_bookmark(@-)"
              "--to"
              "@-"
            ];
          };

          revset-aliases = {
            # jj ships with this by default, cf. `jj config list --include-defaults --include-overridden revsets.log`
            "default()" = "present(@) | ancestors(immutable_heads().., 2) | present(trunk())";

            "recent()" = "committer_date(after:'1 month ago')";
            "closest_bookmark(to)" = "heads(::to & bookmarks())";
            "private()" = "description(glob:'private:*')";
          };
        };
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
          format = builtins.concatStringsSep "" (
            map (name: "\$${name}") [
              # https://github.com/spaceship-prompt/spaceship-prompt/issues/558#issuecomment-1890833657
              "username"
              "hostname"
              "localip"
              "shlvl"
              "singularity"
              "kubernetes"
              "directory"
              "vcsh"
              "fossil_branch"
              "fossil_metrics"
              "{custom.jj}" # Has dot, so need braces syntax
              "git_branch"
              "git_commit"
              "git_state"
              "git_metrics"
              "git_status"
              "hg_branch"
              "pijul_channel"
              "docker_context"
              "package"
              "c"
              "cmake"
              "cobol"
              "daml"
              "dart"
              "deno"
              "dotnet"
              "elixir"
              "elm"
              "erlang"
              "fennel"
              "golang"
              "guix_shell"
              "haskell"
              "haxe"
              "helm"
              "java"
              "julia"
              "kotlin"
              "gradle"
              "lua"
              "nim"
              "nodejs"
              "ocaml"
              "opa"
              "perl"
              "php"
              "pulumi"
              "purescript"
              "python"
              "raku"
              "rlang"
              "red"
              "ruby"
              "rust"
              "scala"
              "solidity"
              "swift"
              "terraform"
              "typst"
              "vlang"
              "vagrant"
              "zig"
              "buf"
              "nix_shell"
              "conda"
              "meson"
              "spack"
              "memory_usage"
              "aws"
              "gcloud"
              "openstack"
              "azure"
              "direnv"
              "env_var"
              "crystal"
              "custom"
              "sudo"
              "cmd_duration"
              "fill"
              "time"
              "line_break"
              "jobs"
              "battery"
              "status"
              "os"
              "container"
              "shell"
              "character"
            ]
          );

          custom = {
            jj = {
              # https://gitlab.com/lanastara_foss/starship-jj#usage
              command = "prompt";
              format = "$output";
              shell = [
                "starship-jj"
                "--ignore-working-copy"
                "starship"
              ];
              use_stdin = false;
              when = true;
            };
          };

          fill = {
            symbol = " ";
          };

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

          jc = {
            # cf. https://news.ycombinator.com/item?id=44640823
            description = "Condense JSON by keeping only N elements of each array (default: 1)";
            body = ''
              set --local n 1
              if test (count $argv) -gt 0
                set n $argv[1]
              end

              ${pkgs.jq}/bin/jq 'def w: arrays |= .[:1]|iterables[] |= w; w'
            '';
          };

          jstr = {
            # cf. https://news.ycombinator.com/item?id=44640405
            description = "Print structure of a JSON document";
            body = ''
              ${pkgs.jq}/bin/jq --raw-output '[path(..)|map(if type=="number" then "[]" end)]|unique[]|join(".")/".[]"|"."+join("[]")'
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

          ts = {
            description = "Print a UNIX timestamp human-readably.";
            body = ''
              python -c "
              from datetime import datetime as dt, timezone
              import sys

              ts = float(sys.argv[1])

              utc_dt = dt.fromtimestamp(ts, timezone.utc)
              local_dt = dt.fromtimestamp(ts).astimezone()

              print(f'Pretty:\t{local_dt.strftime(\"%c\")}')
              print(f'UTC:\t{utc_dt.isoformat()}')
              print(f'Local:\t{local_dt.isoformat()}')
              " $argv[1]
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
          set completions_dir ~/.config/fish/completions
          mkdir -p $completions_dir

          if not test -f $completions_dir/docker.fish
            docker completion fish > $completions_dir/docker.fish
          end

          if not test -f $completions_dir/rustup.fish
            rustup completions fish > $completions_dir/rustup.fish
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
          j = "jj";
          m = "make";
          pi = "ipython";
          tf = "terraform";
        }
        # Enable some jj-specific abbrs, which only trigger while within the `jj`
        # command and not in others (NB: they trigger *anywhere* within the command,
        # not just in the position they're legal in). Note each abbr still needs a
        # globally unique name, hence the prefixes.
        //
          pkgs.lib.mapAttrs'
            (regex: expansion: {
              name = "jj_${builtins.replaceStrings [ " " "-" ] [ "_" "_" ] expansion}";
              value = {
                command = "jj";
                inherit regex expansion;
              };
            })
            {
              # keep-sorted start
              a = "abandon";
              b = "bookmark";
              d = "diff";
              e = "edit";
              f = "git fetch";
              g = "git";
              n = "new";
              o = "operation";
              p = "git push";
              rb = "rebase --skip-emptied";
              s = "status";
              sq = "squash";
              swap = "rebase --revisions @ --before @-";
              u = "undo";
              # keep-sorted end
            };
      };
    };
}
