{
  pkgs,
  lib,
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

  desktopItem = pkgs.makeDesktopItem {
    name = "lf2";
    desktopName = "LF2 Remake";
    comment = "Little Fighter 2 Remake";
    exec = "lf2";
    icon = "lf2";
    terminal = false;
    categories = [ "Game" ];
  };
in
pkgs.stdenv.mkDerivation {
  pname = "lf2";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/kiramidru/lf2/releases/download/v${version}/lf2-linux-x86_64.tar.gz";
    hash = "sha256-1i6zmTRTuS8u7Uf7QxAKfr0d0huq9Blz5udfaUmURp0=";
  };

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs =
    libraries
    ++ gst_plugins
    ++ (with pkgs; [
      glib
      gsettings-desktop-schemas
    ]);

  desktopItems = [ desktopItem ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp lf2-v${version}/lf2 $out/bin/

    mkdir -p $out/share/icons/hicolor/32x32/apps
    mkdir -p $out/share/icons/hicolor/128x128/apps
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp lf2-v${version}/icons/32x32.png $out/share/icons/hicolor/32x32/apps/lf2.png
    cp lf2-v${version}/icons/128x128.png $out/share/icons/hicolor/128x128/apps/lf2.png
    cp "lf2-v${version}/icons/128x128@2x.png" $out/share/icons/hicolor/256x256/apps/lf2.png

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --set GST_PLUGIN_SYSTEM_PATH_1_0 "${
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gst_plugins
      }"
    )
  '';

  meta = with lib; {
    description = "Little Fighter 2 Remake - A Tauri Application";
    homepage = "https://github.com/kiramidru/lf2";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "lf2";
  };
}
