#!/usr/bin/env bash
# Packages the Flutter Linux release build (binary + lib/ + data/) into a
# single-file AppImage. `flutter build linux` alone only produces a bundle/
# directory — this wraps that directory as one portable executable.
#
# Usage: app/scripts/build_linux_appimage.sh
# Output: app/build/linux/x64/release/Acal-x86_64.AppImage
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_DIR="$REPO_ROOT/build/linux/x64/release/bundle"
TOOLS_DIR="$REPO_ROOT/build/.appimage-tools"
APPDIR="$REPO_ROOT/build/linux/x64/release/AppDir"
OUTPUT="$REPO_ROOT/build/linux/x64/release/Acal-x86_64.AppImage"

if [ ! -x "$BUNDLE_DIR/acalapp" ]; then
  echo "== Building Flutter Linux release =="
  (cd "$REPO_ROOT" && flutter build linux --release)
fi

if [ ! -x "$TOOLS_DIR/squashfs-root/AppRun" ]; then
  echo "== Fetching appimagetool =="
  mkdir -p "$TOOLS_DIR"
  curl -sL -o "$TOOLS_DIR/appimagetool" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "$TOOLS_DIR/appimagetool"
  # Extract instead of running the AppImage directly: containers/CI usually
  # don't have FUSE available to mount it.
  (cd "$TOOLS_DIR" && ./appimagetool --appimage-extract >/dev/null)
fi

echo "== Assembling AppDir =="
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/bin/"
cp "$REPO_ROOT/assets/icon/app_icon.png" "$APPDIR/acalapp.png"

cat > "$APPDIR/acalapp.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Acal
Exec=acalapp
Icon=acalapp
Categories=Utility;
EOF

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib:$LD_LIBRARY_PATH"
exec "$HERE/usr/bin/acalapp" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "== Building AppImage =="
ARCH=x86_64 "$TOOLS_DIR/squashfs-root/AppRun" "$APPDIR" "$OUTPUT"

echo "== Done: $OUTPUT =="
ls -lh "$OUTPUT"
