import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _userData;
  
  // Mode hors ligne pour tester sans Firebase

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userName => _userData?['nom'] ?? _user?.displayName;

  // Initialiser - écouter les changements d'auth
  void initialize() {
    debugPrint('🔵 Initialisation du AuthProvider');
    _authService.authStateChanges.listen((User? user) {
      debugPrint('📱 authStateChanges triggered: user=${user?.email ?? "null"}, uid=${user?.uid ?? "null"}');
      _user = user;
      if (user != null) {
        debugPrint('✅ Utilisateur connecté: ${user.email}');
        debugPrint('📌 userId is now: ${_user?.uid}');
        chargerDonneesUtilisateur();
      } else {
        debugPrint('⚠️ Aucun utilisateur connecté');
        _userData = null;
      }
      notifyListeners();
    });
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> chargerDonneesUtilisateur() async {
    if (_user == null) {
      debugPrint('⚠️ chargerDonneesUtilisateur: _user est null, skip');
      return;
    }

    try {
      debugPrint('🔵 Chargement données utilisateur pour uid=${_user?.uid}');
      _userData = await _authService.getUserData();
      debugPrint('✅ Données utilisateur chargées');
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Erreur chargement données utilisateur (non bloquant): $e');
      // Ne pas bloquer si les données Firestore ne peuvent pas être chargées
      _userData = null;
    }
  }

  // INSCRIPTION
  Future<bool> signUp({
    required String email,
    required String password,
    required String nom,
    required int age,
    required double taille,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔵 Début signUp: email=$email');
      UserCredential? credential = await _authService.signUp(
        email: email,
        password: password,
        nom: nom,
        age: age,
        taille: taille,
      );

      if (credential != null) {
        debugPrint('✅ signUp réussi, uid=${credential.user?.uid}');
        _user = credential.user;
        debugPrint('📌 _user après signUp: ${_user?.uid}');
        await chargerDonneesUtilisateur();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Erreur lors de l\'inscription';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ signUp erreur: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // CONNEXION
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔵 Début signIn: email=$email');
      UserCredential? credential = await _authService.signIn(
        email: email,
        password: password,
      );

      if (credential != null) {
        debugPrint('✅ signIn réussi, uid=${credential.user?.uid}');
        _user = credential.user;
        debugPrint('📌 _user après signIn: ${_user?.uid}');
        await chargerDonneesUtilisateur();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Erreur lors de la connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ signIn erreur: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // DÉCONNEXION
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _userData = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // RÉINITIALISER MOT DE PASSE
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // CHANGER MOT DE PASSE
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // METTRE À JOUR PROFIL
  Future<bool> updateUserProfile({
    String? nom,
    int? age,
    double? taille,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        nom: nom,
        age: age,
        taille: taille,
      );
      
      // Recharger les données
      await chargerDonneesUtilisateur();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // SUPPRIMER COMPTE
  Future<bool> deleteAccount(String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount(password);
      _user = null;
      _userData = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ENVOYER EMAIL DE VÉRIFICATION
  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // RECHARGER UTILISATEUR
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _user = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur rechargement utilisateur: $e');
    }
  }

  // Réinitialiser l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser tout
  void reset() {
    _user = null;
    _userData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}