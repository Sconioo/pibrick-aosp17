## Objet

Publier la V7.1, qui fige l’état V7 final validé sur le matériel réel.

## Validations incluses

- sortie audio interne C-Media, route `dac` ;
- microphone USB C-Media reconnu par Android ;
- gain 32/35 et AGC activé après redémarrage ;
- absence de micro-coupures et de saturation constatée ;
- batterie V1 lissée préservée ;
- aucun APEX audio expérimental ;
- archive finale SHA256 : `03fe2f742066cca690fd1405a4fbd20de914d73224e2bca20960e27a4238b8ae`.

## Contenu du dépôt

- documentation de release ;
- installateur rpiboot ;
- restauration ;
- vérification ADB ;
- correctif source `UsbAlsaManager` ;
- script de gain microphone et propriétés audio.
