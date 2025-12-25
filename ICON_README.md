# Génération de l'icône de l'application

L'icône de l'application CityCare correspond au logo affiché sur la page de login :
- Gradient bleu (de #1E3A8A vers #3B82F6)
- Icône de ville blanche au centre
- Coins arrondis

## Régénérer l'icône

Si vous souhaitez modifier ou régénérer l'icône :

1. Modifiez le script `generate_app_icon.py` si nécessaire
2. Exécutez : `python3 generate_app_icon.py`
3. Régénérez les icônes pour toutes les plateformes : `flutter pub run flutter_launcher_icons`

## Fichiers générés

- **Source** : `assets/app_icon.png` (1024x1024)
- **Android** : Toutes les tailles dans `android/app/src/main/res/mipmap-*/`
- **iOS** : Toutes les tailles dans `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Configuration

La configuration se trouve dans `pubspec.yaml` sous la section `flutter_launcher_icons`.

