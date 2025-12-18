import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/constants.dart';
import '../../models/tension.dart';
import '../../providers/tension_provider.dart';
import '../../providers/auth_provider.dart';

class TensionScreen extends StatefulWidget {
  const TensionScreen({Key? key}) : super(key: key);

  @override
  State<TensionScreen> createState() => _TensionScreenState();
}

class _TensionScreenState extends State<TensionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systoliqueController = TextEditingController();
  final _diastoliqueController = TextEditingController();
  final _remarqueController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Charger les mesures au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId != null) {
        context.read<TensionProvider>().chargerMesures(userId);
      }
    });
  }

  @override
  void dispose() {
    _systoliqueController.dispose();
    _diastoliqueController.dispose();
    _remarqueController.dispose();
    super.dispose();
  }

  Future<void> _ajouterMesure() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      int systolique = int.parse(_systoliqueController.text);
      int diastolique = int.parse(_diastoliqueController.text);
      
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
      
      // Créer l'objet Tension
      final tension = Tension(
        userId: userId,
        systolique: systolique,
        diastolique: diastolique,
        remarque: _remarqueController.text.isEmpty ? null : _remarqueController.text,
      );
      
      // Ajouter via le provider
      final tensionProvider = context.read<TensionProvider>();
      final success = await tensionProvider.ajouterMesure(tension);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (success) {
          // Calculer le statut pour affichage
          String statut = _classifierTension(systolique, diastolique);
          String conseil = _obtenirConseil(systolique, diastolique);
          Color couleur = _obtenirCouleur(systolique, diastolique);
          
          _afficherResultat(statut, conseil, couleur);
          _systoliqueController.clear();
          _diastoliqueController.clear();
          _remarqueController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tensionProvider.error ?? 'Erreur lors de l\'enregistrement'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String _classifierTension(int systolique, int diastolique) {
    if (systolique < 120 && diastolique < 80) {
      return 'Optimale';
    } else if (systolique < 130 && diastolique < 85) {
      return 'Normale';
    } else if (systolique < 140 || diastolique < 90) {
      return 'Normale haute';
    } else if (systolique < 160 || diastolique < 100) {
      return 'Hypertension légère';
    } else {
      return 'Hypertension sévère';
    }
  }

  String _obtenirConseil(int systolique, int diastolique) {
    if (systolique < 100 || diastolique < 60) {
      return 'Tension basse détectée – reposez-vous et surveillez vos symptômes.';
    } else if (systolique < 120 && diastolique < 80) {
      return 'Votre tension est optimale. Continuez vos bonnes habitudes !';
    } else if (systolique < 140 && diastolique < 90) {
      return 'Tension légèrement élevée – limitez le sel et faites de l\'exercice.';
    } else {
      return 'Tension élevée – consultez votre médecin et détendez-vous.';
    }
  }

  Color _obtenirCouleur(int systolique, int diastolique) {
    if (systolique < 100 || diastolique < 60) {
      return AppColors.warning;
    } else if (systolique >= ValeursReference.tensionSystoliqueElevee || 
               diastolique >= ValeursReference.tensionDiastoliqueElevee) {
      return AppColors.danger;
    } else if (systolique > 130 || diastolique > 85) {
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
        title: const Text('Tension artérielle'),
      ),
      body: SingleChildScrollView(
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite, 
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
                            'Suivi de tension',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Optimale : < 120/80 mmHg',
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
              
              // Systolique et Diastolique
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _systoliqueController,
                      label: 'Systolique',
                      hint: '120',
                      prefixIcon: Icons.arrow_upward,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        int? val = int.tryParse(value);
                        if (val == null || val < 50 || val > 250) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _diastoliqueController,
                      label: 'Diastolique',
                      hint: '80',
                      prefixIcon: Icons.arrow_downward,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        int? val = int.tryParse(value);
                        if (val == null || val < 30 || val > 150) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Remarque
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
              
              // Historique
              _buildHistorique(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorique() {
    return Consumer<TensionProvider>(
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
                  final statut = _classifierTension(mesure.systolique, mesure.diastolique);
                  final color = _obtenirCouleur(mesure.systolique, mesure.diastolique);
                  
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.favorite, color: color),
                      ),
                      title: Text('${mesure.systolique}/${mesure.diastolique} mmHg'),
                      subtitle: Text(mesure.dateMesure.toString().split('.')[0]),
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