# piBrick AOSP 17 V7 — sortie audio interne

Cette version cumulative reprend toutes les fonctions de la V6 et ajoute la
sortie audio interne validée du piBrick.

## Ajouts

- carte C-Media interne 0d8c:0014 utilisée par le HAL primaire ;
- route persistante `dac` ;
- correctif `UsbAlsaManager` empêchant la carte soudée d'être présentée comme
  un casque USB externe ;
- libellé Android « Haut-parleur ».

## Limites connues

Le microphone ne fait pas partie du périmètre validé de cette release.
Les essais de tampon microphone et l'image vendor V8.1.3 ne sont pas inclus.

## Correctif installateur V7.0.1

L'installateur reconnaît désormais les ensembles `services` stock, V6 et
audio V7. Il ne tente plus de réinstaller la V6 par-dessus un framework audio
déjà validé.

## Correctif installateur V7.0.2

La partition système est désormais identifiée en recherchant `services.jar`
sur toutes les partitions ext2/3/4 du disque rpiboot. La détection ne dépend
plus d'une étiquette de système de fichiers.

## Correctif V7.0.3

- installation normale documentée avec une seule commande : `./install.sh` ;
- suppression du faux avertissement fondé sur la simple présence textuelle de
  `USB Headset` dans `dumpsys media.audio_policy` ;
- contrôle maintenu sur la route `dac` et la détection de la carte C-Media.
