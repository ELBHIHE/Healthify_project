import 'package:flutter/foundation.dart';
import '../services/openfda_service.dart';

class MedicamentOpenFDAProvider with ChangeNotifier {
  final OpenFDAService _service = OpenFDAService();

  // État de recherche
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedDrugDetails;
  List<String> _adverseEvents = [];
  List<Map<String, dynamic>> _fdaAlerts = [];
  bool _isLoading = false;
  String? _error;
  String? _lastSearchedDrug;

  // Interactions
  Map<String, dynamic>? _interactionResult;

  // Getters
  List<Map<String, dynamic>> get searchResults => _searchResults;
  Map<String, dynamic>? get selectedDrugDetails => _selectedDrugDetails;
  List<String> get adverseEvents => _adverseEvents;
  List<Map<String, dynamic>> get fdaAlerts => _fdaAlerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastSearchedDrug => _lastSearchedDrug;
  Map<String, dynamic>? get interactionResult => _interactionResult;

  // ========== RECHERCHE MÉDICAMENT ==========
  Future<void> searchDrug(String drugName) async {
    _isLoading = true;
    _error = null;
    _searchResults = [];
    _selectedDrugDetails = null;
    _adverseEvents = [];
    _fdaAlerts = [];
    notifyListeners();

    try {
      debugPrint('🔍 Recherche: $drugName');
      final results = await _service.searchDrug(drugName);
      
      _searchResults = results;
      _lastSearchedDrug = drugName;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== OBTENIR DÉTAILS COMPLETS ==========
  Future<void> getDrugDetails(String drugName) async {
    _isLoading = true;
    _error = null;
    _adverseEvents = [];
    _fdaAlerts = [];
    notifyListeners();

    try {
      debugPrint('📋 Détails: $drugName');
      
      // Récupérer les détails
      final details = await _service.getDrugDetails(drugName);
      _selectedDrugDetails = details;

      // Récupérer les effets secondaires
      final events = await _service.getAdverseEvents(drugName);
      _adverseEvents = events;

      // Récupérer les alertes FDA
      final alerts = await _service.getFDAAlerts(drugName);
      _fdaAlerts = alerts;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== VÉRIFIER INTERACTIONS ==========
  Future<void> checkInteractions(String drug1, String drug2) async {
    _isLoading = true;
    _error = null;
    _interactionResult = null;
    notifyListeners();

    try {
      debugPrint('⚠️ Vérification interactions: $drug1 + $drug2');
      final result = await _service.checkInteractions(drug1, drug2);
      
      _interactionResult = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== RÉINITIALISER ==========
  void reset() {
    _searchResults = [];
    _selectedDrugDetails = null;
    _adverseEvents = [];
    _fdaAlerts = [];
    _isLoading = false;
    _error = null;
    _lastSearchedDrug = null;
    _interactionResult = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
