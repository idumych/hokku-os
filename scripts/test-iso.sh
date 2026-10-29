#!/bin/bash
# test-iso.sh CMD …  — boot the Hokku OS ISO (or the system installed from it) in QEMU/KVM.
#
#   start [ISO]      boot the ISO (default: newest out/hokku-os-*.iso) with an empty
#                    20 GB target disk, UEFI
#   start-disk       boot what the installer put on that disk
#   shot NAME        screenshot to $DIR/NAME.png
#   key KEYS         QEMU key names (ret, alt-tab, ctrl-alt-t, …)
#   type TEXT        letters, digits, space and . / - _
#   click X Y        absolute left click (usb-tablet) on a 1280x800 screen
#   stop             hard power-off
#
#   DIR (default build/vm)   BIOS=1 boots SeaBIOS instead of UEFI
#   QCPU (default Nehalem): a CPU without AVX/AVX2, so anything built for x86-64-v3
#   (the host's -march=native, CachyOS's v3 repos) crashes here instead of on a user's machine.
# SSH: 127.0.0.1:2226 -> guest 22 (the live ISO runs sshd; set a password first: passwd liveuser).
# Needs qemu-system-x86_64, edk2-ovmf, socat, ImageMagick.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
DIR=${DIR:-$root/build/vm}
QCPU=${QCPU:-Nehalem}
mkdir -p "$DIR"

hmp() { echo "$1" | socat - "UNIX-CONNECT:$DIR/monitor.sock" >/dev/null; }
qmp() {
    printf '{"execute":"qmp_capabilities"}\n%s\n' "$1" | socat - "UNIX-CONNECT:$DIR/qmp.sock" >/dev/null
}

boot() {
    local boot_args=("$@")
    [ -f "$DIR/disk.qcow2" ] || qemu-img create -q -f qcow2 "$DIR/disk.qcow2" 20G
    local fw=()
    if [ -z "${BIOS:-}" ]; then
        [ -f "$DIR/OVMF_VARS.fd" ] || cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$DIR/OVMF_VARS.fd"
        fw=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd
            -drive "if=pflash,format=raw,file=$DIR/OVMF_VARS.fd")
    fi
    rm -f "$DIR/monitor.sock" "$DIR/qmp.sock"
    setsid qemu-system-x86_64 -enable-kvm -cpu "$QCPU" -smp 4 -m 4096 "${fw[@]}" \
        -drive "file=$DIR/disk.qcow2,if=virtio,format=qcow2" "${boot_args[@]}" \
        -netdev user,id=n0,hostfwd=tcp:127.0.0.1:2226-:22 -device virtio-net,netdev=n0 \
        -device virtio-vga -display none -device qemu-xhci -device usb-tablet -device usb-kbd \
        -audiodev none,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 \
        -monitor "unix:$DIR/monitor.sock,server,nowait" -qmp "unix:$DIR/qmp.sock,server,nowait" \
        -serial "file:$DIR/serial.log" >"$DIR/qemu.log" 2>&1 &
    sleep 2
    [ -S "$DIR/monitor.sock" ] || { cat "$DIR/qemu.log"; exit 1; }
    echo "started (serial: $DIR/serial.log)"
}

cmd=${1:-}; [ $# -gt 0 ] && shift
case $cmd in
start)
    iso=${1:-$(ls -t "$root"/out/hokku-os-*.iso 2>/dev/null | head -1)}
    [ -f "$iso" ] || { echo "no ISO; run scripts/build-iso.sh" >&2; exit 1; }
    boot -cdrom "$iso" -boot order=d ;;
start-disk)
    boot -boot order=c ;;
shot)
    hmp "screendump $DIR/$1.ppm"; sleep 0.5
    magick "$DIR/$1.ppm" "$DIR/$1.png" && rm "$DIR/$1.ppm" && echo "$DIR/$1.png" ;;
key)
    for k in "$@"; do hmp "sendkey $k"; sleep 0.1; done ;;
type)
    s=$1
    for ((i = 0; i < ${#s}; i++)); do
        c=${s:i:1}
        case $c in
            ' ') k=spc ;; .) k=dot ;; /) k=slash ;; -) k=minus ;; _) k=shift-minus ;;
            [A-Z]) k=shift-${c,,} ;; *) k=$c ;;
        esac
        hmp "sendkey $k"; sleep 0.05
    done ;;
click)
    x=$(( $1 * 32767 / 1280 )); y=$(( $2 * 32767 / 800 ))
    ev() { printf '{"type":"%s","data":%s}' "$1" "$2"; }
    move() { qmp "{\"execute\":\"input-send-event\",\"arguments\":{\"events\":[$(ev abs '{"axis":"x","value":'$1'}'),$(ev abs '{"axis":"y","value":'$2'}')]}}"; }
    # Off by one first: the kernel drops a tablet position equal to the last one,
    # so a click where the previous one was never moves a compositor started since
    # (a new session), and the press lands wherever its own pointer is.
    move $(( x > 0 ? x - 1 : 1 )) "$y"
    move "$x" "$y"
    qmp '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":true,"button":"left"}}]}}'
    sleep 0.15
    qmp '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":false,"button":"left"}}]}}' ;;
stop)
    hmp quit || true ;;
*)
    sed -n '2,19p' "$0"; exit 1 ;;
esac
