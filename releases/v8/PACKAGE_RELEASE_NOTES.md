# piBrick AOSP 17 V8

<!-- PIBRICK_V8_RELEASE_FINAL_BEGIN -->
## V8 finale — 2 août 2026

- Batterie V1 lissée conservée.
- Sortie audio `dac` conservée.
- Microphone C-Media reconnu par le framework Android.
- Gain automatique 32/35 et AGC activé au démarrage.
- Services `pibrick_mic_gain_hal` et `pibrick_mic_agc_hal`.
- Exécution SELinux dans `hal_audio_default`, testée temporairement en Enforcing sans refus AVC.
- Suppression du mécanisme expérimental `sysinit/init.d`.
- Sauvegarde et rollback étendus aux fichiers microphone finaux et historiques.
<!-- PIBRICK_V8_RELEASE_FINAL_END -->

La V8 conserve intégralement la logique cumulative V1 à V7 et ajoute l’état
final validé du microphone et de la batterie.

## Ajouts par rapport à la V7

- correction `UsbAlsaManager` avec analyse initiale des nœuds ALSA déjà
  présents au démarrage de `system_server` ;
- entrée microphone USB C-Media disponible dans Android ;
- gain microphone 32/35 et AGC appliqués automatiquement ;
- propriété `ro.boot.audio.tinyalsa.simulate_input=false` ;
- noyau, overlay et APEX Health de la batterie V1 lissée ;
- sauvegarde et restauration groupées de l’état V8.

## Préservé

- sortie audio interne `dac` validée ;
- aucun APEX audio expérimental ;
- aucune image vendor complète ;
- installation normale avec `./install.sh` ;
- détection automatique du piBrick en mode rpiboot.

## Correctif installateur V8.0.1

L’écriture et la restauration de `Image` et du DTBO sur la partition boot FAT
n’essaient plus d’appliquer des propriétaires ou permissions Unix. Les autres
partitions conservent leur traitement précédent.

## Correctif installateur V8.0.2

La détection de la partition système accepte désormais les partitions déjà
montées automatiquement par l’environnement de bureau. Avant l’écriture, les
partitions boot, vendor et système sont démontées proprement puis remontées
dans les points temporaires contrôlés par l’installateur.

## Correctif installateur V8.0.3

La vérification finale lit désormais `vendor/build.prop` avec `sudo`.
L’installation ne déclenche plus un faux échec lorsque la partition vendor
est montée avec des permissions réservées à root.

## Correctif installateur V8.0.4

La vérification de compatibilité lit désormais `ro.build.id` avec `sudo`
depuis la partition système montée. Un refus de lecture ne peut donc plus
transformer silencieusement l’identifiant du build en valeur vide.
