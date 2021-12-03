#!/bin/bash
set -e # Exits on error

rm -rf acpica iasl*

git clone https://github.com/acpica/acpica
cd acpica
git checkout 6afc9c9921265a74062861718087e3321082ca3a
git apply ../acpica-legacy.diff
cd generate/unix/iasl
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make
cp iasl ../../../../iasl-legacy.x86_64
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make clean
CFLAGS="-mmacosx-version-min=10.7 -O3 -target arm64-apple-darwin" \
  LDFLAGS="-mmacosx-version-min=10.7 -target arm64-apple-darwin" make
cp iasl ../../../../iasl-legacy.arm64
cd ../../../../
lipo -create iasl-legacy.x86_64 iasl-legacy.arm64 -output iasl-legacy

cd acpica
git reset --hard origin/master

git checkout R09_25_20
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make iasl
cp generate/unix/bin/iasl ../iasl-stable.x86_64
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make clean
CFLAGS="-mmacosx-version-min=10.7 -O3 -target arm64-apple-darwin" \
  LDFLAGS="-mmacosx-version-min=10.7 -target arm64-apple-darwin" make iasl
cp generate/unix/bin/iasl ../iasl-stable.arm64
cd ..
lipo -create iasl-stable.x86_64 iasl-stable.arm64 -output iasl-stable

cd acpica
git reset --hard origin/master

git checkout R03_31_21
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make iasl
cp generate/unix/bin/iasl ../iasl-dev.x86_64
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make clean
CFLAGS="-mmacosx-version-min=10.7 -O3 -target arm64-apple-darwin" \
  LDFLAGS="-mmacosx-version-min=10.7 -target arm64-apple-darwin" make iasl
cp generate/unix/bin/iasl ../iasl-dev.arm64
cd ..
lipo -create iasl-dev.x86_64 iasl-dev.arm64 -output iasl-dev
