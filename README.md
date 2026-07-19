# Android 17 sur piBrick Pocket CM5

Correctif cumulatif pour utiliser l’écran AMOLED, les deux sorties HDMI, la
luminosité, le tactile et l’autorotation du piBrick avec
[KonstaKANG AOSP 17 pour Raspberry Pi 5](https://konstakang.com/devices/rpi5/AOSP17/).

> Ce projet ne contient pas Android. Installez d’abord l’image KonstaKANG AOSP
> 17 du **2 juillet 2026**, puis appliquez ce correctif.

## Origine du projet et crédits

Ce portage repose sur plusieurs travaux successifs. Le rôle de chacun est
présenté dans l’ordre chronologique :

| Étape | Auteur ou projet | Contribution |
|---|---|---|
| 1. Matériel | [amarullz / piBrick](https://github.com/amarullz/piBrick) | Conception du piBrick Pocket CM5, fichiers matériels et documentation de référence |
| 2. Pilotes Linux | [lshaf / pibrick-driver](https://github.com/lshaf/pibrick-driver) | Dépôt de pilotes de référence pour l’AMOLED, le tactile et les périphériques du piBrick |
| 3. Base Android Raspberry Pi | [KonstaKANG](https://konstakang.com/devices/rpi5/AOSP17/) et [Raspberry Vanilla](https://github.com/raspberry-vanilla) | AOSP 17 pour Raspberry Pi 5, arborescence appareil et noyau Android de base |
| 4. Portage piBrick AOSP 17 | [Sconioo](https://github.com/Sconioo) | Adaptation, compilation, intégration Android, tests matériels, installateurs et releases cumulatives V1 à V6 |

Le travail réalisé dans ce dépôt comprend notamment l’intégration AMOLED à
90 Hz, la correction des deux sorties HDMI, la luminosité 0–100 %, les boutons
en 20 pas, le tactile 5 points, le MMA8451Q et l’autorotation, ainsi que les
scripts de sauvegarde et d’installation en mode `rpiboot`.

Les licences et mentions présentes dans les projets et pilotes d’origine
restent applicables. Ce dépôt ne prétend pas remplacer leurs auteurs.

<!-- PIBRICK_LATEST_START -->
## Version recommandée : V6

### [⬇️ Télécharger la V6 complète](https://github.com/Sconioo/pibrick-aosp17/releases/download/v6/pibrick-aosp17-v6-90hz-hdmi-brightness-touch-autorotation.tar.gz)

La V6 est la dernière version testée sur un vrai piBrick Pocket CM5.

| Fonction | État validé |
|---|---|
| AMOLED | 1080×1240 à 90 Hz |
| HDMI | HDMI-1 et HDMI-2, simultanément avec l’AMOLED |
| Luminosité AMOLED | Réglable de 0 à 100 % |
| Boutons physiques | `−` et `+`, progression en 20 pas |
| Tactile | Hynitron CST3530, 5 points |
| Autorotation | MMA8451Q, quatre orientations |
| Installation | Automatique en mode `rpiboot` avec sauvegarde |

Noyau validé : `Linux 6.18.26-g9944b3831291-v8`

SHA-256 de l’archive :

```text
e469e532aa8e0973f2d581fae9862dc6f5e7ad34374963f16e7ec7d21069dfa5
```

[Notes de la release V6](https://github.com/Sconioo/pibrick-aosp17/releases/tag/v6) ·
[Sources du noyau V6](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/autorotation-driver-v1)
<!-- PIBRICK_LATEST_END -->

## Avant de commencer

Vous avez besoin de :

- un piBrick Pocket CM5 avec l’image AOSP 17 du 2 juillet 2026 ;
- un ordinateur Linux avec `sudo`, `lsblk`, `mount`, `sha256sum` et `tar` ;
- un câble USB de données pour le mode `rpiboot` ;
- l’archive V6 téléchargée ci-dessus.

Important :

- ne lancez pas `install.sh` avec `sudo` ; le script le demandera uniquement
  lorsqu’il doit accéder aux partitions Android ;
- ne débranchez pas le piBrick pendant l’installation ;
- vérifiez que le disque affiché est bien
  `Raspberry Pi multi-function USB device` avant de taper `INSTALLER` ;
- ce paquet est prévu pour le build indiqué, pas pour une autre version AOSP.

## Installation pas à pas

### 1. Installer Android

Téléchargez le build AOSP 17 du 2 juillet 2026 sur la
[page KonstaKANG](https://konstakang.com/devices/rpi5/AOSP17/) et installez-le
sur le piBrick. Démarrez Android une première fois pour vérifier qu’il
fonctionne, puis éteignez complètement le piBrick.

### 2. Décompresser la V6

Dans un terminal Linux :

```bash
DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || pwd)"
cd "$DOWNLOAD_DIR"
tar -xzf pibrick-aosp17-v6-90hz-hdmi-brightness-touch-autorotation.tar.gz
cd pibrick-aosp17-display-v6-90hz-hdmi-brightness-touch-autorotation
```

`xdg-user-dir DOWNLOAD` sélectionne automatiquement le dossier de
téléchargement du compte, qu’il s’appelle `Téléchargements`, `Downloads` ou
autrement. L’archive peut aussi être décompressée ailleurs : l’installateur ne
dépend pas de son emplacement.

Optionnel, mais recommandé : contrôler l’archive téléchargée.

```bash
DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || pwd)"
cd "$DOWNLOAD_DIR"
sha256sum pibrick-aosp17-v6-90hz-hdmi-brightness-touch-autorotation.tar.gz
```

Le résultat doit être :

```text
e469e532aa8e0973f2d581fae9862dc6f5e7ad34374963f16e7ec7d21069dfa5
```

### 3. Passer le piBrick en mode `rpiboot`

Éteignez le piBrick, connectez-le à l’ordinateur avec le câble USB de données,
puis démarrez-le en mode `rpiboot`. Le stockage doit apparaître comme un disque
USB nommé `Raspberry Pi multi-function USB device`.

Pour vérifier :

```bash
lsblk -dnpo NAME,MODEL,TRAN | grep -i "Raspberry Pi"
```

### 4. Lancer l’installateur

Depuis le dossier décompressé :

```bash
chmod +x install.sh
./install.sh
```

Ne mettez pas `sudo` devant `./install.sh`.

Le script affiche le disque, les partitions `boot`, `vendor` et système, puis
demande :

```text
Tapez INSTALLER pour continuer: INSTALLER
```

Relisez la cible affichée avant de taper `INSTALLER`. Le script sauvegarde les
fichiers actuels, installe les correctifs et contrôle toutes les copies.

### 5. Redémarrer normalement

Lorsque `INSTALLATION TERMINÉE` apparaît, quittez le mode `rpiboot`, débranchez
le câble utilisé pour ce mode et démarrez normalement.

Vérifiez ensuite :

- AMOLED et tactile ;
- rotation gauche, droite, portrait et portrait inversé ;
- boutons de luminosité `−` et `+` ;
- HDMI-1 puis HDMI-2.

## Comportements normaux

- Le réglage Android contrôle la luminosité de l’AMOLED intégré. La luminosité
  d’un écran HDMI se règle sur l’écran HDMI lui-même.
- En mode miroir, l’image HDMI suit l’orientation actuelle du piBrick. Une
  rotation en portrait est donc également visible sur HDMI.
- L’icône de batterie et la gestion de charge ne font pas partie de ce paquet
  consacré à l’affichage et aux entrées.

## Dépannage rapide

### `ERREUR: un unique piBrick rpiboot est requis`

Le piBrick n’est pas détecté ou plusieurs appareils similaires sont présents.
Vérifiez le câble USB de données et relancez :

```bash
lsblk -dnpo NAME,MODEL,TRAN | grep -i "Raspberry Pi"
```

### `Permission denied` sur `install.sh`

```bash
chmod +x install.sh
./install.sh
```

### L’installation s’arrête avant les copies

L’installateur refuse une image Android, un fichier ou une partition qui ne
correspond pas à la version attendue. N’essayez pas de contourner ce contrôle :
utilisez le build AOSP 17 du 2 juillet 2026.

### Échec pendant l’installation

Le script tente automatiquement de restaurer la sauvegarde créée avant les
modifications. Conservez le chemin de sauvegarde affiché dans le terminal.

## Versions disponibles

Chaque release reste téléchargeable pour faciliter les tests et le retour à une
étape précédente.

| Version | Fonctions principales | Release |
|---|---|---|
| **V6 — recommandée** | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons 20 pas, tactile 5 points, autorotation | [V6](https://github.com/Sconioo/pibrick-aosp17/releases/tag/v6) |
| V5 | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons 20 pas, tactile 5 points | [V5](https://github.com/Sconioo/pibrick-aosp17/releases/tag/display-v5-90hz-hdmi-brightness-touch) |
| V4 | AMOLED 90 Hz, HDMI-1/2, luminosité 0–100 %, boutons 20 pas | [V4](https://github.com/Sconioo/pibrick-aosp17/releases/tag/display-v4-90hz-hdmi-brightness) |
| V3 | AMOLED 90 Hz et HDMI-1/2 | [V3](https://github.com/Sconioo/pibrick-aosp17/releases/tag/display-v3-90hz-hdmi) |
| V2 | AMOLED 60 Hz et HDMI-1/2 | [V2](https://github.com/Sconioo/pibrick-aosp17/releases/tag/display-v2-hdmi-60hz) |
| V1 | Première intégration AMOLED 60 Hz | [V1](https://github.com/Sconioo/pibrick-aosp17/releases/tag/display-v1-60hz) |

[Afficher toutes les releases](https://github.com/Sconioo/pibrick-aosp17/releases)

## Sauvegarde et retour arrière

Avant toute modification, l’installateur crée une sauvegarde dans :

```text
$HOME/pibrick-aosp17-backups/
```

Le chemin exact apparaît avant la confirmation. Ne supprimez pas ce dossier
tant que la nouvelle version n’a pas été testée. Pour revenir à une ancienne
fonctionnalité, utilisez la release correspondante ci-dessus.

## Sources et reproductibilité

Chaque archive de release contient :

- les binaires précompilés et testés ;
- `install.sh` ;
- `SHA256SUMS` ;
- les patchs sources utilisés pour cette version ;
- `source/SOURCE.txt` avec les commits et dépôts de référence.

### Branches noyau publiques et validées

| Étape | Branche | Utilisation |
|---|---|---|
| Affichage AMOLED initial | [`pibrick/display-v1`](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/display-v1) | Base des V1 et V2 |
| Tactile | [`pibrick/touch-v1`](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/touch-v1) | Noyau de la V5 |
| Autorotation | [`pibrick/autorotation-driver-v1`](https://github.com/Sconioo/android_kernel_brcm_rpi/tree/pibrick/autorotation-driver-v1) | Noyau final de la V6 |

Les changements intermédiaires des V2, V3 et V4 touchent aussi
`drm_hwcomposer`, le HAL Light et le framework Android. Ils sont conservés sous
forme de patchs dans le dossier `source/` de chaque archive correspondante.
Cette présentation évite de faire croire qu’une seule branche noyau contient
tous les composants Android.

## Périmètre validé

La V6 a été validée sur :

- piBrick Pocket CM5 ;
- KonstaKANG AOSP 17 du 2 juillet 2026 ;
- AMOLED, HDMI-1, HDMI-2, luminosité, boutons, tactile et autorotation.

Chaque nouvelle étape n’est déclarée recommandée qu’après test sur le matériel
réel.
