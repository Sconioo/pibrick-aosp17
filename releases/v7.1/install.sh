#!/usr/bin/env bash
set -Eeuo pipefail

PKGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK="${1:-}"

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

copy_required() {
    local source="$1"
    local destination="$2"
    local mode="$3"
    local owner="$4"
    local group="$5"

    [ -f "$source" ] || die "source absente : $source"
    [ -e "$destination" ] || die "destination attendue absente : $destination"

    cp -f "$source" "$destination"
    chmod "$mode" "$destination"
    chown "$owner:$group" "$destination"
}

copy_new_or_replace() {
    local source="$1"
    local destination="$2"
    local mode="$3"
    local owner="$4"
    local group="$5"

    [ -f "$source" ] || die "source absente : $source"

    mkdir -p "$(dirname "$destination")"
    cp -f "$source" "$destination"
    chmod "$mode" "$destination"
    chown "$owner:$group" "$destination"
}

compare_file() {
    local source="$1"
    local installed="$2"
    local label="$3"
    local expected actual

    expected="$(sha256sum "$source" | awk '{print $1}')"
    actual="$(sha256sum "$installed" | awk '{print $1}')"

    if [ "$expected" != "$actual" ]; then
        echo "ERREUR : $label"
        echo "  attendu : $expected"
        echo "  obtenu  : $actual"
        exit 1
    fi

    echo "OK : $label"
}

backup_optional() {
    local source="$1"
    local destination="$2"
    local marker="$3"

    mkdir -p "$(dirname "$destination")"

    if [ -e "$source" ]; then
        cp -a "$source" "$destination"
        rm -f "$marker"
    else
        : > "$marker"
    fi
}

[ "$(id -u)" -eq 0 ] ||
    die "lance cet installateur avec sudo"

[ -n "$DISK" ] || {
    echo "Utilisation : sudo ./install.sh /dev/sdX"
    echo
    echo "Disques visibles :"
    lsblk -dpno NAME,SIZE,MODEL,TRAN
    exit 1
}

[ -b "$DISK" ] ||
    die "$DISK n’est pas un périphérique bloc"

TRANSPORT="$(lsblk -dn -o TRAN "$DISK" 2>/dev/null | tr -d '[:space:]')"
[ "$TRANSPORT" = "usb" ] ||
    die "sécurité : $DISK n’est pas présenté comme un disque USB"

BOOT_PART="$(partition_path "$DISK" 1)"
ROOT_PART="$(partition_path "$DISK" 5)"
VENDOR_PART="$(partition_path "$DISK" 6)"

for part in "$BOOT_PART" "$ROOT_PART" "$VENDOR_PART"; do
    [ -b "$part" ] ||
        die "partition introuvable : $part"
done

echo "===== DISQUE SÉLECTIONNÉ ====="
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL,TRAN "$DISK"

echo
echo "Le script écrira uniquement sur : $DISK"
read -r -p "Tape exactement $DISK pour confirmer : " CONFIRM
[ "$CONFIRM" = "$DISK" ] || {
    echo "Installation annulée."
    exit 0
}

echo
echo "===== CONTRÔLE DU PAQUET ====="
(
    cd "$PKGDIR"
    sha256sum -c MANIFEST.sha256
)

WORKDIR="$(mktemp -d /tmp/pibrick-v7-install.XXXXXX)"
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

[ -f "$BOOT_MNT/config.txt" ] ||
    die "la partition boot du piBrick n’est pas reconnue"

if [ -f "$ROOT_MNT/system/framework/services.jar" ]; then
    SYSTEM_DIR="$ROOT_MNT/system"
elif [ -f "$ROOT_MNT/system/system/framework/services.jar" ]; then
    SYSTEM_DIR="$ROOT_MNT/system/system"
else
    die "framework Android introuvable sur $ROOT_PART"
fi

[ -f "$VENDOR_MNT/build.prop" ] ||
    die "vendor/build.prop introuvable sur $VENDOR_PART"

OWNER="${SUDO_USER:-root}"
OWNER_HOME="$(getent passwd "$OWNER" | cut -d: -f6)"
[ -n "$OWNER_HOME" ] || OWNER_HOME="/root"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$OWNER_HOME/pibrick-backups/aosp17-before-v7-$STAMP"

mkdir -p \
    "$BACKUP/boot/overlays" \
    "$BACKUP/system/framework/oat/arm64" \
    "$BACKUP/vendor/apex" \
    "$BACKUP/vendor/etc/init.d" \
    "$BACKUP/vendor/etc/init" \
    "$BACKUP/vendor/bin"

echo
echo "===== SAUVEGARDE AVANT INSTALLATION ====="
echo "$BACKUP"

cp -a "$BOOT_MNT/Image" "$BACKUP/boot/Image"
cp -a "$BOOT_MNT/overlays/vc4-kms-dsi-pibrick.dtbo" \
    "$BACKUP/boot/overlays/vc4-kms-dsi-pibrick.dtbo"

cp -a "$SYSTEM_DIR/framework/services.jar" \
    "$BACKUP/system/framework/services.jar"

for file in services.art services.odex services.vdex; do
    cp -a "$SYSTEM_DIR/framework/oat/arm64/$file" \
        "$BACKUP/system/framework/oat/arm64/$file"
done

cp -a "$VENDOR_MNT/build.prop" "$BACKUP/vendor/build.prop"

backup_optional \
    "$VENDOR_MNT/apex/com.android.hardware.health.rpi.apex" \
    "$BACKUP/vendor/apex/com.android.hardware.health.rpi.apex" \
    "$BACKUP/vendor/apex/com.android.hardware.health.rpi.apex.absent"

backup_optional \
    "$VENDOR_MNT/etc/init.d/04pibrick-microphone" \
    "$BACKUP/vendor/etc/init.d/04pibrick-microphone" \
    "$BACKUP/vendor/etc/init.d/04pibrick-microphone.absent"

backup_optional \
    "$VENDOR_MNT/etc/init/sysinit.rc" \
    "$BACKUP/vendor/etc/init/sysinit.rc" \
    "$BACKUP/vendor/etc/init/sysinit.rc.absent"

backup_optional \
    "$VENDOR_MNT/bin/sysinit" \
    "$BACKUP/vendor/bin/sysinit" \
    "$BACKUP/vendor/bin/sysinit.absent"

cat > "$BACKUP/BACKUP_INFO.txt" <<EOF
Création : $(date --iso-8601=seconds)
Disque cible : $DISK
Partition boot : $BOOT_PART
Partition système : $ROOT_PART
Partition vendor : $VENDOR_PART
EOF

cp -a "$PKGDIR/restore.sh" "$BACKUP/restore.sh"
chmod 0755 "$BACKUP/restore.sh"

(
    cd "$BACKUP"
    find . -type f ! -name BACKUP_MANIFEST.sha256 -print0 |
        sort -z |
        xargs -0 sha256sum > BACKUP_MANIFEST.sha256
)

echo
echo "===== INSTALLATION BOOT ====="

copy_required \
    "$PKGDIR/payload/boot/Image" \
    "$BOOT_MNT/Image" \
    0644 0 0

copy_required \
    "$PKGDIR/payload/boot/overlays/vc4-kms-dsi-pibrick.dtbo" \
    "$BOOT_MNT/overlays/vc4-kms-dsi-pibrick.dtbo" \
    0644 0 0

echo
echo "===== INSTALLATION FRAMEWORK ====="

copy_required \
    "$PKGDIR/payload/system/framework/services.jar" \
    "$SYSTEM_DIR/framework/services.jar" \
    0644 0 0

for file in services.art services.odex services.vdex; do
    copy_required \
        "$PKGDIR/payload/system/framework/oat/arm64/$file" \
        "$SYSTEM_DIR/framework/oat/arm64/$file" \
        0644 0 0
done

echo
echo "===== INSTALLATION BATTERIE ====="

copy_new_or_replace \
    "$PKGDIR/payload/vendor/apex/com.android.hardware.health.rpi.apex" \
    "$VENDOR_MNT/apex/com.android.hardware.health.rpi.apex" \
    0644 0 0

echo
echo "===== INSTALLATION MICROPHONE ====="

copy_new_or_replace \
    "$PKGDIR/payload/vendor/etc/init.d/04pibrick-microphone" \
    "$VENDOR_MNT/etc/init.d/04pibrick-microphone" \
    0755 0 2000

if [ -f "$PKGDIR/payload/vendor/etc/init/sysinit.rc" ]; then
    copy_new_or_replace \
        "$PKGDIR/payload/vendor/etc/init/sysinit.rc" \
        "$VENDOR_MNT/etc/init/sysinit.rc" \
        0644 0 0
fi

if [ -f "$PKGDIR/payload/vendor/bin/sysinit" ]; then
    copy_new_or_replace \
        "$PKGDIR/payload/vendor/bin/sysinit" \
        "$VENDOR_MNT/bin/sysinit" \
        0755 0 2000
fi

echo
echo "===== PROPRIÉTÉS AUDIO ====="

sed -i \
    -e '/^persist\.vendor\.audio\.device=/d' \
    -e '/^ro\.boot\.audio\.tinyalsa\.simulate_input=/d' \
    "$VENDOR_MNT/build.prop"

printf '\n%s\n%s\n' \
    'persist.vendor.audio.device=dac' \
    'ro.boot.audio.tinyalsa.simulate_input=false' \
    >> "$VENDOR_MNT/build.prop"

sync

echo
echo "===== VÉRIFICATION ====="

compare_file \
    "$PKGDIR/payload/boot/Image" \
    "$BOOT_MNT/Image" \
    "noyau"

compare_file \
    "$PKGDIR/payload/boot/overlays/vc4-kms-dsi-pibrick.dtbo" \
    "$BOOT_MNT/overlays/vc4-kms-dsi-pibrick.dtbo" \
    "overlay piBrick"

compare_file \
    "$PKGDIR/payload/system/framework/services.jar" \
    "$SYSTEM_DIR/framework/services.jar" \
    "services.jar"

for file in services.art services.odex services.vdex; do
    compare_file \
        "$PKGDIR/payload/system/framework/oat/arm64/$file" \
        "$SYSTEM_DIR/framework/oat/arm64/$file" \
        "$file"
done

compare_file \
    "$PKGDIR/payload/vendor/apex/com.android.hardware.health.rpi.apex" \
    "$VENDOR_MNT/apex/com.android.hardware.health.rpi.apex" \
    "batterie V1 lissée"

compare_file \
    "$PKGDIR/payload/vendor/etc/init.d/04pibrick-microphone" \
    "$VENDOR_MNT/etc/init.d/04pibrick-microphone" \
    "script microphone"

grep -qx 'persist.vendor.audio.device=dac' \
    "$VENDOR_MNT/build.prop" ||
    die "propriété persist.vendor.audio.device incorrecte"

grep -qx 'ro.boot.audio.tinyalsa.simulate_input=false' \
    "$VENDOR_MNT/build.prop" ||
    die "propriété simulate_input incorrecte"

echo "OK : propriétés audio"

echo
echo "INSTALLATION V7 TERMINÉE"
echo "Sauvegarde de restauration : $BACKUP"
echo
echo "Redémarre le piBrick puis lance :"
echo "  ./verify-adb.sh 192.168.1.168:5555"
