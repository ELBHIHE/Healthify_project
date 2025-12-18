import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _tailleController = TextEditingController();
  bool _initialized = false;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _tailleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Remplir les contrôleurs avec les données si disponibles
      final user = auth.user;
      final data = auth.userData;
      if (data != null) {
        _nomController.text = data['nom'] ?? user?.displayName ?? '';
        _emailController.text = data['email'] ?? user?.email ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _tailleController.text = data['taille']?.toString() ?? '';
      } else {
        _nomController.text = user?.displayName ?? '';
        _emailController.text = user?.email ?? '';
      }
      _initialized = true;
    }
  }

  Future<void> _sauvegarderProfil() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      try {
        int age = int.tryParse(_ageController.text) ?? 0;
        double taille = (int.tryParse(_tailleController.text) ?? 0).toDouble();
        final success = await auth.updateUserProfile(
          nom: _nomController.text.trim(),
          age: age == 0 ? null : age,
          taille: taille == 0 ? null : taille,
        );

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil mis à jour avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${auth.error ?? 'Échec mise à jour'}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _annulerModification() {
    setState(() => _isEditing = false);
    // Recharger les données originales
    _nomController.text = 'Jean Dupont';
    _emailController.text = 'jean.dupont@email.com';
    _ageController.text = '35';
    _tailleController.text = '175';
  }

  void _deconnexion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Déconnexion Firebase
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                _nomController.text,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _emailController.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 32),
              
              // Informations personnelles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Informations personnelles',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Mode édition',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      CustomTextField(
                        controller: _nomController,
                        label: 'Nom complet',
                        prefixIcon: Icons.person_outline,
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        enabled: false, // Email non modifiable
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _ageController,
                              label: 'Âge',
                              prefixIcon: Icons.cake_outlined,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                int? age = int.tryParse(value);
                                if (age == null || age < 1 || age > 120) {
                                  return 'Invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _tailleController,
                              label: 'Taille (cm)',
                              prefixIcon: Icons.height,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                int? taille = int.tryParse(value);
                                if (taille == null || taille < 50 || taille > 250) {
                                  return 'Invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Boutons d'action
              if (_isEditing) ...[
                CustomButton(
                  text: 'Sauvegarder les modifications',
                  onPressed: _sauvegarderProfil,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Annuler',
                  onPressed: _annulerModification,
                  backgroundColor: Colors.grey,
                  icon: Icons.close,
                ),
              ] else ...[
                // Statistiques
                _buildStatistiques(),
                const SizedBox(height: 24),
                
                // Options
                _buildOptions(),
              ],
              
              const SizedBox(height: 24),
              
              // Bouton déconnexion
              if (!_isEditing)
                CustomButton(
                  text: 'Déconnexion',
                  onPressed: _deconnexion,
                  backgroundColor: AppColors.danger,
                  icon: Icons.logout,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistiques() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.water_drop, '12', 'Mesures\nGlycémie'),
                _buildStatItem(Icons.favorite, '8', 'Mesures\nTension'),
                _buildStatItem(Icons.medication, '3', 'Médicaments\nActifs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String valeur, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          valeur,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implémenter changement de mot de passe
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Gérer les notifications
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Aide et support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Page d'aide
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Text('v1.0.0', style: TextStyle(color: AppColors.textSecondary)),
            onTap: () {
              // TODO: Page à propos
            },
          ),
        ],
      ),
    );
  }
}