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
  srgn = import ./../build/srgn.nix {
    inherit pkgs;
  };
in
[
  ansible
  ansible-lint
  bat
  cargo-flamegraph
  cargo-insta
  cargo-msrv
  cargo-tarpaulin
  cargo-udeps
  cue
  curl
  dig
  duckdb
  erdtree
  eza
  fastgron
  ffmpeg
  gh
  git-url-extract-path
  gnumake
  gnuplot
  golangci-lint
  graphviz
  hexyl
  hyperfine
  imagemagick
  inetutils # telnet, ping, traceroute, whois
  inkscape
  jd-diff-patch
  jq
  kubectl
  kubernetes-helm
  lua
  ncdu
  nil
  nix-direnv
  nixd
  nixfmt-rfc-style
  nmap
  nodejs
  pandoc
  panicparse
  postgresql
  pre-commit
  python
  rclone
  rsync
  shellcheck
  shfmt
  sqlite
  srgn
  tokei
  typescript
  typst
  uv
  wget
  whois
]
