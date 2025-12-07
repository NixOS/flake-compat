{
  description = "Allow flakes to be used with Nix < 2.4";

  outputs =
    { self, ... }:
    let
      allOutputs = publicOutputs // {
        # Use explicit inherit, to ensure allOutputs is evaluated without
        # evaluating devOutputs.
        inherit (devOutputs) devShells checks formatter;
      };

      # Currently none (`import flake-compat`)
      # TODO: add `lib`.
      publicOutputs = { };

      devOutputs = devInputs.flake-parts.lib.mkFlake {
        inputs = devInputs;
      } ./dev/config.nix;
      devInputs = devDeps // {
        self = self // {
          inputs = devInputs;
        };
      };
      # TODO: use clean library entrypoint when that's factored out.
      devDeps =
        (import ./default.nix {
          src = ./dev/deps;
        }).defaultNix.inputs;
    in
    allOutputs;
}
