{ pkgs }:

(pkgs.rustPlatform.buildRustPackage
rec {
  # See also https://github.com/NixOS/nixpkgs/pull/293076, adjusted here
  pname = "srgn";
  version = "srgn-v0.13.3";

  src = pkgs.fetchFromGitHub {
    owner = "alexpovel";
    repo = pname;
    rev = version;
    hash = "sha256-JjO4ZH4CYu2qwYfUrwTASYuxyBjObLb9ydPPbObew0g="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-arM7N6gX3QfyRCFgoHBTzcLwv69XBxNXG4+rYdX4vAg="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd srgn "--$shell" <("$out/bin/srgn" --completions "$shell")
    done
  '';
}
)
