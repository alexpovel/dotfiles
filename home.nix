{
  config,
  pkgs,
  # Nix will search for and inject this parameter from `specialArgs` in `flake.nix`
  pkgs-unstable,
  ...
}:

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
      "Library/Application Support/numbat/init.nbt" = {
        # https://numbat.dev/doc/cli-customization.html#config-path
        text = ''
          @aliases(events)
          unit event
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

    packages = import ./packages/lists/personal.nix { inherit pkgs pkgs-unstable; };

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

    shell = {
      enableFishIntegration = true;
    };
  };

  programs =
    let
      vcs = {
        name = "Alex Povel";
        email = "git@alexpovel.de";
      };
      backup = {
        shell_history = {
          # `ln -s ~/actual/path ~/.shell_history_backup` to control where this actually
          # points, if desired (e.g., cloud storage). On macOS, use `system_profiler
          # SPHardwareDataType | awk '/Hardware UUID/ {print $3}'` for a stable machine
          # identifier.
          destination = "${home}/.shell_history_backup/.fish_history";
        };
      };
    in
    {
      delta = {
        enable = true;
        enableGitIntegration = true;

        options = {
          hyperlinks = true;
          navigate = true; # use n and N to move between diff sections
        };
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
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

        settings = {
          alias = {
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
            email = vcs.email;
            name = vcs.name;
            signingKey = ssh.key.pub;
          };
        };

        ignores = [
          # General-purpose, low-false positive items.
          # https://git-scm.com/docs/gitignore#_pattern_format
          ".DS_Store"
          ".dev/" # In-repo temporary experiments
        ];
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
        package = pkgs-unstable.jujutsu;

        settings = {
          user = {
            name = vcs.name;
            email = vcs.email;
          };

          git = {
            private-commits = "private()"; # enable pattern of https://jj-vcs.github.io/jj/v0.29.0/FAQ/#how-can-i-avoid-committing-my-local-only-changes-to-tracked-files
          };

          template-aliases = {
            "format_short_change_id(id)" = "id.shortest()"; # Only display the shortest possible ID
            "format_timestamp(timestamp)" = "timestamp.ago()"; # Human-readable relative timestamps, "3 days ago"
            "log_compact_with_diff_summary" = ''
              builtin_log_compact(self)
              ++ label("diff_summary",
                label("files", self.diff().files().len())
                ++ " "
                ++ label("added", "+" ++ self.diff().stat().total_added())
                ++ label("removed", "-" ++ self.diff().stat().total_removed())
              )
            '';
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

            git_push_bookmark = "'${user}/' ++ change_id.short()";
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
            diff-formatter = [
              "${pkgs.lib.getExe pkgs.difftastic}"
              "--color=always"
              "$left"
              "$right"
            ];
            conflict-marker-style = "git"; # aka diff3 style
            pager = "less --quit-if-one-screen --RAW-CONTROL-CHARS --no-init";
          };

          colors = {
            # These colors work a bit like CSS; a key of `foo bar` is applied to content
            # with `label("foo", ...)`, where `...` contains another nested
            # `label("bar", ...)` somewhere. For color definitions, see
            # https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit.
            "diff_summary files" = "ansi-color-67"; # Faded cyan
            "diff_summary added" = "ansi-color-65"; # Faded green
            "diff_summary removed" = "ansi-color-174"; # Faded red
          };

          aliases = {
            log-recent = [
              "log"
              "--template"
              "log_compact_with_diff_summary"
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
            swap = [
              # Swap the current work revision with the previous one.
              "rebase"
              "--revisions"
              "@"
              "--before"
              "@-"
            ];
          };

          remotes = {
            origin = {
              auto-track-bookmarks = "regex:(main|master)";
            };
            upstream = {
              auto-track-bookmarks = "regex:(main|master)";
            };
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

        enableDefaultConfig = false;
        matchBlocks = {
          # All hosts
          "*" = {
            addKeysToAgent = ssh.agentDuration;
            compression = true;
          };
        };

        includes = [
          # Place add. config files here. Allows for non-Nix managed, throw-away configs.
          "dynamic.d/*"
        ];
      };

      starship = {
        enable = true;

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
              # Module to show whether we're in a jj repo -- and nothing else.
              description = "Current jj repo status";
              when = "jj --ignore-working-copy root";
              symbol = "🥋 ";
              shell = [
                # Using minimal shell cuts ~60ms off execution time.
                "sh"
                "--norc"
                "--noprofile"
              ];
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

        # Use this over shell init once available, cf.
        # https://github.com/nix-community/home-manager/commit/85a27991d5d9c980e33179b2fc7f0eb4f7262db0
        # binds = {
        #   "ctrl-j" = {
        #     command = "jj_log_picker";
        #   };
        # };

        functions = {
          backup_history = {
            body = ''
              echo "Running history backup"

              set --local BACKUP_SRC "$HOME/.local/share/fish/fish_history"
              set --local BACKUP_DST "${backup.shell_history.destination}"

              if test -e "$BACKUP_SRC"
                  mkdir -p "$(dirname $BACKUP_DST)"
                  cp "$BACKUP_SRC" "$BACKUP_DST"
              end
            '';
            description = "Backup fish history";
          };

          jj_log_picker = {
            description = "Launches jj into fzf to pick a change ID from the jj log, if possible.";
            body = ''
              if not jj --ignore-working-copy root >/dev/null 2>&1
                  echo "Not in a jujutsu repository"
                  commandline --function repaint
                  return 1
              end

              set -l selection (
                  jj \
                      --color=always \
                      --limit 100 \
                      # Prefixing by underscore happens to prefix the change ID, which allows
                      # picking it out via regex later on.
                      --template '"_" ++ builtin_log_compact' \
                      # Do not are about timestamps for picking.
                      --config "template-aliases.'format_timestamp(timestamp)'"="" |
                  fzf \
                      --ansi \
                      --height=50% \
                      # Reverse to display in usual order.
                      --reverse \
                      # Grab first hex-looking string with underscore prefix. We can have multiple
                      # per line as e.g. `git_head()` might be a bookmark.
                      --preview 'change_id=$(echo {} | grep --only-matching "_[a-z0-9]\+" | head -1 | sed "s/^_//"); [ -n "$change_id" ] && jj show --color=always "$change_id" || echo "No change ID on this line"' \
                      --preview-window=right:60%
              )

              if test -n "$selection"
                  # Important: use the same extraction method as the preview
                  set -l change_id (echo $selection | grep --only-matching "_[a-z0-9]\+" | head -1 | sed "s/^_//")
                  if test -n "$change_id"
                      commandline --insert $change_id
                  end
              end
              commandline --function repaint
            '';
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

          # Control + J becomes the jj log picker.
          # NB: switch to name option at https://github.com/nix-community/home-manager/commit/85a27991d5d9c980e33179b2fc7f0eb4f7262db0 once available.
          bind \cj jj_log_picker

          # Custom functions. Note that event handlers cannot live in the functions/
          # directory, as auto-sourcing does not work for them
          # (https://fishshell.com/docs/current/language.html#event-handlers). So define
          # some thin wrappers which handle the event here, while keeping the function
          # definitions in the functions/ directory.

          function init_ssh_event_handler --on-event="fish_preexec" --wraps "init_ssh"
            set --local cmd (string trim -- $argv)

            # Only fire on commands requiring ssh keys
            if not string match --quiet --regex '^(git|ssh|jj) ' -- $cmd
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
          urlencode = "${pkgs.lib.getExe pkgs.python3} -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
          urldecode = "${pkgs.lib.getExe pkgs.python3} -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        };

        shellAbbrs = {
          # keep-sorted start block=yes
          c = "cargo";
          d = "docker";
          g = "git";
          j = "jj";
          ja = "jj abandon";
          jb = "jj bookmark";
          jd = "jj diff";
          je = "jj edit";
          jf = "jj git fetch";
          jg = "jj git";
          jn = "jj new";
          jnt = "jj new 'trunk()'";
          jo = "jj operation";
          jp = "jj git push";
          jrb = "jj rebase --skip-emptied";
          js = "jj status";
          jsq = "jj squash";
          ju = "jj undo";
          k = {
            # Expand this fully, for example to `kubectl --context=foo --namespace=bar`,
            # for easy copy-pasting around and meaningful shell history.
            function = "kubectl_expand";
          };
          m = "make";
          n = "numbat";
          ne = {
            setCursor = true;
            expansion = "numbat --expression '%'";
          };
          pi = "ipython";
          tf = "terraform";
          # keep-sorted end
        };
      };
    };
}
