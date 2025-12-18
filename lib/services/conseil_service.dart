import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ConseilService {
  // ========== GLYCÉMIE ==========
  
  static String obtenirConseilGlycemie(double valeur, String moment) {
    if (valeur < ValeursReference.glycemieMin) {
      return _getConseilHypoglycemie(moment);
    } else if (valeur <= ValeursReference.glycemieMax) {
      return _getConseilGlycemieNormale(moment);
    } else {
      return _getConseilHyperglycemie(valeur, moment);
    }
  }

  static String _getConseilHypoglycemie(String moment) {
    if (moment == MomentsGlycemie.aJeun) {
      return 'Hypoglycémie à jeun détectée. Prenez immédiatement 15g de glucides rapides (jus, miel) et consultez votre médecin.';
    }
    return 'Hypoglycémie détectée. Prenez un jus de fruits ou des fruits secs et reposez-vous 15 minutes.';
  }

  static String _getConseilGlycemieNormale(String moment) {
    if (moment == MomentsGlycemie.aJeun) {
      return 'Excellente glycémie à jeun ! Maintenez ce niveau avec un petit-déjeuner équilibré.';
    }
    return 'Votre glycémie est dans la normale. Continuez vos bonnes habitudes alimentaires !';
  }

  static String _getConseilHyperglycemie(double valeur, String moment) {
    if (valeur > 180) {
      return 'Glycémie très élevée. Buvez de l\'eau, évitez tout sucre et contactez votre médecin si elle persiste.';
    }
    if (moment == MomentsGlycemie.apresRepas) {
      return 'Glycémie post-prandiale élevée. Réduisez les portions de glucides au prochain repas et marchez 10-15 minutes.';
    }
    return 'Glycémie élevée. Évitez les aliments sucrés et privilégiez les légumes verts et protéines.';
  }

  static Color obtenirCouleurGlycemie(double valeur) {
    if (valeur < ValeursReference.glycemieMin || valeur > 180) {
      return AppColors.danger;
    } else if (valeur > ValeursReference.glycemieMax) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  // ========== TENSION ==========
  
  static String obtenirConseilTension(int systolique, int diastolique) {
    // Hypotension
    if (systolique < 90 || diastolique < 60) {
      return 'Tension basse détectée. Hydratez-vous, allongez-vous avec les jambes surélevées. Si des symptômes persistent, consultez.';
    }
    
    // Optimale
    if (systolique < 120 && diastolique < 80) {
      return 'Tension artérielle optimale ! Maintenez une activité physique régulière et une alimentation pauvre en sel.';
    }
    
    // Normale
    if (systolique < 130 && diastolique < 85) {
      return 'Tension normale. Continuez vos bonnes habitudes et surveillez votre consommation de sel.';
    }
    
    // Normale haute
    if (systolique < 140 || diastolique < 90) {
      return 'Tension légèrement élevée. Réduisez le sel, pratiquez 30 min d\'exercice par jour et gérez votre stress.';
    }
    
    // Hypertension légère
    if (systolique < 160 || diastolique < 100) {
      return 'Hypertension légère. Consultez votre médecin pour un suivi. Limitez drastiquement le sel et augmentez l\'activité physique.';
    }
    
    // Hypertension sévère
    return 'Hypertension sévère. Consultez un médecin rapidement. Reposez-vous et évitez tout effort intense.';
  }

  static Color obtenirCouleurTension(int systolique, int diastolique) {
    if (systolique < 90 || diastolique < 60 || systolique >= 160 || diastolique >= 100) {
      return AppColors.danger;
    } else if (systolique >= 130 || diastolique >= 85) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  // ========== CHOLESTÉROL ==========
  
  static String obtenirConseilCholesterol(double ldl, double hdl, double ratio) {
    List<String> conseils = [];
    
    // LDL élevé
    if (ldl > ValeursReference.ldlMax) {
      conseils.add('LDL élevé: limitez les graisses saturées (viandes grasses, fromages), privilégiez les oméga-3 (poisson, noix)');
    }
    
    // HDL faible
    if (hdl < ValeursReference.hdlMin) {
      conseils.add('HDL faible: augmentez l\'activité physique (30 min/jour minimum), consommez des bonnes graisses (huile d\'olive, avocat)');
    }
    
    // Ratio élevé
    if (ratio > 5.0) {
      conseils.add('Ratio élevé: risque cardiovasculaire augmenté. Consultez un médecin pour un bilan complet');
    }
    
    // Tout va bien
    if (conseils.isEmpty) {
      return 'Excellent bilan lipidique ! Maintenez une alimentation équilibrée riche en fibres et pauvre en graisses saturées.';
    }
    
    return conseils.join('. ') + '.';
  }

  static Color obtenirCouleurCholesterol(double ldl, double hdl) {
    if (ldl > ValeursReference.ldlMax || hdl < ValeursReference.hdlMin) {
      return AppColors.danger;
    } else if (ldl > 1.3 || hdl < 0.5) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  // ========== IMC ==========
  
  static String obtenirConseilIMC(double imc, double poidsActuel, double poidsIdeal) {
    double difference = poidsActuel - poidsIdeal;
    
    // Sous-poids
    if (imc < ValeursReference.imcSousPoids) {
      return 'IMC en sous-poids (${imc.toStringAsFixed(1)}). Objectif: +${difference.abs().toStringAsFixed(1)} kg. '
          'Augmentez vos portions, ajoutez des collations nutritives (fruits secs, smoothies), consultez un nutritionniste.';
    }
    
    // Normal
    if (imc < ValeursReference.imcNormal) {
      return 'IMC normal (${imc.toStringAsFixed(1)}) - Félicitations ! '
          'Maintenez votre poids avec une alimentation équilibrée et 150 min d\'activité physique par semaine.';
    }
    
    // Surpoids
    if (imc < ValeursReference.imcSurpoids) {
      return 'IMC en surpoids (${imc.toStringAsFixed(1)}). Objectif: -${difference.toStringAsFixed(1)} kg. '
          'Réduisez les portions de 20%, privilégiez légumes et protéines maigres, marchez 30 min par jour.';
    }
    
    // Obésité
    return 'IMC en obésité (${imc.toStringAsFixed(1)}). Objectif: -${difference.toStringAsFixed(1)} kg. '
        'Consultez un médecin pour un programme personnalisé. Commencez par de petits changements durables.';
  }

  static Color obtenirCouleurIMC(double imc) {
    if (imc < ValeursReference.imcSousPoids || imc >= ValeursReference.imcSurpoids) {
      return AppColors.danger;
    } else if (imc >= 23 && imc < ValeursReference.imcNormal) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  // ========== MÉDICAMENTS ==========
  
  static String obtenirRappelMedicament(String nom, String periode) {
    Map<String, String> horaires = {
      PeriodesMedicament.matin: '8h00',
      PeriodesMedicament.midi: '12h00',
      PeriodesMedicament.soir: '20h00',
      PeriodesMedicament.nuit: '22h00',
    };
    
    String heure = horaires[periode] ?? '8h00';
    return '⏰ N\'oubliez pas de prendre $nom à $heure';
  }

  static List<String> obtenirConseilsPrise(String periode) {
    switch (periode) {
      case PeriodesMedicament.matin:
        return [
          'Prenez avec un grand verre d\'eau',
          'Avant ou après le petit-déjeuner selon prescription',
          'Évitez le café si contre-indiqué'
        ];
      case PeriodesMedicament.midi:
        return [
          'Pendant ou après le repas',
          'Ne sautez pas cette prise',
          'Espacez de 4-6h avec la prise du matin'
        ];
      case PeriodesMedicament.soir:
        return [
          'Prenez 30 min avant le dîner',
          'Évitez l\'alcool',
          'Respectez l\'intervalle avec la prise de midi'
        ];
      case PeriodesMedicament.nuit:
        return [
          'Prenez avant le coucher',
          'Peut faciliter l\'endormissement',
          'Gardez de l\'eau à portée'
        ];
      default:
        return ['Suivez la prescription de votre médecin'];
    }
  }

  // ========== RÉSUMÉ SANTÉ ==========
  
  static String genererResumeSante({
    double? derniereGlycemie,
    String? derniereTension,
    double? dernierIMC,
    int? nombreMedicaments,
  }) {
    List<String> messages = [];
    
    if (derniereGlycemie != null) {
      if (derniereGlycemie >= ValeursReference.glycemieMin && 
          derniereGlycemie <= ValeursReference.glycemieMax) {
        messages.add('✓ Glycémie normale');
      } else {
        messages.add('⚠ Glycémie à surveiller');
      }
    }
    
    if (dernierIMC != null) {
      if (dernierIMC >= ValeursReference.imcSousPoids && 
          dernierIMC < ValeursReference.imcNormal) {
        messages.add('✓ IMC normal');
      } else {
        messages.add('⚠ IMC hors norme');
      }
    }
    
    if (nombreMedicaments != null && nombreMedicaments > 0) {
      messages.add('• $nombreMedicaments médicament(s) à prendre');
    }
    
    if (messages.isEmpty) {
      return 'Ajoutez vos premières mesures pour obtenir un résumé personnalisé.';
    }
    
    return messages.join('\n');
  }

  // ========== CONSEILS GÉNÉRAUX ==========
  
  static List<String> obtenirConseilsGeneraux() {
    return [
      '💧 Buvez 1,5 à 2L d\'eau par jour',
      '🥗 5 portions de fruits et légumes quotidiens',
      '🏃‍♂️ 30 minutes d\'activité physique par jour',
      '😴 7-8 heures de sommeil par nuit',
      '🧘 Gérez votre stress (méditation, respiration)',
      '🚭 Évitez le tabac et limitez l\'alcool',
      '📊 Surveillez régulièrement vos indicateurs',
      '👨‍⚕️ Consultez votre médecin régulièrement',
    ];
  }
}