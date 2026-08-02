#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ADB_TARGET="${ADB_TARGET:-192.168.1.168:5555}"
INIT_SHA="18547fc5148556453c6210eb5d69b8f0b399aa44d1c49c1f3df45be3b1f7b453"
HAL_SHA="e35c4ede27f85fe9f8a96cc8e798eb004cf91a87e99ac46ae24784dfe38a3a5d"
HAL_LABEL="u:object_r:hal_audio_default_exec:s0"
INIT_LABEL="u:object_r:vendor_configs_file:s0"

fail() {
    printf 'ERREUR : %s\n' "$*" >&2
    exit 1
}

adb connect "$ADB_TARGET" >/dev/null
adb -s "$ADB_TARGET" root >/dev/null
sleep 2
adb -s "$ADB_TARGET" wait-for-device

remote_hash() {
    adb -s "$ADB_TARGET" shell sha256sum "$1" | awk '{print $1}' | tr -d '\r'
}

printf '%s\n' '===== V8 — VÉRIFICATION APRÈS BOOT ====='

boot="$(adb -s "$ADB_TARGET" shell getprop sys.boot_completed | tr -d '\r')"
route="$(adb -s "$ADB_TARGET" shell getprop persist.vendor.audio.device | tr -d '\r')"
sim="$(adb -s "$ADB_TARGET" shell getprop ro.boot.audio.tinyalsa.simulate_input | tr -d '\r')"
gain_service="$(adb -s "$ADB_TARGET" shell getprop init.svc.pibrick_mic_gain_hal | tr -d '\r')"
agc_service="$(adb -s "$ADB_TARGET" shell getprop init.svc.pibrick_mic_agc_hal | tr -d '\r')"

[[ "$boot" == 1 ]] || fail "Android n’a pas terminé son démarrage"
[[ "$route" == dac ]] || fail "route audio inattendue : $route"
[[ "$sim" == false ]] || fail "entrée microphone simulée : $sim"
[[ "$gain_service" == stopped ]] || fail "service gain non exécuté : $gain_service"
[[ "$agc_service" == stopped ]] || fail "service AGC non exécuté : $agc_service"

[[ "$(remote_hash /vendor/etc/init/hw/init.rpi5.rc)" == "$INIT_SHA" ]] ||
    fail "init.rpi5.rc incorrect"
[[ "$(remote_hash /vendor/bin/hw/android.hardware.audio.service)" == "$HAL_SHA" ]] ||
    fail "binaire HAL microphone incorrect"

init_label="$(adb -s "$ADB_TARGET" shell ls -lZ /vendor/etc/init/hw/init.rpi5.rc | tr -d '\r')"
[[ "$init_label" == *"$INIT_LABEL"* ]] || fail "étiquette SELinux init.rpi5.rc incorrecte"
label="$(adb -s "$ADB_TARGET" shell ls -lZ /vendor/bin/hw/android.hardware.audio.service | tr -d '\r')"
[[ "$label" == *"$HAL_LABEL"* ]] || fail "étiquette SELinux HAL incorrecte"

gain="$(adb -s "$ADB_TARGET" shell '/vendor/bin/amixer -D hw:Device cget "name=Mic Capture Volume"' | tr -d '\r')"
agc="$(adb -s "$ADB_TARGET" shell '/vendor/bin/amixer -D hw:Device cget "name=Auto Gain Control"' | tr -d '\r')"
[[ "$gain" == *": values=32"* ]] || fail "gain microphone différent de 32"
[[ "$agc" == *": values=on"* ]] || fail "AGC microphone désactivé"

battery="$(adb -s "$ADB_TARGET" shell dumpsys battery | tr -d '\r')"
level="$(printf '%s\n' "$battery" | awk -F: '/^[[:space:]]*level:/ {gsub(/[[:space:]]/, "", $2); print $2; exit}')"
[[ "$level" =~ ^[0-9]+$ ]] || fail "niveau de batterie illisible"

printf 'OK : Android démarré\n'
printf 'OK : route audio dac\n'
printf 'OK : microphone réel\n'
printf 'OK : services microphone exécutés\n'
printf 'OK : gain 32/35\n'
printf 'OK : AGC activé\n'
printf 'OK : contexte SELinux %s\n' "$HAL_LABEL"
printf 'OK : batterie lisible (%s %%)\n' "$level"
printf '\nV8 prête pour le test physique final.\n'
