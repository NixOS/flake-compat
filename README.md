# flake-compat

A compatibility shim to use Nix flakes with versions of Nix that don't have native flake support.

Given a source tree containing `flake.nix` and `flake.lock`, it fetches the flake inputs and calls the flake's `outputs` function. This allows you to use flake-based projects with:

- Stable Nix without `experimental-features = nix-command flakes`
- Nix versions before 2.4 (insecure, please upgrade)
- Tooling that doesn't support flakes natively

The flake-compat function returns
- `defaultNix` for use in `default.nix`,
- `shellNix` for `shell.nix`) attributes,
- `outputs` for simple access to the flake outputs.

This project was originally at `edolstra/flake-compat` and is now maintained at `NixOS/flake-compat`.

## Usage

To use, add the following to your `flake.nix`:

```nix
inputs.flake-compat = {
  url = "github:NixOS/flake-compat";
  flake = false;
};
```

Afterwards, create a `default.nix` file containing the following:

```nix
(import
  (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      nodeName = lock.nodes.root.inputs.flake-compat;
    in
    fetchTarball {
      url = lock.nodes.${nodeName}.locked.url or "https://github.com/NixOS/flake-compat/archive/${lock.nodes.${nodeName}.locked.rev}.tar.gz";
      sha256 = lock.nodes.${nodeName}.locked.narHash;
    }
  )
  { src = ./.; }
).defaultNix
```

If you would like a `shell.nix` file, create one containing the above, replacing `defaultNix` with `shellNix`.

You can access any flake output via the `outputs` attribute returned by `flake-compat`, e.g.

```nix
(import ... { src = ./.; }).outputs.packages.x86_64-linux.default
```

## Contributing

Improvements are welcomed. Some tips to make that a success:

- Check the issue tracker.

- Chat in the [Nix Package Manager development](https://matrix.to/#/#nix-dev:nixos.org) matrix channel.

- We're writing a test suite, `tests.nix`.
  Science shows that PRs with tests are more likely to be merged!

- Update the documentation.

## Support the project

`flake-compat` is part of the Nix/NixOS community, which is supported by the NixOS Foundation.

Here's how you can [help out financially](https://nixos.org/donate/).
