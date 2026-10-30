import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// Démarre l’application de fléchettes.
void main() {
  runApp(const MyApp());
}

/// Configure le thème de l’application et ouvre l’écran de création des joueurs.
class MyApp extends StatelessWidget {
  /// Crée le widget racine de l’application.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00C853),
          surface: const Color(0xFF1C1C1C),
        ),

        scaffoldBackgroundColor: const Color(0xFF0F0F0F),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
