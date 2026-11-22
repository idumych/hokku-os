#!/bin/sh
# Install Hokku, its desktop session, apps and Power Theme on Ubuntu 26.04 or a
# derivative (Linux Lite 8…). Run from this folder: sudo ./install.sh
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
if [ "${UBUNTU_CODENAME:-}" != resolute ]; then
    echo "install.sh: built for Ubuntu 26.04 (resolute); this is ${UBUNTU_CODENAME:-$PRETTY_NAME}." >&2
    echo "Carry on anyway? [y/N] " >&2
    read -r answer
    case $answer in [yY]*) ;; *) exit 1 ;; esac
fi
if [ "$(dpkg --print-architecture)" != amd64 ]; then
    echo "install.sh: these packages are for amd64 (x86-64)" >&2
    exit 1
fi

apt-get update
# apt installs the packages' dependencies from the distribution's repositories
apt-get install -y ./*.deb

echo
echo "Hokku is installed. Log out, choose \"Hokku\" in the login screen's session menu, and log in."
