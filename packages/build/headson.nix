{ pkgs }:

(pkgs.rustPlatform.buildRustPackage rec {
  pname = "headson";
  version = "0.11.4-patched";

  src = pkgs.fetchFromGitHub {
    owner = "alexpovel";
    repo = pname;
    rev = "a1a0e7dc3883b11f0ad48d6eea68adec68b76cfe";
    hash = "sha256-tSQGPRDS7j1l/hBBovNOs8DJl6t6rAS4NSGFe6yniDE="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-oDCvjkqq6dEiz1Pxj4mN17Z3t2Ul+KDFDZvjEnuceW4="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  # Tests rely on temporary files and on macOS, looks like they write to `$HOME`?
  # Failing test:
  # https://github.com/kantord/headson/blob/a15c1bdb6fc848ea562d3498a323946a772e595d/tests/fileset_ordering.rs#L80
  doCheck = false;

  nativeBuildInputs = [
    pkgs.installShellFiles
    pkgs.perl # git2 dependency builds openssl (unnecessarily) which needs perl
  ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd hson "--$shell" <("$out/bin/hson" --completions "$shell")
    done
  '';
})
