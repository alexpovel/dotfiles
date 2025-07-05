{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  # See also https://github.com/NixOS/nixpkgs/pull/293076, adjusted here
  pname = "srgn";
  version = "srgn-v0.14.0";

  src = pkgs.fetchFromGitHub {
    owner = "alexpovel";
    repo = pname;
    rev = version;
    hash = "sha256-ZWjpkClhac4VD4b/Veffb5FHGvh+oeTu3ukaOux6MG0="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-d/wFD0kxWNOsYaY4G5P9iM85dSo0UZGSte5AqOosM2g="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd srgn "--$shell" <("$out/bin/srgn" --completions "$shell")
    done
  '';
})
