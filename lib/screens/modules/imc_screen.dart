import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../utils/constants.dart';
import '../../models/imc.dart';
import '../../providers/imc_provider.dart';
import '../../providers/auth_provider.dart';

class IMCScreen extends StatefulWidget {
  const IMCScreen({Key? key}) : super(key: key);

  @override
  State<IMCScreen> createState() => _IMCScreenState();
}

class _IMCScreenState extends State<IMCScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  bool _isLoading = false;
  double? _imcCalcule;
  String? _categorie;
  double? _poidsIdeal;

  @override
  void initState() {
    super.initState();
    // Charger les mesures au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;
      if (userId != null) {
        context.read<IMCProvider>().chargerMesures(userId);
      }
    });
  }

  @override
  void dispose() {
    _tailleController.dispose();
    _poidsController.dispose();
    super.dispose();
  }

  Future<void> _calculerIMC() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      double taille = double.parse(_tailleController.text);
      double poids = double.parse(_poidsController.text);
      
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
      
      double tailleEnMetres = taille / 100;
      double imc = _calculer(poids, tailleEnMetres);
      String categorie = _determinerCategorie(imc);
      double poidsIdeal = _calculerPoidsIdeal(tailleEnMetres);
      String conseil = _obtenirConseil(imc, poids, poidsIdeal);
      Color couleur = _obtenirCouleur(imc);
      
      // Créer l'objet IMC
      final imcObj = IMC(
        userId: userId,
        taille: taille,
        poids: poids,
        imc: imc,
      );
      
      // Ajouter via le provider
      final imcProvider = context.read<IMCProvider>();
      final success = await imcProvider.ajouterMesure(imcObj);
      
      setState(() {
        _imcCalcule = imc;
        _categorie = categorie;
        _poidsIdeal = poidsIdeal;
        _isLoading = false;
      });
      
      if (mounted) {
        if (success) {
          _afficherResultat(imc, categorie, poidsIdeal, conseil, couleur);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(imcProvider.error ?? 'Erreur lors de l\'enregistrement'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  double _calculer(double poids, double taille) {
    return poids / (taille * taille);
  }

  String _determinerCategorie(double imc) {
    if (imc < ValeursReference.imcSousPoids) {
      return 'Sous-poids';
    } else if (imc < ValeursReference.imcNormal) {
      return 'Normal';
    } else if (imc < ValeursReference.imcSurpoids) {
      return 'Surpoids';
    } else {
      return 'Obésité';
    }
  }

  double _calculerPoidsIdeal(double taille) {
    // Formule de Lorentz : Poids idéal = (taille - 100) - (taille - 150) / k
    // k = 4 pour les hommes, 2 pour les femmes (on prend 3 comme moyenne)
    double tailleEnCm = taille * 100;
    return (tailleEnCm - 100) - (tailleEnCm - 150) / 3;
  }

  String _obtenirConseil(double imc, double poids, double poidsIdeal) {
    if (imc < ValeursReference.imcSousPoids) {
      return 'Vous êtes en sous-poids. Adoptez une alimentation plus riche et consultez un nutritionniste.';
    } else if (imc < ValeursReference.imcNormal) {
      return 'Votre IMC est normal ! Maintenez une alimentation équilibrée et une activité physique régulière.';
    } else if (imc < ValeursReference.imcSurpoids) {
      return 'Vous êtes en surpoids. Privilégiez une alimentation équilibrée et augmentez votre activité physique.';
    } else {
      return 'Obésité détectée. Il est recommandé de consulter un médecin pour un suivi personnalisé.';
    }
  }

  Color _obtenirCouleur(double imc) {
    if (imc < ValeursReference.imcSousPoids || imc >= ValeursReference.imcSurpoids) {
      return AppColors.danger;
    } else if (imc >= 23 && imc < ValeursReference.imcNormal) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  void _afficherResultat(double imc, String categorie, double poidsIdeal, String conseil, Color couleur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: couleur, size: 28),
            const SizedBox(width: 12),
            const Text('Calcul terminé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    imc.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: couleur,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: couleur.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      categorie,
                      style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.scale, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Poids idéal : ${poidsIdeal.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
        title: const Text('IMC'),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monitor_weight, 
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
                            'Calcul d\'IMC',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Normal : 18.5 - 25',
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
                'Calculer votre IMC',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Taille
              CustomTextField(
                controller: _tailleController,
                label: 'Taille (cm)',
                hint: '175',
                prefixIcon: Icons.height,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre taille';
                  }
                  int? val = int.tryParse(value);
                  if (val == null || val < 50 || val > 250) {
                    return 'Taille invalide (50-250 cm)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Poids
              CustomTextField(
                controller: _poidsController,
                label: 'Poids (kg)',
                hint: '70',
                prefixIcon: Icons.scale,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre poids';
                  }
                  double? val = double.tryParse(value);
                  if (val == null || val < 20 || val > 300) {
                    return 'Poids invalide (20-300 kg)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Bouton calculer
              CustomButton(
                text: 'Calculer mon IMC',
                onPressed: _calculerIMC,
                isLoading: _isLoading,
                icon: Icons.calculate,
              ),
              
              // Affichage du résultat si calculé
              if (_imcCalcule != null) ...[
                const SizedBox(height: 24),
                _buildResultatCard(),
              ],
              
              const SizedBox(height: 24),
              
              // Guide IMC
              _buildGuideIMC(),
              
              const SizedBox(height: 24),
              
              // Historique
              _buildHistorique(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultatCard() {
    Color couleur = _obtenirCouleur(_imcCalcule!);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Votre IMC',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _imcCalcule!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _categorie!,
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_poidsIdeal != null) ...[
            const SizedBox(height: 16),
            Text(
              'Poids idéal : ${_poidsIdeal!.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuideIMC() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guide de référence',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildGuideRow('Sous-poids', '< 18.5', AppColors.warning),
                const Divider(),
                _buildGuideRow('Normal', '18.5 - 24.9', AppColors.success),
                const Divider(),
                _buildGuideRow('Surpoids', '25 - 29.9', AppColors.warning),
                const Divider(),
                _buildGuideRow('Obésité', '≥ 30', AppColors.danger),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideRow(String label, String valeur, Color couleur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              valeur,
              style: TextStyle(
                color: couleur,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorique() {
    return Consumer<IMCProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historique',
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
              const EmptyState(
                icon: Icons.monitor_weight_outlined,
                title: 'Aucun calcul',
                message: 'Calculez votre IMC ci-dessus pour commencer le suivi',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.mesures.take(5).length,
                itemBuilder: (context, index) {
                  final mesure = provider.mesures[index];
                  String categorie = _determinerCategorie(mesure.imc);
                  final color = mesure.imc >= ValeursReference.imcSurpoids ? AppColors.danger : AppColors.success;
                  
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.monitor_weight, color: color),
                      ),
                      title: Text('${mesure.imc.toStringAsFixed(1)} (${mesure.poids.toStringAsFixed(1)} kg)'),
                      subtitle: Text(mesure.dateMesure.toString().split('.')[0]),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categorie,
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