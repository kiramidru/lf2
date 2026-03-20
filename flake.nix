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

        libraries = with pkgs; [
          webkitgtk_4_1
          librsvg
          gtk3
          libsoup_3
          glib
          at-spi2-atk
          pango
          gdk-pixbuf
          cairo
        ];

        buildTools = with pkgs; [
          pkg-config
          cargo-tauri
          rust-bin.stable.latest.default
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = buildTools;
          buildInputs = libraries;
          shellHook = ''
            export GST_PLUGIN_SYSTEM_PATH_1_0="${
              pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" libraries
            }"
          '';
        };
      }
    );
}
