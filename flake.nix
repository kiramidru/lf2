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
    let
      # Systems that support the package (Linux only due to GTK/WebKit)
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      # Overlay that can be used by other flakes
      overlay = final: prev: {
        lf2 = self.packages.${final.system}.default;
      };

      # Helper to create package/app outputs for Linux systems only
      linuxOutputs = flake-utils.lib.eachSystem supportedSystems (
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

          # The lf2 package
          lf2 = pkgs.rustPlatform.buildRustPackage {
            pname = "lf2";
            version = "0.1.0";

            src = ./.;

            cargoLock = {
              lockFile = ./src-tauri/Cargo.lock;
            };

            # Build from src-tauri directory
            buildAndTestSubdir = "src-tauri";

            nativeBuildInputs = with pkgs; [
              pkg-config
              cargo-tauri
              wrapGAppsHook3
              copyDesktopItems
            ];

            buildInputs = libraries ++ gst_plugins ++ (with pkgs; [
              glib
              gsettings-desktop-schemas
            ]);

            # Tauri needs the frontend dist during build
            preBuild = ''
              # Ensure dist folder exists for tauri build
              mkdir -p dist
              cp -r ${./dist}/* dist/
            '';

            # Use cargo-tauri to build
            buildPhase = ''
              runHook preBuild

              export HOME=$(mktemp -d)
              cd src-tauri
              cargo tauri build --bundles none

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              # Install binary
              mkdir -p $out/bin
              cp target/release/lf2 $out/bin/

              # Install desktop file
              mkdir -p $out/share/applications
              cat > $out/share/applications/lf2.desktop << EOF
              [Desktop Entry]
              Name=LF2 Remake
              Comment=Little Fighter 2 Remake
              Exec=lf2
              Icon=lf2
              Terminal=false
              Type=Application
              Categories=Game;
              EOF

              # Install icons
              mkdir -p $out/share/icons/hicolor/32x32/apps
              mkdir -p $out/share/icons/hicolor/128x128/apps
              mkdir -p $out/share/icons/hicolor/256x256/apps

              cp icons/32x32.png $out/share/icons/hicolor/32x32/apps/lf2.png
              cp icons/128x128.png $out/share/icons/hicolor/128x128/apps/lf2.png
              cp "icons/128x128@2x.png" $out/share/icons/hicolor/256x256/apps/lf2.png

              runHook postInstall
            '';

            # Set up GStreamer plugin path at runtime
            preFixup = ''
              gappsWrapperArgs+=(
                --set GST_PLUGIN_SYSTEM_PATH_1_0 "${pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gst_plugins}"
              )
            '';

            meta = with pkgs.lib; {
              description = "Little Fighter 2 Remake - A Tauri Application";
              homepage = "https://github.com/your-username/lf2";
              license = licenses.mit;
              maintainers = [ ];
              platforms = platforms.linux;
              mainProgram = "lf2";
            };
          };
        in
        {
          packages = {
            default = lf2;
            lf2 = lf2;
          };

          apps.default = {
            type = "app";
            program = "${lf2}/bin/lf2";
          };
        }
      );

      # DevShells for supported systems only (needs Linux GTK/WebKit)
      devShellOutputs = flake-utils.lib.eachSystem supportedSystems (
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
    in
    {
      overlays.default = overlay;
    }
    // linuxOutputs
    // devShellOutputs;
}
