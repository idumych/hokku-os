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

# mkarchroot writes .arch-chroot last, so a chroot without it is left over
# from a failed run (on btrfs it is a subvolume) and is rebuilt from scratch.
if [ ! -f "$chroot/root/.arch-chroot" ]; then
    if [ -d "$chroot/root" ]; then
        echo "build-packages: removing incomplete chroot $chroot/root" >&2
        sudo btrfs subvolume delete "$chroot/root" 2>/dev/null || sudo rm -rf "$chroot/root"
        sudo rm -f "$chroot/root.lock"
    fi
    mkdir -p "$chroot"
    mkarchroot \
        -C /usr/share/devtools/pacman.conf.d/extra.conf \
        -M /usr/share/devtools/makepkg.conf.d/x86_64.conf \
        "$chroot/root" base-devel
fi
arch-nspawn "$chroot/root" pacman -Syu --noconfirm

mkdir -p "$repo"
pkgs=("$@")
[ ${#pkgs[@]} -gt 0 ] || pkgs=(hokku labwc-hokku hokku-os-settings folio sheath ringbinder)

for pkg in "${pkgs[@]}"; do
    (
        cd "$root/packages/$pkg"
        # makepkg installs depends too, and the chroot only has Arch's repos:
        # hand it our own packages (they depend on each other), but not an
        # earlier build of the one being built: installed, it would be there
        # already (an app's type in the MIME database, which mimeset then
        # leaves out of the package), and debug packages aren't needed.
        installs=()
        if (source PKGBUILD; printf '%s\n' "${depends[@]}" "${makedepends[@]}") | grep -q '^hokku'; then
            own=" $(source PKGBUILD; echo "${pkgname[@]}") "
            for f in "$repo"/*.pkg.tar.zst; do
                [ -e "$f" ] || continue
                name="$(bsdtar -xOf "$f" .PKGINFO | sed -n 's/^pkgname = //p')"
                case "$own" in *" $name "*) continue ;; esac
                [[ "$name" == *-debug ]] && continue
                installs+=(-I "$f")
            done
        fi
        makechrootpkg -c -r "$chroot" "${installs[@]}"
        for f in $(makepkg --packagelist); do
            cp "$f" "$repo/"
            repo-add --remove --quiet "$repo/hokku.db.tar.gz" "$repo/$(basename "$f")"
        done
    )
done

ls -lh "$repo"
