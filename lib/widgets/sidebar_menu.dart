import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SidebarMenu extends StatelessWidget {
  final String userName;
  final String userEmail;

  const SidebarMenu({
    Key? key,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tableau de bord'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          const Divider(),
          _buildSectionTitle('Modules de santé'),
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: const Text('Glycémie'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/glycemie');
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Tension'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/tension');
            },
          ),
          ListTile(
            leading: const Icon(Icons.opacity, color: Colors.orange),
            title: const Text('Cholestérol'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cholesterol');
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight, color: Colors.green),
            title: const Text('IMC'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/imc');
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication, color: Colors.purple),
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
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigation vers paramètres
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                Navigator.pop(context); // Fermer le dialog
                Navigator.pop(context); // Fermer le drawer
                // TODO: Appeler le service de déconnexion
                Navigator.pushReplacementNamed(context, '/login');
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
}