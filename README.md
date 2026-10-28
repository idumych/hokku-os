# Hokku OS

A CachyOS respin whose desktop is [Hokku](https://github.com/idumych/hokku): the Be/Haiku
API on Linux, with Haiku's Tracker and Deskbar running as Wayland clients of labwc.

It is CachyOS underneath (its kernels, repositories, hardware detection and Calamares
installer). The Plasma desktop is replaced with:

| | |
|---|---|
| Session | `hokku-session` (passes the system keyboard layout, as set by the installer or `localectl`, to labwc and Hokku), then `cosmoe-desktop.sh` from Hokku: labwc + Tracker + Deskbar + Terminal, mako, polkit-gnome, portals |
| Look | [Gonx](https://github.com/idumych/gonx) throughout: Hokku is built from its `gonx-frame` branch, and new users start with what `gonx-theme apply` sets (window frame, controls, colours, fonts, plain desktop colour) from `/etc/skel`. labwc's frames for non-Be apps use Gonx's colours. `gonx-theme revert` goes back to Hokku's own look |
| Displays | wdisplays (resolution, scale, arrangement, rotation; from the Super-key menu) and kanshi, started from `/etc/xdg/labwc/autostart`, which applies the layouts in `~/.config/kanshi/config` at login |
| Login | greetd + tuigreet (the live ISO logs `liveuser` in automatically) |
| Installer | Calamares in offline mode: copies the live system to disk, then sets up greetd for Hokku |

Not affiliated with or endorsed by CachyOS.

## Layout

```
packages/hokku/              PKGBUILD: hokku, hokku-apps, hokku-desktop (split) from the gonx-frame
                             branch, plus Hokku fixes not yet pushed, as *.patch
packages/hokku-os-settings/  hokku-session, the Gonx settings for /etc/skel, labwc rc.xml, menu.xml
                             and its Gonx-coloured theme
iso/                         overlay on CachyOS's archiso profile (CachyOS-Live-ISO, pinned commit)
  packages.add / .remove       changes to CachyOS's packages_desktop.x86_64
  airootfs.remove              Plasma files dropped from CachyOS's airootfs
  airootfs/                    greetd, os-release, the installer launcher
scripts/build-packages.sh    clean-chroot builds into repo/x86_64 (the local [hokku] repo)
scripts/build-iso.sh         profile + overlay -> mkarchiso -> out/hokku-os-*.iso
scripts/test-iso.sh          boot the ISO / installed disk in QEMU, screenshots, keys, clicks
```

## Building

On an Arch-based host (CachyOS is fine: packages are built in a clean chroot with generic
x86-64 flags, not the host's `-march=native`):

```sh
sudo pacman -S --needed devtools archiso git curl
scripts/build-packages.sh
scripts/build-iso.sh
scripts/test-iso.sh start && scripts/test-iso.sh shot desktop
```

## Known gaps

- Installed systems don't get Hokku updates yet: there's no hosted `[hokku]` pacman repository.
- Calamares still shows CachyOS's branding and slideshow; the boot splash images are CachyOS's.
- The installer's "log in automatically" option is ignored (greetd is set up without it).
- x86_64 only (CachyOS has no arm64 edition).
