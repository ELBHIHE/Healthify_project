import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _tailleController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _tailleController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      debugPrint('🔵 SignupScreen: _isLoading set to true');
      
      final authProvider = context.read<AuthProvider>();
      
      try {
        int age = int.parse(_ageController.text);
        double taille = double.parse(_tailleController.text) / 100; // Convertir cm en mètres
        
        bool success = false;
        try {
          // Défensive: timeout pour éviter spinner infini si quelque chose coince
          success = await authProvider
              .signUp(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                nom: _nomController.text.trim(),
                age: age,
                taille: taille,
              )
              .timeout(const Duration(seconds: 10), onTimeout: () {
            debugPrint('⚠️ signUp timeout after 10s');
            return false;
          });
        } finally {
          // Toujours arrêter le loader
          setState(() => _isLoading = false);
          debugPrint('🔵 SignupScreen: _isLoading set to false (finally)');
        }

        if (mounted) {
          if (success) {
            debugPrint('🔵 SignupScreen: signUp success, will show snackbar and pop');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Utilisateur inscris avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
            // Attendre un instant puis revenir à l'écran de login
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pop(context);
            }
          } else {
            debugPrint('🔵 SignupScreen: signUp failed, showing error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erreur: ${authProvider.error ?? "Inscription échouée"}'),
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
              content: Text('❌ Erreur: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer un compte',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remplissez vos informations',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                
                // Nom complet
                CustomTextField(
                  controller: _nomController,
                  label: 'Nom complet',
                  hint: 'Jean Dupont',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'example@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return ErrorMessages.emailInvalide;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword 
                          ? Icons.visibility_outlined 
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return ErrorMessages.motDePasseCourt;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Âge et Taille sur la même ligne
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Âge',
                        hint: '25',
                        prefixIcon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          int? age = int.tryParse(value);
                          if (age == null || age < 1 || age > 120) {
                            return 'Âge invalide';
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
                        hint: '175',
                        prefixIcon: Icons.height,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                
                const SizedBox(height: 32),
                
                // Bouton inscription
                CustomButton(
                  text: 'S\'inscrire',
                  onPressed: _signup,
                  isLoading: _isLoading,
                  icon: Icons.person_add,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}