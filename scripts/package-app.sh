#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=${1:-0.1.1}
APP_NAME="HanaEdit"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"

"$ROOT_DIR/scripts/build-app.sh"

cd "$DIST_DIR"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_PATH"

shasum -a 256 "$ZIP_PATH"
echo "Packaged $ZIP_PATH"
