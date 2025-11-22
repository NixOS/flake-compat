{
  description = "Allow flakes to be used with Nix < 2.4";

  outputs = _: {
    lib = import ./lib.nix;
  };
}
