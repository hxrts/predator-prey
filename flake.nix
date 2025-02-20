{
  description = "Simple PureScript application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    purescript-overlay = {
      url = "github:thomashoneyman/purescript-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, purescript-overlay }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ purescript-overlay.overlays.default ];
      });
    in {
      devShells = forAllSystems (system:
        let 
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              purs
              spago-bin.spago-0_93_9
              nodejs_20
              nodePackages.npm
              nodePackages.http-server
              esbuild
              purescript-language-server
              purs-tidy
              purs-backend-es
            ];
            shellHook = ''
              source scripts/dev.sh
            '';
          };
        });
    };
} 