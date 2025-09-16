{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  pname = "starship-jj";
  version = "0.6.0";

  src = pkgs.fetchFromGitLab {
    owner = "lanastara_foss";
    repo = pname;
    rev = version;
    hash = "sha256-HTkDZQJnlbv2LlBybpBTNh1Y3/M8RNeQuiked3JaLgI="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-E5z3AZhD3kiP6ojthcPne0f29SbY0eV4EYTFewA+jNc="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd starship-jj "--$shell" <("$out/bin/starship-jj" util completion "$shell")
    done
  '';
})
