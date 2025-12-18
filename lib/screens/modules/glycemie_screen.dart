import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/constants.dart';
import '../../models/glycemie.dart';
import '../../providers/glycemie_provider.dart';
import '../../providers/auth_provider.dart';

class GlycemieScreen extends StatefulWidget {
  const GlycemieScreen({Key? key}) : super(key: key);

  @override
  State<GlycemieScreen> createState() => _GlycemieScreenState();
}

class _GlycemieScreenState extends State<GlycemieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valeurController = TextEditingController();
  final _remarqueController = TextEditingController();
  String _momentSelectionne = MomentsGlycemie.aJeun;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Charger les mesures au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      debugPrint('🔵 GlycemieScreen initState: userId=$userId, isLoggedIn=${authProvider.isLoggedIn}');
      if (userId != null) {
        context.read<GlycemieProvider>().chargerMesures(userId);
      }
    });
  }

  @override
  void dispose() {
    _valeurController.dispose();
    _remarqueController.dispose();
    super.dispose();
  }

  Future<void> _ajouterMesure() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      double valeur = double.parse(_valeurController.text);
      
      // Obtenir l'ID utilisateur
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      debugPrint('🔵 _ajouterMesure: userId=$userId, isLoggedIn=${authProvider.isLoggedIn}, _user=${authProvider.user?.email}');
      
      if (userId == null) {
        debugPrint('❌ userId est null, affichage erreur');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non connecté'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Créer l'objet Glycemie
      final glycemie = Glycemie(
        userId: userId,
        valeur: valeur,
        moment: _momentSelectionne,
        remarque: _remarqueController.text.isEmpty ? null : _remarqueController.text,
      );
      
      // Ajouter via le provider
      final glycemieProvider = context.read<GlycemieProvider>();
      final success = await glycemieProvider.ajouterMesure(glycemie);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (success) {
          // Calculer le statut pour affichage
          String statut = _calculerStatut(valeur);
          String conseil = _obtenirConseil(valeur);
          Color couleur = _obtenirCouleur(valeur);
          
          _afficherResultat(statut, conseil, couleur);
          _valeurController.clear();
          _remarqueController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(glycemieProvider.error ?? 'Erreur lors de l\'enregistrement'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String _calculerStatut(double valeur) {
    if (valeur < ValeursReference.glycemieMin) {
      return 'Hypoglycémie';
    } else if (valeur <= ValeursReference.glycemieMax) {
      return 'Normal';
    } else {
      return 'Hyperglycémie';
    }
  }

  String _obtenirConseil(double valeur) {
    if (valeur < ValeursReference.glycemieMin) {
      return 'Hypoglycémie détectée – prenez un jus sucré ou un fruit.';
    } else if (valeur <= ValeursReference.glycemieMax) {
      return 'Votre glycémie est dans la normale. Continuez ainsi !';
    } else {
      return 'Glycémie élevée – évitez les aliments sucrés et consultez votre médecin.';
    }
  }

  Color _obtenirCouleur(double valeur) {
    if (valeur < ValeursReference.glycemieMin || 
        valeur > ValeursReference.glycemieMax) {
      return AppColors.danger;
    } else if (valeur > 110) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  void _afficherResultat(String statut, String conseil, Color couleur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: couleur, size: 28),
            const SizedBox(width: 12),
            const Text('Mesure enregistrée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statut,
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(conseil, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glycémie'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône
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
                      child: const Icon(Icons.water_drop, 
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
                            'Suivi de glycémie',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Valeur normale : 70-126 mg/dL',
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
              
              Text(
                'Nouvelle mesure',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Valeur
              CustomTextField(
                controller: _valeurController,
                label: 'Valeur (mg/dL)',
                hint: 'Ex: 105',
                prefixIcon: Icons.monitor_heart,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une valeur';
                  }
                  double? val = double.tryParse(value);
                  if (val == null || val < 20 || val > 600) {
                    return 'Valeur invalide (20-600)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Moment
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moment de la mesure',
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
                        value: _momentSelectionne,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: MomentsGlycemie.getAll()
                            .map((String moment) => DropdownMenuItem(
                                  value: moment,
                                  child: Text(moment),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _momentSelectionne = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Remarque (optionnel)
              CustomTextField(
                controller: _remarqueController,
                label: 'Remarque (optionnel)',
                hint: 'Ajoutez une note...',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Bouton enregistrer
              CustomButton(
                text: 'Enregistrer la mesure',
                onPressed: _ajouterMesure,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
              
              const SizedBox(height: 24),
              
              // Historique (TODO)
              _buildHistorique(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorique() {
    return Consumer<GlycemieProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique récent',
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                        fontSize: 18,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.mesures.isEmpty)
              Center(
                child: Text(
                  'Aucune mesure enregistrée',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.mesures.take(5).length,
                itemBuilder: (context, index) {
                  final mesure = provider.mesures[index];
                  final statut = mesure.calculerStatut();
                  final color = statut == 'Normal' 
                    ? AppColors.success 
                    : (statut == 'Hypoglycémie' ? AppColors.warning : AppColors.danger);
                  
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.water_drop, color: color),
                      ),
                      title: Text('${mesure.valeur.toStringAsFixed(1)} mg/dL'),
                      subtitle: Text('${mesure.moment} • ${mesure.dateMesure.toString().split('.')[0]}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statut,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}