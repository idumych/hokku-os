#!/bin/bash
# Build Hokku OS's packages as .debs for Ubuntu 26.04 and its derivatives (Linux Lite 8),
# or 22.04 (Linux Lite 6: RELEASE=jammy below),
# in a clean Ubuntu VM (scripts/deb-vm.sh), and bundle them with an installer:
# out/hokku-debs-<date>.tar.gz.
#
#   scripts/build-debs.sh              # all packages, then the bundle
#   scripts/build-debs.sh folio sheath # some (the others' .debs from an earlier run stay)
#
# Each package is built from the commit its PKGBUILD pins (packages/*/PKGBUILD:
# url, _commit, pkgver, pkgrel), with deb/<pkg>/debian added; Hokku keeps its own
# debian/, with deb/hokku/*.patch applied. Each .deb is installed in the VM after
# it is built, as the next packages build against it.
#
#   SRC_<pkg>=DIR   build from DIR, a working tree as it is, instead of the pinned
#                   commit (SRC_power_theme=~/Projects/power-theme …; - becomes _)
#   FRESH=1         start from a fresh VM (scripts/deb-vm.sh reset)
#   RELEASE=jammy   for Ubuntu 22.04 (Linux Lite 6) instead of 26.04, in its own VM:
#                   out/debs-jammy and out/hokku-debs-jammy-<date>.tar.gz
#
# Needs what scripts/deb-vm.sh needs, and git.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
vm="$root/scripts/deb-vm.sh"
work="$root/build/debs"
export RELEASE=${RELEASE:-resolute}
if [ "$RELEASE" = resolute ]; then suffix=; else suffix=-$RELEASE; fi
out="$root/out/debs$suffix"
all=(hokku power-theme folio sheath ringbinder hokku-os-settings)
pkgs=("$@")
[ ${#pkgs[@]} -gt 0 ] || pkgs=("${all[@]}")

pkgbuild() { (source "$root/packages/$1/PKGBUILD"; eval "echo \"\$$2\""); }

# The source tree of a package, as a tarball: the pinned commit (from a cached
# clone of its url), or SRC_<pkg>'s working tree
source_tar() {
    local pkg=$1 tar=$2 var="SRC_${1//-/_}" dir
    dir=${!var:-}
    if [ "$pkg" = hokku-os-settings ]; then
        tar -C "$root/packages/hokku-os-settings" --exclude=PKGBUILD -cf "$tar" .
    elif [ -n "$dir" ]; then
        echo "build-debs: $pkg from $dir" >&2
        tar -C "$dir" --exclude=.git --exclude=build --exclude=builddir -cf "$tar" .
    else
        local url commit git="$work/git/$pkg.git"
        url=$(pkgbuild "$pkg" url) commit=$(pkgbuild "$pkg" _commit)
        [ -d "$git" ] || git clone -q --bare "$url" "$git"
        git -C "$git" cat-file -e "$commit^{commit}" 2>/dev/null || git -C "$git" fetch -q origin
        git -C "$git" archive -o "$tar" "$commit"
    fi
}

if [ -n "${FRESH:-}" ]; then "$vm" stop; sleep 5; "$vm" reset; fi
"$vm" ssh true 2>/dev/null || "$vm" start
mkdir -p "$work" "$out"

for pkg in "${pkgs[@]}"; do
    echo "=== $pkg"
    tar="$work/$pkg.tar"
    source_tar "$pkg" "$tar"
    # what goes in debian/: the package's own, and the shared helpers
    rm -rf "$work/debian-$pkg"
    if [ "$pkg" != hokku ]; then
        mkdir -p "$work/debian-$pkg"
        cp -a "$root/deb/$pkg/debian/." "$work/debian-$pkg/"
        cp "$root/deb/common/hokku-deb" "$root/deb/common/hokku-app.mk" "$work/debian-$pkg/"
        [ -e "$work/debian-$pkg/postinst" ] || [ "$pkg" = hokku-os-settings ] \
            || cp "$root/deb/common/postinst" "$work/debian-$pkg/postinst"
        mkdir -p "$work/debian-$pkg/source"
        echo '3.0 (native)' >"$work/debian-$pkg/source/format"
        version="$(pkgbuild "$pkg" pkgver)-$(pkgbuild "$pkg" pkgrel)"
        printf '%s (%s) %s; urgency=medium\n\n  * Built from %s.\n\n -- %s  %s\n' \
            "$pkg" "$version" "$RELEASE" "${pkg} $(pkgbuild "$pkg" _commit)" \
            "idumych <idumych@gmail.com>" "$(date -R)" >"$work/debian-$pkg/changelog"
    fi

    "$vm" ssh "rm -rf src/$pkg src/debian-$pkg && mkdir -p src/$pkg debs"
    "$vm" put "$tar" "src/$pkg.tar"
    [ -d "$work/debian-$pkg" ] && "$vm" put "$work/debian-$pkg" "src/debian-$pkg"
    for patch in "$root/deb/$pkg"/*.patch; do
        [ -e "$patch" ] && "$vm" put "$patch" "src/"
    done
    "$vm" ssh bash -s "$pkg" "$RELEASE" <<'EOF'
set -euo pipefail
pkg=$1 release=$2
profiles=
if [ "$release" != resolute ]; then
    # Hokku and labwc want a newer meson than Ubuntu 22.04's (0.61); only to
    # build. labwc-hokku is built on its own there (Hokku's build profile).
    command -v pip3 >/dev/null || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-pip >/dev/null
    [ -x /usr/local/bin/meson ] || sudo pip3 install -q meson==1.8.2 2>/dev/null
    profiles=pkg.cosmoe.static-labwc
fi
export DEB_BUILD_PROFILES=$profiles
cd ~/src/$pkg
if [ -d ../debian-$pkg ]; then
    # ours, not one the source may have
    tar -xf ../$pkg.tar --exclude=debian --exclude=./debian
    mv ../debian-$pkg debian
else
    tar -xf ../$pkg.tar
fi
for patch in ../*.patch; do
    [ -e "$patch" ] || continue
    git apply "$patch"
    rm "$patch"
done
# not against an earlier build of itself: Power Theme leaves out the add-ons
# the system has already, and the apps their MIME database entries
[ "$pkg" = hokku ] || sudo dpkg -r "$pkg" >/dev/null 2>&1 || true
sudo DEBIAN_FRONTEND=noninteractive mk-build-deps -i -r ${profiles:+--build-profiles=$profiles} \
    -t 'apt-get -y --no-install-recommends' debian/control >/dev/null
if [ "$pkg" = hokku ]; then
    make deb >../$pkg.log 2>&1 || { tail -40 ../$pkg.log; exit 1; }
    debs=(debian/packages/*.deb)
else
    dpkg-buildpackage -us -uc -b >../$pkg.log 2>&1 || { tail -40 ../$pkg.log; exit 1; }
    debs=(../${pkg}_*.deb)
fi
rm -f ~/debs/${pkg}_* ; [ "$pkg" != hokku ] || rm -f ~/debs/cosmoe*
mv "${debs[@]}" ~/debs/
cd ~/debs
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall \
    $(for d in "${debs[@]}"; do echo ./"${d##*/}"; done) >/dev/null
EOF
done

rm -f "$out"/*.deb
"$vm" get 'debs/*.deb' "$out/"

# The bundle: the .debs and an installer
date=$(date +%Y%m%d)
name=hokku-debs$suffix-$date
bundle="$work/$name"
rm -rf "$bundle"
mkdir -p "$bundle"
cp "$out"/*.deb "$bundle/"
case $RELEASE in
    resolute) ubuntu="Ubuntu 26.04" derivative="Linux Lite 8" ;;
    jammy) ubuntu="Ubuntu 22.04" derivative="Linux Lite 6" ;;
    *) ubuntu="Ubuntu ($RELEASE)" derivative="its derivatives" ;;
esac
for f in install.sh README.txt; do
    sed -e "s/@UBUNTU@/$ubuntu/g" -e "s/@DERIVATIVE@/$derivative/g" \
        -e "s/@CODENAME@/$RELEASE/g" "$root/deb/$f" >"$bundle/$f"
done
chmod 755 "$bundle/install.sh"
tar -C "$work" -czf "$root/out/$name.tar.gz" "$name"
ls -lh "$out" "$root/out/$name.tar.gz"
