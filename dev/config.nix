# https://flake.parts/options/flake-parts.html
{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  imports = [
    inputs.git-hooks.flakeModule
    inputs.nix-unit.modules.flake.default
    inputs.treefmt-nix.flakeModule
  ];

  # https://flake.parts/options/flake-parts.html#opt-perSystem
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {

      # Formatting configuration
      # https://flake.parts/options/treefmt-nix.html
      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
        };

        settings.formatter = {
          deadnix = {
            priority = 1;
          };
        };
      };

      # Pre-commit hooks
      # https://flake.parts/options/git-hooks-nix.html
      pre-commit = {
        check.enable = true;

        settings.hooks = {
          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
        };
      };

      # Nix-unit tests
      # https://flake.parts/options/nix-unit.html
      nix-unit = {
        allowNetwork = true;
        tests = import ../tests.nix;
      };

      # Development shell
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          config.nix-unit.package
          config.treefmt.build.wrapper
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };

      # Formatter package
      formatter = config.treefmt.build.wrapper;
    };
}
