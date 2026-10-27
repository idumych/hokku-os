#!/bin/bash
# Build the Hokku OS packages in a clean Arch chroot and put them in the local
# pacman repository repo/x86_64 (the [hokku] repo the ISO build installs from).
#
# Packages are built with Arch's generic flags (devtools' makepkg.conf:
# -march=x86-64 -mtune=generic), not the host's: a CachyOS host builds with
# -march=native, and the ISO has to boot on any x86-64 machine.
#
#   scripts/build-packages.sh              # all packages
#   scripts/build-packages.sh hokku        # one
#
# Needs devtools (sudo pacman -S --needed devtools); makechrootpkg asks for sudo.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
chroot="$root/build/chroot"
repo="$root/repo/x86_64"

command -v makechrootpkg >/dev/null || { echo "build-packages: install devtools first" >&2; exit 1; }

if [ ! -d "$chroot/root" ]; then
    mkdir -p "$chroot"
    mkarchroot \
        -C /usr/share/devtools/pacman.conf.d/extra.conf \
        -M /usr/share/devtools/makepkg.conf.d/x86_64.conf \
        "$chroot/root" base-devel
fi
arch-nspawn "$chroot/root" pacman -Syu --noconfirm

mkdir -p "$repo"
pkgs=("$@")
[ ${#pkgs[@]} -gt 0 ] || pkgs=(hokku hokku-os-settings)

for pkg in "${pkgs[@]}"; do
    (
        cd "$root/packages/$pkg"
        makechrootpkg -c -r "$chroot"
        for f in $(makepkg --packagelist); do
            cp "$f" "$repo/"
            repo-add --remove --quiet "$repo/hokku.db.tar.gz" "$repo/$(basename "$f")"
        done
    )
done

ls -lh "$repo"
