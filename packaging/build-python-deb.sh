#!/usr/bin/env bash
# Build python3-cryptoauthlib_<version>_all.deb — the pure-Python ctypes
# wrapper packaged for the target. Architecture-independent: it loads the
# native library at runtime, so it pairs with the arch-matching
# cryptoauthlib_<version>_<arch>.deb (which ships /usr/lib/libcryptoauth.so*).
#
# Usage:
#   ./packaging/build-python-deb.sh [version]
#
# Version defaults to the library version in the top-level CMakeLists.txt so
# both debs of a release carry the same version.
#
# Output: build/python-deb/python3-cryptoauthlib_<version>_all.deb
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT="${ROOT}/build/python-deb"

VERSION="${1:-}"
if [ -z "${VERSION}" ]; then
    VERSION="$(sed -n 's/^set(VERSION "\([0-9.]*\)")$/\1/p' "${ROOT}/CMakeLists.txt")"
fi
if [ -z "${VERSION}" ]; then
    echo "ERROR: could not determine version (CMakeLists.txt VERSION missing)" >&2
    exit 1
fi

PKGROOT="${OUT}/pkgroot"
PKGDIR="${PKGROOT}/usr/lib/python3/dist-packages/cryptoauthlib"
rm -rf "${PKGROOT}"
mkdir -p "${PKGDIR}" "${PKGROOT}/DEBIAN"

cp "${ROOT}/python/cryptoauthlib/"*.py "${PKGDIR}/"
cp "${ROOT}/python/cryptoauthlib/cryptoauth.json" "${PKGDIR}/"

INSTALLED_SIZE="$(du -sk "${PKGROOT}/usr" | cut -f1)"

cat > "${PKGROOT}/DEBIAN/control" <<EOF
Package: python3-cryptoauthlib
Version: ${VERSION}
Architecture: all
Maintainer: EIS
Section: python
Priority: optional
Depends: python3, cryptoauthlib (>= ${VERSION})
Installed-Size: ${INSTALLED_SIZE}
Description: Python wrapper for Microchip CryptoAuthLib (ATECC608)
 Pure-Python ctypes bindings for libcryptoauth. Requires the cryptoauthlib
 package for the native shared library.
EOF

DEB="${OUT}/python3-cryptoauthlib_${VERSION}_all.deb"
dpkg-deb --build --root-owner-group "${PKGROOT}" "${DEB}"

echo ""
echo "==> Package: ${DEB}"
dpkg-deb --info "${DEB}"
