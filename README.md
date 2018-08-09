MaciASL
=======

[![Build Status](https://travis-ci.org/acidanthera/MaciASL.svg?branch=master)](https://travis-ci.org/acidanthera/MaciASL) [![Scan Status](https://scan.coverity.com/projects/16447/badge.svg?flat=1)](https://scan.coverity.com/projects/16447)

_This repository is an unfortunate necessity, as the [original project](https://sourceforge.net/projects/maciasl/) is not maintained, crashes very often, and the license requires me to publish the source code. If you are phpdev32, you are welcome to take over and merge the changes upstream._

A native AML compiler and IDE for macOS, with syntax coloring, tree navigation, automated patching, online patch file repositories, and iASL binary updates. Written entirely in Cocoa, conforms to macOS guidelines.

#### Features
- Syntax Coloring
- Live tree navigation
- Native OS X autosaving and restore
- File patching
- Online patch file repositories
- Updatable iASL binary
- Customizable text and layout
- Compiler summary and hinting

#### Compiling iasl
To build the latest ACPI compiler download the latest source release from [ACPICA](https://www.acpica.org/downloads/) and compile it with the following command:
```
CFLAGS="-mmacosx-version-min=10.7 -O3" \
LDFLAGS="-mmacosx-version-min=10.7" \
make iasl -j $(getconf _NPROCESSORS_ONLN)
```
The binary will be present at `generate/unix/bin/iasl` path, and should replace `iasl62` in the project dir.
