{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  pname = "starship-jj";
  version = "0.4.1";

  src = pkgs.fetchFromGitLab {
    owner = "lanastara_foss";
    repo = pname;
    rev = version;
    hash = "sha256-gV0YerQrOt15Z781pg5dPnkZqxyXV8KP8zlzU5wC5SI="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-Fm3RHNPdq9SIt6wFRlPWTTyCrfaDAAdLp96rC53H4lI="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd starship-jj "--$shell" <("$out/bin/starship-jj" util completion "$shell")
    done
  '';
})
