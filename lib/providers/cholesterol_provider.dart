import 'package:flutter/foundation.dart';
import '../models/cholesterol.dart';
import '../services/database_helper.dart';

class CholesterolProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Cholesterol> _bilans = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Cholesterol> get bilans => _bilans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Cholesterol? get dernierBilan => _bilans.isNotEmpty ? _bilans.first : null;
  int get nombreBilans => _bilans.length;

  // Charger tous les bilans d'un utilisateur
  Future<void> chargerBilans(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bilans = await _db.getCholesterolsByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des bilans';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un nouveau bilan
  Future<bool> ajouterBilan(Cholesterol cholesterol) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int id = await _db.createCholesterol(cholesterol);
      
      // Créer une nouvelle instance avec l'ID
      Cholesterol nouveauBilan = cholesterol.copyWith(id: id);
      
      // Ajouter au début de la liste
      _bilans.insert(0, nouveauBilan);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du bilan';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Modifier un bilan
  Future<bool> modifierBilan(Cholesterol cholesterol) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateCholesterol(cholesterol);
      
      // Mettre à jour dans la liste
      int index = _bilans.indexWhere((b) => b.id == cholesterol.id);
      if (index != -1) {
        _bilans[index] = cholesterol;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la modification du bilan';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Supprimer un bilan
  Future<bool> supprimerBilan(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteCholesterol(id);
      
      // Retirer de la liste
      _bilans.removeWhere((b) => b.id == id);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression du bilan';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtenir les bilans par période
  List<Cholesterol> getBilansParPeriode(DateTime debut, DateTime fin) {
    return _bilans.where((b) {
      return b.dateBilan.isAfter(debut) && b.dateBilan.isBefore(fin);
    }).toList();
  }

  // Calculer la moyenne du cholestérol total
  double? calculerMoyenneTotal({DateTime? debut, DateTime? fin}) {
    List<Cholesterol> bilansFiltres;
    
    if (debut != null && fin != null) {
      bilansFiltres = getBilansParPeriode(debut, fin);
    } else {
      bilansFiltres = _bilans;
    }

    if (bilansFiltres.isEmpty) return null;
    
    double somme = bilansFiltres.fold(0, (sum, b) => sum + b.total);
    return somme / bilansFiltres.length;
  }

  // Calculer la moyenne HDL
  double? calculerMoyenneHDL({DateTime? debut, DateTime? fin}) {
    List<Cholesterol> bilansFiltres;
    
    if (debut != null && fin != null) {
      bilansFiltres = getBilansParPeriode(debut, fin);
    } else {
      bilansFiltres = _bilans;
    }

    if (bilansFiltres.isEmpty) return null;
    
    double somme = bilansFiltres.fold(0, (sum, b) => sum + b.hdl);
    return somme / bilansFiltres.length;
  }

  // Calculer la moyenne LDL
  double? calculerMoyenneLDL({DateTime? debut, DateTime? fin}) {
    List<Cholesterol> bilansFiltres;
    
    if (debut != null && fin != null) {
      bilansFiltres = getBilansParPeriode(debut, fin);
    } else {
      bilansFiltres = _bilans;
    }

    if (bilansFiltres.isEmpty) return null;
    
    double somme = bilansFiltres.fold(0, (sum, b) => sum + b.ldl);
    return somme / bilansFiltres.length;
  }

  // Obtenir les statistiques
  Map<String, dynamic> obtenirStatistiques() {
    if (_bilans.isEmpty) {
      return {
        'total': 0,
        'moyenneTotal': 0.0,
        'moyenneHDL': 0.0,
        'moyenneLDL': 0.0,
        'bons': 0,
        'risques': 0,
      };
    }

    int bons = _bilans.where((b) => 
      b.interpreterResultat() == 'Bon' || b.interpreterResultat() == 'Excellent'
    ).length;
    
    int risques = _bilans.where((b) => 
      b.interpreterResultat().contains('Risque')
    ).length;

    return {
      'total': _bilans.length,
      'moyenneTotal': calculerMoyenneTotal(),
      'moyenneHDL': calculerMoyenneHDL(),
      'moyenneLDL': calculerMoyenneLDL(),
      'bons': bons,
      'risques': risques,
    };
  }

  // Réinitialiser l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser tout
  void reset() {
    _bilans = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}