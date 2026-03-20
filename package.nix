{
  lib,
  rustPlatform,
  pkg-config,
  webkitgtk_4_1,
  librsvg,
  gtk3,
  libsoup_3,
  glib,
  nodejs,
  cargo-tauri,
}:

rustPlatform.buildRustPackage rec {
  pname = "Little Fighter 2";
  version = "0.1.0";

  src = ./.;
  buildAndTestSubdir = "src-tauri";

  cargoHash = lib.fakeHash;

  nativeBuildInputs = [
    pkg-config
    nodejs
    cargo-tauri.hook
  ];

  buildInputs = [
    webkitgtk_4_1
    librsvg
    gtk3
    libsoup_3
    glib
  ];

  meta = with lib; {
    description = "LF2 Remake";
    homepage = "https://github.com/kiramidru/lf2";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "lf2";
  };
}
