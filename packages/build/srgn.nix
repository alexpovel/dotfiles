{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  # See also https://github.com/NixOS/nixpkgs/pull/293076, adjusted here
  pname = "srgn";
  version = "srgn-v0.13.7";

  src = pkgs.fetchFromGitHub {
    owner = "alexpovel";
    repo = pname;
    rev = version;
    hash = "sha256-JHO++d25UmYgTuSOvkZaF0rkab8B6XetHcoEchpLimk="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-H0LBH8nd/uyFufrUWVyNZjn9AKJcAlsv3UVuXoM7ZGM="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd srgn "--$shell" <("$out/bin/srgn" --completions "$shell")
    done
  '';
})
