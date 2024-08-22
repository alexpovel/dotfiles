{ pkgs }:

(pkgs.rustPlatform.buildRustPackage
rec {
  # See also https://github.com/NixOS/nixpkgs/pull/293076, adjusted here
  pname = "srgn";
  version = "srgn-v0.13.1";

  src = pkgs.fetchFromGitHub {
    owner = "alexpovel";
    repo = pname;
    rev = version;
    hash = "sha256-KG5y5V+IWIAlFULnJEomNF2Q/jyKHSSJ6o83J6vlP8w="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-Zi5QIFInh/pBLAQ8l+mqRMZlcrCT2zLPOArqtdmruYI="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    for shell in bash zsh fish; do
      installShellCompletion --cmd srgn "--$shell" <("$out/bin/srgn" --completions "$shell")
    done
  '';
}
)
