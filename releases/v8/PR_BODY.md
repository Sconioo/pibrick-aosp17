## Objet

Publier la V8 finale de piBrick AOSP 17, validée sur le matériel réel.

## Changements

- microphone USB C-Media reconnu par Android ;
- initialisation des nœuds ALSA préexistants dans `UsbAlsaManager` ;
- gain 32/35 et AGC activé automatiquement ;
- services microphone Android Init dans le domaine
  `hal_audio_default` ;
- test SELinux `Enforcing` sans refus AVC relatif au microphone ;
- sortie audio `dac` préservée ;
- batterie V1 lissée préservée ;
- anciens mécanismes `sysinit/init.d` retirés ;
- documentation, vérification après boot et rollback mis à jour.

## Validation physique

- installation depuis l’archive finale : OK ;
- redémarrage Android : OK ;
- microphone et haut-parleurs : OK ;
- absence de microcoupures et de saturation : OK ;
- batterie : OK ;
- rollback : OK ;
- réinstallation de la même archive : OK.

## Archive

`pibrick-aosp17-v8-90hz-hdmi-brightness-touch-autorotation-audio-microphone-battery.tar.gz`

SHA-256 : `6a06f64128413de84ddb0f03fb2853be447fcb50057c45f2ed80c5797e09285b`
