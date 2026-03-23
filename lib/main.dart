import 'package:flutter/material.dart';
// Make sure this import matches your actual folder structure.
// If your project name is different, change 'mda_automac' to your package name.
import 'package:mda_automac/features/splash/screens/splash_screen.dart';

void main() {
  // You can initialize core services here later (like Firebase, Hive, or SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MDAAutomacApp());
}

class MDAAutomacApp extends StatelessWidget {
  const MDAAutomacApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MDA Automac',
      debugShowCheckedModeBanner: false, // Removes the red debug banner
      // Base Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF090D1A,
        ), // Matches your splash background
        colorScheme: ColorScheme.dark(
          background: const Color(0xFF090D1A),
          primary: const Color(0xFFFF7A00), // The orange from your logo
          secondary: const Color(0xFF00E5FF), // The cyan from your logo
        ),
        fontFamily: 'Inter', // Placeholder for a clean sans-serif font
      ),

      // Initial Route
      home: const SplashScreen(),
    );
  }
}
