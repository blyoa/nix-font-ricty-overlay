# nix-font-ricty-overlay

A Nix flake that provides overlays for customizing the [Ricty](https://rictyfonts.github.io/) font.

## Features

- Excludes Ricty Discord font variants from the build process
- Adjusts xAvgCharWidth for better character display in Windows

## Example Usage

You can use overlays in flake.nix as follows:

```nix
{
  description = "Example configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ricty-font-overlay = {
      url = "github:blyoa/nix-font-ricty-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ricty-font-overlay,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              # Apply all features of this overlay
              ricty-font-overlay.overlays.default

              # or use specific overlays individually
              # ricty-font-overlay.overlays.excludeRictyDiscord
              # ricty-font-overlay.overlays.adjustXAvgCharWidth
            ];
          };
        in
        {
          # You can built the customized Ricty font with `nix build`
          default = pkgs.ricty;
        }
      );
    };
}
```

## Available Overlays

### `excludeRictyDiscord`

Removes the Ricty Discord font variants from the build process.

### `adjustXAvgCharWidth`

Modifies the `xAvgCharWidth` value in the font files to improve character width display on Windows.
