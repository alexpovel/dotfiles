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
  ansible
  ansible-lint
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
  gotools
  graphviz
  hexyl
  hyperfine
  imagemagick
  inetutils # telnet, ping, traceroute, whois
  inkscape
  jd-diff-patch
  jq
  keep-sorted
  kubectl
  kubernetes-helm
  lua
  mergiraf
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
  sops
  sqlite
  srgn
  starship-jj
  tokei
  typescript
  typst
  uv
  watchman
  wget
  whois
  # keep-sorted end
]
