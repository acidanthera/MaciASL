#!/bin/bash

rm -rf acpica iasl*

git clone https://github.com/acpica/acpica || exit 1
cd acpica || exit 1
git checkout 6afc9c9921265a74062861718087e3321082ca3a || exit 1
git apply ../acpica-legacy.diff || exit 1
cd generate/unix/iasl || exit 1
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make || exit 1
cp iasl ../../../../iasl-legacy.x86_64 || exit 1
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make clean || exit 1
CFLAGS="-mmacosx-version-min=10.7 -O3 -target arm64-apple-darwin" \
  LDFLAGS="-mmacosx-version-min=10.7 -target arm64-apple-darwin" make || exit 1
cp iasl ../../../../iasl-legacy.arm64 || exit 1
cd ../../../../ || exit 1
lipo -create iasl-legacy.x86_64 iasl-legacy.arm64 -output iasl-legacy || exit 1

rm -rf acpica || exit 1

git clone https://github.com/acpica/acpica || exit 1
cd acpica || exit 1
git checkout R09_25_20 || exit 1
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make iasl || exit 1
cp generate/unix/bin/iasl ../iasl-stable.x86_64 || exit 1
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make clean || exit 1
CFLAGS="-mmacosx-version-min=10.7 -O3 -target arm64-apple-darwin" \
  LDFLAGS="-mmacosx-version-min=10.7 -target arm64-apple-darwin" make iasl || exit 1
cp generate/unix/bin/iasl ../iasl-stable.arm64 || exit 1
cd .. || exit 1
lipo -create iasl-stable.x86_64 iasl-stable.arm64 -output iasl-stable || exit 1

rm -rf acpica || exit 1

git clone https://github.com/acpica/acpica || exit 1
cd acpica || exit 1
git checkout R03_31_21 || exit 1
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make iasl || exit 1
cp generate/unix/bin/iasl ../iasl-dev.x86_64 || exit 1
CC=clang CFLAGS="-mmacosx-version-min=10.7 -O3" \
  LDFLAGS="-mmacosx-version-min=10.7" make clean || exit 1
CFLAGS="-mmacosx-version-min=10.7 -O3 -target arm64-apple-darwin" \
  LDFLAGS="-mmacosx-version-min=10.7 -target arm64-apple-darwin" make iasl || exit 1
cp generate/unix/bin/iasl ../iasl-dev.arm64 || exit 1
cd .. || exit 1
lipo -create iasl-dev.x86_64 iasl-dev.arm64 -output iasl-dev || exit 1
