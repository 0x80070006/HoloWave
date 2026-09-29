# HoloWave

Lecteur de musique locale pour Android, écrit en Flutter. Il parcourt la bibliothèque audio de l'appareil, gère des playlists et expose les commandes de lecture Android.

**État :** APK v5.0.8 publiée. Le code de `main` porte encore le numéro interne `1.0.0` et sa correspondance avec les APK publiés n'est pas établie. La compilation et la lecture sur appareil n'ont pas été vérifiées pendant cet audit.

## Télécharger

[Télécharger HoloWave v5.0.8](https://github.com/0x80070006/HoloWave/releases/download/ver.5.0.8/HoloWave-ver.5.0.8.apk) · [Historique des versions](https://github.com/0x80070006/HoloWave/releases)

La version 5.0.5 est explicitement une démonstration. Les anciens tags conservent leur nom d'origine pour que leurs liens et APK restent accessibles.

![Logo HoloWave](assets/logo.png)

## Fonctionnalités

- Indexation des morceaux présents sur le téléphone.
- Lecture locale et commandes en arrière-plan.
- Playlists, écran de lecture et réglages.

## Construire

Prérequis : Flutter, Dart et Android SDK. Depuis la racine :

```bash
flutter pub get
flutter build apk --debug
```

L'APK est normalement créée dans `build/app/outputs/flutter-apk/`. Le dossier Android contient un wrapper Gradle, mais pas la structure Flutter générée complète ; si la compilation échoue, il faut d'abord rétablir les fichiers Android manquants et valider le résultat. Aucun build reproductible n'est garanti à ce stade.

## Technologies

| Rôle | Dépendances |
| --- | --- |
| Interface et état | Flutter, Dart, `provider` |
| Lecture et notification | `just_audio`, `just_audio_background`, `audio_service`, `audio_session` |
| Bibliothèque locale | `on_audio_query`, `permission_handler` |
| Préférences et médias | `shared_preferences`, `image_picker`, `path`, `rxdart` |

Les versions exactes sont dans [pubspec.yaml](pubspec.yaml) et [pubspec.lock](pubspec.lock).

## Données et permissions

L'application demande l'accès aux médias locaux pour indexer et lire les morceaux. Vérifiez les permissions Android avant installation.

## Licence

Code sous licence MIT : [LICENSE](LICENSE). Les noms, pochettes et autres contenus tiers ne sont pas inclus dans cette autorisation.
