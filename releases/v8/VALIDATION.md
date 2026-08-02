# Validation matérielle de la V8

La V8 a été installée depuis son archive finale extraite dans un dossier neuf,
puis testée sur un piBrick Pocket CM5 réel.

## Cycle final validé

1. installation complète depuis l’archive candidate ;
2. démarrage Android et vérification ADB ;
3. enregistrement réel et réécoute sur les haut-parleurs ;
4. contrôle de la jauge de batterie ;
5. rollback V8 ;
6. redémarrage et contrôle de l’état restauré ;
7. réinstallation de la même archive finale ;
8. nouvelle vérification après démarrage.

## Fonctions validées

- Android démarre normalement ;
- AMOLED 1080×1240 à 90 Hz ;
- HDMI-1 et HDMI-2 ;
- luminosité 0–100 % et boutons physiques en 20 pas ;
- tactile Hynitron CST3530 à cinq points ;
- autorotation MMA8451Q dans les quatre orientations ;
- sortie audio interne C-Media avec route Android persistante `dac` ;
- microphone C-Media reconnu comme entrée réelle ;
- gain microphone 32/35 ;
- contrôle automatique de gain activé ;
- services microphone exécutés automatiquement après le démarrage ;
- test du service microphone en mode SELinux `Enforcing`, sans refus AVC
  relatif à son accès ALSA ;
- enregistrement et réécoute physiques validés, sans microcoupure ni
  saturation constatée ;
- batterie V1 lissée conservée et lisible ;
- sauvegarde et rollback validés.

## Architecture du microphone

Le correctif framework initialise `UsbAlsaManager` avec les nœuds ALSA déjà
présents lorsque `system_server` démarre.

Le gain et l’AGC sont appliqués par deux services Android Init `oneshot`.
Ils exécutent une copie dédiée d’`amixer` dans le domaine
`hal_audio_default`, avec le contexte :

```text
u:object_r:hal_audio_default_exec:s0
```

Cette solution remplace les anciens essais `sysinit/init.d` et n’utilise aucun
APEX audio expérimental.
