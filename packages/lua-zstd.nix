# Built up from output of `nix-shell -p luarocks-nix --command 'luarocks nix lua-zstd'`
{
  buildLuarocksPackage, fetchFromGitHub, fetchurl, zstd, luaOlder
}:

buildLuarocksPackage {
  pname = "lua-zstd";
  version = "0.2.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/lua-zstd-0.2.0-1.rockspec";
    sha256 = "04xxjjxbp1anm9ifngd7k3lxyddclsnampzk3vk2h5cb8iijpkvv";
  }).outPath;

  src = fetchFromGitHub {
    owner = "neoxic";
    repo = "lua-zstd";
    rev = "0.2.0";
    hash = "sha256-7tYTYZe1rb6PfHY96d2icoe22YhHT1FitHA+yue3YMk=";
  };

  # `zstd` is a multiple-output package
  # (https://nixos.org/manual/nixpkgs/stable/#chap-multiple-output). It exposes `dev`
  # and `out` as attributes; by default, the rocks installation looks in the `bin`
  # output directory, where it won't find the headers and libraries. Set these here to
  # hook into the luarocks process
  # (https://github.com/luarocks/luarocks/wiki/Config-file-format#variables). Use
  # `nix-index` with `nix-locate` to find paths if ever in doubt, e.g. `nix-locate
  # zstd.h` (which rocks complained it couldn't find).
  extraConfig = ''
    variables.ZSTD_INCDIR="${zstd.dev}/include"
    variables.ZSTD_LIBDIR="${zstd.out}/lib"
  '';

  disabled = luaOlder "5.1";

  meta = {
    homepage = "https://github.com/neoxic/lua-zstd";
    description = "Zstandard module for Lua";
    license.fullName = "MIT";
  };
}
