{ pkgs }:

with pkgs;
let
  git-url-extract-path = import ./../build/git-url-path-extract.nix {
    inherit (pkgs) writers;
  };
  gcloud = (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ]);
  lua = (luajit.withPackages (p: with p; [
    luacheck
    luaunit
    luarocks
    luazstd
  ]));
  luazstd = import ./../build/lua-zstd.nix {
    inherit (pkgs) fetchFromGitHub fetchurl zstd;
    inherit (pkgs.luajitPackages) buildLuarocksPackage luaOlder;
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
  curl
  dig
  erdtree
  exiftool
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
  htop
  hyperfine
  imagemagick
  inetutils # telnet, ping, traceroute, whois
  inkscape
  jq
  just
  kubectl
  kubernetes-helm
  lua
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
  postgresql
  pre-commit
  python
  rclone
  rsync
  rustup
  shellcheck
  sqlite
  srgn
  tldr
  tokei
  typescript
  typst
  wget
  whois
]
