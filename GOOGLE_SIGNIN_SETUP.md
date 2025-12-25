# Configuration de la connexion Google

## ✅ Code implémenté

Le code pour la connexion Google a été implémenté dans l'application. Cependant, vous devez configurer le provider dans Firebase Console pour que cela fonctionne.

## 🔧 Configuration Firebase

### 1. Activer Google Sign-In dans Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet `citycare-5aa31`
3. Allez dans **Authentication** > **Sign-in method**
4. Cliquez sur **Google** et activez-le
5. Entrez votre **Email de support** (votre email)
6. Cliquez sur **Enregistrer**

### 2. Configuration Android (SHA-1)

Pour que Google Sign-In fonctionne sur Android, vous devez ajouter l'empreinte SHA-1 de votre clé de signature dans Firebase :

1. **Obtenir le SHA-1 :**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   
   Ou pour la clé de release :
   ```bash
   keytool -list -v -keystore android/app/keystore.jks -alias votre-alias
   ```

2. **Ajouter dans Firebase :**
   - Allez dans Firebase Console > **Project Settings** > **Your apps** > **Android app**
   - Cliquez sur **Add fingerprint**
   - Collez le SHA-1 (sans les deux-points)
   - Cliquez sur **Save**

3. **Télécharger le nouveau `google-services.json` :**
   - Dans Firebase Console > Project Settings > Your apps > Android app
   - Téléchargez le fichier `google-services.json` mis à jour
   - Remplacez le fichier existant dans `android/app/google-services.json`

### 3. Configuration iOS (optionnel)

Si vous développez pour iOS, vous devez également :
1. Configurer l'URL de redirection dans Firebase Console
2. Ajouter l'URL scheme dans `ios/Runner/Info.plist`

## 📱 Test

Une fois la configuration terminée :

1. Recompilez l'application : `flutter clean && flutter pub get`
2. Lancez l'application : `flutter run`
3. Testez le bouton "Continuer avec Google" sur la page de login

## ⚠️ Notes importantes

- Les utilisateurs qui se connectent avec Google seront automatiquement créés dans Firestore
- Le rôle par défaut est `user` (pas `admin`)
- L'avatar sera récupéré automatiquement depuis le compte Google
- Le nom et l'email seront récupérés depuis le compte Google

## 🐛 Dépannage

**Erreur "DEVELOPER_ERROR" sur Android :**
- Vérifiez que le SHA-1 est correctement configuré dans Firebase
- Régénérez le fichier `google-services.json`
- Assurez-vous que le package name dans Firebase correspond à celui de votre app

**Erreur "10" (DEVELOPER_ERROR) :**
- Vérifiez que Google Sign-In est activé dans Firebase Console
- Vérifiez que l'email de support est configuré

**L'application se ferme lors de la connexion :**
- Vérifiez les logs avec `flutter run -v`
- Assurez-vous que toutes les dépendances sont à jour

