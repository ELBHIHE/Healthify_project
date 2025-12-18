import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/module_card.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implémenter les notifications
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec salutation
            _buildHeader(context),
            const SizedBox(height: 24),
            
            // Résumé rapide
            _buildQuickSummary(context),
            const SizedBox(height: 24),
            
            // Titre modules
            Text(
              'Modules de suivi',
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Cartes des modules
            ModuleCard(
              title: 'Glycémie',
              icon: Icons.water_drop,
              color: Colors.blue,
              lastValue: '105 mg/dL',
              status: 'Normal',
              onTap: () {
                // TODO: Navigation vers module Glycémie
                Navigator.pushNamed(context, '/glycemie');
              },
            ),
            const SizedBox(height: 12),
            
            ModuleCard(
              title: 'Tension artérielle',
              icon: Icons.favorite,
              color: Colors.red,
              lastValue: '120/80 mmHg',
              status: 'Optimale',
              onTap: () {
                // TODO: Navigation vers module Tension
                Navigator.pushNamed(context, '/tension');
              },
            ),
            const SizedBox(height: 12),
            
            ModuleCard(
              title: 'Cholestérol',
              icon: Icons.opacity,
              color: Colors.orange,
              lastValue: '1.8 g/L',
              status: 'Bon',
              onTap: () {
                // TODO: Navigation vers module Cholestérol
                Navigator.pushNamed(context, '/cholesterol');
              },
            ),
            const SizedBox(height: 12),
            
            ModuleCard(
              title: 'IMC',
              icon: Icons.monitor_weight,
              color: Colors.green,
              lastValue: '23.5',
              status: 'Normal',
              onTap: () {
                // TODO: Navigation vers module IMC
                Navigator.pushNamed(context, '/imc');
              },
            ),
            const SizedBox(height: 12),
            
            ModuleCard(
              title: 'Médicaments',
              icon: Icons.medication,
              color: Colors.purple,
              lastValue: '3 médicaments',
              status: null,
              onTap: () {
                // TODO: Navigation vers module Médicament
                Navigator.pushNamed(context, '/medicament');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Afficher le nom depuis AuthProvider
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = auth.userName ?? auth.userEmail ?? 'Utilisateur';
                    return Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Résumé du jour',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '✓ Tous vos indicateurs sont dans la normale',
            style: TextStyle(color: AppColors.success, fontSize: 13),
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 4),
          const Text(
            '• Prenez vos médicaments ce soir',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.favorite, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Healthify',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Votre santé, simplifiée',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tableau de bord'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Glycémie'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/glycemie');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Tension'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/tension');
            },
          ),
          ListTile(
            leading: const Icon(Icons.opacity),
            title: const Text('Cholestérol'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cholesterol');
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight),
            title: const Text('IMC'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/imc');
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Médicaments'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/medicament');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Déconnexion', 
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () {
              // TODO: Implémenter la déconnexion
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}