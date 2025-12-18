import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/openfda_details_widget.dart';
import '../../utils/constants.dart';
import '../../models/medicament.dart';
import '../../providers/medicament_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicament_openfda_provider.dart';

class MedicamentScreen extends StatefulWidget {
  const MedicamentScreen({Key? key}) : super(key: key);

  @override
  State<MedicamentScreen> createState() => _MedicamentScreenState();
}

class _MedicamentScreenState extends State<MedicamentScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _searchController = TextEditingController();
  String _periodeSelectionnee = PeriodesMedicament.matin;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Charger les médicaments au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId != null) {
        context.read<MedicamentProvider>().chargerMedicaments(userId);
      }
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _ajouterMedicament() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Obtenir l'ID utilisateur
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non connecté'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Créer l'objet Medicament
      final medicament = Medicament(
        userId: userId,
        nom: _nomController.text,
        periode: _periodeSelectionnee,
        estActif: true,
      );
      
      // Ajouter via le provider
      final medicamentProvider = context.read<MedicamentProvider>();
      final success = await medicamentProvider.ajouterMedicament(medicament);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_nomController.text} ajouté avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
          _nomController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(medicamentProvider.error ?? 'Erreur lors de l\'enregistrement'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String _obtenirRappel(String nom, String periode) {
    String moment = '';
    switch (periode) {
      case PeriodesMedicament.matin:
        moment = '8h00';
        break;
      case PeriodesMedicament.midi:
        moment = '12h00';
        break;
      case PeriodesMedicament.soir:
        moment = '20h00';
        break;
      case PeriodesMedicament.nuit:
        moment = '22h00';
        break;
    }
    return 'Prendre $nom à $moment';
  }

  IconData _obtenirIconePeriode(String periode) {
    switch (periode) {
      case PeriodesMedicament.matin:
        return Icons.wb_sunny;
      case PeriodesMedicament.midi:
        return Icons.wb_sunny_outlined;
      case PeriodesMedicament.soir:
        return Icons.nightlight;
      case PeriodesMedicament.nuit:
        return Icons.bedtime;
      default:
        return Icons.medication;
    }
  }

  Color _obtenirCouleurPeriode(String periode) {
    switch (periode) {
      case PeriodesMedicament.matin:
        return Colors.orange;
      case PeriodesMedicament.midi:
        return Colors.amber;
      case PeriodesMedicament.soir:
        return Colors.indigo;
      case PeriodesMedicament.nuit:
        return Colors.deepPurple;
      default:
        return AppColors.primary;
    }
  }

  void _supprimerMedicament(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer'),
          content: const Text('Voulez-vous vraiment supprimer ce médicament ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final medicamentProvider = context.read<MedicamentProvider>();
                await medicamentProvider.supprimerMedicament(id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Médicament supprimé'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _toggleActif(int id) async {
    final medicamentProvider = context.read<MedicamentProvider>();
    await medicamentProvider.toggleActif(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médicaments'),
        bottom: TabBar(
          controller: _tabController,
          // Explicit colors to ensure labels remain visible on all themes
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: 'Mes médicaments',
            ),
            Tab(
              icon: const Icon(Icons.medical_information),
              text: 'Recherche OpenFDA 🔍',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: Gestion des médicaments
          _buildMedicamentsTab(),
          // Onglet 2: Recherche OpenFDA
          _buildOpenFDATab(),
        ],
      ),
    );
  }

  // ========== ONGLET 1: MES MÉDICAMENTS ==========
  Widget _buildMedicamentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication, 
                      color: Colors.white, 
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion des médicaments',
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Consumer<MedicamentProvider>(
                          builder: (context, provider, _) {
                            return Text(
                              '${provider.medicaments.length} médicament(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Ajouter un médicament',
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Nom du médicament
            CustomTextField(
              controller: _nomController,
              label: 'Nom du médicament',
              hint: 'Ex: Metformine, Aspirine...',
              prefixIcon: Icons.medication_liquid,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom du médicament';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Période de prise
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Période de prise',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _periodeSelectionnee,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: PeriodesMedicament.getAll()
                          .map((String periode) => DropdownMenuItem(
                                value: periode,
                                child: Row(
                                  children: [
                                    Icon(
                                      _obtenirIconePeriode(periode),
                                      color: _obtenirCouleurPeriode(periode),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(periode),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _periodeSelectionnee = newValue);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Bouton ajouter
            CustomButton(
              text: 'Ajouter le médicament',
              onPressed: _ajouterMedicament,
              isLoading: _isLoading,
              icon: Icons.add,
            ),
            
            const SizedBox(height: 24),
            
            // Liste des médicaments
            _buildListeMedicaments(),
          ],
        ),
      ),
    );
  }

  // ========== ONGLET 2: RECHERCHE OPENFDA ==========
  Widget _buildOpenFDATab() {
    return Consumer<MedicamentOpenFDAProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_information, 
                        color: Colors.white, 
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recherche Intelligente 🔍',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Infos complètes & alertes FDA',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Barre de recherche
              CustomTextField(
                controller: _searchController,
                label: 'Chercher un médicament',
                hint: 'Ex: Metformine, Paracétamol...',
                prefixIcon: Icons.search,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<MedicamentOpenFDAProvider>(context, listen: false).reset();
                          setState(() {});
                        },
                      )
                    : null,
              ),

              const SizedBox(height: 12),

              // Bouton recherche
              CustomButton(
                text: 'Rechercher',
                onPressed: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    provider.getDrugDetails(_searchController.text.trim());
                  }
                },
                isLoading: provider.isLoading,
                icon: Icons.search,
              ),

              const SizedBox(height: 24),

              // Résultats de recherche
              if (provider.selectedDrugDetails != null)
                OpenFDADetailsWidget(
                  drugName: _searchController.text.trim(),
                )
              else if (!provider.isLoading && provider.lastSearchedDrug == null)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cherchez un médicament pour voir les informations FDA',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else if (provider.error != null)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Section interactions
              if (Provider.of<MedicamentProvider>(context).medicaments.isNotEmpty)
                _buildInteractionsSection(),
            ],
          ),
        );
      },
    );
  }

  // Section vérification d'interactions
  Widget _buildInteractionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ Vérifier les interactions',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 12),

        Consumer2<MedicamentProvider, MedicamentOpenFDAProvider>(
          builder: (context, medProvider, openfdaProvider, _) {
            if (medProvider.medicaments.length < 2) {
              return Text(
                'Ajoutez au moins 2 médicaments pour vérifier les interactions',
                style: TextStyle(color: Colors.grey.shade600),
              );
            }

            return Column(
              children: [
                // Sélectionner deux médicaments
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélectionnez deux médicaments:',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMedicamentSelector(
                              medProvider,
                              'Médicament 1',
                              (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMedicamentSelector(
                              medProvider,
                              'Médicament 2',
                              (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Afficher résultats
                if (openfdaProvider.interactionResult != null)
                  _buildInteractionResult(openfdaProvider.interactionResult!),
              ],
            );
          },
        ),
      ],
    );
  }

  String? _selectedDrug1;
  String? _selectedDrug2;

  Widget _buildMedicamentSelector(
    MedicamentProvider provider,
    String label,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(label),
          value: label == 'Médicament 1' ? _selectedDrug1 : _selectedDrug2,
          items: provider.medicaments
              .map((m) => DropdownMenuItem(
                    value: m.nom,
                    child: Text(m.nom),
                  ))
              .toList(),
          onChanged: (value) {
            onChanged(value);
            if (label == 'Médicament 1') {
              _selectedDrug1 = value;
            } else {
              _selectedDrug2 = value;
            }
          },
        ),
      ),
    );
  }

  Widget _buildInteractionResult(Map<String, dynamic> result) {
    final hasError = result['error'] != null;

    return Card(
      color: hasError
          ? AppColors.danger.withOpacity(0.05)
          : Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasError)
              Text(
                'Erreur: ${result['error']}',
                style: const TextStyle(color: AppColors.danger),
              )
            else ...[
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result['warning'] ?? '⚠️ Interaction détectée',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result['recommendation'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💊 ${_selectedDrug1 ?? "Drug1"} + ${_selectedDrug2 ?? "Drug2"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListeMedicaments() {
    return Consumer<MedicamentProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes médicaments',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        fontSize: 18,
                      ),
                ),
                if (provider.medicaments.isNotEmpty)
                  Text(
                    '${provider.medicaments.length}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.medicaments.isEmpty)
              const EmptyState(
                icon: Icons.medication_outlined,
                title: 'Aucun médicament',
                message: 'Ajoutez votre premier médicament ci-dessus',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.medicaments.length,
                itemBuilder: (context, index) {
                  final medicament = provider.medicaments[index];
                  return _buildMedicamentCard(medicament);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildMedicamentCard(Medicament medicament) {
    Color couleur = _obtenirCouleurPeriode(medicament.periode);
    bool estActif = medicament.estActif;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _obtenirIconePeriode(medicament.periode),
                    color: couleur,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicament.nom,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: estActif ? null : TextDecoration.lineThrough,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            medicament.periode,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: estActif,
                  onChanged: (value) => _toggleActif(medicament.id!),
                  activeColor: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                  onPressed: () => _supprimerMedicament(medicament.id!),
                ),
              ],
            ),
            if (estActif) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _obtenirRappel(medicament.nom, medicament.periode),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}