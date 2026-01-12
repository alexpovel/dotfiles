{ pkgs, pkgs-unstable }:

with pkgs;
let
  git-url-extract-path = import ./../build/git-url-path-extract.nix {
    inherit (pkgs) writers;
  };
  python = (
    python313.withPackages (
      p: with p; [
        httpx
        httpx-auth
        ipython
        matplotlib
      ]
    )
  );
  headson = import ./../build/headson.nix {
    inherit pkgs;
  };
  u = pkgs-unstable;
in
[
  # keep-sorted start
  age
  bat
  curl
  difftastic
  dig
  erdtree
  eza
  git-url-extract-path
  gnumake
  golangci-lint
  gotools
  graphviz
  headson
  hexyl
  imagemagick
  inetutils # telnet, ping, traceroute, whois
  jq
  keep-sorted
  kubectl
  mergiraf
  ncdu
  nil
  nix-direnv
  nixd
  nixfmt
  nmap
  nodejs
  numbat
  python
  rclone
  restic
  rsync
  shellcheck
  shfmt
  sops
  sqlite
  testssl
  tokei
  typescript
  uv
  watchman
  whois
  # keep-sorted end
]
++ [
  # keep-sorted start
  u.cue
  u.srgn
  # keep-sorted end
]
