# Android 17 sur piBrick — AMOLED, HDMI, luminosité et tactile

<!-- PIBRICK_LATEST_START -->
## Version recommandée

### piBrick AOSP 17 display v6 — 90 Hz, HDMI, brightness, touch and autorotation

[Télécharger la V6](https://github.com/Sconioo/pibrick-aosp17-display/releases/download/display-v6-90hz-hdmi-brightness-touch-autorotation/pibrick-aosp17-display-v6-90hz-hdmi-brightness-touch-autorotation.tar.gz)

- AMOLED 1080x1240 à 90 Hz
- HDMI 1 et 2
- luminosité 0-100 % et boutons en 20 pas
- tactile multipoint
- autorotation MMA8451Q dans les quatre orientations
- installateur automatique avec sauvegarde

SHA-256 : `60f5871a200b212da21be3022590502fdbc603f8e7d24f752773f0a265dd6042`

[Sources du noyau](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/autorotation-driver-v1) · [Toutes les releases](https://github.com/Sconioo/pibrick-aosp17-display/releases)
<!-- PIBRICK_LATEST_END -->

Ce projet ajoute le support matériel du piBrick Pocket CM5 à
[KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/).

## Version recommandée

### [⬇️ Télécharger la v5 complète](https://github.com/Sconioo/pibrick-aosp17-display/releases/download/display-v5-90hz-hdmi-brightness-touch/pibrick-aosp17-display-v5-90hz-hdmi-brightness-touch.tar.gz)

La **v5** est la dernière version validée sur le matériel réel.

Fonctions validées :

- écran AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 fonctionnels ;
- AMOLED et HDMI utilisables simultanément ;
- luminosité Android réglable de 0 à 100 % ;
- boutons physiques `−` et `+` avec 20 pas plus fins ;
- tactile Hynitron CST3530 à 5 points ;
- orientation et coordonnées tactiles correctes ;
- sauvegarde automatique avant modification ;
- contrôle SHA-256 de tous les fichiers.

> L’autorotation de l’affichage par accéléromètre n’est pas encore prise en
> charge. Cela n’affecte pas l’orientation ni le fonctionnement du tactile.

Compatibilité validée :

- piBrick Pocket CM5 ;
- KonstaKANG AOSP 17 du 2 juillet 2026 ;
- noyau Linux `6.18.26-g3d165839d2c4-v8`.

SHA-256 de l’archive v5 :

```text
b1d8cc266eb0ac650c90f4a182d09b8a1f0e95774b99bb05e82a76cfab0e1fa6
```

[Consulter la release v5 et ses notes](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v5-90hz-hdmi-brightness-touch)

## Installation en trois étapes

### 1. Installer Android 17

Télécharger l’image depuis la
[page officielle KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/)
et l’écrire sur le stockage du piBrick avec Raspberry Pi Imager.

> Utiliser le build AOSP 17 du 2 juillet 2026. L’image Android complète n’est
> pas redistribuée dans ce projet.

### 2. Appliquer le correctif piBrick

Éteindre le piBrick et le démarrer en mode `rpiboot`.

Décompresser l’archive v5, ouvrir un terminal dans le dossier obtenu, puis
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
HDMI, la luminosité et le tactile sont alors opérationnels.

## Revenir à une version précédente

Les anciennes releases restent disponibles comme solutions de repli :

| Version | Fonctions principales | Lien |
|---|---|---|
| **v5 — recommandée** | AMOLED 90 Hz, HDMI-1/2, luminosité, boutons et tactile 5 points | [Télécharger](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v5-90hz-hdmi-brightness-touch) |
| v4 | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons fins | [Release v4](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v4-90hz-hdmi-brightness) |
| v3 | AMOLED 90 Hz et HDMI-1/2 | [Release v3](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v3-90hz-hdmi) |
| v2 | AMOLED 60 Hz et HDMI-1/2 | [Release v2](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v2-hdmi-60hz) |
| v1 | Première intégration AMOLED 60 Hz | [Release v1](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v1-60hz) |

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
- les patchs du noyau, du tactile, de `drm_hwcomposer`, du HAL Light et du
  framework ;
- les commits de base et d’intégration dans `source/SOURCE.txt` ;
- les empreintes dans `SHA256SUMS`.

La branche du noyau tactile validée est disponible ici :
[`pibrick/touch-v1`](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/touch-v1).

Chaque nouvelle étape n’est mise en avant ici qu’après validation sur le
piBrick réel.
