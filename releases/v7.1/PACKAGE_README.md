# piBrick Pocket-CM5 — AOSP 17 V7 validée

## Éléments inclus

- noyau et overlay piBrick validés ;
- batterie V1 lissée ;
- sortie audio C-Media routée vers `dac` ;
- sortie USB C-Media masquée du framework Android ;
- entrée microphone USB C-Media disponible dans Android ;
- gain microphone fixé à 32/35 ;
- contrôle automatique de gain activé ;
- application automatique du gain par `init.d`.

## Propriétés audio persistantes

```text
persist.vendor.audio.device=dac
ro.boot.audio.tinyalsa.simulate_input=false
```

Ce paquet contient l’état validé ainsi que l’installateur rpiboot, le script de restauration et le contrôle ADB.

## Scripts fournis

- `install.sh` : installation hors ligne en mode rpiboot ;
- `restore.sh` : restauration d’une sauvegarde créée par l’installateur ;
- `verify-adb.sh` : contrôle après redémarrage Android.

L’installateur crée toujours une sauvegarde complète des éléments remplacés
avant toute écriture.
