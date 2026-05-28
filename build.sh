#!/usr/bin/env bash
# Build resvg.xcframework (iOS device + simulator) from a resvg release.
# Usage: ./build.sh [tag]   (defaults to the latest vX.Y.Z release)
# Outputs resvg.xcframework/, resvg.xcframework.zip, and prints the SPM checksum.
set -euo pipefail
cd "$(dirname "$0")"

REPO="https://github.com/linebender/resvg.git"
SRC=".resvg-src"
FRAMEWORK="resvg.xcframework"
ZIP="resvg.xcframework.zip"
TARGETS=(aarch64-apple-ios aarch64-apple-ios-sim)

TAG="${1:-$(git ls-remote --tags --refs "$REPO" 'v*' \
  | awk -F/ '{print $NF}' | sort -V | tail -1)}"
echo "==> resvg $TAG"

rm -rf "$SRC"
git clone --quiet --depth 1 --branch "$TAG" "$REPO" "$SRC"

for t in "${TARGETS[@]}"; do
  rustup target add "$t" >/dev/null 2>&1 || true
  echo "==> building $t"
  ( cd "$SRC" && cargo build --release -p resvg-capi --target "$t" )
done

echo "==> assembling headers"
H="$SRC/.headers"
rm -rf "$H" && mkdir -p "$H"
cp "$SRC"/crates/c-api/{resvg.h,ResvgQt.h} "$H"/
cp "$SRC"/LICENSE-APACHE "$SRC"/LICENSE-MIT "$H"/
cat > "$H/module.modulemap" <<'EOF'
module CResvg {
    header "resvg.h"
    export *
}
EOF

echo "==> creating $FRAMEWORK"
rm -rf "$FRAMEWORK" "$ZIP"
xcodebuild -create-xcframework \
  -library "$SRC/target/aarch64-apple-ios/release/libresvg.a" -headers "$H" \
  -library "$SRC/target/aarch64-apple-ios-sim/release/libresvg.a" -headers "$H" \
  -output "$FRAMEWORK"

zip -r -q "$ZIP" "$FRAMEWORK"

echo
echo "$(grep RESVG_VERSION "$FRAMEWORK"/ios-arm64/Headers/resvg.h)"
echo "zip:      $ZIP ($(du -h "$ZIP" | cut -f1))"
echo "checksum: $(swift package compute-checksum "$ZIP")"
echo
echo "Next: put tag ${TAG#v} + the checksum above into Package.swift, commit, then"
echo "  gh release create ${TAG#v} $ZIP --title ${TAG#v} --notes \"resvg ${TAG#v}\""
