{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        lf2-app = pkgs.callPackage ./package.nix {
          rustPlatform = pkgs.makeRustPlatform {
            cargo = pkgs.rust-bin.stable.latest.default;
            rustc = pkgs.rust-bin.stable.latest.default;
          };
        };
      in
      {
        packages.default = lf2-app;

        devShells.default = pkgs.mkShell {
          inputsFrom = [ lf2-app ];
          packages = with pkgs; [
            cargo-edit # For 'cargo add'
          ];

          shellHook = ''
            echo "🛡️ LF2 Development Environment Loaded"
            # Your GStreamer and XDG fixes go here
            export GST_PLUGIN_SYSTEM_PATH_1_0="${
              pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" lf2-app.buildInputs
            }"
          '';
        };
      }
    );
}
