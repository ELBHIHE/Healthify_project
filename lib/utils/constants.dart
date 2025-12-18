import 'package:flutter/material.dart';

// Couleurs de l'application
class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF2196F3);
  static const Color accent = Color(0xFFFF9800);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

// Moments de prise de glycémie
class MomentsGlycemie {
  static const String aJeun = 'À jeun';
  static const String apresRepas = 'Après repas';
  static const String avantRepas = 'Avant repas';
  static const String auCoucher = 'Au coucher';
  
  static List<String> getAll() {
    return [aJeun, apresRepas, avantRepas, auCoucher];
  }
}

// Périodes de prise de médicaments
class PeriodesMedicament {
  static const String matin = 'Matin';
  static const String midi = 'Midi';
  static const String soir = 'Soir';
  static const String nuit = 'Nuit';
  
  static List<String> getAll() {
    return [matin, midi, soir, nuit];
  }
}

// Valeurs de référence pour la santé
class ValeursReference {
  // Glycémie (mg/dL)
  static const double glycemieMin = 70.0;
  static const double glycemieMax = 126.0;
  
  // Tension artérielle (mmHg)
  static const int tensionSystoliqueOptimale = 120;
  static const int tensionDiastoliqueOptimale = 80;
  static const int tensionSystoliqueElevee = 140;
  static const int tensionDiastoliqueElevee = 90;
  
  // Cholestérol (g/L)
  static const double cholesterolTotalMax = 2.0;
  static const double ldlMax = 1.6;
  static const double hdlMin = 0.4;
  
  // IMC
  static const double imcSousPoids = 18.5;
  static const double imcNormal = 25.0;
  static const double imcSurpoids = 30.0;
}

// Messages d'erreur
class ErrorMessages {
  static const String emailInvalide = 'Adresse email invalide';
  static const String motDePasseCourt = 'Le mot de passe doit contenir au moins 6 caractères';
  static const String champsVides = 'Veuillez remplir tous les champs';
  static const String erreurConnexion = 'Erreur de connexion';
  static const String erreurInscription = 'Erreur lors de l\'inscription';
}