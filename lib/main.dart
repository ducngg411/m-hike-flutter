import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MHikeApp());
}

class MHikeApp extends StatelessWidget {
  const MHikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M-Hike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  Future<void> _checkWelcomeStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay

    final prefs = await SharedPreferences.getInstance();
    final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => welcomeCompleted
              ? const MainNavigationScreen()
              : const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hiking,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'M-Hike',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Hiking Companion',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
