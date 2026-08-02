# piBrick AOSP 17 — V8

<!-- PIBRICK_V8_FINAL_BEGIN -->
## V8 — microphone, audio et batterie validés

La V8 conserve toutes les fonctions V7 et ajoute le microphone USB C-Media réellement reconnu par Android, avec gain automatique 32/35 et AGC activé. La jauge de batterie V1 lissée et la sortie audio `dac` sont conservées.

```bash
./install.sh
ADB_TARGET=192.168.1.168:5555 ./tools/verify-after-boot.sh
```

Le rollback V8 reste disponible avec `./install.sh rollback-v8`.
<!-- PIBRICK_V8_FINAL_END -->

Paquet cumulatif pour le piBrick Pocket CM5 avec KonstaKANG AOSP 17 du
2 juillet 2026.

## Fonctions incluses

- AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 ;
- luminosité AMOLED 0–100 % ;
- boutons physiques en 20 pas ;
- tactile Hynitron CST3530, 5 points ;
- autorotation MMA8451Q dans les quatre orientations ;
- sortie audio interne C-Media avec route Android `dac` ;
- microphone USB C-Media reconnu par Android ;
- gain microphone 32/35 avec AGC ;
- batterie V1 lissée préservée.

## Logique cumulative conservée

La V8 reprend sans les modifier les composants V6 et V7 officiels.

L’installateur détecte automatiquement l’état des fichiers `services` :

- AOSP stock ou autre état : V6, puis V7, puis V8 ;
- V6 : conservation de la base, puis V7 et V8 ;
- V7 : conservation de V6/V7, puis passage à V8 ;
- V8 : conservation du framework déjà acquis et contrôle final V8.

Aucune image `vendor.img` complète n’est écrite.

## Installation normale

Placez le piBrick en mode `rpiboot`, puis lancez sans `sudo` :

```bash
chmod +x install.sh
./install.sh
```

Relisez toujours le disque et les partitions affichés avant de taper
`INSTALLER`.

Les sauvegardes sont conservées dans :

```text
$HOME/pibrick-aosp17-backups/
```

## Vérification après démarrage

```bash
ADB_TARGET=192.168.1.168:5555 ./tools/verify-after-boot.sh
```

## Retour à l’état précédant la dernière installation V8

En mode `rpiboot` :

```bash
./install.sh rollback-v8
```

Cette action utilise la sauvegarde créée par le composant V8. Elle restaure
exactement l’état qui précédait sa dernière installation. Elle n’est disponible
qu’après une installation V8 réalisée par ce paquet.

## Modes avancés

```bash
./install.sh verify
./install.sh status
./install.sh apply-stock
./install.sh upgrade-from-v7
./install.sh rollback-v8
./install.sh rollback-route
```

Le mode normal recommandé reste uniquement :

```bash
./install.sh
```
