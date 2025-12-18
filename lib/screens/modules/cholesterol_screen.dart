import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../utils/constants.dart';
import '../../models/cholesterol.dart';
import '../../providers/cholesterol_provider.dart';
import '../../providers/auth_provider.dart';

class CholesterolScreen extends StatefulWidget {
  const CholesterolScreen({Key? key}) : super(key: key);

  @override
  State<CholesterolScreen> createState() => _CholesterolScreenState();
}

class _CholesterolScreenState extends State<CholesterolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _hdlController = TextEditingController();
  final _ldlController = TextEditingController();
  final _remarqueController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Charger les bilans au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId != null) {
        context.read<CholesterolProvider>().chargerBilans(userId);
      }
    });
  }

  @override
  void dispose() {
    _totalController.dispose();
    _hdlController.dispose();
    _ldlController.dispose();
    _remarqueController.dispose();
    super.dispose();
  }

  Future<void> _ajouterBilan() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      double total = double.parse(_totalController.text);
      double hdl = double.parse(_hdlController.text);
      double ldl = double.parse(_ldlController.text);
      
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
      
      // Créer l'objet Cholesterol
      final cholesterol = Cholesterol(
        userId: userId,
        total: total,
        hdl: hdl,
        ldl: ldl,
        remarque: _remarqueController.text.isEmpty ? null : _remarqueController.text,
      );
      
      // Ajouter via le provider
      final cholesterolProvider = context.read<CholesterolProvider>();
      final success = await cholesterolProvider.ajouterBilan(cholesterol);
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (success) {
          // Calculer le statut pour affichage
          double ratio = _calculerRatio(total, hdl);
          String interpretation = _interpreterResultat(ldl, hdl, ratio);
          String conseil = _obtenirConseil(ldl, hdl);
          Color couleur = _obtenirCouleur(ldl, hdl);
          
          _afficherResultat(interpretation, conseil, couleur, ratio);
          _totalController.clear();
          _hdlController.clear();
          _ldlController.clear();
          _remarqueController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(cholesterolProvider.error ?? 'Erreur lors de l\'enregistrement'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  double _calculerRatio(double total, double hdl) {
    if (hdl == 0) return 0;
    return total / hdl;
  }

  String _interpreterResultat(double ldl, double hdl, double ratio) {
    if (ldl > ValeursReference.ldlMax) {
      return 'Risque cardiovasculaire';
    } else if (hdl < ValeursReference.hdlMin) {
      return 'HDL trop faible';
    } else if (ratio > 5.0) {
      return 'Ratio élevé';
    } else if (ratio < 3.5) {
      return 'Excellent';
    } else {
      return 'Bon';
    }
  }

  String _obtenirConseil(double ldl, double hdl) {
    if (ldl > ValeursReference.ldlMax) {
      return 'LDL élevé – limitez les graisses saturées et privilégiez les oméga-3.';
    } else if (hdl < ValeursReference.hdlMin) {
      return 'HDL faible – pratiquez une activité physique régulière.';
    } else {
      return 'Votre bilan lipidique est satisfaisant. Maintenez une alimentation équilibrée.';
    }
  }

  Color _obtenirCouleur(double ldl, double hdl) {
    if (ldl > ValeursReference.ldlMax || hdl < ValeursReference.hdlMin) {
      return AppColors.danger;
    } else if (ldl > 1.3 || hdl < 0.5) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  void _afficherResultat(String interpretation, String conseil, Color couleur, double ratio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: couleur, size: 28),
            const SizedBox(width: 12),
            const Text('Bilan enregistré'),
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
                interpretation,
                style: TextStyle(
                  color: couleur,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ratio Total/HDL : ${ratio.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
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
        title: const Text('Cholestérol'),
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.opacity, 
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
                            'Bilan lipidique',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'LDL < 1.6 g/L • HDL > 0.4 g/L',
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
                'Nouveau bilan',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Cholestérol total
              CustomTextField(
                controller: _totalController,
                label: 'Cholestérol total (g/L)',
                hint: '1.8',
                prefixIcon: Icons.analytics,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une valeur';
                  }
                  double? val = double.tryParse(value);
                  if (val == null || val < 0.5 || val > 5.0) {
                    return 'Valeur invalide (0.5-5.0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // HDL et LDL
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _hdlController,
                      label: 'HDL (g/L)',
                      hint: '0.5',
                      prefixIcon: Icons.trending_up,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        double? val = double.tryParse(value);
                        if (val == null || val < 0.1 || val > 3.0) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _ldlController,
                      label: 'LDL (g/L)',
                      hint: '1.2',
                      prefixIcon: Icons.trending_down,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requis';
                        }
                        double? val = double.tryParse(value);
                        if (val == null || val < 0.1 || val > 4.0) {
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
                text: 'Enregistrer le bilan',
                onPressed: _ajouterBilan,
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
    return Consumer<CholesterolProvider>(
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
            else if (provider.bilans.isEmpty)
              const EmptyState(
                icon: Icons.opacity_outlined,
                title: 'Aucun bilan',
                message: 'Ajoutez votre premier bilan lipidique ci-dessus',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.bilans.take(5).length,
                itemBuilder: (context, index) {
                  final bilan = provider.bilans[index];
                  final color = bilan.ldl > ValeursReference.ldlMax ? AppColors.danger : AppColors.success;
                  
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.opacity, color: color),
                      ),
                      title: Text('${bilan.total.toStringAsFixed(1)} g/L'),
                      subtitle: Text('HDL: ${bilan.hdl.toStringAsFixed(2)} • LDL: ${bilan.ldl.toStringAsFixed(2)}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bilan.ldl > ValeursReference.ldlMax ? 'Risque' : 'Bon',
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