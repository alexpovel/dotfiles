{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  pname = "starship-jj";
  version = "0.7.0";

  src = pkgs.fetchFromGitLab {
    owner = "lanastara_foss";
    repo = pname;
    rev = version;
    hash = "sha256-EgOKjPJK6NdHghMclbn4daywJ8oODiXkS48Nrn5cRZo="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-NNeovW27YSK/fO2DjAsJqBvebd43usCw7ni47cgTth8="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd starship-jj "--$shell" <("$out/bin/starship-jj" util completion "$shell")
    done
  '';
})
