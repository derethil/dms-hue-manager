{pkgs, ...}: {
  packages = [
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtbase
    pkgs.qt6.qt5compat
    pkgs.qt6.qtmultimedia
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
      # Update .qmlls.ini with correct Qt6 QML import paths for NixOS
      QML_IMPORT_PATHS="/run/current-system/sw/bin:${pkgs.quickshell}/lib/qt-6/qml:${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml"

      if [ -f .qmlls.ini ]; then
        # Remove readonly flag before updating
        chmod u+w .qmlls.ini

        # Find the dynamic buildDir from quickshell vfs
        VFS_DIR="/run/user/1000/quickshell/vfs"
        if [ -d "$VFS_DIR" ]; then
          BUILD_DIR=$(find "$VFS_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
          if [ -n "$BUILD_DIR" ]; then
            sed -i "s|^buildDir=.*|buildDir=\"$BUILD_DIR\"|" .qmlls.ini
            echo "Updated buildDir: $BUILD_DIR"
          fi
        fi

        # Update the importPaths
        sed -i "s|^importPaths=.*|importPaths=\"$QML_IMPORT_PATHS\"|" .qmlls.ini
        echo "Updated Qt6 QML import paths"

        # Make .qmlls.ini readonly
        chmod u-w .qmlls.ini
        echo "Made .qmlls.ini readonly"
      fi
    '';
}
