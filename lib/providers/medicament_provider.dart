import 'package:flutter/foundation.dart';
import '../models/medicament.dart';
import '../services/database_helper.dart';

class MedicamentProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Medicament> _medicaments = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Medicament> get medicaments => _medicaments;
  List<Medicament> get medicamentsActifs => 
      _medicaments.where((m) => m.estActif).toList();
  List<Medicament> get medicamentsInactifs => 
      _medicaments.where((m) => !m.estActif).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get nombreMedicaments => _medicaments.length;
  int get nombreMedicamentsActifs => medicamentsActifs.length;

  // Charger tous les médicaments d'un utilisateur
  Future<void> chargerMedicaments(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicaments = await _db.getMedicamentsByUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des médicaments';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger uniquement les médicaments actifs
  Future<void> chargerMedicamentsActifs(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicaments = await _db.getActiveMedicaments(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des médicaments actifs';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un nouveau médicament
  Future<bool> ajouterMedicament(Medicament medicament) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int id = await _db.createMedicament(medicament);
      
      // Créer une nouvelle instance avec l'ID
      Medicament nouveauMedicament = medicament.copyWith(id: id);
      
      // Ajouter au début de la liste
      _medicaments.insert(0, nouveauMedicament);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du médicament';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Modifier un médicament
  Future<bool> modifierMedicament(Medicament medicament) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.updateMedicament(medicament);
      
      // Mettre à jour dans la liste
      int index = _medicaments.indexWhere((m) => m.id == medicament.id);
      if (index != -1) {
        _medicaments[index] = medicament;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la modification du médicament';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Supprimer un médicament
  Future<bool> supprimerMedicament(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.deleteMedicament(id);
      
      // Retirer de la liste
      _medicaments.removeWhere((m) => m.id == id);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression du médicament';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle l'état actif/inactif d'un médicament
  Future<bool> toggleActif(int id) async {
    try {
      // Trouver le médicament
      int index = _medicaments.indexWhere((m) => m.id == id);
      if (index == -1) return false;

      // Inverser l'état
      Medicament medicamentModifie = _medicaments[index].toggleActif();
      
      // Mettre à jour en base
      return await modifierMedicament(medicamentModifie);
    } catch (e) {
      _error = 'Erreur lors du changement d\'état';
      notifyListeners();
      return false;
    }
  }

  // Obtenir les médicaments par période
  List<Medicament> getMedicamentsParPeriode(String periode) {
    return _medicaments.where((m) => m.periode == periode).toList();
  }

  // Obtenir les rappels du jour
  List<Map<String, dynamic>> obtenirRappelsDuJour() {
    List<Map<String, dynamic>> rappels = [];
    
    for (var medicament in medicamentsActifs) {
      rappels.add({
        'medicament': medicament,
        'rappel': medicament.obtenirRappel(),
        'periode': medicament.periode,
      });
    }
    
    // Trier par période (Matin → Midi → Soir → Nuit)
    List<String> ordre = ['Matin', 'Midi', 'Soir', 'Nuit'];
    rappels.sort((a, b) => 
      ordre.indexOf(a['periode']).compareTo(ordre.indexOf(b['periode']))
    );
    
    return rappels;
  }

  // Obtenir les statistiques
  Map<String, dynamic> obtenirStatistiques() {
    Map<String, int> parPeriode = {
      'Matin': 0,
      'Midi': 0,
      'Soir': 0,
      'Nuit': 0,
    };

    for (var medicament in medicamentsActifs) {
      parPeriode[medicament.periode] = (parPeriode[medicament.periode] ?? 0) + 1;
    }

    return {
      'total': _medicaments.length,
      'actifs': nombreMedicamentsActifs,
      'inactifs': medicamentsInactifs.length,
      'parPeriode': parPeriode,
    };
  }

  // Vérifier si un médicament existe déjà
  bool medicamentExiste(String nom) {
    return _medicaments.any((m) => 
      m.nom.toLowerCase() == nom.toLowerCase()
    );
  }

  // Rechercher des médicaments
  List<Medicament> rechercherMedicaments(String query) {
    String queryLower = query.toLowerCase();
    return _medicaments.where((m) => 
      m.nom.toLowerCase().contains(queryLower)
    ).toList();
  }

  // Réinitialiser l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser tout
  void reset() {
    _medicaments = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}