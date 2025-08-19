{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  pname = "starship-jj";
  version = "0.5.1";

  src = pkgs.fetchFromGitLab {
    owner = "lanastara_foss";
    repo = pname;
    rev = version;
    hash = "sha256-ZF0j5vL9CHXCoHT8Vj4X9cRVgS+t2pRZolhWp7gszps="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-+rLejMMWJyzoKcjO7hcZEDHz5IzKeAGk1NinyJon4PY="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd starship-jj "--$shell" <("$out/bin/starship-jj" util completion "$shell")
    done
  '';
})
