{
  description = "Rust Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/fbcf476f790d8a217c3eab4e12033dc4";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
    rust-overlay.url = "github:oxalica/rust-overlay/292ca754b0f679b842fbfc4734f017c351f0e9eb";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        gst-plugins = with pkgs.gst_all_1; [
          gstreamer
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
        ];

        rust = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "x86_64-unknown-linux-gnu" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rust
            pkgs.rust-analyzer
            pkgs.clippy
            pkgs.rustfmt
            pkgs.librsvg
            pkgs.webkitgtk_4_1
          ]
          ++ gst-plugins;

          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook4
            cargo
            cargo-tauri
            nodejs
          ];

          shellHook = ''
            # Fix for GStreamer plugins on NixOS
            export GST_PLUGIN_SYSTEM_PATH_1_0="${
              pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gst-plugins
            }"

            # Keep your existing Wayland fix
            export XDG_DATA_DIRS="$GSETTINGS_SCHEMAS_PATH:$XDG_DATA_DIRS"
          '';
        };
      }
    );
}
