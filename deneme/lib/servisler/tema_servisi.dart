import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaServisi extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  TemaServisi() {
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      primaryColor: Colors.green,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.grey[700]),
        bodyMedium: TextStyle(color: Colors.grey[600]),
      ),
      iconTheme: IconThemeData(color: Colors.grey[700]),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      primaryColor: Colors.green[400],
      scaffoldBackgroundColor: Color(0xFF1A1A1A), // Daha yumuşak koyu gri
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[600], // AppBar yeşil kalsın
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: Color(0xFF2D2D30), // Daha açık koyu gri
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[500],
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.green.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.bold), // Daha yumuşak beyaz
        headlineMedium: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFFE8E8E8)), // Okunabilir açık gri
        bodyMedium: TextStyle(color: Color(0xFFBDBDBD)), // Orta ton gri
      ),
      iconTheme: IconThemeData(color: Color(0xFFE8E8E8)),
      dividerColor: Color(0xFF404040),
      // Daha okunabilir renk şeması
      colorScheme: ColorScheme.dark(
        primary: Colors.green[400]!,
        secondary: Colors.green[300]!,
        surface: Color(0xFF2D2D30),
        background: Color(0xFF1A1A1A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE8E8E8),
        onBackground: Color(0xFFE8E8E8),
        brightness: Brightness.dark,
      ),
      // TabBar tema
      tabBarTheme: TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
      ),
      // Bottom sheet tema
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xFF2D2D30),
        modalBackgroundColor: Color(0xFF2D2D30),
      ),
      // Dialog tema
      dialogTheme: DialogTheme(
        backgroundColor: Color(0xFF2D2D30),
        titleTextStyle: TextStyle(color: Color(0xFFF0F0F0), fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: Color(0xFFE8E8E8)),
      ),
      // Input decoration tema
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Color(0xFF3A3A3C),
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF404040)),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF404040)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: TextStyle(color: Color(0xFFBDBDBD)),
        hintStyle: TextStyle(color: Color(0xFF8E8E93)),
      ),
      // Liste tile tema
      listTileTheme: ListTileThemeData(
        textColor: Color(0xFFE8E8E8),
        iconColor: Color(0xFFE8E8E8),
        tileColor: Color(0xFF2D2D30),
      ),
    );
  }
} 