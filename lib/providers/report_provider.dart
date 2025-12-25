import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart'; // BDD
import 'package:firebase_storage/firebase_storage.dart'; // Images
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/report.dart';
import '../services/image_storage_service.dart';

class ReportProvider with ChangeNotifier {
  List<Report> _reports = [];
  DocumentSnapshot? _lastDocument; // Pour la pagination
  DocumentSnapshot? _lastAllDocument; // Pour la pagination admin
  bool _hasMore = true;
  bool _hasMoreAll = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 10; // Nombre de documents par page

  List<Report> get reports {
    return [..._reports];
  }

  bool get hasMore => _hasMore;
  bool get hasMoreAll => _hasMoreAll;
  bool get isLoadingMore => _isLoadingMore;

  // 1. Récupérer les signalements depuis Firebase pour l'utilisateur connecté (avec pagination)
  Future<void> fetchReports([String? userId, bool loadMore = false]) async {
    try {
      // Si userId n'est pas fourni, utiliser l'utilisateur Firebase actuel
      final currentUserId = userId ?? auth.FirebaseAuth.instance.currentUser?.uid;
      
      developer.log('fetchReports appelé avec userId: $currentUserId, loadMore: $loadMore', name: 'ReportProvider');
      
      if (currentUserId == null) {
        developer.log('Aucun utilisateur connecté', name: 'ReportProvider');
        _reports = [];
        _hasMore = false;
        notifyListeners();
        return;
      }

      // Si on charge plus, on continue depuis le dernier document
      // Sinon, on réinitialise la liste
      if (!loadMore) {
        _reports = [];
        _lastDocument = null;
        _hasMore = true;
      }

      if (_isLoadingMore) return; // Éviter les appels multiples
      _isLoadingMore = true;
      notifyListeners();

      Query query = FirebaseFirestore.instance
          .collection('reports')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('date', descending: true)
          .limit(_pageSize);

      // Si on a un dernier document, commencer après celui-ci
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      developer.log('Nombre de documents trouvés: ${snapshot.docs.length}', name: 'ReportProvider');

      final List<Report> loadedReports = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        developer.log('Document trouvé: ${doc.id} avec userId: ${data['userId']}', name: 'ReportProvider');
        
        // Gérer l'image - utiliser placeholder si vide ou invalide
        String imagePath = 'assets/placeholder.png';
        String? localImagePath = data['imagePath'] as String?;
        if (localImagePath != null && localImagePath.isNotEmpty) {
          // Vérifier si l'image locale existe
          if (await ImageStorageService.localImageExists(localImagePath)) {
            imagePath = localImagePath;
          } else {
            developer.log('Image locale non trouvée: $localImagePath', name: 'ReportProvider');
          }
        }
        
        loadedReports.add(Report(
          id: doc.id,
          title: data['title'] as String? ?? 'Sans titre',
          description: data['description'] as String? ?? '',
          date: data['date'] as String? ?? '',
          status: data['status'] as String? ?? 'En attente',
          imagePath: imagePath,
          latitude: data['latitude'] as double?,
          longitude: data['longitude'] as double?,
        ));
      }

      // Mettre à jour la liste et le dernier document
      if (loadMore) {
        _reports.addAll(loadedReports);
      } else {
      _reports = loadedReports;
      }

      // Vérifier s'il y a plus de documents à charger
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }

      developer.log('Nombre total de rapports chargés: ${_reports.length}, hasMore: $_hasMore', name: 'ReportProvider');
      _isLoadingMore = false;
      notifyListeners();
    } catch (error) {
      developer.log('Erreur fetchReports : $error', name: 'ReportProvider');
      _isLoadingMore = false;
      notifyListeners();
      rethrow;
    }
  }

  // Charger plus de signalements (pagination)
  Future<void> loadMoreReports([String? userId]) async {
    if (!_hasMore || _isLoadingMore) return;
    await fetchReports(userId, true);
  }

  // Pour admin : récupérer TOUS les signalements (avec pagination)
  Future<void> fetchAllReports({bool loadMore = false}) async {
    try {
      developer.log('fetchAllReports appelé, loadMore: $loadMore', name: 'ReportProvider');
      
      // Si on charge plus, on continue depuis le dernier document
      // Sinon, on réinitialise la liste
      if (!loadMore) {
        _reports = [];
        _lastAllDocument = null;
        _hasMoreAll = true;
      }

      if (_isLoadingMore) return; // Éviter les appels multiples
      _isLoadingMore = true;
      notifyListeners();

      Query query = FirebaseFirestore.instance
          .collection('reports')
          .orderBy('date', descending: true)
          .limit(_pageSize);

      // Si on a un dernier document, commencer après celui-ci
      if (_lastAllDocument != null) {
        query = query.startAfterDocument(_lastAllDocument!);
      }

      final snapshot = await query.get();

      developer.log('Nombre total de documents trouvés: ${snapshot.docs.length}', name: 'ReportProvider');

      final List<Report> loadedReports = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        developer.log('Document trouvé dans fetchAllReports: ${doc.id} avec userId: ${data['userId']}', name: 'ReportProvider');
        
        // Gérer le format de date - convertir si nécessaire
        String reportDate = data['date'] as String? ?? '';
        if (reportDate.contains('T')) {
          // Format ISO 8601, convertir en format lisible
          try {
            final dateTime = DateTime.parse(reportDate);
            reportDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
          } catch (e) {
            developer.log('Erreur de conversion de date: $e', name: 'ReportProvider');
            // Garder la date originale si la conversion échoue
          }
        }
        
        // Gérer l'image - utiliser placeholder si vide ou invalide
        String imagePath = 'assets/placeholder.png';
        String? localImagePath = data['imagePath'] as String?;
        if (localImagePath != null && localImagePath.isNotEmpty) {
          // Vérifier si l'image locale existe
          if (await ImageStorageService.localImageExists(localImagePath)) {
            imagePath = localImagePath;
          } else {
            developer.log('Image locale non trouvée: $localImagePath', name: 'ReportProvider');
          }
        }
        
        loadedReports.add(Report(
          id: doc.id,
          title: data['title'] as String? ?? 'Sans titre',
          description: data['description'] as String? ?? '',
          date: reportDate,
          status: data['status'] as String? ?? 'En attente',
          imagePath: imagePath,
          latitude: data['latitude'] as double?,
          longitude: data['longitude'] as double?,
        ));
      }

      // Mettre à jour la liste et le dernier document
      if (loadMore) {
        _reports.addAll(loadedReports);
      } else {
      _reports = loadedReports;
      }

      // Vérifier s'il y a plus de documents à charger
      if (snapshot.docs.isNotEmpty) {
        _lastAllDocument = snapshot.docs.last;
        _hasMoreAll = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreAll = false;
      }

      developer.log('Nombre total de rapports chargés: ${_reports.length}, hasMoreAll: $_hasMoreAll', name: 'ReportProvider');
      _isLoadingMore = false;
      notifyListeners();
    } catch (error) {
      developer.log('Erreur fetchAllReports : $error', name: 'ReportProvider');
      _isLoadingMore = false;
      notifyListeners();
      rethrow;
    }
  }

  // Charger plus de signalements pour admin (pagination)
  Future<void> loadMoreAllReports() async {
    if (!_hasMoreAll || _isLoadingMore) return;
    await fetchAllReports(loadMore: true);
  }

  // Mettre à jour uniquement le statut d'un signalement (pour admin)
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Mettre à jour la liste locale
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = Report(
          id: _reports[index].id,
          title: _reports[index].title,
          description: _reports[index].description,
          date: _reports[index].date,
          status: newStatus,
          imagePath: _reports[index].imagePath,
          latitude: _reports[index].latitude,
          longitude: _reports[index].longitude,
        );
        notifyListeners();
      }
    } catch (error) {
      developer.log('Erreur updateReportStatus : $error', name: 'ReportProvider');
      rethrow;
    }
  }

  // 3. Mettre à jour un signalement (avec vérification utilisateur)
  Future<void> updateReport(Report report, File? newImageFile) async {
    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      String imagePath = report.imagePath;

      // Si une nouvelle image est fournie, la sauvegarder localement
      if (newImageFile != null) {
        try {
          // Supprimer l'ancienne image si elle existe
          if (report.imagePath.isNotEmpty) {
            await ImageStorageService.deleteLocalImage(report.imagePath);
          }
          
          // Sauvegarder la nouvelle image
          imagePath = await ImageStorageService.saveImageLocally(newImageFile, report.id);
          developer.log('Nouvelle image sauvegardée localement: $imagePath', name: 'ReportProvider');
        } catch (storageError) {
          developer.log('Erreur sauvegarde image locale: $storageError', name: 'ReportProvider');
          imagePath = '';
        }
      }

      // Mettre à jour le document dans Firestore
      await FirebaseFirestore.instance.collection('reports').doc(report.id).update({
        'title': report.title,
        'description': report.description,
        'status': report.status,
        'imagePath': imagePath, // Chemin local au lieu de l'URL
        'latitude': report.latitude,
        'longitude': report.longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Mettre à jour la liste locale
      final index = _reports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _reports[index] = Report(
          id: report.id,
          title: report.title,
          description: report.description,
          date: report.date,
          status: report.status,
          imagePath: imagePath,
          latitude: report.latitude,
          longitude: report.longitude,
        );
        notifyListeners();
      }
    } catch (error) {
      developer.log('Erreur updateReport : $error', name: 'ReportProvider');
      rethrow;
    }
  }

  // Statistiques en temps réel
  Map<String, int> get statusCounts {
    Map<String, int> counts = {
      'En attente': 0,
      'En cours': 0,
      'Résolu': 0,
    };
    
    for (var report in _reports) {
      if (counts.containsKey(report.status)) {
        counts[report.status] = (counts[report.status] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  double get resolutionRate {
    if (_reports.isEmpty) return 0.0;
    int resolved = _reports.where((r) => r.status == 'Résolu').length;
    return (resolved / _reports.length) * 100;
  }

  List<Map<String, dynamic>> get weeklyStats {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    List<Map<String, dynamic>> weekData = [];
    for (int i = 0; i < 5; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayReports = _reports.where((r) {
        try {
          final reportDate = DateTime.parse(r.date.replaceAll('/', '-'));
          return reportDate.year == day.year && 
                 reportDate.month == day.month && 
                 reportDate.day == day.day;
        } catch (e) {
          return false;
        }
      }).length;
      
      weekData.add({
        'day': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'][i],
        'count': dayReports,
      });
    }
    
    return weekData;
  }

  Map<String, int> get monthlyStats {
  Map<String, int> monthlyData = {};
  
  for (var report in _reports) {
    try {
      final reportDate = DateTime.parse(report.date.replaceAll('/', '-'));
      final monthKey = '${reportDate.year}-${reportDate.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    } catch (e) {
      continue;
    }
  }
  
  return monthlyData;
}

  Future<void> deleteReport(String reportId) async {
    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Supprimer le document de Firestore
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();

      // Supprimer de la liste locale
      _reports.removeWhere((r) => r.id == reportId);
      notifyListeners();
    } catch (error) {
      developer.log('Erreur deleteReport : $error', name: 'ReportProvider');
      rethrow;
    }
  }
  Future<void> addReport(Report report, File? imageFile) async {
    try {
      String imagePath = '';

      // A. Sauvegarde locale de l'image si elle existe
      if (imageFile != null) {
        try {
          // Générer un ID temporaire pour le nom de fichier
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          imagePath = await ImageStorageService.saveImageLocally(imageFile, tempId);
          developer.log('Image sauvegardée localement: $imagePath', name: 'ReportProvider');
        } catch (storageError) {
          developer.log('Erreur sauvegarde locale image: $storageError', name: 'ReportProvider');
          imagePath = '';
        }
      }

      // B. Envoi des données dans Firestore avec le chemin local de l'image
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      developer.log('Création d\'un rapport avec userId: $currentUserId', name: 'ReportProvider');

      final docRef = await FirebaseFirestore.instance.collection('reports').add({
        'title': report.title,
        'description': report.description,
        'date': DateTime.now().toIso8601String(),
        'status': report.status,
        'imagePath': imagePath, // Chemin local au lieu de l'URL Firebase
        'latitude': report.latitude,
        'longitude': report.longitude,
        'userId': currentUserId,
      });

      developer.log('Rapport créé avec ID: ${docRef.id}', name: 'ReportProvider');

      // C. Si l'image a été sauvegardée localement, renommer avec le vrai ID du rapport
      if (imagePath.isNotEmpty) {
        try {
          final newPath = await ImageStorageService.saveImageLocally(imageFile!, docRef.id);
          // Mettre à jour le chemin dans Firestore avec le bon nom de fichier
          await FirebaseFirestore.instance.collection('reports').doc(docRef.id).update({
            'imagePath': newPath,
          });
          imagePath = newPath;
          developer.log('Image renommée avec ID rapport: $newPath', name: 'ReportProvider');
        } catch (renameError) {
          developer.log('Erreur renommage image: $renameError', name: 'ReportProvider');
        }
      }

      // D. Mise à jour locale (pour voir le résultat tout de suite sans recharger)
      final newReport = Report(
        id: docRef.id,
        title: report.title,
        description: report.description,
        date: report.date,
        status: report.status,
        imagePath: imagePath,
        latitude: report.latitude,
        longitude: report.longitude,
      );
      
      _reports.insert(0, newReport);
      notifyListeners();

    } catch (error) {
      developer.log('Erreur addReport : $error', name: 'ReportProvider');
      rethrow;
    }
  }
}