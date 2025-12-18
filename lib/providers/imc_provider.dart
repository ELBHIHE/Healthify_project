import 'package:flutter/foundation.dart';
import '../models/imc.dart';
import '../services/database_helper.dart';

class IMCProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<IMC> _mesures = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<IMC> get mesures => _mesures;
  bool get isLoading => _isLoading;
  String? get error => _error;
  IMC? get derniereMesure => _mesures.isNotEmpty ? _mesures.first : null;
  int get nombreMesures => _mesures.length;

  // Charger toutes les mesures d'un utilisateur
  Future<void> chargerMesures(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mesures = await _db.getIMCsByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des mesures';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter une nouvelle mesure
  Future<bool> ajouterMesure(IMC imc) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int id = await _db.createIMC(imc);
      
      // Créer une nouvelle instance avec l'ID
      IMC nouvelleMesure = imc.copyWith(id: id);
      
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
  Future<bool> modifierMesure(IMC imc) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateIMC(imc);
      
      // Mettre à jour dans la liste
      int index = _mesures.indexWhere((m) => m.id == imc.id);
      if (index != -1) {
        _mesures[index] = imc;
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
      await _db.deleteIMC(id);
      
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
  List<IMC> getMesuresParPeriode(DateTime debut, DateTime fin) {
    return _mesures.where((m) {
      return m.dateMesure.isAfter(debut) && m.dateMesure.isBefore(fin);
    }).toList();
  }

  // Calculer la moyenne IMC
  double? calculerMoyenneIMC({DateTime? debut, DateTime? fin}) {
    List<IMC> mesuresFiltrees;
    
    if (debut != null && fin != null) {
      mesuresFiltrees = getMesuresParPeriode(debut, fin);
    } else {
      mesuresFiltrees = _mesures;
    }

    if (mesuresFiltrees.isEmpty) return null;
    
    double somme = mesuresFiltrees.fold(0, (sum, m) => sum + m.imc);
    return somme / mesuresFiltrees.length;
  }

  // Calculer la moyenne poids
  double? calculerMoyennePoids({DateTime? debut, DateTime? fin}) {
    List<IMC> mesuresFiltrees;
    
    if (debut != null && fin != null) {
      mesuresFiltrees = getMesuresParPeriode(debut, fin);
    } else {
      mesuresFiltrees = _mesures;
    }

    if (mesuresFiltrees.isEmpty) return null;
    
    double somme = mesuresFiltrees.fold(0, (sum, m) => sum + m.poids);
    return somme / mesuresFiltrees.length;
  }

  // Obtenir l'évolution du poids
  List<Map<String, dynamic>> obtenirEvolutionPoids() {
    return _mesures.reversed.map((m) => {
      'date': m.dateMesure,
      'poids': m.poids,
      'imc': m.imc,
    }).toList();
  }

  // Calculer la différence de poids avec la première mesure
  double? calculerDifferencePoids() {
    if (_mesures.length < 2) return null;
    
    double premierPoids = _mesures.last.poids;
    double dernierPoids = _mesures.first.poids;
    
    return dernierPoids - premierPoids;
  }

  // Obtenir les statistiques
  Map<String, dynamic> obtenirStatistiques() {
    if (_mesures.isEmpty) {
      return {
        'total': 0,
        'moyenneIMC': 0.0,
        'moyennePoids': 0.0,
        'minPoids': 0.0,
        'maxPoids': 0.0,
        'difference': 0.0,
        'normaux': 0,
      };
    }

    List<double> poids = _mesures.map((m) => m.poids).toList();
    int normaux = _mesures.where((m) => 
      m.imc >= 18.5 && m.imc < 25.0
    ).length;

    return {
      'total': _mesures.length,
      'moyenneIMC': calculerMoyenneIMC(),
      'moyennePoids': calculerMoyennePoids(),
      'minPoids': poids.reduce((a, b) => a < b ? a : b),
      'maxPoids': poids.reduce((a, b) => a > b ? a : b),
      'difference': calculerDifferencePoids(),
      'normaux': normaux,
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