#!/bin/sh
# Install Hokku, its desktop session, apps and Power Theme on @UBUNTU@ or a
# derivative (@DERIVATIVE@…). Run from this folder: sudo ./install.sh
# Then log out, choose "Hokku" in the login screen's session menu, and log in.
set -e

cd "$(dirname "$0")"

if [ "$(id -u)" != 0 ]; then
    exec sudo "$0" "$@"
fi

. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
    *" ubuntu "*|*" debian "*) ;;
    *) echo "install.sh: this is for Ubuntu and its derivatives (this is ${PRETTY_NAME:-unknown})" >&2
       exit 1 ;;
esac
if [ "${UBUNTU_CODENAME:-}" != @CODENAME@ ]; then
    echo "install.sh: built for @UBUNTU@ (@CODENAME@); this is ${UBUNTU_CODENAME:-$PRETTY_NAME}." >&2
    echo "Carry on anyway? [y/N] " >&2
    read -r answer
    case $answer in [yY]*) ;; *) exit 1 ;; esac
fi
if [ "$(dpkg --print-architecture)" != amd64 ]; then
    echo "install.sh: these packages are for amd64 (x86-64)" >&2
    exit 1
fi

# a source that can't be reached (a CD-ROM line, a third party's) needn't
# stop it: apt installs from the lists it has
apt-get update || echo "install.sh: some package lists weren't updated; carrying on" >&2
# apt installs the packages' dependencies from the distribution's repositories
apt-get install -y ./*.deb

# Linux Lite 6's login screen has no session menu (its indicators leave out
# ~session), so there'd be no way to choose Hokku: add it
greeter=/etc/lightdm/lightdm-gtk-greeter.conf
if [ -f "$greeter" ] && grep -q '^ *indicators *=' "$greeter" \
        && ! grep -q '^ *indicators *=.*~session' "$greeter"; then
    cp -p "$greeter" "$greeter.hokku-bak"
    sed -i 's/^\( *indicators *= *\)/\1~session;/' "$greeter"
    echo "install.sh: added the session menu to the login screen ($greeter; the old one is $greeter.hokku-bak)"
fi

echo
echo "Hokku is installed. Log out, choose \"Hokku\" in the login screen's session menu, and log in."
