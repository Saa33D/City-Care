import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ImageStorageService {
  static const String _imagesFolderName = 'citycare_images';
  
  /// Crée le dossier local pour stocker les images s'il n'existe pas
  static Future<Directory> _getImagesDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/$_imagesFolderName');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        developer.log('Dossier créé: ${imagesDir.path}', name: 'ImageStorage');
      }
      
      return imagesDir;
    } catch (e) {
      developer.log('Erreur création dossier images: $e', name: 'ImageStorage');
      throw Exception('Impossible de créer le dossier de stockage des images');
    }
  }
  
  /// Sauvegarde une image dans le dossier local et retourne le chemin du fichier
  static Future<String> saveImageLocally(File sourceImage, String reportId) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${reportId}_$timestamp.jpg';
      final localImagePath = '${imagesDir.path}/$fileName';
      
      // Copier l'image vers le dossier local
      final savedImage = await sourceImage.copy(localImagePath);
      
      developer.log('Image sauvegardée localement: ${savedImage.path}', name: 'ImageStorage');
      return savedImage.path;
    } catch (e) {
      developer.log('Erreur sauvegarde image locale: $e', name: 'ImageStorage');
      throw Exception('Impossible de sauvegarder l\'image localement');
    }
  }
  
  /// Supprime une image locale
  static Future<void> deleteLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        developer.log('Image supprimée: $imagePath', name: 'ImageStorage');
      }
    } catch (e) {
      developer.log('Erreur suppression image locale: $e', name: 'ImageStorage');
    }
  }
  
  /// Vérifie si une image locale existe
  static Future<bool> localImageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      developer.log('Erreur vérification image locale: $e', name: 'ImageStorage');
      return false;
    }
  }
  
  /// Nettoie les anciennes images locales (optionnel pour la gestion de l'espace)
  static Future<void> cleanupOldImages({int maxAgeDays = 30}) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final files = await imagesDir.list().toList();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            developer.log('Ancienne image supprimée: ${file.path}', name: 'ImageStorage');
          }
        }
      }
    } catch (e) {
      developer.log('Erreur nettoyage images anciennes: $e', name: 'ImageStorage');
    }
  }
  
  /// Retourne la liste des chemins d'images locales
  static Future<List<String>> getLocalImagesPaths() async {
    try {
      final imagesDir = await _getImagesDirectory();
      final files = await imagesDir.list().toList();
      
      return files
          .whereType<File>()
          .map((file) => file.path)
          .toList();
    } catch (e) {
      developer.log('Erreur récupération chemins images: $e', name: 'ImageStorage');
      return [];
    }
  }
}
