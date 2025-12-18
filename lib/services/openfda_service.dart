import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class OpenFDAService {
  static const String _baseUrl = 'https://api.fda.gov/drug';
  static const Duration _timeout = Duration(seconds: 10);

  // ========== RECHERCHE MÉDICAMENT ==========
  /// Recherche un médicament par nom
  /// Retourne liste de médicaments avec infos de base
  Future<List<Map<String, dynamic>>> searchDrug(String drugName) async {
    try {
      if (drugName.trim().isEmpty) return [];

      // Nettoyer le nom
      final cleanName = drugName.trim().toLowerCase();
      
      // Chercher dans les noms propriétaires (brand names)
      final query = 'openfda.brand_name:$cleanName';
      final url = Uri.parse(
        '$_baseUrl/label.json?search=$query&limit=10',
      );

      debugPrint('🔍 OpenFDA search: $drugName');
      
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          debugPrint('⚠️ Aucun résultat trouvé pour: $drugName');
          return [];
        }

        return results
            .map((result) => _parseDrugInfo(result))
            .toList();
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ Médicament non trouvé: $drugName');
        return [];
      } else {
        throw 'Erreur API OpenFDA: ${response.statusCode}';
      }
    } on TimeoutException {
      throw 'Timeout: impossible de se connecter à OpenFDA';
    } catch (e) {
      throw 'Erreur recherche médicament: $e';
    }
  }

  // ========== OBTENIR EFFETS SECONDAIRES ==========
  /// Récupère les effets secondaires d'un médicament
  Future<List<String>> getAdverseEvents(String drugName) async {
    try {
      final cleanName = drugName.trim().toLowerCase();
      
      // Chercher les événements indésirables
      final query = 'patient.drug.openfda.brand_name:$cleanName';
      final url = Uri.parse(
        '$_baseUrl/event.json?search=$query&limit=1',
      );

      debugPrint('🔴 Recherche effets secondaires: $drugName');
      
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return [];
        }

        Set<String> adverseEvents = {};
        for (var event in results) {
          final reactions = event['patient']['reaction'] as List?;
          if (reactions != null) {
            for (var reaction in reactions) {
              final reactionTerm = reaction['reactionmeddrapt'];
              if (reactionTerm != null) {
                adverseEvents.add(reactionTerm.toString());
              }
            }
          }
        }

        debugPrint('✅ ${adverseEvents.length} effets secondaires trouvés');
        return adverseEvents.toList();
      }

      return [];
    } catch (e) {
      debugPrint('⚠️ Erreur récupération effets: $e');
      return [];
    }
  }

  // ========== OBTENIR DÉTAILS COMPLETS ==========
  /// Récupère les détails complets d'un médicament
  Future<Map<String, dynamic>?> getDrugDetails(String drugName) async {
    try {
      final cleanName = drugName.trim().toLowerCase();
      final query = 'openfda.brand_name:$cleanName';
      final url = Uri.parse(
        '$_baseUrl/label.json?search=$query&limit=1',
      );

      debugPrint('📋 Détails médicament: $drugName');
      
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return null;
        }

        return _parseDetailedDrugInfo(results[0]);
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Erreur détails: $e');
      return null;
    }
  }

  // ========== INTERACTIONS MÉDICAMENTEUSES ==========
  /// Vérifie les interactions potentielles entre deux médicaments
  Future<Map<String, dynamic>> checkInteractions(
    String drug1,
    String drug2,
  ) async {
    try {
      // Pour une vraie vérification, il faudrait une BD d'interactions
      // OpenFDA n'a pas d'endpoint direct pour ça
      // On peut chercher les deux drugs et analyser leurs infos
      
      final details1 = await getDrugDetails(drug1);
      final details2 = await getDrugDetails(drug2);

      return {
        'drug1': drug1,
        'drug2': drug2,
        'hasInfo1': details1 != null,
        'hasInfo2': details2 != null,
        'warning': _generateInteractionWarning(drug1, drug2),
        'recommendation': 'Consultez un pharmacien pour vérifier les interactions entre ces médicaments.',
      };
    } catch (e) {
      debugPrint('⚠️ Erreur vérification interactions: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  // ========== ALERTES FDA ==========
  /// Récupère les alertes et retraits du marché pour un médicament
  Future<List<Map<String, dynamic>>> getFDAAlerts(String drugName) async {
    try {
      final cleanName = drugName.trim().toLowerCase();
      
      // Chercher les retraits du marché (enforcement)
      final query = 'openfda.brand_name:$cleanName';
      final url = Uri.parse(
        '$_baseUrl/enforcement.json?search=$query&limit=5',
      );

      debugPrint('🚨 Recherche alertes FDA: $drugName');
      
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .map((alert) => {
              'raison': alert['reason_for_recall'] ?? 'Non spécifiée',
              'date': alert['recall_initiation_date'] ?? 'Inconnue',
              'status': alert['recall_status'] ?? 'Unknown',
              'description': alert['product_description'] ?? '',
            })
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('⚠️ Erreur alertes FDA: $e');
      return [];
    }
  }

  // ========== HELPER FUNCTIONS ==========

  /// Parse les infos basiques d'un médicament
  Map<String, dynamic> _parseDrugInfo(dynamic result) {
    final openfda = result['openfda'] as Map<String, dynamic>? ?? {};
    
    return {
      'brandNames': _getList(openfda['brand_name']),
      'genericName': _getString(openfda['generic_name']),
      'manufacturer': _getString(openfda['manufacturer_name']),
      'route': _getList(openfda['route']),
      'activeIngredients': _getList(openfda['substance_name']),
    };
  }

  /// Parse les infos détaillées
  Map<String, dynamic> _parseDetailedDrugInfo(dynamic result) {
    final openfda = result['openfda'] as Map<String, dynamic>? ?? {};
    
    return {
      'brandNames': _getList(openfda['brand_name']),
      'genericName': _getString(openfda['generic_name']),
      'manufacturer': _getString(openfda['manufacturer_name']),
      'route': _getList(openfda['route']),
      'dosageForm': _getList(openfda['dosage_form']),
      'activeIngredients': _getList(openfda['substance_name']),
      'ndc': _getList(openfda['ndc']),
      'purpose': _getList(result['purpose']),
      'indications': _getList(result['indications_and_usage']),
      'contraindications': _getList(result['contraindications']),
      'warnings': _getList(result['warnings']),
      'adverseReactions': _getList(result['adverse_reactions']),
      'dosage': _getList(result['dosage_and_administration']),
      'storage': _getList(result['storage_and_handling']),
    };
  }

  /// Génère un avertissement d'interaction générique
  String _generateInteractionWarning(String drug1, String drug2) {
    // Cette logique pourrait être enrichie avec une vraie BD d'interactions
    return '⚠️ Interaction potentielle: $drug1 + $drug2';
  }

  /// Récupère un string d'une liste ou d'une valeur unique
  String _getString(dynamic value) {
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value[0].toString();
    return '';
  }

  /// Récupère une liste de strings
  List<String> _getList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .toList();
    }
    if (value is String) return [value];
    return [];
  }
}

// ========== TRADUCTEUR FRANÇAIS ==========
class OpenFDATranslator {
  static const Map<String, String> _translations = {
    // Noms de sections
    'Indications': 'Indications & Utilisation',
    'Indications and Usage': 'Indications & Utilisation',
    'Contraindications': 'Contre-indications',
    'Warnings': 'Avertissements',
    'Dosage and Administration': 'Dosage & Administration',
    'Adverse Reactions': 'Effets Secondaires',
    'Storage and Handling': 'Stockage & Conservation',
    'Purpose': 'Objectif',
    'Active Ingredients': 'Ingrédients Actifs',
    'Brand Names': 'Noms Commerciaux',
    'Generic Name': 'Nom Générique',
    'Manufacturer': 'Fabricant',
    'Route': 'Voie d\'Administration',
    'Dosage Form': 'Forme Galénique',
    'NDC': 'Code NDC',
    
    // Voies d'administration
    'Oral': 'Par voie orale',
    'Intravenous': 'Par voie intraveineuse',
    'Intramuscular': 'Par voie intramusculaire',
    'Subcutaneous': 'Par voie sous-cutanée',
    'Transdermal': 'Par voie transdermique',
    'Topical': 'Application topique',
    'Inhaled': 'Par inhalation',
    'Rectal': 'Par voie rectale',
    
    // Formes galéniques
    'Tablet': 'Comprimé',
    'Capsule': 'Gélule',
    'Liquid': 'Liquide',
    'Injection': 'Injection',
    'Cream': 'Crème',
    'Ointment': 'Pommade',
    'Solution': 'Solution',
    'Suspension': 'Suspension',
    'Powder': 'Poudre',
    'Patch': 'Patch',
    
    // Effets secondaires courants
    'Nausea': 'Nausée',
    'Vomiting': 'Vomissement',
    'Diarrhea': 'Diarrhée',
    'Constipation': 'Constipation',
    'Headache': 'Mal de tête',
    'Dizziness': 'Vertiges',
    'Rash': 'Éruption cutanée',
    'Itching': 'Démangeaisons',
    'Fatigue': 'Fatigue',
    'Weakness': 'Faiblesse',
    'Insomnia': 'Insomnie',
    'Anxiety': 'Anxiété',
    'Tremor': 'Tremblement',
    'Fever': 'Fièvre',
    'Chills': 'Frissons',
    'Muscle Pain': 'Douleur musculaire',
    'Joint Pain': 'Douleur articulaire',
    'Abdominal Pain': 'Douleur abdominale',
    'Back Pain': 'Mal de dos',
    'Chest Pain': 'Douleur thoracique',
    'Shortness of Breath': 'Essoufflement',
    'Cough': 'Toux',
    'Sore Throat': 'Mal de gorge',
    'Runny Nose': 'Nez qui coule',
    'Dry Mouth': 'Sécheresse buccale',
    'Loss of Appetite': 'Perte d\'appétit',
    'Weight Loss': 'Perte de poids',
    'Weight Gain': 'Gain de poids',
    'Increased Thirst': 'Soif accrue',
    'Frequent Urination': 'Miction fréquente',
    'Blurred Vision': 'Vision floue',
    'Eye Pain': 'Douleur oculaire',
    'Hearing Loss': 'Perte auditive',
    'Tinnitus': 'Acouphènes',
    'Loss of Consciousness': 'Perte de conscience',
    'Seizures': 'Convulsions',
    'Hallucinations': 'Hallucinations',
    'Confusion': 'Confusion',
    'Depression': 'Dépression',
    'Mood Changes': 'Changements d\'humeur',
    'Allergic Reaction': 'Réaction allergique',
    'Anaphylaxis': 'Anaphylaxie',
    'Severe Rash': 'Éruption cutanée grave',
    'Stevens-Johnson Syndrome': 'Syndrome de Stevens-Johnson',
    'Liver Damage': 'Dommages hépatiques',
    'Kidney Damage': 'Dommages rénaux',
    'Heart Problems': 'Problèmes cardiaques',
    'High Blood Pressure': 'Hypertension',
    'Low Blood Pressure': 'Hypotension',
    'Irregular Heartbeat': 'Battement cardiaque irrégulier',
    'Blood Clots': 'Caillots sanguins',
    'Bleeding': 'Saignement',
    'Bruising': 'Ecchymoses',
    'Swelling': 'Gonflement',
    'Hives': 'Urticaire',
    'Hair Loss': 'Chute de cheveux',
    'Nail Problems': 'Problèmes d\'ongles',
    'Skin Discoloration': 'Décoloration de la peau',
    'Yellowing of Skin': 'Jaunissement de la peau',
    'Yellowing of Eyes': 'Jaunissement des yeux',
    
    // Statuts
    'Completed': 'Terminé',
    'Ongoing': 'En cours',
    'Terminated': 'Arrêté',
    'Pending': 'En attente',
    
    // Autres
    'Unknown': 'Inconnu',
    'Not Available': 'Non disponible',
    'See Full Label': 'Voir notice complète',
  };

  /// Traduit un texte de l'anglais au français
  static String translate(String text) {
    if (text.isEmpty) return text;
    
    // Chercher la traduction exacte
    if (_translations.containsKey(text)) {
      return _translations[text]!;
    }
    
    // Chercher une traduction partielle (pour les variations)
    for (var key in _translations.keys) {
      if (text.toLowerCase().contains(key.toLowerCase())) {
        return text.replaceAll(
          RegExp(key, caseSensitive: false),
          _translations[key]!,
        );
      }
    }
    
    return text; // Retourner le texte original si pas de traduction
  }

  /// Traduit une liste de textes
  static List<String> translateList(List<String> items) {
    return items.map((item) => translate(item)).toList();
  }

  /// Traduit un dictionnaire de clés/valeurs
  static Map<String, dynamic> translateMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      final translatedKey = translate(key);
      
      if (value is String) {
        return MapEntry(translatedKey, translate(value));
      } else if (value is List) {
        return MapEntry(
          translatedKey,
          value.map((item) => item is String ? translate(item) : item).toList(),
        );
      } else {
        return MapEntry(translatedKey, value);
      }
    });
  }
}

