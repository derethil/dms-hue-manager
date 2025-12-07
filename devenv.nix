{pkgs, ...}: {
  packages = [
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtbase
    pkgs.qt6.qtwayland
    pkgs.quickshell
    pkgs.watchexec
  ];

  processes.reload.exec = "watchexec -e qml -- 'dms ipc call plugins disable hueManager && dms ipc call plugins enable hueManager && dms ipc call plugins reload hueManager'";

  git-hooks.hooks = {
    qmlformat = {
      enable = true;
      name = "qmlformat";
      entry = "${pkgs.qt6.qtdeclarative}/bin/qmlformat -i";
      files = "\\.qml$";
    };
  };

  enterShell =
    /*
    bash
    */
    ''
      # Update .qmlls.ini with correct Qt6 and Quickshell QML import paths for NixOS
      QML_IMPORT_PATHS="${pkgs.quickshell}/bin:${pkgs.quickshell}/lib/qt-6/qml:${pkgs.qt6.qtwayland}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"

      # Find the dynamic buildDir from quickshell vfs
      VFS_DIR="/run/user/1000/quickshell/vfs"
      if [ -d "$VFS_DIR" ]; then
        BUILD_DIR=$(find "$VFS_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
      fi

      # Create or update .qmlls.ini
      if [ ! -f .qmlls.ini ]; then
        echo "Creating .qmlls.ini from .qmlls.ini.example"
        cp .qmlls.ini.example .qmlls.ini
      else
        chmod u+w .qmlls.ini
      fi

      # Update buildDir and importPaths
      if [ -n "$BUILD_DIR" ]; then
        sed -i "s|__BUILD_DIR__|\"$BUILD_DIR\"|; s|^buildDir=.*|buildDir=\"$BUILD_DIR\"|" .qmlls.ini
        echo "Updated buildDir: $BUILD_DIR"
      else
        sed -i "s|__BUILD_DIR__|\"/run/user/1000/quickshell/vfs\"|" .qmlls.ini
      fi
      sed -i "s|__IMPORT_PATHS__|\"$QML_IMPORT_PATHS\"|; s|^importPaths=.*|importPaths=\"$QML_IMPORT_PATHS\"|" .qmlls.ini
      echo "Updated Qt6 QML import paths"

      # Make .qmlls.ini readonly to prevent accidental changes
      chmod u-w .qmlls.ini
      echo "Made .qmlls.ini readonly"
    '';
}
