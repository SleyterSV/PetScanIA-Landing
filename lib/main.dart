import 'package:flutter/material.dart';
import 'package:petscania/screens/home_screen.dart';
import 'package:petscania/screens/login_screen.dart';
import 'package:petscania/theme/petscania_brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://glexxwtbgnwzsxlbhjga.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsZXh4d3RiZ253enN4bGJoamdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk5MDUzNDcsImV4cCI6MjA4NTQ4MTM0N30.tj8JGJvXmd8J8eFaX9g-hfEXELVb0X9nIpdV1XZxmNk',
  );

  runApp(const PetScanIAApp());
}

class PetScanIAApp extends StatelessWidget {
  const PetScanIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetScanIA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: PetScaniaColors.mist,
        primaryColor: PetScaniaColors.royalBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PetScaniaColors.royalBlue,
          primary: PetScaniaColors.royalBlue,
          secondary: PetScaniaColors.skyBlue,
          surface: PetScaniaColors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: PetScaniaColors.ink,
          displayColor: PetScaniaColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: PetScaniaColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
