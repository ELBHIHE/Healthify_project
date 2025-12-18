/// Exemples d'utilisation du service OpenFDA
/// 
/// Ce fichier montre comment utiliser OpenFDAService
/// dans vos propres widgets et logique métier.

import 'package:healthify/services/openfda_service.dart';

// ========== EXEMPLE 1: Recherche simple ==========
Future<void> exemplesimpleSearch() async {
  final service = OpenFDAService();
  
  try {
    final results = await service.searchDrug('Metformine');
    
    print('✅ Résultats trouvés: ${results.length}');
    
    if (results.isNotEmpty) {
      final drug = results[0];
      print('💊 Brand names: ${drug['brandNames']}');
      print('🏭 Fabricant: ${drug['manufacturer']}');
      print('📊 Voie d\'administration: ${drug['route']}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// ========== EXEMPLE 2: Détails complets ==========
Future<void> exampleDetailedSearch() async {
  final service = OpenFDAService();
  
  try {
    final details = await service.getDrugDetails('Paracétamol');
    
    if (details != null) {
      print('📋 Information du médicament:');
      print('Nom générique: ${details['genericName']}');
      print('Indications: ${details['indications']}');
      print('Dosage: ${details['dosage']}');
      print('Contre-indications: ${details['contraindications']}');
      print('Stockage: ${details['storage']}');
    } else {
      print('⚠️ Médicament non trouvé');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// ========== EXEMPLE 3: Effets secondaires ==========
Future<void> exampleAdverseEvents() async {
  final service = OpenFDAService();
  
  try {
    final events = await service.getAdverseEvents('Ibuprofen');
    
    print('⚠️ Effets secondaires rapportés: ${events.length}');
    
    // Afficher les 5 premiers
    for (var event in events.take(5)) {
      print('  • $event');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// ========== EXEMPLE 4: Alertes FDA ==========
Future<void> exampleFDAAlerts() async {
  final service = OpenFDAService();
  
  try {
    final alerts = await service.getFDAAlerts('Metformin');
    
    if (alerts.isNotEmpty) {
      print('🚨 Alertes FDA trouvées: ${alerts.length}');
      
      for (var alert in alerts) {
        print('  Raison: ${alert['raison']}');
        print('  Date: ${alert['date']}');
        print('  Status: ${alert['status']}');
      }
    } else {
      print('✅ Aucune alerte pour ce médicament');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// ========== EXEMPLE 5: Vérification d'interactions ==========
Future<void> exampleInteractionCheck() async {
  final service = OpenFDAService();
  
  try {
    final result = await service.checkInteractions('Metformin', 'Aspirin');
    
    if (result['error'] == null) {
      print('⚠️ Interaction Analysis:');
      print('Drug 1: ${result['drug1']}');
      print('Drug 2: ${result['drug2']}');
      print('Warning: ${result['warning']}');
      print('Recommendation: ${result['recommendation']}');
    } else {
      print('❌ Erreur: ${result['error']}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// ========== EXEMPLE 6: Utilisation dans un widget ==========
import 'package:flutter/material.dart';
import 'package:healthify/providers/medicament_openfda_provider.dart';
import 'package:provider/provider.dart';

class ExampleOpenFDAWidget extends StatefulWidget {
  @override
  State<ExampleOpenFDAWidget> createState() => _ExampleOpenFDAWidgetState();
}

class _ExampleOpenFDAWidgetState extends State<ExampleOpenFDAWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicamentOpenFDAProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Barre de recherche
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Chercher un médicament...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      provider.getDrugDetails(_controller.text);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Affichage du chargement
            if (provider.isLoading)
              const CircularProgressIndicator()
            
            // Affichage des erreurs
            else if (provider.error != null)
              Text('Erreur: ${provider.error}',
                  style: const TextStyle(color: Colors.red))
            
            // Affichage des résultats
            else if (provider.selectedDrugDetails != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nom générique: ${provider.selectedDrugDetails!['genericName']}'),
                  Text('Fabricant: ${provider.selectedDrugDetails!['manufacturer']}'),
                  const SizedBox(height: 16),
                  Text('Effets secondaires: ${provider.adverseEvents.length}'),
                  ...provider.adverseEvents.take(5).map(
                        (event) => Chip(label: Text(event)),
                      ),
                  const SizedBox(height: 16),
                  if (provider.fdaAlerts.isNotEmpty)
                    Text('⚠️ Alertes FDA: ${provider.fdaAlerts.length}'),
                ],
              )
            
            // État vide
            else
              const Text('Cherchez un médicament pour commencer'),
          ],
        );
      },
    );
  }
}

// ========== NOTES IMPORTANTES ==========
/*
1. TIMEOUT: Tous les appels API ont un timeout de 10 secondes
   pour éviter que l'app ne se freeze.

2. ERREURS COURANTES:
   - "Aucun résultat": Le médicament n'existe pas dans la base FDA
     → Essayez le nom générique (ex: "Metformin" au lieu de marque)
   - "Timeout": Connexion Internet lente
     → Réessayez après quelques secondes
   - "Erreur API": Serveur OpenFDA indisponible
     → Réessayez plus tard

3. PERFORMANCE:
   - Pas de caching automatique (à implémenter si besoin)
   - Chaque recherche fait un appel HTTP
   - Utilisez les providers pour éviter les rebuilds inutiles

4. DONNÉES:
   - Toutes les données viennent de FDA.gov
   - Les informations sont à jour quotidiennement
   - Les interactions sont basiques (voir un pharmacien)

5. CONFIDENTIALITÉ:
   - Les recherches ne sont pas tracées
   - Aucun données personnelle envoyée à OpenFDA
   - API publique et gratuite
*/

// ========== CAS D'USAGE AVANCÉS ==========

// Cas 1: Chercher un médicament et afficher les contrindications
Future<void> advancedUseCase1() async {
  final service = OpenFDAService();
  final drugName = 'Metformin';
  
  try {
    final details = await service.getDrugDetails(drugName);
    
    if (details != null && details['contraindications'] != null) {
      final contraindications = details['contraindications'] as List<String>;
      
      print('⛔ CONTRE-INDICATIONS pour $drugName:');
      for (var contra in contraindications) {
        print('  ❌ $contra');
      }
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

// Cas 2: Afficher uniquement les alertes critiques
Future<void> advancedUseCase2() async {
  final service = OpenFDAService();
  
  try {
    final alerts = await service.getFDAAlerts('SomeDrug');
    
    // Filtrer les alertes critiques (exemple: retraits complèts)
    final criticalAlerts = alerts.where((alert) {
      final status = alert['status'] as String?;
      return status?.toLowerCase().contains('completed') ?? false;
    }).toList();
    
    if (criticalAlerts.isNotEmpty) {
      print('🚨 ALERTES CRITIQUES: ${criticalAlerts.length}');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

// Cas 3: Analyser les effets secondaires les plus courants
Future<void> advancedUseCase3() async {
  final service = OpenFDAService();
  final events = await service.getAdverseEvents('Aspirin');
  
  // Prendre les 10 premières (les plus rapportées)
  final topEffects = events.take(10).toList();
  
  print('🔥 EFFETS LES PLUS RAPPORTÉS:');
  for (var i = 0; i < topEffects.length; i++) {
    print('  ${i + 1}. ${topEffects[i]}');
  }
}
