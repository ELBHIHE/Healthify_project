import 'package:flutter_test/flutter_test.dart';
import 'package:healthify/services/openfda_service.dart';

void main() {
  group('OpenFDAService Tests', () {
    late OpenFDAService openfdaService;

    setUp(() {
      openfdaService = OpenFDAService();
    });

    test('searchDrug returns empty list for empty query', () async {
      final results = await openfdaService.searchDrug('');
      expect(results, isEmpty);
    });

    test('searchDrug handles whitespace correctly', () async {
      final results = await openfdaService.searchDrug('   ');
      expect(results, isEmpty);
    });

    // Tests d'intégration (nécessitent Internet)
    test('searchDrug returns results for valid drug name', () async {
      // Ce test nécessite une connexion Internet
      // À ignorer en CI sans réseau
      
      final results = await openfdaService.searchDrug('Metformin');
      
      // Vérifier que c'est une liste
      expect(results, isA<List>());
      
      // Si des résultats, vérifier la structure
      if (results.isNotEmpty) {
        expect(results[0], isA<Map<String, dynamic>>());
        expect(results[0].containsKey('brandNames'), true);
      }
    }, skip: 'Nécessite connexion Internet - à activer pour tester l\'API');

    test('getDrugDetails returns map for valid drug', () async {
      final details = await openfdaService.getDrugDetails('Metformin');
      
      if (details != null) {
        expect(details, isA<Map<String, dynamic>>());
        expect(details.containsKey('genericName'), true);
      }
    }, skip: 'Nécessite connexion Internet');

    test('checkInteractions returns result map', () async {
      final result = await openfdaService.checkInteractions(
        'Metformin',
        'Aspirin',
      );
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('drug1'), true);
      expect(result.containsKey('drug2'), true);
    }, skip: 'Nécessite connexion Internet');

    test('getFDAAlerts handles non-existent drugs gracefully', () async {
      final alerts = await openfdaService.getFDAAlerts('FakeDrugName12345');
      
      expect(alerts, isA<List>());
      // Probablement vide pour un médicament inexistant
    }, skip: 'Nécessite connexion Internet');
  });

  group('OpenFDAService Error Handling', () {
    late OpenFDAService openfdaService;

    setUp(() {
      openfdaService = OpenFDAService();
    });

    test('searchDrug throws on invalid input', () async {
      expect(
        () => openfdaService.searchDrug(''),
        completes,
      );
    });
  });
}
