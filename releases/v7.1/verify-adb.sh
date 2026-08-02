#!/usr/bin/env bash
set -u

TARGET="${1:-192.168.1.168:5555}"

adb connect "$TARGET" >/dev/null 2>&1
adb -s "$TARGET" root >/dev/null 2>&1 || true
sleep 2
adb connect "$TARGET" >/dev/null 2>&1
adb -s "$TARGET" wait-for-device

adb -s "$TARGET" shell '
echo "===== DÉMARRAGE ====="
echo "sys.boot_completed=$(getprop sys.boot_completed)"

echo
echo "===== PROPRIÉTÉS AUDIO ====="
echo "persist.vendor.audio.device=$(getprop persist.vendor.audio.device)"
echo "ro.boot.audio.tinyalsa.simulate_input=$(getprop ro.boot.audio.tinyalsa.simulate_input)"

echo
echo "===== CARTES ALSA ====="
cat /proc/asound/cards

echo
echo "===== MICROPHONE ====="
/vendor/bin/amixer -D hw:Device cget name="Mic Capture Volume"
/vendor/bin/amixer -D hw:Device cget name="Auto Gain Control"

echo
echo "===== BATTERIE ====="
dumpsys battery | head -n 35

echo
echo "===== USB AUDIO ====="
dumpsys usb | grep -A12 -B3 "USB Audio Device"
'
