# Android 17 sur piBrick — AMOLED, HDMI, luminosité, tactile et autorotation

Ce projet ajoute le support matériel du piBrick Pocket CM5 à
[KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/).

<!-- PIBRICK_LATEST_START -->
## Version recommandée

### [⬇️ Télécharger la V6 complète](https://github.com/Sconioo/pibrick-aosp17-display/releases/download/display-v6-90hz-hdmi-brightness-touch-autorotation/pibrick-aosp17-display-v6-90hz-hdmi-brightness-touch-autorotation.tar.gz)

La **V6** est la dernière version cumulative validée sur le matériel réel.

Fonctions validées :

- écran AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 fonctionnels ;
- AMOLED et HDMI utilisables simultanément ;
- luminosité Android réglable de 0 à 100 % ;
- boutons physiques `−` et `+` avec 20 pas ;
- tactile Hynitron CST3530 à 5 points ;
- autorotation MMA8451Q dans les quatre orientations ;
- tactile correctement aligné après rotation ;
- sauvegarde automatique avant modification ;
- contrôle SHA-256 de tous les fichiers.

Compatibilité validée :

- piBrick Pocket CM5 ;
- KonstaKANG AOSP 17 du 2 juillet 2026 ;
- noyau Linux `6.18.26-g9944b3831291-v8`.

SHA-256 de l’archive V6 :

```text
60f5871a200b212da21be3022590502fdbc603f8e7d24f752773f0a265dd6042
```

[Consulter la release V6](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v6-90hz-hdmi-brightness-touch-autorotation) ·
[Sources du noyau](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/autorotation-driver-v1)
<!-- PIBRICK_LATEST_END -->

## Installation en trois étapes

### 1. Installer Android 17

Télécharger l’image depuis la
[page officielle KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/)
et l’écrire sur le stockage du piBrick avec Raspberry Pi Imager.

> Utiliser le build AOSP 17 du 2 juillet 2026. L’image Android complète n’est
> pas redistribuée dans ce projet.

### 2. Appliquer le correctif piBrick

Éteindre le piBrick et le démarrer en mode `rpiboot`.

Décompresser l’archive V6, ouvrir un terminal dans le dossier obtenu, puis
lancer sans `sudo` :

```bash
./install.sh
```

Contrôler le disque et les partitions affichés, puis taper :

```text
INSTALLER
```

L’installateur détecte automatiquement les partitions `boot`, `vendor` et
système, sauvegarde les fichiers présents, puis applique tous les correctifs.

### 3. Démarrer

Quitter le mode `rpiboot` et démarrer normalement. L’AMOLED, les deux ports
HDMI, la luminosité, le tactile et l’autorotation sont alors opérationnels.

## Revenir à une version précédente

Les anciennes releases restent disponibles comme solutions de repli :

| Version | Fonctions principales | Lien |
|---|---|---|
| **V6 — recommandée** | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons 20 pas, tactile 5 points et autorotation | [Télécharger](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v6-90hz-hdmi-brightness-touch-autorotation) |
| V5 | AMOLED 90 Hz, HDMI-1/2, luminosité, boutons et tactile 5 points | [Release V5](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v5-90hz-hdmi-brightness-touch) |
| V4 | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons fins | [Release V4](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v4-90hz-hdmi-brightness) |
| V3 | AMOLED 90 Hz et HDMI-1/2 | [Release V3](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v3-90hz-hdmi) |
| V2 | AMOLED 60 Hz et HDMI-1/2 | [Release V2](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v2-hdmi-60hz) |
| V1 | Première intégration AMOLED 60 Hz | [Release V1](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v1-60hz) |

[Afficher toutes les releases](https://github.com/Sconioo/pibrick-aosp17-display/releases)

## Sauvegarde et restauration

Avant toute modification, l’installateur sauvegarde les fichiers remplacés
dans :

```text
$HOME/pibrick-aosp17-backups/
```

En cas d’erreur pendant l’installation, il tente une restauration automatique.
Les anciennes releases restent disponibles pour revenir manuellement à une
étape précédemment validée.

## Sources et reproductibilité

L’archive contient :

- les binaires précompilés et testés ;
- l’installateur automatique ;
- les patchs du noyau, du tactile, de l’autorotation, de `drm_hwcomposer`,
  du HAL Light et du framework ;
- les commits de base et d’intégration dans `source/SOURCE.txt` ;
- les empreintes dans `SHA256SUMS`.

Branches validées :

- [noyau V6 avec autorotation](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/autorotation-driver-v1) ;
- [noyau V5 tactile](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/touch-v1).

Chaque nouvelle étape n’est mise en avant ici qu’après validation sur le
piBrick réel.
