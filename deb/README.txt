Hokku OS for @UBUNTU@ and its derivatives (@DERIVATIVE@…)
==========================================================

Hokku is the Be/Haiku API on Linux: Haiku's Tracker and Deskbar run on labwc
(Wayland), and Linux apps share the desktop with Be apps in the same look.
These packages put the whole Hokku OS desktop beside the system's own:

  cosmoe, cosmoe-dev   Hokku: libraries, add-ons, data, command-line and
                       development tools
  cosmoe-apps          Haiku's apps and preferences (Terminal, StyledEdit,
                       ShowImage, Icon-O-Matic, Appearance…)
  cosmoe-desktop       Tracker, the Deskbar and the session: labwc-hokku draws
                       every window, Hokku's or not, in Hokku's frames
  power-theme          Power Theme: window borders, controls, colours, fonts
                       and icons, for Hokku apps and every window in the session
  folio, sheath,       apps built on Hokku: Markdown notebooks, a Bible reader,
  ringbinder           a personal organizer
  hokku-os-settings    the Gonx look for new users, and the "Hokku" session

Install:   sudo ./install.sh
           (or: sudo apt install ./*.deb)
Then log out, pick "Hokku" in the login screen's session menu, and log in.
Your usual desktop (Xfce on Linux Lite) stays in that menu.

The first time you log in to Hokku it takes the Gonx look. Appearance
(Deskbar > Preferences) or Power Theme switches it.

Remove:    sudo apt remove cosmoe cosmoe-dev hokku-os-settings

On Linux Lite 6 the login screen has no session menu, so install.sh adds
one to /etc/lightdm/lightdm-gtk-greeter.conf, keeping the old file as
lightdm-gtk-greeter.conf.hokku-bak (copy it back to undo).

Built for @UBUNTU@ (@CODENAME@), amd64. There's no package repository yet,
so updates come as a new bundle. https://github.com/idumych/hokku-os
