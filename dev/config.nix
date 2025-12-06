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

      # Checks
      checks = {
        # nix-unit tests for flake-compat
        nix-unit =
          pkgs.runCommand "nix-unit-tests"
            {
              nativeBuildInputs = [ pkgs.nix-unit ];
            }
            ''
              # Run nix-unit tests on the flake-compat default.nix
              export HOME=$TMPDIR
              nix-unit --eval-store "$HOME" ${../.}/tests.nix 2>&1 | tee $out

              # Check if there were any failures
              if grep -q "FAIL" $out; then
                echo "Tests failed!"
                exit 1
              fi

              echo "All tests passed!"
            '';
      };

      # Development shell
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          config.treefmt.build.wrapper
          pkgs.nix-unit
        ];

        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };

      # Formatter package
      formatter = config.treefmt.build.wrapper;
    };
}
