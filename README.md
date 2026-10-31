# Hokku OS

A CachyOS respin whose desktop is [Hokku](https://github.com/idumych/hokku): the Be/Haiku
API on Linux, with Haiku's Tracker and Deskbar running as Wayland clients of labwc.

It is CachyOS underneath (its kernels, repositories, hardware detection and Calamares
installer). The Plasma desktop is replaced with:

| | |
|---|---|
| Session | `hokku-session` (passes the system keyboard layout, as set by the installer or `localectl`, to labwc and Hokku), then `cosmoe-desktop.sh` from Hokku: labwc + Tracker + Deskbar (with a tray for other desktops' applets through TrayBridge: network, volume and Bluetooth start with the session; on a laptop, Hokku's own brightness slider) + Terminal, Xwayland for X11 apps, polkit-gnome, portals. Hokku's notification_server shows the desktop's notifications, and the Deskbar's menu lists every app, Hokku and Linux alike |
| Apps | Hokku's (Terminal, StyledEdit, ShowImage, Icon-O-Matic, DeskCalc…, and the demos) and three more built on it: [Folio](https://github.com/idumych/folio) (notebooks in Markdown), [Sheath](https://github.com/idumych/sheath) (a Bible reader on SWORD) and [Ringbinder](https://github.com/idumych/ringbinder) (a tabbed personal organizer), in the Deskbar's Applications menu |
| Look | [Gonx](https://github.com/idumych/gonx) throughout, or Haiku's own look: Appearance's Themes tab (or `hokku-theme apply Haiku`) switches the window frames, controls, colours, fonts and desktop, the frames round other apps (labwc-hokku draws Hokku's own Haiku or Gonx tab round them), and GTK 3 and Qt apps (Hokku's GTK and Kvantum themes of both looks) at once. New users start in Gonx, set up from `/etc/skel` |
| Displays | wdisplays (resolution, scale, arrangement, rotation; in the Deskbar's applications menu) and kanshi, started from `/etc/xdg/labwc/autostart`, which applies the layouts in `~/.config/kanshi/config` at login |
| Login | greetd + tuigreet (the live ISO logs `liveuser` in automatically) |
| Installer | Calamares in offline mode: copies the live system to disk, then sets up greetd for Hokku |

Not affiliated with or endorsed by CachyOS.

## Screenshots

From the 1.0 (Icefell) ISO, in QEMU at 1280x800.

![The desktop: About this system, GLTeapot spinning its red teapot at over 400 frames per second, and Pulse showing the four CPUs; Disks and Trash on the Tracker desktop, and the Deskbar in the top right corner with the brightness, volume and network icons in its tray](docs/screenshots/desktop.png)

| | |
|---|---|
| ![The Deskbar menu with the Applications submenu open: CharacterMap, DeskCalc, Folio, Icon-O-Matic, Ringbinder, Sheath, ShowImage, StyledEdit and Terminal](docs/screenshots/deskbar-menu.png) | ![Two notifications beside the Deskbar: a mail with Reply and Mark read buttons, and a backup at 65% with a progress bar](docs/screenshots/notifications.png) |
| The Deskbar menu: every Hokku app, plus Linux applications | Notifications from Linux apps, with their buttons and progress bars |
| ![The brightness slider open under the sun icon in the Deskbar's tray, at 70%](docs/screenshots/brightness.png) | ![About this system: Hokku, what it adds, and the machine it runs on](docs/screenshots/about.png) |
| The brightness slider (on a laptop; the VM's backlight was faked for this shot) | About this system |

![Folio showing its Start Here page: a notebook tree on the left, Markdown with links in the middle, and the page's backlinks on the right](docs/screenshots/folio.png)

![Sheath reading John 1 in the King James Version](docs/screenshots/sheath.png)

![Ringbinder's calendar: a week across two ring-bound pages, with coloured tabs for To Do, Address, Calls, Planner, Notepad and Anniversary](docs/screenshots/ringbinder.png)

### Themes

Haiku's look and Gonx, switched from Appearance's Themes tab. Each shot has a Hokku app
(Appearance), a GTK 3 app (Network Connections) and a Qt app (Kvantum Manager), all in the
same look, with labwc's frames round the other apps to match. From a development build of
Hokku (2439048) on the 1.0 ISO.

![Haiku's look: Appearance's Themes tab with Haiku in use in a yellow Haiku tab, Network Connections (GTK) and Kvantum Manager (Qt, its active theme Haiku) in Haiku's grey controls, on Haiku's blue desktop](docs/screenshots/theme-haiku.png)

![Gonx: the same three windows in the Gonx look, Appearance in the Gonx tab and flap, Network Connections and Kvantum Manager in Gonx's controls and blue-grey selection, on the Gonx desktop, with the Hokku tab on the Deskbar](docs/screenshots/theme-gonx.png)

Other apps' windows get the theme's frame too: labwc-hokku draws Hokku's own Haiku or Gonx
tab and border round them, so a GTK or Qt window moves, zooms, closes and resizes like a Hokku
one. Every window casts a soft shadow, of a light above and to the left, standing it off the
desktop: about 13 pixels past the frame's right edge and 16 below, none when it fills the
screen. Below, Appearance (Hokku), Network Connections (GTK 3) and V4L2 Test Bench (Qt 6),
from Hokku 7516f3a and labwc-hokku on the 1.0 ISO:

![Haiku's look: Appearance with Haiku in use, Network Connections and V4L2 Test Bench, each in Haiku's frame and casting a soft shadow down and to the right: a tab as wide as its title with the close box at the left and the zoom box at the right, the Qt app's tab yellow as the active window, the others grey](docs/screenshots/frames-haiku.png)

![Gonx: the same three windows in the Gonx frame, a rounded tab with the close, zoom and minimize buttons on the blue-grey shelf beside it, each window's soft shadow falling down and to the right over the desktop and the windows below, the Qt app's tab yellow as the active window](docs/screenshots/frames-gonx.png)

The same Gonx controls in Hokku's Showcase, a GTK 3 app and a Qt app (the GTK and Qt test
galleries copy Showcase's layout):

| Hokku | GTK 3 | Qt (Kvantum) |
|---|---|---|
| ![Showcase's check boxes, radio buttons and buttons in Gonx](docs/screenshots/gonx-hokku.png) | ![GTK check boxes with the Gonx ✕, radio buttons, buttons and scroll bars](docs/screenshots/gonx-gtk.png) | ![Qt check boxes, radio buttons, buttons, scroll bar and fields in Gonx](docs/screenshots/gonx-qt.png) |

## Hokku OS and Renku OS

Hokku OS and [Renku OS](https://github.com/RenkuOS/Source), the Haiku fork, run the same
API, so work done for one tends to land on the other. Notifications are one example:
Hokku OS needed buttons on its notifications (Reply and Mark read for a mail, Snooze for a
reminder). They were built in Hokku first, as `BNotification::AddAction()`. The same API was
then proposed to Renku OS
([RenkuOS/Source#233](https://github.com/RenkuOS/Source/pull/233)), which merged it the same
day, so an app can add those actions on both systems from one source (Renku's notification
server shows them as buttons once the second half, already written, lands). The other direction
works too: [Gonx](https://github.com/idumych/gonx), the look Hokku OS wears throughout, was
made for Renku OS, and Folio, Sheath and Ringbinder are Renku OS apps that Hokku OS builds
from the same source.

## Layout

```
packages/hokku/              PKGBUILD: hokku, hokku-apps, hokku-desktop (split) from a pinned
                             commit of the hokku branch
aur/hokku-git/               the same split for the AUR, from the hokku branch's latest commit
                             (hokku-git, hokku-apps-git, hokku-desktop-git; no Hokku OS apps)
aur/labwc-hokku/             packages/labwc-hokku for the AUR (hokku-desktop-git suggests it)
packages/folio/, sheath/,     PKGBUILDs for those apps from their release tags, built against
  ringbinder/                the system Hokku (their release AppImages bundle their own)
packages/hokku-os-settings/  hokku-session, the Gonx settings for /etc/skel, labwc rc.xml
                             and its Gonx-coloured theme
packages/labwc-hokku/        Arch's labwc with a patch that draws Hokku's Haiku and Gonx frames
                             (Hokku's frame code, from packages/hokku's commit) round other
                             apps, when the theme sets window.decorator
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

## Testing so far

From 27 to 30 October 2026, about 14 ISOs were built and booted in QEMU (`scripts/test-iso.sh`,
on a CPU without AVX so that nothing built for x86-64-v3 slips through). Testing them found
and fixed about 35 bugs: some 30 in Hokku (login hangs, Tracker and Terminal freezes, the
desktop and Deskbar lost after a text console, zombie apps, stale Deskbar entries, unfair
semaphores, apps untyped on ext4…), all in the hokku branch, and 5 or 6 in this repository's
packaging and build scripts. Real hardware has been tried far less than the VM.

## Known gaps

- Installed systems don't get Hokku updates yet: there's no hosted `[hokku]` pacman repository.
- Calamares still shows CachyOS's branding and slideshow; the boot splash images are CachyOS's.
- The installer's "log in automatically" option is ignored (greetd is set up without it).
- x86_64 only (CachyOS has no arm64 edition).
- GTK 4 and libadwaita apps keep their own look; a Qt app shows a newly chosen style only
  after logging in again (it takes a new font when it restarts).
