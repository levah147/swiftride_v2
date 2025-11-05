// // ==================== app_theme.dart ====================
// // COMPLETE LIGHT & DARK THEME SYSTEM
// // Production-ready with smooth transitions

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class AppTheme {
//   // ============================================
//   // LIGHT THEME
//   // ============================================
//   static ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
    
//     // Color Scheme - Light Mode
//     colorScheme: const ColorScheme.light(
//       primary: Color(0xFF0066FF),
//       primaryContainer: Color(0xFFE6F0FF),
//       secondary: Color(0xFF7C3AED),
//       secondaryContainer: Color(0xFFF3EEFF),
//       tertiary: Color(0xFF00D9FF),
//       tertiaryContainer: Color(0xFFE0F9FF),
      
//       surface: Color(0xFFFFFFFF),
//       surfaceVariant: Color(0xFFF5F5F5),
//       surfaceTint: Color(0xFF0066FF),
      
//       background: Color(0xFFFAFAFA),
      
//       error: Color(0xFFEF4444),
//       errorContainer: Color(0xFFFFE6E6),
      
//       onPrimary: Color(0xFFFFFFFF),
//       onPrimaryContainer: Color(0xFF001D35),
//       onSecondary: Color(0xFFFFFFFF),
//       onSecondaryContainer: Color(0xFF210042),
//       onSurface: Color(0xFF1A1A1A),
//       onSurfaceVariant: Color(0xFF666666),
//       onBackground: Color(0xFF1A1A1A),
//       onError: Color(0xFFFFFFFF),
//       onErrorContainer: Color(0xFF8C0000),
      
//       outline: Color(0xFFE0E0E0),
//       outlineVariant: Color(0xFFF0F0F0),
//       shadow: Color(0x1A000000),
//       scrim: Color(0x4D000000),
//       inverseSurface: Color(0xFF2A2A2A),
//       onInverseSurface: Color(0xFFF5F5F5),
//       inversePrimary: Color(0xFF6BB6FF),
//     ),
    
//     scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    
//     // AppBar Theme
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Color(0xFFFFFFFF),
//       foregroundColor: Color(0xFF1A1A1A),
//       elevation: 0,
//       centerTitle: false,
//       systemOverlayStyle: SystemUiOverlayStyle.dark,
//       titleTextStyle: TextStyle(
//         color: Color(0xFF1A1A1A),
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//       ),
//     ),
    
//     // Card Theme
//     cardTheme: CardTheme(
//       color: const Color(0xFFFFFFFF),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: const BorderSide(color: Color(0xFFF0F0F0)),
//       ),
//     ),
    
//     // Button Themes
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF0066FF),
//         foregroundColor: const Color(0xFFFFFFFF),
//         elevation: 0,
//         shadowColor: Colors.transparent,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     ),
    
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: const Color(0xFF0066FF),
//       ),
//     ),
    
//     // Input Decoration
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: const Color(0xFFF5F5F5),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
//       ),
//       hintStyle: const TextStyle(color: Color(0xFF999999)),
//     ),
    
//     // Bottom Navigation Bar
//     bottomNavigationBarTheme: const BottomNavigationBarTheme(
//       backgroundColor: Color(0xFFFFFFFF),
//       selectedItemColor: Color(0xFF0066FF),
//       unselectedItemColor: Color(0xFF999999),
//       elevation: 8,
//       type: BottomNavigationBarType.fixed,
//     ),
    
//     // Divider
//     dividerTheme: const DividerThemeData(
//       color: Color(0xFFE0E0E0),
//       thickness: 1,
//     ),
//   );
  
//   // ============================================
//   // DARK THEME
//   // ============================================
//   static ThemeData darkTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
    
//     // Color Scheme - Dark Mode
//     colorScheme: const ColorScheme.dark(
//       primary: Color(0xFF0066FF),
//       primaryContainer: Color(0xFF0052CC),
//       secondary: Color(0xFF7C3AED),
//       secondaryContainer: Color(0xFF5B21B6),
//       tertiary: Color(0xFF00D9FF),
//       tertiaryContainer: Color(0xFF00B8D4),
      
//       surface: Color(0xFF262626),
//       surfaceVariant: Color(0xFF1A1A1A),
//       surfaceTint: Color(0xFF0066FF),
      
//       background: Color(0xFF0A0A0A),
      
//       error: Color(0xFFEF4444),
//       errorContainer: Color(0xFF8C0000),
      
//       onPrimary: Color(0xFFFFFFFF),
//       onPrimaryContainer: Color(0xFFE6F0FF),
//       onSecondary: Color(0xFFFFFFFF),
//       onSecondaryContainer: Color(0xFFF3EEFF),
//       onSurface: Color(0xFFFFFFFF),
//       onSurfaceVariant: Color(0xFFB3B3B3),
//       onBackground: Color(0xFFFFFFFF),
//       onError: Color(0xFFFFFFFF),
//       onErrorContainer: Color(0xFFFFE6E6),
      
//       outline: Color(0xFF333333),
//       outlineVariant: Color(0xFF2A2A2A),
//       shadow: Color(0x40000000),
//       scrim: Color(0x80000000),
//       inverseSurface: Color(0xFFE5E5E5),
//       onInverseSurface: Color(0xFF1A1A1A),
//       inversePrimary: Color(0xFF0052CC),
//     ),
    
//     scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    
//     // AppBar Theme
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Color(0xFF0A0A0A),
//       foregroundColor: Color(0xFFFFFFFF),
//       elevation: 0,
//       centerTitle: false,
//       systemOverlayStyle: SystemUiOverlayStyle.light,
//       titleTextStyle: TextStyle(
//         color: Color(0xFFFFFFFF),
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//       ),
//     ),
    
//     // Card Theme
//     cardTheme: CardTheme(
//       color: const Color(0xFF262626),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//     ),
    
//     // Button Themes
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF0066FF),
//         foregroundColor: const Color(0xFFFFFFFF),
//         elevation: 0,
//         shadowColor: Colors.transparent,
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     ),
    
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: const Color(0xFF0066FF),
//       ),
//     ),
    
//     // Input Decoration
//     inputDecorationTheme: InputDecorationTheme(
//       filled: true,
//       fillColor: const Color(0xFF262626),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
//       ),
//       hintStyle: const TextStyle(color: Color(0xFF666666)),
//     ),
    
//     // Bottom Navigation Bar
//     bottomNavigationBarTheme: const BottomNavigationBarTheme(
//       backgroundColor: Color(0xFF1A1A1A),
//       selectedItemColor: Color(0xFF0066FF),
//       unselectedItemColor: Color(0xFF666666),
//       elevation: 0,
//       type: BottomNavigationBarType.fixed,
//     ),
    
//     // Divider
//     dividerTheme: const DividerThemeData(
//       color: Color(0xFF2A2A2A),
//       thickness: 1,
//     ),
//   );
// }