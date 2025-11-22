# Compatibility function to allow flakes to be used by
# non-flake-enabled Nix versions. Given a source tree containing a
# 'flake.nix' and 'flake.lock' file, it fetches the flake inputs and
# calls the flake's 'outputs' function. It then returns an attrset
# containing 'defaultNix' (to be used in 'default.nix'), 'shellNix'
# (to be used in 'shell.nix').

{
  src,
  system ? builtins.currentSystem or "unknown-system",
}:

let
  inherit (import ./lib.nix) cleanRootSrc resolveNodes callLocklessFlake callFlake4;

  lockFilePath = src + "/flake.lock";

  lockFile = builtins.fromJSON (builtins.readFile lockFilePath);

  rootSrc = cleanRootSrc src;

  allNodes = resolveNodes {
    inherit (lockFile) nodes root;
    inherit rootSrc;
  };

  result =
    if !(builtins.pathExists lockFilePath) then
      callLocklessFlake rootSrc
    else if lockFile.version == 4 then
      callFlake4 rootSrc (lockFile.inputs)
    else if lockFile.version >= 5 && lockFile.version <= 7 then
      allNodes.${lockFile.root}.result
    else
      throw "lock file '${lockFilePath}' has unsupported version ${toString lockFile.version}";

in
rec {
  outputs = result;

  defaultNix =
    builtins.removeAttrs result [ "__functor" ]
    // (
      if result ? defaultPackage.${system} then { default = result.defaultPackage.${system}; } else { }
    )
    // (
      if result ? packages.${system}.default then
        { default = result.packages.${system}.default; }
      else
        { }
    );

  shellNix =
    defaultNix
    // (if result ? devShell.${system} then { default = result.devShell.${system}; } else { })
    // (
      if result ? devShells.${system}.default then
        { default = result.devShells.${system}.default; }
      else
        { }
    );
}
