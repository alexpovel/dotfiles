{ pkgs }:

(pkgs.rustPlatform.buildRustPackage
rec {
  # See also https://github.com/NixOS/nixpkgs/pull/293076, adjusted here
  pname = "srgn";
  version = "srgn-v0.12.0";

  src = pkgs.fetchFromGitHub {
    owner = "alexpovel";
    repo = pname;
    rev = version;
    hash = "sha256-d53aSo1gzINC8WdMzjCHzU/8+9kvrrGglV4WsiCt+rM="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
  };

  cargoHash = "sha256-NSP/AwghyLfaZjQ/tUv8pSbxgD6Kf12In9UdXnRLE0I="; # On update: replace w/ `pkgs.lib.fakeHash`, run, let it fail and take hash from error message
}
)
