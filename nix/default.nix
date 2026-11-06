{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  fish,
  ddcutil,
  brightnessctl,
  networkmanager,
  lm_sensors,
  swappy,
  wl-clipboard,
  libqalculate,
  bash,
  hyprland,
  material-symbols,
  rubik,
  nerd-fonts,
  qt6,
  quickshell,
  protobuf,
  aubio,
  libcava,
  fftw,
  pipewire,
  xkeyboard-config,
  cmake,
  ninja,
  pkg-config,
  python3,
  m3shapes,
  gettext,
  openssl,
  debug ? false,
  extraRuntimeDeps ? [],
}: let
  version = "1.0.0";

  qs = quickshell.withModules [qt6.qtimageformats qt6.qtmultimedia m3shapes];
  # The in-tree command surface (bin/aether) imports these two at runtime.
  cliPython = python3.withPackages (ps: [ps.materialyoucolor ps.pillow]);

  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      networkmanager
      lm_sensors
      swappy
      wl-clipboard
      libqalculate
      bash
      hyprland
      cliPython
      fuzzel
      grim
      slurp
      libnotify
      procps
      gpu-screen-recorder
    ]
    ++ extraRuntimeDeps;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols rubik nerd-fonts.caskaydia-cove];
  };

  cmakeBuildType =
    if debug
    then "Debug"
    else "RelWithDebInfo";

  cmakeVersionFlags = [
    (lib.cmakeFeature "VERSION" version)
    (lib.cmakeFeature "GIT_REVISION" rev)
    (lib.cmakeFeature "DISTRIBUTOR" "nix-flake")
  ];

  extras = stdenv.mkDerivation {
    inherit cmakeBuildType;
    name = "aether-extras${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      fileset = lib.fileset.union ./../CMakeLists.txt ./../extras;
    };

    nativeBuildInputs = [cmake ninja];

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "extras")
        (lib.cmakeFeature "INSTALL_LIBDIR" "${placeholder "out"}/lib")
      ]
      ++ cmakeVersionFlags;
  };

  plugin = stdenv.mkDerivation {
    inherit cmakeBuildType;
    name = "aether-qml-plugin${lib.optionalString debug "-debug"}";
    src = lib.fileset.toSource {
      root = ./..;
      # scripts/trs.fish compiles the .po files as part of the plugin build, so it has to be in
      # the source, not only the plugin directory itself.
      fileset = lib.fileset.unions [./../CMakeLists.txt ./../plugin ./../scripts];
    };

    # scripts/trs.fish is a fish script and runs msgfmt, so both have to be present when the
    # .po file is compiled; without them the plugin build fails before it reaches CMake's output.
    nativeBuildInputs = [cmake ninja pkg-config fish gettext];
    # qtmultimedia and openssl are find_package requirements in plugin/CMakeLists.txt; without
    # them the plugin configure fails.
    buildInputs = [qt6.qtbase qt6.qtdeclarative qt6.qtshadertools qt6.qtmultimedia openssl libqalculate pipewire aubio libcava fftw lm_sensors protobuf];    dontWrapQtApps = true;
    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "plugin")
        (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
      ]
      ++ cmakeVersionFlags;
  };
in
  stdenv.mkDerivation {
    inherit version cmakeBuildType;
    pname = "aether-shell${lib.optionalString debug "-debug"}";
    src = ./..;

    nativeBuildInputs = [cmake ninja makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [qs extras plugin xkeyboard-config qt6.qtbase];
    propagatedBuildInputs = runtimeDeps;

    cmakeFlags =
      [
        (lib.cmakeFeature "ENABLE_MODULES" "shell")
        (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/aether-shell")
      ]
      ++ cmakeVersionFlags;

    dontStrip = debug;

    prePatch = ''
      substituteInPlace assets/pam.d/fprint \
        --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so
      substituteInPlace assets/pam.d/howdy \
        --replace-fail pam_howdy.so /run/current-system/sw/lib/security/pam_howdy.so
    '';

    postInstall = ''
      makeWrapper ${qs}/bin/qs $out/bin/aether-shell \
        --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
        --set FONTCONFIG_FILE "${fontconfig}" \
        --set AETHER_LIB_DIR ${extras}/lib \
        --set AETHER_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
        --add-flags "-p $out/share/aether-shell"

      # Hyprland can only call a name; QML calls the same file by path. The wrapper is what
      # puts materialyoucolor and Pillow on PATH -- a plain symlink would use the system python.
      makeWrapper ${cliPython}/bin/python3 $out/bin/aether \
        --add-flags "$out/share/aether-shell/bin/aether" \
        --prefix PATH : "${lib.makeBinPath runtimeDeps}"

      mkdir -p $out/lib
      ln -s ${extras}/lib/* $out/lib/
    '';

    passthru = {
      inherit plugin extras;
    };

    meta = {
      description = "A fluid, morphing shell for your Linux desktop";
      homepage = "https://github.com/clague/aether-shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "aether-shell";
    };
  }
