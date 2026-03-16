import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/menu/main_menu_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const VoidcryptApp());
}

class VoidcryptApp extends StatelessWidget {
  const VoidcryptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voidcrypt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF130C1F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA170FF),
          onPrimary: Color(0xFF1D1230),
          secondary: Color(0xFFE2B86A),
          onSecondary: Color(0xFF261A09),
          surface: Color(0xFF201533),
          onSurface: Color(0xFFF9EEFF),
          outline: Color(0xFFD7AA5E),
          error: Color(0xFFFF6D8A),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: const Color(0xFFFFF3DF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFD7AA5E), width: 1),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFE8C2),
            side: const BorderSide(color: Color(0xFFD7AA5E), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const MainMenuPage(),
    );
  }
}
