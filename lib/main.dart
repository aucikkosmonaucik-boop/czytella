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
                onPrimary: Colors.white,
                secondary: const Color(0xFFD49B6A),
                onSecondary: Colors.white,
                surface: const Color(0xFF1B231C),
                onSurface: const Color(0xFFE8ECE8),
                onSurfaceVariant: const Color(0xFFBCC4BC),
                background: const Color(0xFF121612),
                onBackground: const Color(0xFFE8ECE8),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFFE8ECE8)),
                bodyMedium: TextStyle(color: Color(0xFFDDE3DD)),
                bodySmall: TextStyle(color: Color(0xFFB8C2B8)),
                titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                titleSmall: TextStyle(color: Color(0xFFE8ECE8), fontWeight: FontWeight.bold),
                labelLarge: TextStyle(color: Color(0xFFE8ECE8)),
                labelMedium: TextStyle(color: Color(0xFFDDE3DD)),
                labelSmall: TextStyle(color: Color(0xFFB8C2B8)),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0xFF1F2B20),
                selectedColor: const Color(0xFF2E6B32),
                disabledColor: const Color(0xFF161E17),
                labelStyle: const TextStyle(color: Color(0xFFE2E8E2), fontSize: 12),
                secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                side: const BorderSide(color: Color(0xFF2E3D30)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF86E875),
                  side: const BorderSide(color: Color(0xFF4E9F3D)),
                ),
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
                      color: Colors.white),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1B231C),
                hintStyle: const TextStyle(color: Color(0xFF8E9E8E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E3D30)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E3D30)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF5DBB4D), width: 1.8),
                ),
              ),
              dividerTheme: const DividerThemeData(color: Color(0xFF2E3D30)),
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
