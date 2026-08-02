# piBrick AOSP 17 — composant V8 final

Ce composant ajoute à la base V7 validée :

- la jauge de batterie V1 lissée ;
- la reconnaissance du microphone USB C-Media par le framework ;
- le gain microphone automatique à 32/35 ;
- l’AGC activé au démarrage ;
- une exécution directe dans le domaine SELinux `hal_audio_default` ;
- la conservation de la sortie audio `dac`.

## Installation

Placez le piBrick en mode `rpiboot`, puis lancez depuis la racine du paquet :

```bash
./install.sh
```

## Vérification après démarrage

```bash
ADB_TARGET=192.168.1.168:5555 ./tools/verify-after-boot.sh
```

## Retour arrière

Replacez le piBrick en mode `rpiboot`, puis lancez :

```bash
./install.sh rollback-v8
```

## Fichiers microphone finaux

- `/vendor/etc/init/hw/init.rpi5.rc`
- `/vendor/bin/hw/android.hardware.audio.service`

Le second fichier contient une copie identique de `/vendor/bin/amixer`, installée avec le contexte SELinux `u:object_r:hal_audio_default_exec:s0`.

## Hachages

- init.rpi5.rc : `18547fc5148556453c6210eb5d69b8f0b399aa44d1c49c1f3df45be3b1f7b453`
- amixer HAL : `e35c4ede27f85fe9f8a96cc8e798eb004cf91a87e99ac46ae24784dfe38a3a5d`
