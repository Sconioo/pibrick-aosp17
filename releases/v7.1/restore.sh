#!/usr/bin/env bash
set -Eeuo pipefail

DISK="${1:-}"
BACKUP="${2:-}"

WORKDIR=""
BOOT_MNT=""
ROOT_MNT=""
VENDOR_MNT=""

cleanup() {
    sync 2>/dev/null || true

    if [ -n "$BOOT_MNT" ] && mountpoint -q "$BOOT_MNT"; then
        umount "$BOOT_MNT" 2>/dev/null || true
    fi

    if [ -n "$ROOT_MNT" ] && mountpoint -q "$ROOT_MNT"; then
        umount "$ROOT_MNT" 2>/dev/null || true
    fi

    if [ -n "$VENDOR_MNT" ] && mountpoint -q "$VENDOR_MNT"; then
        umount "$VENDOR_MNT" 2>/dev/null || true
    fi

    [ -z "$WORKDIR" ] || rm -rf "$WORKDIR" 2>/dev/null || true
}
trap cleanup EXIT

die() {
    echo "ERREUR : $*" >&2
    exit 1
}

partition_path() {
    local disk="$1"
    local number="$2"

    if [[ "$disk" =~ [0-9]$ ]]; then
        printf '%sp%s\n' "$disk" "$number"
    else
        printf '%s%s\n' "$disk" "$number"
    fi
}

restore_optional() {
    local backup_file="$1"
    local absent_marker="$2"
    local destination="$3"

    if [ -f "$absent_marker" ]; then
        rm -f "$destination"
    elif [ -f "$backup_file" ]; then
        mkdir -p "$(dirname "$destination")"
        cp -af "$backup_file" "$destination"
    fi
}

[ "$(id -u)" -eq 0 ] ||
    die "lance cette restauration avec sudo"

[ -n "$DISK" ] && [ -n "$BACKUP" ] || {
    echo "Utilisation :"
    echo "  sudo ./restore.sh /dev/sdX /chemin/aosp17-before-v7-AAAA..."
    exit 1
}

[ -b "$DISK" ] ||
    die "$DISK n’est pas un périphérique bloc"

[ -d "$BACKUP" ] ||
    die "sauvegarde introuvable : $BACKUP"

[ -f "$BACKUP/BACKUP_MANIFEST.sha256" ] ||
    die "BACKUP_MANIFEST.sha256 absent"

echo "===== CONTRÔLE DE LA SAUVEGARDE ====="
(
    cd "$BACKUP"
    sha256sum -c BACKUP_MANIFEST.sha256
)

BOOT_PART="$(partition_path "$DISK" 1)"
ROOT_PART="$(partition_path "$DISK" 5)"
VENDOR_PART="$(partition_path "$DISK" 6)"

for part in "$BOOT_PART" "$ROOT_PART" "$VENDOR_PART"; do
    [ -b "$part" ] ||
        die "partition introuvable : $part"
done

echo
echo "===== DISQUE DE RESTAURATION ====="
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL,TRAN "$DISK"

echo
read -r -p "Tape exactement RESTAURER-$DISK : " CONFIRM
[ "$CONFIRM" = "RESTAURER-$DISK" ] || {
    echo "Restauration annulée."
    exit 0
}

WORKDIR="$(mktemp -d /tmp/pibrick-v7-restore.XXXXXX)"
BOOT_MNT="$WORKDIR/boot"
ROOT_MNT="$WORKDIR/root"
VENDOR_MNT="$WORKDIR/vendor"

mkdir -p "$BOOT_MNT" "$ROOT_MNT" "$VENDOR_MNT"

for part in "$BOOT_PART" "$ROOT_PART" "$VENDOR_PART"; do
    umount "$part" 2>/dev/null || true
done

mount "$BOOT_PART" "$BOOT_MNT"
mount "$ROOT_PART" "$ROOT_MNT"
mount "$VENDOR_PART" "$VENDOR_MNT"

if [ -f "$ROOT_MNT/system/framework/services.jar" ]; then
    SYSTEM_DIR="$ROOT_MNT/system"
elif [ -f "$ROOT_MNT/system/system/framework/services.jar" ]; then
    SYSTEM_DIR="$ROOT_MNT/system/system"
else
    die "framework Android introuvable"
fi

echo
echo "===== RESTAURATION ====="

cp -af "$BACKUP/boot/Image" "$BOOT_MNT/Image"
cp -af "$BACKUP/boot/overlays/vc4-kms-dsi-pibrick.dtbo" \
    "$BOOT_MNT/overlays/vc4-kms-dsi-pibrick.dtbo"

cp -af "$BACKUP/system/framework/services.jar" \
    "$SYSTEM_DIR/framework/services.jar"

for file in services.art services.odex services.vdex; do
    cp -af "$BACKUP/system/framework/oat/arm64/$file" \
        "$SYSTEM_DIR/framework/oat/arm64/$file"
done

cp -af "$BACKUP/vendor/build.prop" "$VENDOR_MNT/build.prop"

restore_optional \
    "$BACKUP/vendor/apex/com.android.hardware.health.rpi.apex" \
    "$BACKUP/vendor/apex/com.android.hardware.health.rpi.apex.absent" \
    "$VENDOR_MNT/apex/com.android.hardware.health.rpi.apex"

restore_optional \
    "$BACKUP/vendor/etc/init.d/04pibrick-microphone" \
    "$BACKUP/vendor/etc/init.d/04pibrick-microphone.absent" \
    "$VENDOR_MNT/etc/init.d/04pibrick-microphone"

restore_optional \
    "$BACKUP/vendor/etc/init/sysinit.rc" \
    "$BACKUP/vendor/etc/init/sysinit.rc.absent" \
    "$VENDOR_MNT/etc/init/sysinit.rc"

restore_optional \
    "$BACKUP/vendor/bin/sysinit" \
    "$BACKUP/vendor/bin/sysinit.absent" \
    "$VENDOR_MNT/bin/sysinit"

sync

echo
echo "RESTAURATION TERMINÉE"
