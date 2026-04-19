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

        # Integration test: submodule content is accessible through flake-compat
        submodules =
          pkgs.runCommand "submodule-test"
            {
              nativeBuildInputs = [
                pkgs.git
                pkgs.nix
              ];
            }
            ''
              export HOME=$TMPDIR
              git config --global user.email "test@test"
              git config --global user.name "test"
              git config --global protocol.file.allow always

              # Create a repo to use as a submodule
              mkdir -p $TMPDIR/sub
              cd $TMPDIR/sub
              git init
              echo "hello from submodule" > sub-file.txt
              git add . && git commit -m "init sub"

              # Invoke flake-compat using an alternative store so this
              # works in sandboxed builds on both Linux and darwin.
              export NIX_STORE_DIR=$TMPDIR/store
              export NIX_STATE_DIR=$TMPDIR/state

              # Without inputs.self.submodules, submodule content should
              # not be accessible.
              mkdir -p $TMPDIR/main-no-sub
              cd $TMPDIR/main-no-sub
              git init
              git submodule add $TMPDIR/sub sub
              cat > flake.nix << 'EOF'
              {
                outputs = { self, ... }: {
                  subFileExists = builtins.pathExists (self + "/sub/sub-file.txt");
                };
              }
              EOF
              git add . && git commit -m "init main-no-sub"

              result=$(nix-instantiate --eval --strict --expr '
                let
                  r = import ${../.} { src = '"$TMPDIR/main-no-sub"'; };
                in
                r.defaultNix.subFileExists
              ')

              if [ "$result" = "false" ]; then
                echo "PASS: submodule content not accessible without flag"
              else
                echo "FAIL: expected false, got: $result"
                exit 1
              fi

              # With inputs.self.submodules = true, submodule content
              # should be accessible.
              mkdir -p $TMPDIR/main
              cd $TMPDIR/main
              git init
              git submodule add $TMPDIR/sub sub
              cat > flake.nix << 'EOF'
              {
                inputs.self.submodules = true;
                outputs = { self, ... }: {
                  subFileExists = builtins.pathExists (self + "/sub/sub-file.txt");
                  subFileContent = builtins.readFile (self + "/sub/sub-file.txt");
                };
              }
              EOF
              git add . && git commit -m "init main"

              result=$(nix-instantiate --eval --strict --expr '
                let
                  r = import ${../.} { src = '"$TMPDIR/main"'; };
                in
                r.defaultNix.subFileContent
              ')

              if [ "$result" = '"hello from submodule\n"' ]; then
                echo "PASS: submodule content accessible"
              else
                echo "FAIL: expected submodule content, got: $result"
                exit 1
              fi

              touch $out
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
