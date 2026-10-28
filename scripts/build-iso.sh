#!/bin/bash
# Build the Hokku OS live/install ISO.
#
# Takes CachyOS's archiso profile (CachyOS-Live-ISO, pinned below), applies the
# Hokku overlay in iso/ and runs mkarchiso with the local [hokku] repository that
# scripts/build-packages.sh fills. Unlike CachyOS's buildiso.sh it doesn't patch
# the host's /usr/bin/mkarchiso.
#
#   scripts/build-packages.sh      # first: hokku, hokku-apps, hokku-desktop, hokku-os-settings
#   scripts/build-iso.sh           # asks for sudo once, for mkarchiso
#
# Output: out/hokku-os-YYYY.MM.DD-x86_64.iso (+ .sha256)

set -euo pipefail

CACHYOS_ISO_REPO=https://github.com/CachyOS/CachyOS-Live-ISO.git
CACHYOS_ISO_COMMIT=3215497   # 2026-10-03; bump deliberately and re-test

root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/build"
upstream="$build/cachyos-live-iso"
profile="$build/profile"
repo="$root/repo/x86_64"
out="$root/out"

die() { echo "build-iso: $*" >&2; exit 1; }

for tool in mkarchiso git curl; do
    command -v "$tool" >/dev/null || die "$tool is missing (sudo pacman -S --needed archiso git curl)"
done
[ -f "$repo/hokku.db" ] || die "no local repository at $repo; run scripts/build-packages.sh first"

# 1. CachyOS's profile at the pinned commit
if [ ! -d "$upstream/.git" ]; then
    git clone --quiet "$CACHYOS_ISO_REPO" "$upstream"
fi
git -C "$upstream" fetch --quiet origin
git -C "$upstream" -c advice.detachedHead=false checkout --quiet "$CACHYOS_ISO_COMMIT"

rm -rf "$profile"
cp -a "$upstream/archiso" "$profile"

# 2. Packages: CachyOS's desktop list minus Plasma, plus Hokku
strip_comments() { sed -e 's/#.*//' -e '/^\s*$/d' "$1"; }
grep -vxFf <(strip_comments "$root/iso/packages.remove") "$profile/packages_desktop.x86_64" \
    | cat - <(strip_comments "$root/iso/packages.add") | sort -u >"$profile/packages.x86_64"
rm -f "$profile/packages_desktop.x86_64"

# 3. airootfs: drop Plasma files, add the overlay
while read -r path; do
    rm -rf "${profile:?}/airootfs/$path"
done < <(strip_comments "$root/iso/airootfs.remove")
rm -f "$profile/airootfs/etc/systemd/system/display-manager.service"
cp -a "$root/iso/airootfs/." "$profile/airootfs/"

iso_version="$(date +%y%m%d)"
echo "$iso_version" >"$profile/airootfs/etc/version-tag"
echo "desktop" >"$profile/airootfs/etc/edition-tag"   # CachyOS's scripts expect their edition names
printf 'ZPOOL_VDEV_NAME_PATH=1\n' >"$profile/airootfs/etc/environment"
curl -fsSL https://github.com/CachyOS/CachyOS-PKGBUILDS/raw/master/cachyos-mirrorlist/cachyos-mirrorlist \
    >"$profile/airootfs/etc/pacman.d/cachyos-mirrorlist"
ln -sf /dev/null "$profile/airootfs/etc/systemd/system/cachyos-rate-mirrors.timer"
cat >"$profile/airootfs/etc/motd" <<'EOF'
Hokku OS: the Hokku desktop (the Be API on Linux) on CachyOS.
https://github.com/idumych/hokku-os

To install, open "Install Hokku OS" from the Deskbar menu, or run hokku-installer.
EOF

# 4. Name, labels and boot menus
sed -i \
    -e 's/^iso_name=.*/iso_name="hokku-os"/' \
    -e 's/^iso_label=.*/iso_label="HOKKU_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
    -e 's|^iso_publisher=.*|iso_publisher="Hokku OS <https://github.com/idumych/hokku-os>"|' \
    -e 's/^iso_application=.*/iso_application="Hokku OS Live\/Install"/' \
    -e 's|^)$|  ["/usr/local/bin/hokku-installer"]="0:0:755"\n)|' \
    "$profile/profiledef.sh"
sed -i -e "s/CACHYOS_VERSION=\".*\"/CACHYOS_VERSION=\"$iso_version\"/" \
    -e '/menuentry/s/CachyOS/Hokku OS/g' "$profile/grub/grub.cfg"
sed -i -e '/MENU \(LABEL\|TITLE\)/s/CachyOS/Hokku OS/g' "$profile"/syslinux/*.cfg

# 5. The local [hokku] repository goes first, so its packages win
{
    sed -n '1,/^\[cachyos\]/{/^\[cachyos\]/!p}' "$upstream/archiso/pacman.conf"
    printf '[hokku]\nSigLevel = Optional TrustAll\nServer = file://%s\n\n' "$repo"
    sed -n '/^\[cachyos\]/,$p' "$upstream/archiso/pacman.conf"
} >"$profile/pacman.conf"

# 6. Build
mkdir -p "$out"
# One sudo for all of it: mkarchiso outlasts sudo's password timeout.
sudo sh -c 'mkarchiso -v -w "$1/work" -o "$2" "$3" && rm -rf "$1/work" && chown "$4" "$2"/*.iso' \
    sh "$build" "$out" "$profile" "$(id -u):$(id -g)"

cd "$out"
for iso in hokku-os-*.iso; do
    [ "$iso" -nt "$iso.sha256" ] && sha256sum "$iso" >"$iso.sha256"
done
ls -lh "$out"
