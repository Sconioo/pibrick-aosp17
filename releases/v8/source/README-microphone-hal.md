# Implémentation microphone V8 finale

Le mécanisme `sysinit` a été abandonné : les fichiers ajoutés après compilation restaient `unlabeled`, et les domaines `konstakang` puis `initd` généraient des refus SELinux.

La solution validée fait lancer directement deux commandes `amixer` par Android Init, avec un exécutable portant le type `hal_audio_default_exec`. La transition `init -> hal_audio_default` donne les accès ALSA nécessaires, y compris en mode Enforcing.

Fichier Init : `18547fc5148556453c6210eb5d69b8f0b399aa44d1c49c1f3df45be3b1f7b453`
Binaire HAL : `e35c4ede27f85fe9f8a96cc8e798eb004cf91a87e99ac46ae24784dfe38a3a5d`
