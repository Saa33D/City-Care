import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import '../services/profile_image_service.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String phone;
  final DateTime createdAt;
  final int reportsCount;
  final String role; // 'user' ou 'admin'

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
    this.phone = '',
    required this.createdAt,
    this.reportsCount = 0,
    this.role = 'user',
  });

  // Convertir depuis Firebase User
  factory User.fromFirebase(auth.User firebaseUser, Map<String, dynamic>? userData) {
    final role = userData?['role'] ?? 'user';
    final avatarPath = userData?['avatar'] ?? firebaseUser.photoURL ?? '';
    
    developer.log('User.fromFirebase - role: $role pour ${firebaseUser.email}', name: 'AuthProvider');
    developer.log('User.fromFirebase - avatar: $avatarPath', name: 'AuthProvider');
    
    return User(
      id: firebaseUser.uid,
      name: userData?['name'] ?? firebaseUser.displayName ?? 'Utilisateur',
      email: firebaseUser.email ?? '',
      avatar: avatarPath,
      phone: userData?['phone'] ?? '',
      createdAt: userData?['createdAt']?.toDate() ?? DateTime.now(),
      reportsCount: userData?['reportsCount'] ?? 0,
      role: role,
    );
  }

  // Propriété pour vérifier si c'est un admin
  bool get isAdmin => role == 'admin';

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'reportsCount': reportsCount,
      'role': role,
    };
  }
}

class AuthProvider with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkAuthStatus();
  }

  // Vérifier le statut d'authentification au démarrage
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      auth.User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser);
      }
    } catch (error) {
      debugPrint('Erreur checkAuthStatus: $error');
      notifyListeners();
    }
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserData(auth.User firebaseUser) async {
    try {
      // Charger les données utilisateur depuis Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      
      developer.log('Firestore userData: $userData', name: 'AuthProvider');
      developer.log('Avatar from Firestore: ${userData?['avatar']}', name: 'AuthProvider');
      
      _currentUser = User.fromFirebase(firebaseUser, userData);
      developer.log('User créé - role: ${_currentUser?.role}, avatar: ${_currentUser?.avatar}', name: 'AuthProvider');
      
      _isAuthenticated = true;
      notifyListeners();
    } catch (error) {
      debugPrint('Erreur loadUserData: $error');
      // Créer le document utilisateur s'il n'existe pas
      await _createUserDocument(firebaseUser);
    }
  }

  // Créer le document utilisateur dans Firestore
  Future<void> _createUserDocument(auth.User firebaseUser) async {
    try {
      User newUser = User.fromFirebase(firebaseUser, null);
      
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toMap());

      _currentUser = newUser;
      _isAuthenticated = true;
      notifyListeners();
    } catch (error) {
      debugPrint('Erreur createUserDocument: $error');
      throw Exception('Impossible de créer le profil utilisateur');
    }
  }

  // Inscription avec email et mot de passe
  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Créer l'utilisateur Firebase
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Attendre que l'utilisateur soit complètement initialisé
      await Future.delayed(const Duration(milliseconds: 500));

      // Créer le document utilisateur avec les données de base
      final newUser = User(
        id: result.user!.uid,
        name: name,
        email: email,
        avatar: '',
        phone: '',
        createdAt: DateTime.now(),
        reportsCount: 0,
      );
      
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      _currentUser = newUser;
      _isAuthenticated = true;
      notifyListeners();
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);
      throw Exception(errorMessage);
    } catch (error) {
      throw Exception('Erreur d\'inscription: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Connexion avec email et mot de passe
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Attendre que l'utilisateur soit complètement initialisé
      await Future.delayed(const Duration(milliseconds: 500));

      // Charger les données utilisateur depuis Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      
      developer.log('Login - Firestore userData: $userData', name: 'AuthProvider');
      developer.log('Login - Avatar from Firestore: ${userData?['avatar']}', name: 'AuthProvider');
      
      if (userData != null) {
        _currentUser = User.fromFirebase(result.user!, userData);
        developer.log('Login - User créé - role: ${_currentUser?.role}, avatar: ${_currentUser?.avatar}', name: 'AuthProvider');
      } else {
        // Créer un document utilisateur si inexistant
        final newUser = User(
          id: result.user!.uid,
          name: result.user!.displayName ?? 'Utilisateur',
          email: result.user!.email ?? '',
          avatar: '',
          phone: '',
          createdAt: DateTime.now(),
          reportsCount: 0,
        );
        
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());
        
        _currentUser = newUser;
      }
      
      _isAuthenticated = true;
      notifyListeners();
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);
      throw Exception(errorMessage);
    } catch (error) {
      throw Exception('Erreur de connexion: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (error) {
      throw Exception('Erreur de déconnexion: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);
      throw Exception(errorMessage);
    } catch (error) {
      throw Exception('Erreur d\'envoi de l\'email de réinitialisation: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Connexion avec Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Créer une instance de GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: <String>['email', 'profile'],
      );

      // Déclencher le flux de connexion Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer un credential Firebase
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter avec Firebase
      final auth.UserCredential result = await _auth.signInWithCredential(credential);

      // Attendre que l'utilisateur soit complètement initialisé
      await Future.delayed(const Duration(milliseconds: 500));

      // Vérifier si le document utilisateur existe dans Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        // Utilisateur existant
        _currentUser = User.fromFirebase(result.user!, userData);
      } else {
        // Nouvel utilisateur - créer le document dans Firestore
        final newUser = User(
          id: result.user!.uid,
          name: result.user!.displayName ?? googleUser.displayName ?? 'Utilisateur',
          email: result.user!.email ?? googleUser.email,
          avatar: result.user!.photoURL ?? googleUser.photoUrl ?? '',
          phone: '',
          createdAt: DateTime.now(),
          reportsCount: 0,
          role: 'user',
        );
        
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());
        
        _currentUser = newUser;
      }

      _isAuthenticated = true;
      notifyListeners();
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);
      throw Exception(errorMessage);
    } catch (error) {
      developer.log('Erreur Google Sign-In: $error', name: 'AuthProvider');
      throw Exception('Erreur de connexion Google: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateProfile({String? name, String? phone, File? profileImage}) async {
    if (_currentUser == null) return;

    developer.log('updateProfile appelé - name: $name, phone: $phone, profileImage: ${profileImage?.path}', name: 'AuthProvider');
    developer.log('Avatar actuel: ${_currentUser!.avatar}', name: 'AuthProvider');

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> updateData = {};
      String? profileImagePath;
      
      // Gérer la photo de profil
      if (profileImage != null) {
        try {
          developer.log('Traitement de la nouvelle photo de profil...', name: 'AuthProvider');
          
          // Supprimer l'ancienne photo si elle existe
          if (_currentUser!.avatar.isNotEmpty && !_currentUser!.avatar.startsWith('http')) {
            await ProfileImageService.deleteProfileImage(_currentUser!.avatar);
            developer.log('Ancienne photo locale supprimée: ${_currentUser!.avatar}', name: 'AuthProvider');
          }
          
          // Sauvegarder la nouvelle photo
          profileImagePath = await ProfileImageService.saveProfileImage(profileImage, _currentUser!.id);
          updateData['avatar'] = profileImagePath;
          developer.log('Photo de profil mise à jour: $profileImagePath', name: 'AuthProvider');
        } catch (imageError) {
          developer.log('Erreur mise à jour photo profil: $imageError', name: 'AuthProvider');
        }
      }
      
      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
        await _auth.currentUser?.updateDisplayName(name);
      }
      
      if (phone != null) {
        updateData['phone'] = phone;
      }

      developer.log('updateData à envoyer: $updateData', name: 'AuthProvider');

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_currentUser!.id)
            .update(updateData);
        
        developer.log('Firestore mis à jour avec succès', name: 'AuthProvider');

        // Mettre à jour l'utilisateur local
        _currentUser = User(
          id: _currentUser!.id,
          name: name ?? _currentUser!.name,
          email: _currentUser!.email,
          avatar: profileImagePath ?? _currentUser!.avatar,
          phone: phone ?? _currentUser!.phone,
          createdAt: _currentUser!.createdAt,
          reportsCount: _currentUser!.reportsCount,
          role: _currentUser!.role,
        );
        
        developer.log('Utilisateur local mis à jour - nouvel avatar: ${_currentUser!.avatar}', name: 'AuthProvider');
        notifyListeners();
      } else {
        developer.log('Aucune donnée à mettre à jour', name: 'AuthProvider');
      }
    } catch (error) {
      developer.log('Erreur globale updateProfile: $error', name: 'AuthProvider');
      throw Exception('Erreur de mise à jour: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthodes admin
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      
      if (_currentUser?.id == userId) {
        _currentUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          avatar: _currentUser!.avatar,
          phone: _currentUser!.phone,
          createdAt: _currentUser!.createdAt,
          reportsCount: _currentUser!.reportsCount,
          role: newRole,
        );
        notifyListeners();
      }
    } catch (error) {
      throw Exception('Erreur mise à jour rôle: $error');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (error) {
      throw Exception('Erreur suppression utilisateur: $error');
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          avatar: data['avatar'] ?? '',
          phone: data['phone'] ?? '',
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          reportsCount: data['reportsCount'] ?? 0,
          role: data['role'] ?? 'user',
        );
      }).toList();
    } catch (error) {
      throw Exception('Erreur récupération utilisateurs: $error');
    }
  }

  List<User> get allUsers => []; // À implémenter avec cache local

  // Créer le premier compte admin (à utiliser une seule fois)
  Future<void> createFirstAdmin(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(snapshot.docs.first.id)
            .update({'role': 'admin'});
      }
    } catch (error) {
      throw Exception('Erreur création admin: $error');
    }
  }

  // Obtenir les messages d'erreur Firebase en français
  String _getFirebaseErrorMessage(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 6 caractères)';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
