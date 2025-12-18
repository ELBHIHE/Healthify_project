import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/medicament_openfda_provider.dart';
import '../services/openfda_service.dart';

class OpenFDADetailsWidget extends StatelessWidget {
  final String drugName;

  const OpenFDADetailsWidget({
    Key? key,
    required this.drugName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicamentOpenFDAProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Erreur: ${provider.error}',
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final details = provider.selectedDrugDetails;
        if (details == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucune information trouvée'),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === INFOS BASIQUES ===
                _buildSectionTitle('📋 Informations Générales'),
                _buildInfoRow('Nom générique', 
                    OpenFDATranslator.translate(details['genericName'] ?? 'Non disponible')),
                _buildInfoRow('Fabricant', 
                    OpenFDATranslator.translate(details['manufacturer'] ?? 'Non disponible')),
                if ((details['route'] as List?)?.isNotEmpty ?? false)
                  _buildInfoRow('Voie d\'administration',
                      OpenFDATranslator.translateList(details['route'] as List<String>).join(', ')),
                if ((details['dosageForm'] as List?)?.isNotEmpty ?? false)
                  _buildInfoRow('Forme galénique',
                      OpenFDATranslator.translateList(details['dosageForm'] as List<String>).join(', ')),
                const SizedBox(height: 16),

                // === COMPOSITION ===
                if ((details['activeIngredients'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('💊 Composition'),
                      ...(details['activeIngredients'] as List).map<Widget>(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• ${OpenFDATranslator.translate(ingredient.toString())}',
                              style: const TextStyle(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === INDICATIONS ===
                if ((details['indications'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('🎯 Indications'),
                      Text(
                        OpenFDATranslator.translateList(details['indications'] as List<String>).join('\n'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === DOSAGE ===
                if ((details['dosage'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('📌 Dosage et Administration'),
                      Text(
                        OpenFDATranslator.translateList(details['dosage'] as List<String>).join('\n'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === CONTRE-INDICATIONS ===
                if ((details['contraindications'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('⛔ Contre-indications'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          OpenFDATranslator.translateList(details['contraindications'] as List<String>).join('\n'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === AVERTISSEMENTS ===
                if ((details['warnings'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('🚨 Avertissements'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          OpenFDATranslator.translateList(details['warnings'] as List<String>).join('\n'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === EFFETS SECONDAIRES ===
                if (provider.adverseEvents.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('⚠️ Effets Secondaires Rapportés'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.adverseEvents
                              .take(10)
                              .map(
                                (event) => Chip(
                                  label: Text(
                                    OpenFDATranslator.translate(event),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor:
                                      Colors.yellow.withOpacity(0.3),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      if (provider.adverseEvents.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '...et ${provider.adverseEvents.length - 10} autres effets',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === ALERTES FDA ===
                if (provider.fdaAlerts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('🚨 Alertes et Retraits FDA'),
                      ...provider.fdaAlerts
                          .map(
                            (alert) => Card(
                              color: AppColors.danger.withOpacity(0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      OpenFDATranslator.translate(alert['raison'] ?? 'Alerte'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${alert['date'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (alert['status'] != null)
                                      Text(
                                        'Statut: ${OpenFDATranslator.translate(alert['status'])}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === STOCKAGE ===
                if ((details['storage'] as List?)?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('🏠 Stockage et Conservation'),
                      Text(
                        OpenFDATranslator.translateList(details['storage'] as List<String>).join('\n'),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // === CREDIT ===
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Données provenant de l\'API OpenFDA (Food and Drug Administration USA)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
