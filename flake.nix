{
  description = "Allow flakes to be used with Nix < 2.4";

  outputs =
    { self, ... }:
    let
      # Currently none (`import flake-compat`)
      # TODO: add `lib`.
      publicOutputs = { };

      # TODO: use clean library entrypoint when that's factored out.
      devDeps =
        (import ./default.nix {
          src = ./dev/deps;
        }).defaultNix.inputs;

      devInputs = devDeps // {
        self = self // {
          inputs = devInputs;
        };
      };

      devOutputs = devInputs.flake-parts.lib.mkFlake {
        inputs = devInputs;
      } ./dev/config.nix;

      allOutputs = publicOutputs // {
        # Use explicit inherit, to ensure allOutputs is evaluated without
        # evaluating devOutputs.
        inherit (devOutputs) devShells checks formatter;
      };
    in
    allOutputs;
}
