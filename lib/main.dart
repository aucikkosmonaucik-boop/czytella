import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/czytella_provider.dart';
import 'services/api_service.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  runApp(const CzytellaApp());
}

class CzytellaApp extends StatelessWidget {
  const CzytellaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CzytellaProvider(),
      child: Consumer<CzytellaProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Czytella',
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF4F4F0),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E5128),
                brightness: Brightness.light,
                primary: const Color(0xFF1E5128),
                secondary: const Color(0xFF8C5523),
                surface: const Color(0xFFFAFAF7),
                background: const Color(0xFFF4F4F0),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 1,
                backgroundColor: Color(0xFFFAFAF7),
              ),
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: const Color(0xFFD6E8D5),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E5128), width: 1.8),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121612),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4E9F3D),
                brightness: Brightness.dark,
                primary: const Color(0xFF5DBB4D),
                secondary: const Color(0xFFD49B6A),
                surface: const Color(0xFF1B231C),
                background: const Color(0xFF121612),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1B231C),
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 1,
                backgroundColor: Color(0xFF171E17),
                foregroundColor: Colors.white,
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: const Color(0xFF141914),
                indicatorColor: const Color(0xFF264028),
                labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1B231C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF5DBB4D), width: 1.8),
                ),
              ),
              dividerTheme: DividerThemeData(color: Colors.grey.shade800),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF1B231C),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
