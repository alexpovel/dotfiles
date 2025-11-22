{ pkgs }:

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
        pandas
        pint
      ]
    )
  );
  starship-jj = import ./../build/starship-jj.nix {
    inherit pkgs;
  };
in
[
  # keep-sorted start
  age
  bat
  cargo-flamegraph
  cargo-insta
  cargo-msrv
  cargo-tarpaulin
  cargo-udeps
  cargo-watch
  cue
  curl
  difftastic
  dig
  erdtree
  eza
  ffmpeg
  git-url-extract-path
  gnumake
  golangci-lint
  gotools
  graphviz
  hexyl
  imagemagick
  inetutils # telnet, ping, traceroute, whois
  inkscape
  jq
  keep-sorted
  kubectl
  mergiraf
  ncdu
  nil
  nix-direnv
  nixd
  nixfmt-rfc-style
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
  srgn
  starship-jj
  testssl
  tldr
  tokei
  typescript
  uv
  watchman
  whois
  # keep-sorted end
]
