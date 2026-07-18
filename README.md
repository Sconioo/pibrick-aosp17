# Android 17 sur piBrick — écran AMOLED

Ce projet ajoute automatiquement le support de l’écran AMOLED du piBrick
Pocket CM5 à KonstaKANG AOSP 17.

## Télécharger

### [⬇️ Télécharger le paquet complet](https://github.com/Sconioo/pibrick-aosp17-display/releases/download/display-v1-60hz/pibrick-aosp17-display-v1-60hz.tar.gz)

Une seule archive contient le noyau testé, l’overlay, la configuration, le
patch source et l’installateur automatique.

## Installation en trois étapes

### 1. Installer Android 17

Télécharger l’image depuis la
[page officielle KonstaKANG AOSP 17](https://konstakang.com/devices/rpi5/AOSP17/)
et l’écrire sur le stockage avec Raspberry Pi Imager.

### 2. Installer le correctif piBrick

Placer le piBrick en mode `rpiboot`, décompresser le paquet téléchargé, puis
lancer dans son dossier, **sans sudo** :

```bash
./install.sh
```

Contrôler la cible affichée et taper `INSTALLER`. Une sauvegarde automatique est
créée avant toute modification.

### 3. Démarrer

Quitter le mode `rpiboot`, laisser HDMI débranché et démarrer le piBrick.

Résultat validé : Android 17 sur écran AMOLED 1080×1240 à 60 Hz.

> L’image Android complète n’est pas redistribuée. KonstaKANG interdit les
> miroirs de ses builds ; utilisez toujours son lien officiel.
