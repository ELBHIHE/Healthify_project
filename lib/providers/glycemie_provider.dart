import 'package:flutter/foundation.dart';
import '../models/glycemie.dart';
import '../services/database_helper.dart';

class GlycemieProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Glycemie> _mesures = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Glycemie> get mesures => _mesures;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Glycemie? get derniereMesure => _mesures.isNotEmpty ? _mesures.first : null;
  int get nombreMesures => _mesures.length;

  // Charger toutes les mesures d'un utilisateur
  Future<void> chargerMesures(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mesures = await _db.getGlycemiesByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des mesures';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter une nouvelle mesure
  Future<bool> ajouterMesure(Glycemie glycemie) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int id = await _db.createGlycemie(glycemie);
      
      // Créer une nouvelle instance avec l'ID
      Glycemie nouvelleMesure = glycemie.copyWith(id: id);
      
      // Ajouter au début de la liste
      _mesures.insert(0, nouvelleMesure);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout de la mesure';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Modifier une mesure
  Future<bool> modifierMesure(Glycemie glycemie) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateGlycemie(glycemie);
      
      // Mettre à jour dans la liste
      int index = _mesures.indexWhere((m) => m.id == glycemie.id);
      if (index != -1) {
        _mesures[index] = glycemie;
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
      await _db.deleteGlycemie(id);
      
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
  List<Glycemie> getMesuresParPeriode(DateTime debut, DateTime fin) {
    return _mesures.where((m) {
      return m.dateMesure.isAfter(debut) && m.dateMesure.isBefore(fin);
    }).toList();
  }

  // Obtenir les mesures par moment
  List<Glycemie> getMesuresParMoment(String moment) {
    return _mesures.where((m) => m.moment == moment).toList();
  }

  // Calculer la moyenne
  double? calculerMoyenne({DateTime? debut, DateTime? fin}) {
    List<Glycemie> mesuresFiltrees;
    
    if (debut != null && fin != null) {
      mesuresFiltrees = getMesuresParPeriode(debut, fin);
    } else {
      mesuresFiltrees = _mesures;
    }

    if (mesuresFiltrees.isEmpty) return null;
    
    double somme = mesuresFiltrees.fold(0, (sum, m) => sum + m.valeur);
    return somme / mesuresFiltrees.length;
  }

  // Obtenir les statistiques
  Map<String, dynamic> obtenirStatistiques() {
    if (_mesures.isEmpty) {
      return {
        'total': 0,
        'moyenne': 0.0,
        'min': 0.0,
        'max': 0.0,
        'normales': 0,
        'anormales': 0,
      };
    }

    List<double> valeurs = _mesures.map((m) => m.valeur).toList();
    int normales = _mesures.where((m) => m.calculerStatut() == 'Normal').length;

    return {
      'total': _mesures.length,
      'moyenne': calculerMoyenne(),
      'min': valeurs.reduce((a, b) => a < b ? a : b),
      'max': valeurs.reduce((a, b) => a > b ? a : b),
      'normales': normales,
      'anormales': _mesures.length - normales,
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