#!/bin/bash
# deb-vm.sh CMD …  — an Ubuntu 26.04 VM (QEMU/KVM, from Ubuntu's cloud image) to build
# Hokku's .debs in a clean system and try them, for Ubuntu derivatives such as Linux Lite 8.
#
#   start            boot the VM (made on first use: a disk over the cloud image and a
#                    cloud-init seed with user "build", password "build", and an SSH key)
#   ssh [CMD…]       run CMD in the VM (a shell without one)
#   put SRC… DEST    copy files into the VM (scp -r; DEST is in the VM)
#   get SRC DEST     copy files out of the VM
#   reset            delete the VM's disk, so the next start is a fresh system
#   stop             power off
#
#   DIR (default build/deb-vm)  SMP (default 16)  MEM (default 16384, MB)
# SSH: 127.0.0.1:2227 -> guest 22.
# Needs qemu-system-x86_64, xorriso, curl, ssh.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
DIR=${DIR:-$root/build/deb-vm}
SMP=${SMP:-16}
MEM=${MEM:-16384}
image_url=https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img
port=2227
mkdir -p "$DIR"

ssh_opts=(-i "$DIR/id_ed25519" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
          -o LogLevel=ERROR -o ConnectTimeout=5)
vm_ssh() { ssh "${ssh_opts[@]}" -p $port build@127.0.0.1 "$@"; }

make_vm() {
    [ -f "$DIR/resolute.img" ] || curl -fL -o "$DIR/resolute.img" "$image_url"
    [ -f "$DIR/id_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -C deb-vm -f "$DIR/id_ed25519"
    qemu-img create -q -f qcow2 -F qcow2 -b "$DIR/resolute.img" "$DIR/disk.qcow2" 80G
    local seed="$DIR/seed"
    rm -rf "$seed"
    mkdir -p "$seed"
    : >"$seed/meta-data"
    cat >"$seed/user-data" <<EOF
#cloud-config
hostname: deb-vm
users:
  - name: build
    groups: [sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    plain_text_passwd: build
    ssh_authorized_keys:
      - $(cat "$DIR/id_ed25519.pub")
ssh_pwauth: false
package_update: true
packages: [build-essential, devscripts, equivs, git, attr]
EOF
    xorriso -as mkisofs -quiet -V CIDATA -o "$DIR/seed.iso" "$seed"
}

cmd=${1:-}; [ $# -gt 0 ] && shift
case $cmd in
start)
    [ -f "$DIR/disk.qcow2" ] || make_vm
    setsid qemu-system-x86_64 -enable-kvm -cpu host -smp "$SMP" -m "$MEM" \
        -drive "file=$DIR/disk.qcow2,if=virtio,format=qcow2" \
        -drive "file=$DIR/seed.iso,media=cdrom,readonly=on" \
        -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:$port-:22" -device virtio-net,netdev=n0 \
        -display none -serial "file:$DIR/serial.log" \
        -monitor "unix:$DIR/monitor.sock,server,nowait" >"$DIR/qemu.log" 2>&1 &
    echo -n "waiting for SSH"
    for _ in $(seq 120); do
        vm_ssh true 2>/dev/null && break
        echo -n .; sleep 3
    done
    echo
    # cloud-init installs the build tools after SSH comes up
    vm_ssh cloud-init status --wait >/dev/null
    echo "ready (ssh: scripts/deb-vm.sh ssh)" ;;
ssh)
    vm_ssh "$@" ;;
put)
    dest=${*: -1}
    scp "${ssh_opts[@]}" -P $port -r "${@:1:$#-1}" "build@127.0.0.1:$dest" ;;
get)
    scp "${ssh_opts[@]}" -P $port -r "build@127.0.0.1:$1" "$2" ;;
reset)
    rm -f "$DIR/disk.qcow2" "$DIR/seed.iso" ;;
stop)
    echo system_powerdown | socat - "UNIX-CONNECT:$DIR/monitor.sock" >/dev/null 2>&1 || true ;;
*)
    sed -n '2,17p' "$0"; exit 1 ;;
esac
