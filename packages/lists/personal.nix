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
  hexyl
  jq
  keep-sorted
  mergiraf
  ncdu
  nil
  nix-direnv
  nixd
  nixfmt
  numbat
  python
  restic
  shellcheck
  shfmt
  sops
  tokei
  uv
  whois
  # keep-sorted end
]
++ [
  # keep-sorted start
  u.cue
  u.srgn
  # keep-sorted end
]
