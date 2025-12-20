{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  pname = "headson";
  version = "0.11.5";

  src = pkgs.fetchFromGitHub {
    owner = "kantord";
    repo = pname;
    rev = "headson-v${version}";
    hash = "sha256-zR3Fmv4UQ2uLG6bdrtf3qIcV1wvHIbnH3cItWrY5R9o="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-+OiqYOpHf8Gdx6Q7Qi8p+5xjMT3sujtcIosIIxGDWnQ="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [
    pkgs.installShellFiles
  ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd hson "--$shell" <("$out/bin/hson" --completions "$shell")
    done
  '';
})
