{ config, pkgs, ... }:

let
  # Found this out debugging and digging with `builtins.trace (pkgs.lib.attrNames config)`. No idea where `config.home` comes from.
  home = config.home.homeDirectory;
  shellStartupDir = "${home}/Code";

  zshCustomCompletionsRelToHome = ".zsh_custom_completions";
  zshCustomCompletions = "${home}/${zshCustomCompletionsRelToHome}";

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
        # Make it obnoxiously different; with a non-hex value, suggestions and actual
        # insertions were the same color.
        highlight = "fg=#c787ee,bold";
        strategy = [
          "history"
          "completion"
        ];
      };

      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
        ];
      };

      plugins = [
        {
          # Get some more native completions (e.g. `go` command). See list at
          # https://github.com/zsh-users/zsh-completions/tree/master/src
          name = "zsh-completions";
          src = "${pkgs.zsh-completions}/share/zsh/site-functions";
        }
      ];

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

        setopt interactive_comments # Allow comments in interactive shell, to tag them for later search

        # `HOME` happens to send '^[[1~' and `END` '^[[4~' on my machine (no idea), see also
        # https://github.com/search?type=code&q=%27%5E%5B%5B1%7E%27 .
        # Found out via `command cat -v` and pressing the keys.
        bindkey '^[[1~' beginning-of-line
        bindkey '^[[4~' end-of-line

        # https://thevaluable.dev/zsh-completion-guide-examples/
        zstyle ':completion:*' menu select
        bindkey '^[[Z' reverse-menu-complete # Shift-Tab; https://unix.stackexchange.com/a/722487

        # zprof # Uncomment for `zprof`
      '';

      envExtra = ''
        path+=("$(go env GOPATH)/bin")  # Target for 'go install'; for syntax, see also https://stackoverflow.com/a/18077919

        export WORDCHARS='-_' # Consider only these part of words (default is MUCH more); see also `man zshall | grep -C5 'WORDCHARS'`

        export HISTORY_SUBSTRING_SEARCH_FUZZY=1 # Fuzzy search in history
        export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1 # Don't show duplicates
        export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_TIMEOUT=2 # Highlight matches for 2 seconds

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

      historySubstringSearch = {
        enable = true;
      };
    };
  };
}
