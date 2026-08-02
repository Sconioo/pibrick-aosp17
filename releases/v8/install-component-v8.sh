#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ACTION="${1:-apply}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="$ROOT/payload"
BACKUP_ROOT="$HOME/pibrick-aosp17-backups/v8"
LATEST_FILE="$BACKUP_ROOT/LATEST"
EXPECTED_BUILD_ID="CP2A.260605.016"

IMAGE_SHA="ce45152acb573f0deffbf0b953df6a8dc14392664dacdb667006a64eee0fe4b0"
DTBO_SHA="98bf1b2606b8bcfcc00440a5924a26549bc617bbac37cbbf904b60e3f0eb9583"
JAR_SHA="5145a87744fe96127c1e0ff317039d989cf2a6383e1fa7ab3fd72d47521850ae"
ART_SHA="9b2fae2e3a01655fb752c0d940e7199b3d3c3a5121d8433b8f9c320033ad285a"
ODEX_SHA="d352c6502b88072f42c9e196fdced4ff6b40dbc084dc086639990e9813d370cd"
VDEX_SHA="cd940512c042990e09a2a3c3cd383f53c4dc44ca9b33fb723a55c85e7d59ec49"
HEALTH_SHA="9a967ab26d5a6d894daef8ee88741711e35fa39a83e7ca6287e0f3527554fb32"
STOCK_INIT_RPI5_SHA="1d42b6d9d462035776d883416a5d5a92af54a29bc43bc30e6e0885e4eb8b89d6"
TESTED_INIT_RPI5_SHA="b583b041976c4f81e031431e86d7f04ed721f5881f9f4bd198856dd7edaf0acb"
INIT_RPI5_SHA="18547fc5148556453c6210eb5d69b8f0b399aa44d1c49c1f3df45be3b1f7b453"
HAL_AMIXER_SHA="e35c4ede27f85fe9f8a96cc8e798eb004cf91a87e99ac46ae24784dfe38a3a5d"
HAL_AMIXER_LABEL="u:object_r:hal_audio_default_exec:s0"
INIT_RPI5_LABEL="u:object_r:vendor_configs_file:s0"

WORK=""
BOOT_MOUNT=""
SYSTEM_MOUNT=""
VENDOR_MOUNT=""
SYSTEM_ROOT=""
RPIBOOT_DISK=""
BOOT_PARTITION=""
SYSTEM_PARTITION=""
VENDOR_PARTITION=""
BACKUP_DIR=""
BACKUP_READY=0
INSTALL_IN_PROGRESS=0

die() {
    printf 'ERREUR : %s\n' "$*" >&2
    exit 1
}

file_hash() {
    sudo sha256sum "$1" | awk '{print $1}'
}

verify_package() {
    (
        cd "$ROOT"
        sha256sum -c SHA256SUMS
    ) || die "contrôle du composant V8 échoué"
}

restore_optional() {
    local backup="$1"
    local absent="$2"
    local target="$3"

    if [[ -f "$absent" ]]; then
        sudo rm -f "$target"
    elif [[ -f "$backup" ]]; then
        sudo mkdir -p "$(dirname "$target")"
        sudo cp -a "$backup" "$target"
    fi
}

restore_backup() {
    local dir="$1"

    [[ -d "$dir" ]] ||
        die "sauvegarde introuvable : $dir"

    printf '%s\n' '===== RESTAURATION V8 ====='

    # La partition boot est en FAT : ne pas tenter de restaurer
    # propriétaires, permissions ou attributs Unix inexistants.
    sudo cp -- "$dir/boot/Image" "$BOOT_MOUNT/Image"
    sudo cp -- "$dir/boot/vc4-kms-dsi-pibrick.dtbo" \
        "$BOOT_MOUNT/overlays/vc4-kms-dsi-pibrick.dtbo"

    sudo cp -a "$dir/system/services.jar" \
        "$SYSTEM_ROOT/framework/services.jar"
    sudo cp -a "$dir/system/services.art" \
        "$SYSTEM_ROOT/framework/oat/arm64/services.art"
    sudo cp -a "$dir/system/services.odex" \
        "$SYSTEM_ROOT/framework/oat/arm64/services.odex"
    sudo cp -a "$dir/system/services.vdex" \
        "$SYSTEM_ROOT/framework/oat/arm64/services.vdex"

    sudo cp -a "$dir/vendor/build.prop" \
        "$VENDOR_MOUNT/build.prop"

    restore_optional \
        "$dir/vendor/apex/com.android.hardware.health.rpi.apex" \
        "$dir/vendor/apex/com.android.hardware.health.rpi.apex.was-absent" \
        "$VENDOR_MOUNT/apex/com.android.hardware.health.rpi.apex"

    sudo cp -a "$dir/vendor/etc/init/hw/init.rpi5.rc" \
        "$VENDOR_MOUNT/etc/init/hw/init.rpi5.rc"

    restore_optional \
        "$dir/vendor/bin/hw/android.hardware.audio.service" \
        "$dir/vendor/bin/hw/android.hardware.audio.service.was-absent" \
        "$VENDOR_MOUNT/bin/hw/android.hardware.audio.service"

    restore_optional \
        "$dir/vendor/etc/init.d/04pibrick-microphone" \
        "$dir/vendor/etc/init.d/04pibrick-microphone.was-absent" \
        "$VENDOR_MOUNT/etc/init.d/04pibrick-microphone"

    restore_optional \
        "$dir/vendor/etc/init/sysinit.rc" \
        "$dir/vendor/etc/init/sysinit.rc.was-absent" \
        "$VENDOR_MOUNT/etc/init/sysinit.rc"

    restore_optional \
        "$dir/vendor/bin/sysinit" \
        "$dir/vendor/bin/sysinit.was-absent" \
        "$VENDOR_MOUNT/bin/sysinit"

    restore_optional \
        "$dir/vendor/bin/rpi-pibrick-microphone.sh" \
        "$dir/vendor/bin/rpi-pibrick-microphone.sh.was-absent" \
        "$VENDOR_MOUNT/bin/rpi-pibrick-microphone.sh"

    restore_optional \
        "$dir/vendor/bin/pibrick-amixer" \
        "$dir/vendor/bin/pibrick-amixer.was-absent" \
        "$VENDOR_MOUNT/bin/pibrick-amixer"

    sync
}

cleanup() {
    local rc=$?
    trap - EXIT
    set +e

    if ((rc != 0 && INSTALL_IN_PROGRESS == 1 && BACKUP_READY == 1)); then
        printf '%s\n' \
            'Échec pendant l’installation. Restauration automatique...' >&2
        restore_backup "$BACKUP_DIR" || true
    fi

    if [[ -n "$SYSTEM_MOUNT" ]] && mountpoint -q "$SYSTEM_MOUNT"; then
        sudo umount "$SYSTEM_MOUNT" >/dev/null 2>&1 || true
    fi
    if [[ -n "$VENDOR_MOUNT" ]] && mountpoint -q "$VENDOR_MOUNT"; then
        sudo umount "$VENDOR_MOUNT" >/dev/null 2>&1 || true
    fi
    if [[ -n "$BOOT_MOUNT" ]] && mountpoint -q "$BOOT_MOUNT"; then
        sudo umount "$BOOT_MOUNT" >/dev/null 2>&1 || true
    fi

    [[ -z "$WORK" ]] || rm -rf "$WORK"
    exit "$rc"
}
trap cleanup EXIT

for cmd in awk basename cp cut date dd find findmnt grep head install lsblk \
    mkdir mktemp mount mountpoint python3 rm rmdir sed sha256sum sort stat \
    sudo sync truncate umount xargs; do
    command -v "$cmd" >/dev/null 2>&1 ||
        die "commande absente : $cmd"
done

((EUID != 0)) ||
    die "lancez ce script sans sudo"

detect_partitions() {
    mapfile -t disks < <(
        lsblk -dnpo NAME,MODEL |
            awk 'index($0, "Raspberry Pi multi-function USB device") {print $1}'
    )

    ((${#disks[@]} == 1)) ||
        die "un unique piBrick en mode rpiboot est requis"

    RPIBOOT_DISK="${disks[0]}"

    mapfile -t boot_parts < <(
        lsblk -rpn -o NAME,LABEL,FSTYPE "$RPIBOOT_DISK" |
            awk '$2 == "boot" && $3 == "vfat" {print $1}'
    )
    mapfile -t vendor_parts < <(
        lsblk -rpn -o NAME,LABEL,FSTYPE "$RPIBOOT_DISK" |
            awk '$2 == "vendor" && $3 ~ /^ext[234]$/ {print $1}'
    )

    ((${#boot_parts[@]} == 1)) ||
        die "partition boot unique introuvable"
    ((${#vendor_parts[@]} == 1)) ||
        die "partition vendor unique introuvable"

    BOOT_PARTITION="${boot_parts[0]}"
    VENDOR_PARTITION="${vendor_parts[0]}"

    mapfile -t ext_parts < <(
        lsblk -rpn -o NAME,TYPE,FSTYPE "$RPIBOOT_DISK" |
            awk '$2 == "part" && $3 ~ /^ext[234]$/ {print $1}'
    )

    WORK="$(mktemp -d /tmp/pibrick-v8.XXXXXX)"
    mkdir -p "$WORK/boot" "$WORK/vendor" "$WORK/system"

    sudo -v

    for part in "${ext_parts[@]}"; do
        existing_mount="$(
            findmnt -rn -S "$part" -o TARGET |
                head -n1 || true
        )"
        mounted_here=0

        if [[ -n "$existing_mount" ]]; then
            probe="$existing_mount"
        else
            probe="$WORK/probe-$(basename "$part")"
            mkdir -p "$probe"

            if ! sudo mount -o ro "$part" "$probe" >/dev/null 2>&1; then
                rmdir "$probe"
                continue
            fi

            mounted_here=1
        fi

        if [[ -f "$probe/system/framework/services.jar" ||
              -f "$probe/framework/services.jar" ]]; then
            SYSTEM_PARTITION="$part"

            if ((mounted_here == 1)); then
                sudo umount "$probe"
                rmdir "$probe"
            fi

            break
        fi

        if ((mounted_here == 1)); then
            sudo umount "$probe"
            rmdir "$probe"
        fi
    done

    [[ -n "$SYSTEM_PARTITION" ]] ||
        die "partition système Android introuvable"
}

unmount_existing_partition() {
    local partition="$1"
    local existing_mount

    existing_mount="$(
        findmnt -rn -S "$partition" -o TARGET |
            head -n1 || true
    )"

    if [[ -n "$existing_mount" ]]; then
        printf 'Démontage préalable : %s (%s)\n' \
            "$partition" "$existing_mount"
        sudo umount "$partition"
    fi
}

mount_partitions() {
    unmount_existing_partition "$BOOT_PARTITION"
    unmount_existing_partition "$VENDOR_PARTITION"
    unmount_existing_partition "$SYSTEM_PARTITION"

    sudo mount -o rw "$BOOT_PARTITION" "$WORK/boot"
    BOOT_MOUNT="$WORK/boot"

    sudo mount -o rw "$VENDOR_PARTITION" "$WORK/vendor"
    VENDOR_MOUNT="$WORK/vendor"

    sudo mount -o rw "$SYSTEM_PARTITION" "$WORK/system"
    SYSTEM_MOUNT="$WORK/system"

    if [[ -f "$SYSTEM_MOUNT/system/framework/services.jar" ]]; then
        SYSTEM_ROOT="$SYSTEM_MOUNT/system"
    elif [[ -f "$SYSTEM_MOUNT/framework/services.jar" ]]; then
        SYSTEM_ROOT="$SYSTEM_MOUNT"
    else
        die "services.jar absent de la partition système"
    fi

    [[ -f "$BOOT_MOUNT/Image" ]] ||
        die "Image absente de boot"
    [[ -f "$BOOT_MOUNT/overlays/vc4-kms-dsi-pibrick.dtbo" ]] ||
        die "overlay piBrick absent de boot"
    [[ -f "$VENDOR_MOUNT/build.prop" ]] ||
        die "vendor/build.prop absent"

    build_prop="$SYSTEM_ROOT/build.prop"
    if [[ -f "$build_prop" ]]; then
        build_id="$(
            sudo grep -m1 '^ro.build.id=' "$build_prop" |
                cut -d= -f2- || true
        )"
        [[ -z "$build_id" || "$build_id" == "$EXPECTED_BUILD_ID" ]] ||
            die "build incompatible : $build_id"
    fi
}

backup_optional() {
    local target="$1"
    local backup="$2"
    local absent="$3"

    mkdir -p "$(dirname "$backup")"

    if [[ -e "$target" ]]; then
        sudo cp -a "$target" "$backup"
    else
        touch "$absent"
    fi
}

create_backup() {
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    BACKUP_DIR="$BACKUP_ROOT/before-$stamp"

    mkdir -p \
        "$BACKUP_DIR/boot" \
        "$BACKUP_DIR/system" \
        "$BACKUP_DIR/vendor/apex" \
        "$BACKUP_DIR/vendor/etc/init.d" \
        "$BACKUP_DIR/vendor/etc/init/hw" \
        "$BACKUP_DIR/vendor/etc/init" \
        "$BACKUP_DIR/vendor/bin/hw" \
        "$BACKUP_DIR/vendor/bin"

    sudo cp -a "$BOOT_MOUNT/Image" \
        "$BACKUP_DIR/boot/Image"
    sudo cp -a "$BOOT_MOUNT/overlays/vc4-kms-dsi-pibrick.dtbo" \
        "$BACKUP_DIR/boot/vc4-kms-dsi-pibrick.dtbo"

    sudo cp -a "$SYSTEM_ROOT/framework/services.jar" \
        "$BACKUP_DIR/system/services.jar"
    sudo cp -a "$SYSTEM_ROOT/framework/oat/arm64/services.art" \
        "$BACKUP_DIR/system/services.art"
    sudo cp -a "$SYSTEM_ROOT/framework/oat/arm64/services.odex" \
        "$BACKUP_DIR/system/services.odex"
    sudo cp -a "$SYSTEM_ROOT/framework/oat/arm64/services.vdex" \
        "$BACKUP_DIR/system/services.vdex"

    sudo cp -a "$VENDOR_MOUNT/build.prop" \
        "$BACKUP_DIR/vendor/build.prop"

    backup_optional \
        "$VENDOR_MOUNT/apex/com.android.hardware.health.rpi.apex" \
        "$BACKUP_DIR/vendor/apex/com.android.hardware.health.rpi.apex" \
        "$BACKUP_DIR/vendor/apex/com.android.hardware.health.rpi.apex.was-absent"

    sudo cp -a "$VENDOR_MOUNT/etc/init/hw/init.rpi5.rc" \
        "$BACKUP_DIR/vendor/etc/init/hw/init.rpi5.rc"

    backup_optional \
        "$VENDOR_MOUNT/bin/hw/android.hardware.audio.service" \
        "$BACKUP_DIR/vendor/bin/hw/android.hardware.audio.service" \
        "$BACKUP_DIR/vendor/bin/hw/android.hardware.audio.service.was-absent"

    backup_optional \
        "$VENDOR_MOUNT/etc/init.d/04pibrick-microphone" \
        "$BACKUP_DIR/vendor/etc/init.d/04pibrick-microphone" \
        "$BACKUP_DIR/vendor/etc/init.d/04pibrick-microphone.was-absent"

    backup_optional \
        "$VENDOR_MOUNT/etc/init/sysinit.rc" \
        "$BACKUP_DIR/vendor/etc/init/sysinit.rc" \
        "$BACKUP_DIR/vendor/etc/init/sysinit.rc.was-absent"

    backup_optional \
        "$VENDOR_MOUNT/bin/sysinit" \
        "$BACKUP_DIR/vendor/bin/sysinit" \
        "$BACKUP_DIR/vendor/bin/sysinit.was-absent"

    backup_optional \
        "$VENDOR_MOUNT/bin/rpi-pibrick-microphone.sh" \
        "$BACKUP_DIR/vendor/bin/rpi-pibrick-microphone.sh" \
        "$BACKUP_DIR/vendor/bin/rpi-pibrick-microphone.sh.was-absent"

    backup_optional \
        "$VENDOR_MOUNT/bin/pibrick-amixer" \
        "$BACKUP_DIR/vendor/bin/pibrick-amixer" \
        "$BACKUP_DIR/vendor/bin/pibrick-amixer.was-absent"

    sudo chown -R "$(id -u):$(id -g)" "$BACKUP_DIR"

    (
        cd "$BACKUP_DIR"
        find . -type f ! -name SHA256SUMS-before -print0 |
            sort -z |
            xargs -0 sha256sum > SHA256SUMS-before
    )

    printf '%s\n' "$BACKUP_DIR" > "$LATEST_FILE"
    BACKUP_READY=1

    printf 'Sauvegarde V8 : %s\n' "$BACKUP_DIR"
}

write_existing() {
    local source="$1"
    local target="$2"
    local mode="$3"
    local owner="$4"
    local group="$5"

    [[ -f "$source" ]] ||
        die "source absente : $source"
    [[ -f "$target" ]] ||
        die "cible absente : $target"

    sudo dd if="$source" of="$target" bs=4M conv=fsync status=none
    sudo truncate -s "$(stat -c '%s' "$source")" "$target"
    sudo chown "$owner:$group" "$target"
    sudo chmod "$mode" "$target"
}

write_boot_file() {
    local source="$1"
    local target="$2"

    [[ -f "$source" ]] ||
        die "source boot absente : $source"
    [[ -f "$target" ]] ||
        die "cible boot absente : $target"

    # Écriture en place adaptée à la partition FAT. Aucun chown/chmod :
    # la FAT ne gère pas ces métadonnées et peut les refuser.
    sudo dd if="$source" of="$target" bs=4M conv=fsync status=none
    sudo truncate -s "$(stat -c '%s' "$source")" "$target"
}

install_file() {
    local source="$1"
    local target="$2"
    local mode="$3"
    local owner="$4"
    local group="$5"

    sudo mkdir -p "$(dirname "$target")"
    sudo install -m "$mode" "$source" "$target"
    sudo chown "$owner:$group" "$target"
}

get_selinux_label() {
    sudo python3 - "$1" <<'PYLABEL'
import os
import sys

value = os.getxattr(sys.argv[1], b"security.selinux")
print(value.rstrip(b"\0").decode("ascii"))
PYLABEL
}

set_selinux_label() {
    local target="$1"
    local label="$2"

    sudo python3 - "$target" "$label" <<'PYLABEL'
import os
import sys

os.setxattr(
    sys.argv[1],
    b"security.selinux",
    sys.argv[2].encode("ascii") + b"\0",
)
PYLABEL

    [[ "$(get_selinux_label "$target")" == "$label" ]] ||
        die "étiquette SELinux incorrecte : $target"
}

remove_optional() {
    local target="$1"
    sudo rm -f -- "$target"
}

check_microphone_target_compatibility() {
    local init_target="$VENDOR_MOUNT/etc/init/hw/init.rpi5.rc"
    local hal_target="$VENDOR_MOUNT/bin/hw/android.hardware.audio.service"
    local init_hash hal_hash

    [[ -f "$init_target" ]] ||
        die "init.rpi5.rc absent"

    init_hash="$(file_hash "$init_target")"
    case "$init_hash" in
        "$STOCK_INIT_RPI5_SHA"|"$TESTED_INIT_RPI5_SHA"|"$INIT_RPI5_SHA") ;;
        *) die "init.rpi5.rc incompatible : $init_hash" ;;
    esac

    [[ "$(get_selinux_label "$init_target")" == "$INIT_RPI5_LABEL" ]] ||
        die "étiquette SELinux init.rpi5.rc incompatible"

    if [[ -e "$hal_target" ]]; then
        hal_hash="$(file_hash "$hal_target")"
        [[ "$hal_hash" == "$HAL_AMIXER_SHA" ]] ||
            die "service HAL audio existant incompatible : $hal_hash"
    fi
}

set_audio_properties() {
    local tmp
    tmp="$(mktemp)"

    sudo awk '
        !/^persist\.vendor\.audio\.device=/ &&
        !/^ro\.boot\.audio\.tinyalsa\.simulate_input=/
    ' "$VENDOR_MOUNT/build.prop" > "$tmp"

    printf '\n%s\n%s\n' \
        'persist.vendor.audio.device=dac' \
        'ro.boot.audio.tinyalsa.simulate_input=false' \
        >> "$tmp"

    sudo dd if="$tmp" of="$VENDOR_MOUNT/build.prop" \
        bs=4M conv=fsync status=none
    sudo truncate -s "$(stat -c '%s' "$tmp")" \
        "$VENDOR_MOUNT/build.prop"

    rm -f "$tmp"
}

check_target() {
    local target="$1"
    local expected="$2"
    local label="$3"
    local actual

    actual="$(file_hash "$target")"
    [[ "$actual" == "$expected" ]] ||
        die "$label incorrect : $actual"

    printf 'OK : %s\n' "$label"
}

show_status() {
    local actual_label legacy

    printf 'Disque  : %s\n' "$RPIBOOT_DISK"
    printf 'Boot    : %s\n' "$BOOT_PARTITION"
    printf 'Système : %s\n' "$SYSTEM_PARTITION"
    printf 'Vendor  : %s\n' "$VENDOR_PARTITION"
    printf '\n'

    check_target "$BOOT_MOUNT/Image" "$IMAGE_SHA" "Image batterie V1 lissée"
    check_target \
        "$BOOT_MOUNT/overlays/vc4-kms-dsi-pibrick.dtbo" \
        "$DTBO_SHA" "DTBO batterie V1 lissée"
    check_target \
        "$SYSTEM_ROOT/framework/services.jar" \
        "$JAR_SHA" "services.jar V8"
    check_target \
        "$SYSTEM_ROOT/framework/oat/arm64/services.art" \
        "$ART_SHA" "services.art V8"
    check_target \
        "$SYSTEM_ROOT/framework/oat/arm64/services.odex" \
        "$ODEX_SHA" "services.odex V8"
    check_target \
        "$SYSTEM_ROOT/framework/oat/arm64/services.vdex" \
        "$VDEX_SHA" "services.vdex V8"
    check_target \
        "$VENDOR_MOUNT/apex/com.android.hardware.health.rpi.apex" \
        "$HEALTH_SHA" "APEX Health V1 lissé"
    check_target \
        "$VENDOR_MOUNT/etc/init/hw/init.rpi5.rc" \
        "$INIT_RPI5_SHA" "init.rpi5.rc microphone HAL"
    check_target \
        "$VENDOR_MOUNT/bin/hw/android.hardware.audio.service" \
        "$HAL_AMIXER_SHA" "amixer HAL microphone"

    actual_label="$(get_selinux_label \
        "$VENDOR_MOUNT/etc/init/hw/init.rpi5.rc")"
    [[ "$actual_label" == "$INIT_RPI5_LABEL" ]] ||
        die "étiquette SELinux init.rpi5.rc incorrecte : $actual_label"
    printf 'OK : étiquette SELinux init.rpi5.rc\n'

    actual_label="$(get_selinux_label \
        "$VENDOR_MOUNT/bin/hw/android.hardware.audio.service")"
    [[ "$actual_label" == "$HAL_AMIXER_LABEL" ]] ||
        die "étiquette SELinux HAL incorrecte : $actual_label"
    printf 'OK : étiquette SELinux HAL audio\n'

    for legacy in \
        "$VENDOR_MOUNT/etc/init.d/04pibrick-microphone" \
        "$VENDOR_MOUNT/etc/init/sysinit.rc" \
        "$VENDOR_MOUNT/bin/sysinit" \
        "$VENDOR_MOUNT/bin/rpi-pibrick-microphone.sh" \
        "$VENDOR_MOUNT/bin/pibrick-amixer"; do
        [[ ! -e "$legacy" ]] ||
            die "ancien mécanisme microphone encore présent : $legacy"
    done
    printf 'OK : anciens mécanismes microphone absents\n' 

    sudo grep -qx 'persist.vendor.audio.device=dac' \
        "$VENDOR_MOUNT/build.prop" ||
        die "route dac absente"

    sudo grep -qx 'ro.boot.audio.tinyalsa.simulate_input=false' \
        "$VENDOR_MOUNT/build.prop" ||
        die "microphone réel non activé"

    printf 'OK : propriétés audio V8\n'
}

apply_v8() {
    verify_package
    detect_partitions
    mount_partitions
    check_microphone_target_compatibility

    printf '%s\n' '===== CIBLE V8 ====='
    printf 'Disque  : %s\n' "$RPIBOOT_DISK"
    printf 'Boot    : %s\n' "$BOOT_PARTITION"
    printf 'Système : %s\n' "$SYSTEM_PARTITION"
    printf 'Vendor  : %s\n' "$VENDOR_PARTITION"
    printf '\n'

    read -r -p "Tapez INSTALLER pour appliquer la V8 : " answer
    [[ "$answer" == "INSTALLER" ]] ||
        die "installation annulée"

    create_backup
    INSTALL_IN_PROGRESS=1

    printf '%s\n' '===== INSTALLATION NOYAU ET OVERLAY ====='
    write_boot_file \
        "$PAYLOAD/boot/Image" \
        "$BOOT_MOUNT/Image"
    write_boot_file \
        "$PAYLOAD/boot/overlays/vc4-kms-dsi-pibrick.dtbo" \
        "$BOOT_MOUNT/overlays/vc4-kms-dsi-pibrick.dtbo"

    printf '%s\n' '===== INSTALLATION FRAMEWORK V8 ====='
    write_existing \
        "$PAYLOAD/system/framework/services.jar" \
        "$SYSTEM_ROOT/framework/services.jar" 0644 0 0
    write_existing \
        "$PAYLOAD/system/framework/oat/arm64/services.art" \
        "$SYSTEM_ROOT/framework/oat/arm64/services.art" 0644 0 0
    write_existing \
        "$PAYLOAD/system/framework/oat/arm64/services.odex" \
        "$SYSTEM_ROOT/framework/oat/arm64/services.odex" 0644 0 0
    write_existing \
        "$PAYLOAD/system/framework/oat/arm64/services.vdex" \
        "$SYSTEM_ROOT/framework/oat/arm64/services.vdex" 0644 0 0

    printf '%s\n' '===== INSTALLATION BATTERIE ET MICROPHONE ====='
    write_existing \
        "$PAYLOAD/vendor/apex/com.android.hardware.health.rpi.apex" \
        "$VENDOR_MOUNT/apex/com.android.hardware.health.rpi.apex" \
        0644 0 0

    write_existing \
        "$PAYLOAD/vendor/etc/init/hw/init.rpi5.rc" \
        "$VENDOR_MOUNT/etc/init/hw/init.rpi5.rc" \
        0644 0 0

    install_file \
        "$PAYLOAD/vendor/bin/hw/android.hardware.audio.service" \
        "$VENDOR_MOUNT/bin/hw/android.hardware.audio.service" \
        0755 0 2000
    set_selinux_label \
        "$VENDOR_MOUNT/bin/hw/android.hardware.audio.service" \
        "$HAL_AMIXER_LABEL"

    remove_optional "$VENDOR_MOUNT/etc/init.d/04pibrick-microphone"
    remove_optional "$VENDOR_MOUNT/etc/init/sysinit.rc"
    remove_optional "$VENDOR_MOUNT/bin/sysinit"
    remove_optional "$VENDOR_MOUNT/bin/rpi-pibrick-microphone.sh"
    remove_optional "$VENDOR_MOUNT/bin/pibrick-amixer"

    set_audio_properties
    sync

    printf '%s\n' '===== VÉRIFICATION V8 ====='
    show_status

    INSTALL_IN_PROGRESS=0

    printf '\n============================================================\n'
    printf 'INSTALLATION V8 TERMINÉE\n'
    printf '============================================================\n'
    printf 'Sauvegarde permettant rollback-v8 : %s\n' "$BACKUP_DIR"
}

rollback_v8() {
    verify_package
    [[ -f "$LATEST_FILE" ]] ||
        die "aucune sauvegarde V8 disponible"

    BACKUP_DIR="$(cat "$LATEST_FILE")"
    [[ -d "$BACKUP_DIR" ]] ||
        die "sauvegarde V8 introuvable : $BACKUP_DIR"

    (
        cd "$BACKUP_DIR"
        sha256sum -c SHA256SUMS-before
    ) || die "sauvegarde V8 corrompue"

    detect_partitions
    mount_partitions

    printf 'Sauvegarde utilisée : %s\n' "$BACKUP_DIR"
    read -r -p "Tapez RESTAURER pour revenir à l’état précédent : " answer
    [[ "$answer" == "RESTAURER" ]] ||
        die "restauration annulée"

    restore_backup "$BACKUP_DIR"

    printf '\nRETOUR À L’ÉTAT PRÉCÉDENT TERMINÉ\n'
}

status_v8() {
    verify_package
    detect_partitions
    mount_partitions
    show_status
}

mkdir -p "$BACKUP_ROOT"

case "$ACTION" in
    apply)
        apply_v8
        ;;
    status)
        status_v8
        ;;
    rollback)
        rollback_v8
        ;;
    *)
        die "action inconnue : $ACTION
Actions :
  ./install.sh apply
  ./install.sh status
  ./install.sh rollback"
        ;;
esac
