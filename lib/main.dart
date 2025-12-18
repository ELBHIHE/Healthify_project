import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/modules/glycemie_screen.dart';
import 'screens/modules/tension_screen.dart';
import 'screens/modules/cholesterol_screen.dart';
import 'screens/modules/imc_screen.dart';
import 'screens/modules/medicament_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/glycemie_provider.dart';
import 'providers/tension_provider.dart';
import 'providers/cholesterol_provider.dart';
import 'providers/imc_provider.dart';
import 'providers/medicament_provider.dart';
import 'providers/medicament_openfda_provider.dart';
import 'utils/theme.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialiser la base de données locale
  await DatabaseHelper.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider d'authentification
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        
        // Providers des modules de santé
        ChangeNotifierProvider(
          create: (_) => GlycemieProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TensionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CholesterolProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => IMCProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicamentProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicamentOpenFDAProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Healthify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        
        // Route initiale
        home: const LoginScreen(),
        
        // Routes nommées
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/glycemie': (context) => const GlycemieScreen(),
          '/tension': (context) => const TensionScreen(),
          '/cholesterol': (context) => const CholesterolScreen(),
          '/imc': (context) => const IMCScreen(),
          '/medicament': (context) => const MedicamentScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}