{
  pkgs,
  version ? "0.1.0",
}:
let
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

  src = pkgs.fetchFromGitHub {
    owner = "kiramidru";
    repo = "lf2";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "lf2";
  inherit version src;

  cargoLock.lockFile = ../src-tauri/Cargo.lock;

  buildAndTestSubdir = "src-tauri";

  nativeBuildInputs = with pkgs; [
    pkg-config
    cargo-tauri
    wrapGAppsHook3
  ];

  buildInputs = libraries ++ gst_plugins ++ (with pkgs; [
    glib
    gsettings-desktop-schemas
  ]);

  preBuild = ''
    mkdir -p dist
    cp -r $src/dist/* dist/
  '';

  buildPhase = ''
    runHook preBuild
    export HOME=$(mktemp -d)
    cd src-tauri
    cargo tauri build --bundles none
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp target/release/lf2 $out/bin/

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

    mkdir -p $out/share/icons/hicolor/32x32/apps
    mkdir -p $out/share/icons/hicolor/128x128/apps
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp icons/32x32.png $out/share/icons/hicolor/32x32/apps/lf2.png
    cp icons/128x128.png $out/share/icons/hicolor/128x128/apps/lf2.png
    cp "icons/128x128@2x.png" $out/share/icons/hicolor/256x256/apps/lf2.png

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --set GST_PLUGIN_SYSTEM_PATH_1_0 "${pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gst_plugins}"
    )
  '';

  meta = with pkgs.lib; {
    description = "Little Fighter 2 Remake - A Tauri Application";
    homepage = "https://github.com/kiramidru/lf2";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "lf2";
  };
}
