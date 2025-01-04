{ pkgs }:

with pkgs;
let
  git-url-extract-path = import ./../build/git-url-path-extract.nix {
    inherit (pkgs) writers;
  };
  python = (python3.withPackages (p: with p; [
    httpx
    (httpx-auth.overridePythonAttrs (old: {
      doCheck = false;
    }))
    ipython
    pandas
    pint
  ]));
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
  cmake
  cue
  curl
  dig
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
  jq
  kubectl
  kubernetes-helm
  lua
  ncdu
  nil
  nix-direnv
  nixpkgs-fmt
  nmap
  nodejs
  pandoc
  postgresql
  pre-commit
  python
  rclone
  rsync
  rustup
  shellcheck
  sqlite
  srgn
  tokei
  typescript
  typst
  wget
  whois
]
