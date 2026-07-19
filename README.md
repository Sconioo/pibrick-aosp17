# Android 17 sur piBrick — AMOLED, HDMI et luminosité

Ce projet ajoute le support matériel du piBrick Pocket CM5 à
[KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/).

## Version recommandée

### [⬇️ Télécharger la v4 complète](https://github.com/Sconioo/pibrick-aosp17-display/releases/download/display-v4-90hz-hdmi-brightness/pibrick-aosp17-display-v4-90hz-hdmi-brightness.tar.gz)

La **v4** est la dernière version validée sur le matériel réel.

Fonctions validées :

- écran AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 fonctionnels ;
- AMOLED et HDMI utilisables simultanément ;
- luminosité Android réglable de 0 à 100 % ;
- plage physique AMOLED de 1 à 1023 ;
- boutons physiques `−` et `+` avec 20 pas plus fins ;
- sauvegarde automatique avant modification ;
- contrôle SHA-256 de tous les fichiers.

Compatibilité validée :

- piBrick Pocket CM5 ;
- KonstaKANG AOSP 17 du 2 juillet 2026 ;
- noyau Linux `6.18.26-g2cd26f3a4a70-v8`.

SHA-256 de l’archive v4 :

```text
a43ebb897e88470ea6e784a09354b61f631470f0397012cadb5bd28f96dcbc4f
```

[Consulter la release v4 et ses notes](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v4-90hz-hdmi-brightness)

## Installation en trois étapes

### 1. Installer Android 17

Télécharger l’image depuis la
[page officielle KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/)
et l’écrire sur le stockage du piBrick avec Raspberry Pi Imager.

> Utiliser le build AOSP 17 du 2 juillet 2026. L’image Android complète n’est
> pas redistribuée dans ce projet.

### 2. Appliquer le correctif piBrick

Éteindre le piBrick et le démarrer en mode `rpiboot`.

Décompresser l’archive v4, ouvrir un terminal dans le dossier obtenu, puis
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

Quitter le mode `rpiboot` et démarrer normalement. La luminosité est ensuite
réglable depuis Android et avec les boutons physiques du piBrick.

## Revenir à une version précédente

Les anciennes releases restent disponibles comme solutions de repli :

| Version | Fonctions principales | Lien |
|---|---|---|
| **v4 — recommandée** | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons fins | [Télécharger](https://github.com/Sconioo/pibrick-aosp17-display/releases/tag/display-v4-90hz-hdmi-brightness) |
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
- les patchs du noyau, de `drm_hwcomposer`, du HAL Light et du framework ;
- les commits de base et d’intégration dans `source/SOURCE.txt` ;
- les empreintes dans `SHA256SUMS`.

Chaque nouvelle étape n’est mise en avant ici qu’après validation sur le
piBrick réel.
