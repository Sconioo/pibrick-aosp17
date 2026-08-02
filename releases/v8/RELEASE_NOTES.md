# piBrick AOSP 17 — V8

La V8 est une version cumulative destinée au piBrick Pocket CM5 avec l’image
KonstaKANG AOSP 17 pour Raspberry Pi 5 du 2 juillet 2026.

## Nouveautés de la V8

- microphone USB C-Media reconnu par Android ;
- analyse initiale des nœuds ALSA déjà présents dans `UsbAlsaManager` ;
- gain microphone fixé automatiquement à 32/35 ;
- AGC activé automatiquement après chaque démarrage ;
- services Android Init exécutés dans le domaine
  `hal_audio_default` ;
- fonctionnement du réglage microphone testé sous SELinux `Enforcing` ;
- batterie V1 lissée conservée ;
- sortie audio interne et route persistante `dac` conservées ;
- anciens mécanismes microphone expérimentaux retirés ;
- sauvegarde et rollback validés sur le matériel réel.

## Fonctions cumulatives

- AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 ;
- luminosité AMOLED de 0 à 100 % ;
- boutons physiques de luminosité en 20 pas ;
- tactile Hynitron CST3530 à cinq points ;
- autorotation MMA8451Q dans les quatre orientations ;
- sortie audio interne C-Media ;
- microphone C-Media ;
- batterie V1 lissée.

## Validation finale

Le cycle installation → vérification → rollback → redémarrage →
réinstallation → nouvelle vérification a été réalisé avec succès.

L’enregistrement réel, la réécoute sur les haut-parleurs et la jauge de
batterie ont également été validés.

## Archive

```text
pibrick-aosp17-v8-90hz-hdmi-brightness-touch-autorotation-audio-microphone-battery.tar.gz
SHA-256 : 6a06f64128413de84ddb0f03fb2853be447fcb50057c45f2ed80c5797e09285b
```
