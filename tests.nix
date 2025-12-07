# Tests for flake-compat
# Run with:
#   nix-unit ./tests.nix
#   or: nix build ./dev#checks.<system>.nix-unit
{
  # Test that the main function can be imported
  testImport = {
    expr = builtins.isFunction (import ./default.nix);
    expected = true;
  };

  # Test that calling with minimal arguments produces an attrset
  testBasicCall =
    let
      result = import ./default.nix {
        src = ./.;
        system = "x86_64-linux";
      };
    in
    {
      expr = builtins.isAttrs result;
      expected = true;
    };

  # Test that result has expected attributes
  testHasOutputs =
    let
      result = import ./default.nix {
        src = ./.;
        system = "x86_64-linux";
      };
    in
    {
      expr = result ? outputs;
      expected = true;
    };

  # Test that result has defaultNix
  testHasDefaultNix =
    let
      result = import ./default.nix {
        src = ./.;
        system = "x86_64-linux";
      };
    in
    {
      expr = result ? defaultNix;
      expected = true;
    };

  # Test that result has shellNix
  testHasShellNix =
    let
      result = import ./default.nix {
        src = ./.;
        system = "x86_64-linux";
      };
    in
    {
      expr = result ? shellNix;
      expected = true;
    };
}
