{ config, pkgs, ... }:

let
  # Found this out debugging and digging with `builtins.trace (pkgs.lib.attrNames config)`. No idea where `config.home` comes from.
  home = config.home.homeDirectory;
  shellStartupDir = "${home}/Code";

  zshCustomCompletionsRelToHome = ".zsh_custom_completions";
  zshCustomCompletions = "${home}/${zshCustomCompletionsRelToHome}";

  # Alacritty default is 10k, its maximum 100k; tmux default is 2k; filling up 100k
  # lines w/ tmux takes 600 MB memory, so let's not max it out
  terminalScrollback = 20000;

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
      "${zshCustomCompletionsRelToHome}/dummy" = {
        text = ''
          # Placeholder for zsh completions, to ensure this directory is created.
          # Managing this in Nix ensures proper lifecycle management.
          # Completion scripts of the form `_some-command` can be placed in this directory.
        '';
      };
    };

    packages = with pkgs;
      let
        luazstd = import ./packages/lua-zstd.nix {
          inherit (pkgs) fetchFromGitHub fetchurl zstd;
          inherit (pkgs.luajitPackages) buildLuarocksPackage luaOlder;
        };
      in
      [
        ansible
        bat
        bottom
        capnproto
        cargo-insta
        cmake
        coreutils-prefixed
        curl
        dig
        erdtree
        eza
        fastgron
        ffmpeg
        gh
        gnumake
        gnuplot
        go-mockery
        golangci-lint
        graphviz
        hexyl
        htop
        hyperfine
        imagemagick
        inetutils # telnet, ping, traceroute, whois
        inkscape
        jq
        just
        kubectl
        kubelogin-oidc
        kubernetes-helm
        (luajit.withPackages (p: with p; [
          luacheck
          luaunit
          luarocks
          luazstd
        ]))
        ncdu
        neofetch
        nil
        nix-direnv
        nixpkgs-fmt
        nmap
        nodejs
        pandoc
        parallel
        perl
        pipx
        poetry
        postgresql
        pre-commit
        protobuf
        (python3.withPackages (p: with p; [
          httpx
          httpx-auth
          ipython
          pandas
        ]))
        rclone
        rsync
        rustup
        shellcheck
        sqlite
        (pkgs.rustPlatform.buildRustPackage
          rec {
            # See also https://github.com/NixOS/nixpkgs/pull/293076, adjusted here
            pname = "srgn";
            version = "srgn-v0.12.0";

            src = pkgs.fetchFromGitHub {
              owner = "alexpovel";
              repo = pname;
              rev = version;
              hash = "sha256-d53aSo1gzINC8WdMzjCHzU/8+9kvrrGglV4WsiCt+rM="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
            };

            cargoHash = "sha256-NSP/AwghyLfaZjQ/tUv8pSbxgD6Kf12In9UdXnRLE0I="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
          }
        )
        squawk
        terraform
        tldr
        tokei
        typescript
        typst
        vault
        wget
        whois
        yq-go
        zstd
      ];
  };

  programs = {
    alacritty = {
      enable = true;
      settings = {
        working_directory = shellStartupDir;

        shell = {
          program = pkgs.lib.getExe pkgs.tmux;
          args = [
            "new-session"
            "-A"
            "-D"
            "-s"
            "main"
          ];
        };

        import = [
          "${pkgs.alacritty-theme}/material_theme.toml"
        ];

        window = {
          startup_mode = "Fullscreen";
          option_as_alt = "Both";
        };

        scrolling = {
          history = terminalScrollback;
        };

        keyboard = {
          bindings = [
            {
              # https://github.com/alacritty/alacritty/issues/474#issuecomment-338803299
              key = "Left";
              mods = "Alt";
              chars = "\\u001bb";
            }
            {
              # https://github.com/alacritty/alacritty/issues/474#issuecomment-338803299
              key = "Right";
              mods = "Alt";
              chars = "\\u001bf";
            }
            {
              # https://github.com/alacritty/alacritty/issues/474#issuecomment-338803299
              key = "Left";
              mods = "Command";
              chars = "\\u001bOH";
            }
            {
              # https://github.com/alacritty/alacritty/issues/474#issuecomment-338803299
              key = "Right";
              mods = "Command";
              chars = "\\u001bOF";
            }
          ];
        };

        selection = {
          save_to_clipboard = true;
        };

        font = {
          normal = {
            family = "FiraCode Nerd Font";
            style = "Regular"; # Default one is too thin
          };
          size = 22; # Going blind over here
        };
      };
    };

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

      tmux = {
        enableShellIntegration = false; # Kinda neat but doesn't put fzf where I want it
      };
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
        cl = "!f() { git clone \"$1\" $(echo \"$1\" | rg --only-matching --replace '$OWNER$REPO' '(?<OWNER>[\\w-]+/)?(?<REPO>[\\w-]+)(?:\.git)?$'); }; f"; # Sort into owner/repo format; tests: https://regex101.com/r/ll16aT/1
        cli = "clean --interactive";
        d = "diff";
        dog = "log --decorate --oneline --graph";
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
    };

    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
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

        custom = {
          sshagent = {
            # Convenience function to not be surprised by untimely password prompts.
            command = ''
              [[ $(ssh-add -L) =~ "no identities" ]] && echo '! 🔐 ssh agent vacant'
            '';
            when = true;
            style = "bold yellow";
            description = "Indicates whether any identites are represented by the ssh agent";
          };
        };
      };

    };

    tmux = {
      enable = true;

      baseIndex = 1; # Default of 0 is inconvenient
      historyLimit = terminalScrollback;
      mouse = true; # For scrolling easily

      extraConfig = ''
        # https://stackoverflow.com/a/45010147/11477374
        set-option -g status-interval 2
        set-option -g automatic-rename on
        set-option -g automatic-rename-format "#{?#{==:#{pane_current_command},zsh},#{b:pane_current_path},#{pane_current_command}}"
      '';
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

    zsh = {
      # Things like starship and fzf integration only start working if home-manager manages zsh.
      # While nix-darwin manages `/etc/zshrc`, home-manager manages `~/.zshrc`, and will source etc. there.
      enable = true;

      autosuggestion = {
        enable = true;
      };

      syntaxHighlighting = {
        enable = true;
      };

      initExtraBeforeCompInit = ''
        # zmodload zsh/zprof # Uncomment for `zprof`

        # Expand where zsh looks for completions.
        # This slows down shell startup massively (~200ms), even for simple completions (https://www.reddit.com/r/zsh/comments/wrbi1v/7x_slowdown_when_modify_fpath_and_add_completion/).
        # THAT'S TRUE EVEN IF THIS DIRECTORY IS EMPTY, which some tests showed.
        fpath+=(${zshCustomCompletions})

        # https://docs.docker.com/config/completion/#zsh
        # Do this dynamically to keep completions in sync. We're rocking Docker Desktop,
        # which isn't natively installable via Nix (which usually takes care of completions).
        docker completion zsh > ${zshCustomCompletions}/_docker # Not the cheapest call; ~20ms on warm cache

        for cmd in 'rustup' 'cargo'; do
          # `cargo` completions were actually already set up, but `rustup` weren't.
          # Just do both for consistency.
          rustup completions zsh "$cmd" > "${zshCustomCompletions}/_$cmd";
        done

        # More completions go here, in the form of `_some-command`...
        # Note: Nix will install most completions natively already.
      '';

      initExtra = ''
        test -f ${ssh.key.priv} || { ssh-keygen -t ${ssh.key.type} -f ${ssh.key.priv} && echo "Run \`ssh-keygen -c\` to set comment on new key"; }
        ssh-add -L | grep "$(cat ${ssh.key.pub})" || { echo -n "(Hit Return to skip) " && ssh-add -t '${ssh.agentDuration}' ${ssh.key.priv}; }

        wf() {
            # "`w`here `f`ile": which files contain the given regex?
            #
            # Can be used as `vim $(wf -i 'foo')` to open a file containing 'foo'
            # (case-insensitive).
            rg --files-with-matches "$@" | fzf
        }

        # Clone a user's personal (== non-fork) GitHub repositories and pull *all* branches.
        pullall() {
            gh auth status 1>/dev/null 2>&1 || gh auth login

            local USER="$1"

            gh repo list "$USER" --limit 1000 --source | while read -r repo _; do
                gh repo clone "$repo" "$repo" || (
                    cd "$repo"

                    for branch in 'main' 'master' 'dev' 'devel'; do
                        # Need to be on a branch to pull; first one found wins.
                        git switch "$branch" && break
                    done

                    git pull --all || echo "Failed to pull $repo"
                )
            done
        }

        # https://unix.stackexchange.com/a/100860
        bindkey '^[[A' history-beginning-search-backward
        bindkey '^[[B' history-beginning-search-forward

        setopt interactive_comments # Allow comments in interactive shell, to tag them for later search

        # `HOME` happens to send '^[[1~' and `END` '^[[4~' on my machine (no idea), see also
        # https://github.com/search?type=code&q=%27%5E%5B%5B1%7E%27 .
        # Found out via `command cat -v` and pressing the keys.
        bindkey '^[[1~' beginning-of-line
        bindkey '^[[4~' end-of-line

        # https://thevaluable.dev/zsh-completion-guide-examples/
        zstyle ':completion:*' menu select
        bindkey '^[[Z' reverse-menu-complete # Shift-Tab; https://unix.stackexchange.com/a/722487

        # Launch and `d`etach new window at `t`arget index, with specific `n`ame
        tmux list-windows -F '#W' | grep -q 'pi' || tmux new-window -d -n 'pi' -t 2 'ipython' || true

        # zprof # Uncomment for `zprof`
      '';

      envExtra = ''
        path+=("$(go env GOPATH)/bin")  # Target for 'go install'; for syntax, see also https://stackoverflow.com/a/18077919

        export WORDCHARS='-_' # Consider only these part of words (default is MUCH more); see also `man zshall | grep -C5 'WORDCHARS'`

        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#c787ee,bold' # Make it obnoxiously different; with a non-hex value, suggestions and actual insertions were the same color.

        # These were unset or "C" before, causing wrong Unicode processing and 'Unknown local' warnings.
        # From `man 7 locale`, it seems `LANG` and `LC_ALL` in combination suffice (`locale` now prints `en_US.UTF-8` for everything).
        export LANG="en_US.UTF-8"
        export LC_ALL="en_US.UTF-8"
      '';
      logoutExtra = ''
        echo "Running history backup"
        BACKUP_SRC=$HOME/.zsh_history # This breaks if ZDOTDIR != HOME
        BACKUP_DST=$HOME/Nextcloud/.backup/zsh_history/$(hostname)/.zsh_history # Excuse the hard-coding
        if [ -e "$BACKUP_SRC" ]; then
            mkdir -p "$(dirname $BACKUP_DST)"
            cp "$BACKUP_SRC" "$BACKUP_DST"
        fi
      '';

      shellAliases = {
        c = "cargo";
        d = "docker";
        cat = "bat";
        g = "git";
        j = "just";
        k = "kubectl";
        l = "eza --long --git --git-repos --header --all --all"; # `all` twice gives `.` and `..`
        m = "make";
        pi = "ipython";
        rr = "git rev-parse --show-toplevel 2>/dev/null || pwd"; # Get current git repo's root, if possible; can be used as `cd $(rr)`, `z `rr`` etc.
        tf = "terraform";
      };

      history = {
        extended = true;
        ignoreSpace = true; # True is default, but be extra sure. Relying on this for secrets
        size = 1000000;
      };
    };
  };
}
