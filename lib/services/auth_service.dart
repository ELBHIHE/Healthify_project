import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour écouter les changements d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _auth.currentUser != null;

  // Obtenir l'UID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  // ========== INSCRIPTION ==========
  
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String nom,
    required int age,
    required double taille,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Essayer de créer le document utilisateur dans Firestore.
      // Si Firestore n'est pas disponible ou si l'écriture échoue,
      // on ne bloque pas l'inscription : on log l'erreur et on continue.
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'nom': nom,
          'email': email,
          'age': age,
          'taille': taille,
          'dateCreation': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 6));
      } catch (e) {
        // Log et continuer : l'utilisateur est quand même créé dans Firebase Auth
        debugPrint('⚠️ Firestore write failed during signUp: $e');
      }

      // Mettre à jour le displayName
      await userCredential.user?.updateDisplayName(nom);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur est survenue lors de l\'inscription: $e';
    }
  }

  // ========== CONNEXION ==========
  
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur est survenue lors de la connexion';
    }
  }

  // ========== DÉCONNEXION ==========
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Erreur lors de la déconnexion';
    }
  }

  // ========== RÉINITIALISATION MOT DE PASSE ==========
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de l\'envoi de l\'email de réinitialisation';
    }
  }

  // ========== CHANGER MOT DE PASSE ==========
  
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Aucun utilisateur connecté';

      // Ré-authentifier l'utilisateur
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors du changement de mot de passe';
    }
  }

  // ========== SUPPRIMER COMPTE ==========
  
  Future<void> deleteAccount(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Aucun utilisateur connecté';

      // Ré-authentifier l'utilisateur
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Supprimer les données Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Supprimer le compte
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erreur lors de la suppression du compte';
    }
  }

  // ========== OBTENIR DONNÉES UTILISATEUR ==========
  
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } on TimeoutException {
      throw 'Timeout: impossible de charger les données utilisateur. Vérifiez les règles Firestore.';
    } catch (e) {
      throw 'Erreur lors de la récupération des données utilisateur: $e';
    }
  }

  // ========== METTRE À JOUR PROFIL ==========
  
  Future<void> updateUserProfile({
    String? nom,
    int? age,
    double? taille,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Aucun utilisateur connecté';

      Map<String, dynamic> updates = {};
      
      if (nom != null) {
        updates['nom'] = nom;
        await user.updateDisplayName(nom);
      }
      if (age != null) updates['age'] = age;
      if (taille != null) updates['taille'] = taille;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil';
    }
  }

  // ========== GESTION DES ERREURS ==========
  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      case 'invalid-credential':
        return 'Les identifiants sont invalides.';
      case 'requires-recent-login':
        return 'Cette opération nécessite une reconnexion récente.';
      default:
        return 'Une erreur est survenue: ${e.message}';
    }
  }

  // ========== VÉRIFICATION EMAIL ==========
  
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'Aucun utilisateur connecté';
      
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Erreur lors de l\'envoi de l\'email de vérification';
    }
  }

  // ========== RECHARGER UTILISATEUR ==========
  
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw 'Erreur lors du rechargement des données utilisateur';
    }
  }
}