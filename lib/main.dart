import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mybike/services/petrol_price_updater.dart';

import 'home.dart';
import 'add_bike.dart';

Future<void> main() async {
  // 👇 Required before Firebase init
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Firebase initialization
  await Firebase.initializeApp();

  await PetrolPriceUpdater.updateIfNeeded();


  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideLimit',

      theme: ThemeData(
        useMaterial3: true,

        // 🌞 Bright color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),

        // 🌞 Bright scaffold background
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),

        // 🌞 AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),

        // 🌞 Card styling
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // 🌞 Button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/add-bike': (context) => const AddBikeScreen(),
      },
    );
  }
}
