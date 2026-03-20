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
          openssl
        ];

        gst_plugins = with pkgs.gst_all_1; [
          gstreamer
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
        ];

        buildTools =
          with pkgs;
          [
            pkg-config
            cargo-tauri
            rust-bin.stable.latest.default
          ]
          ++ gst_plugins;
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = buildTools;
          buildInputs = libraries;

          shellHook = ''
            # We tell GStreamer exactly where the plugins are in the Nix store
            export GST_PLUGIN_SYSTEM_PATH_1_0="${
              pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gst_plugins
            }"

            export XDG_DATA_DIRS="$GSETTINGS_SCHEMAS_PATH:$XDG_DATA_DIRS"
          '';
        };
      }
    );
}
