{
  description = "An overlay for the Ricty font";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.default ];
        }
      );
    in
    {
      overlays = {
        excludeRictyDiscord = final: prev: {
          ricty = prev.ricty.overrideAttrs (oldAttrs: {
            patchPhase =
              ''
                sed -i \
                  -e '/^\$fontforge_command.*discord/,/exit 4/s/^/# /' \
                  -e '/^\$fontforge_command.*regular2oblique_converter/N;/^\$fontforge_command.*Discord.*ttf/,/exit 4/{s/^/# /;s/\n/\n# /}' \
                  ricty_generator.sh
              ''
              + oldAttrs.patchPhase;
          });
        };

        # An overlay to adjust xAvgCharWidth to solve the problem
        # where characters are displayed too wide in Windows.
        adjustXAvgCharWidth = final: prev: {
          ricty = prev.ricty.overrideAttrs (oldAttrs: {
            buildInputs = oldAttrs.buildInputs ++ [
              final.python312Packages.fonttools
            ];

            buildPhase =
              oldAttrs.buildPhase
              + ''
                ttx -t 'OS/2' Ricty-*.ttf
                for f in Ricty-*.ttx; do
                  sed -i 's/^\(\s\+<xAvgCharWidth\s\+value="\)[0-9]\+\(".*\)$/\1500\2/g' "$f"
                  mv "''${f%.ttx}.ttf" "''${f%.ttx}-orig.ttf"
                  ttx -m "''${f%.ttx}-orig.ttf" "$f" -o "''${f%.ttx}.ttf"
                done
                rm *-orig.ttf
              '';
          });
        };

        default =
          final: prev:
          prev.lib.composeManyExtensions (builtins.attrValues (
            builtins.removeAttrs self.overlays [ "default" ]
          )) final prev;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.ricty;
        }
      );
    };
}
