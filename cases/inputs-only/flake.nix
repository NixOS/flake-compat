{
  inputs.flake-compat.url = "github:NixOS/flake-compat";
  outputs = _inputs: throw "Outputs shouldn't be evaluated!";
}
