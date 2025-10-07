import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'firebase_options.dart'; 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Hive
  await HiveService.init();
  
  runApp(const IceCreamPOSApp());
}

class IceCreamPOSApp extends StatelessWidget {
  const IceCreamPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ice Cream POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (AuthService.isLoggedIn) {
          return const HomeScreen();
        } else {
          // Show login screen instead of setup screen
          return const LoginScreen();
        }
      },
    );
  }
}
