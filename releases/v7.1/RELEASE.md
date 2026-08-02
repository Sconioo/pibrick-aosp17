# piBrick AOSP 17 — V7.1 finale validée

Cette release consolide la V7 après validation sur le piBrick Pocket-CM5 réel.

## Fonctions validées

- AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 ;
- luminosité AMOLED de 0 à 100 % ;
- boutons physiques en 20 pas ;
- tactile Hynitron CST3530, 5 points ;
- autorotation MMA8451Q dans les quatre orientations ;
- sortie audio interne C-Media avec route Android `dac` ;
- microphone USB C-Media reconnu par Android ;
- gain microphone 32/35 avec AGC activé ;
- batterie V1 lissée préservée ;
- installation rpiboot, restauration et contrôle ADB.

## Propriétés audio

```text
persist.vendor.audio.device=dac
ro.boot.audio.tinyalsa.simulate_input=false
```

## Archive

```text
pibrick-aosp17-v7-final-validated.tar.xz
SHA256 : 03fe2f742066cca690fd1405a4fbd20de914d73224e2bca20960e27a4238b8ae
```

Aucun APEX audio expérimental n’est inclus.
