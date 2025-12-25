import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ProfileImageService {
  static const String _profileImagesFolderName = 'citycare_profile_images';
  
  /// Crée le dossier local pour stocker les photos de profil
  static Future<Directory> _getProfileImagesDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${appDir.path}/$_profileImagesFolderName');
      
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
        developer.log('Dossier profil créé: ${profileImagesDir.path}', name: 'ProfileImageService');
      }
      
      return profileImagesDir;
    } catch (e) {
      developer.log('Erreur création dossier profil: $e', name: 'ProfileImageService');
      throw Exception('Impossible de créer le dossier de profil');
    }
  }
  
  /// Sauvegarde une photo de profil et retourne le chemin du fichier
  static Future<String> saveProfileImage(File sourceImage, String userId) async {
    try {
      final profileImagesDir = await _getProfileImagesDirectory();
      final fileName = '${userId}_profile.jpg';
      final localImagePath = '${profileImagesDir.path}/$fileName';
      
      // Copier l'image vers le dossier local
      final savedImage = await sourceImage.copy(localImagePath);
      
      developer.log('Photo de profil sauvegardée: ${savedImage.path}', name: 'ProfileImageService');
      return savedImage.path;
    } catch (e) {
      developer.log('Erreur sauvegarde photo profil: $e', name: 'ProfileImageService');
      throw Exception('Impossible de sauvegarder la photo de profil');
    }
  }
  
  /// Supprime une photo de profil locale
  static Future<void> deleteProfileImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        developer.log('Photo de profil supprimée: $imagePath', name: 'ProfileImageService');
      }
    } catch (e) {
      developer.log('Erreur suppression photo profil: $e', name: 'ProfileImageService');
    }
  }
  
  /// Vérifie si une photo de profil locale existe
  static Future<bool> profileImageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      developer.log('Erreur vérification photo profil: $e', name: 'ProfileImageService');
      return false;
    }
  }
  
  /// Obtient le chemin par défaut pour une photo de profil utilisateur
  static Future<String> getProfileImagePath(String userId) async {
    try {
      final profileImagesDir = await _getProfileImagesDirectory();
      return '${profileImagesDir.path}/${userId}_profile.jpg';
    } catch (e) {
      developer.log('Erreur obtention chemin profil: $e', name: 'ProfileImageService');
      return '';
    }
  }
  
  /// Nettoie les anciennes photos de profil (optionnel)
  static Future<void> cleanupOldProfileImages({int maxAgeDays = 90}) async {
    try {
      final profileImagesDir = await _getProfileImagesDirectory();
      final files = await profileImagesDir.list().toList();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            developer.log('Ancienne photo profil supprimée: ${file.path}', name: 'ProfileImageService');
          }
        }
      }
    } catch (e) {
      developer.log('Erreur nettoyage photos profil: $e', name: 'ProfileImageService');
    }
  }
}
