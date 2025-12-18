import 'package:flutter/foundation.dart';
import '../models/tension.dart';
import '../services/database_helper.dart';

class TensionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Tension> _mesures = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Tension> get mesures => _mesures;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Tension? get derniereMesure => _mesures.isNotEmpty ? _mesures.first : null;
  int get nombreMesures => _mesures.length;

  // Charger toutes les mesures d'un utilisateur
  Future<void> chargerMesures(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mesures = await _db.getTensionsByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des mesures';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter une nouvelle mesure
  Future<bool> ajouterMesure(Tension tension) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔵 Debut ajout tension: $tension');
      int id = await _db.createTension(tension);
      debugPrint('✅ Tension créée avec ID: $id');
      
      // Créer une nouvelle instance avec l'ID
      Tension nouvelleMesure = tension.copyWith(id: id);
      
      // Ajouter au début de la liste
      _mesures.insert(0, nouvelleMesure);
      
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Tension ajoutée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur ajout tension: $e');
      _error = 'Erreur lors de l\'ajout de la mesure: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Modifier une mesure
  Future<bool> modifierMesure(Tension tension) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateTension(tension);
      
      // Mettre à jour dans la liste
      int index = _mesures.indexWhere((m) => m.id == tension.id);
      if (index != -1) {
        _mesures[index] = tension;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la modification de la mesure';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Supprimer une mesure
  Future<bool> supprimerMesure(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteTension(id);
      
      // Retirer de la liste
      _mesures.removeWhere((m) => m.id == id);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression de la mesure';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtenir les mesures par période
  List<Tension> getMesuresParPeriode(DateTime debut, DateTime fin) {
    return _mesures.where((m) {
      return m.dateMesure.isAfter(debut) && m.dateMesure.isBefore(fin);
    }).toList();
  }

  // Calculer la moyenne systolique
  double? calculerMoyenneSystolique({DateTime? debut, DateTime? fin}) {
    List<Tension> mesuresFiltrees;
    
    if (debut != null && fin != null) {
      mesuresFiltrees = getMesuresParPeriode(debut, fin);
    } else {
      mesuresFiltrees = _mesures;
    }

    if (mesuresFiltrees.isEmpty) return null;
    
    double somme = mesuresFiltrees.fold(0, (sum, m) => sum + m.systolique);
    return somme / mesuresFiltrees.length;
  }

  // Calculer la moyenne diastolique
  double? calculerMoyenneDiastolique({DateTime? debut, DateTime? fin}) {
    List<Tension> mesuresFiltrees;
    
    if (debut != null && fin != null) {
      mesuresFiltrees = getMesuresParPeriode(debut, fin);
    } else {
      mesuresFiltrees = _mesures;
    }

    if (mesuresFiltrees.isEmpty) return null;
    
    double somme = mesuresFiltrees.fold(0, (sum, m) => sum + m.diastolique);
    return somme / mesuresFiltrees.length;
  }

  // Obtenir les statistiques
  Map<String, dynamic> obtenirStatistiques() {
    if (_mesures.isEmpty) {
      return {
        'total': 0,
        'moyenneSystolique': 0.0,
        'moyenneDiastolique': 0.0,
        'optimales': 0,
        'elevees': 0,
      };
    }

    int optimales = _mesures.where((m) => 
      m.systolique < 120 && m.diastolique < 80
    ).length;
    
    int elevees = _mesures.where((m) => 
      m.systolique >= 140 || m.diastolique >= 90
    ).length;

    return {
      'total': _mesures.length,
      'moyenneSystolique': calculerMoyenneSystolique(),
      'moyenneDiastolique': calculerMoyenneDiastolique(),
      'optimales': optimales,
      'elevees': elevees,
    };
  }

  // Réinitialiser l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser tout
  void reset() {
    _mesures = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}