import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const TuniModeApp());
}

class TuniModeApp extends StatelessWidget {
  const TuniModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);

    return MaterialApp(
      title: 'TuniMode',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,

        // ✅ POLICE SYSTÈME (COMME VINTED)
        fontFamily: null,

        // ✅ TEXTE GLOBAL — JAMAIS EN GRAS
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),

        // ✅ BOUTONS — JAMAIS EN GRAS
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: _buildElevatedButtonStyle(colorScheme),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: _buildOutlinedButtonStyle(colorScheme),
        ),
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
      initialRoute: '/',
    );
  }
}

// ✅ STYLE DES BOUTONS ÉLEVATED — NORMAL (400)
ButtonStyle _buildElevatedButtonStyle(ColorScheme colorScheme) {
  final primary = colorScheme.primary;
  final hoverColor = _darken(primary, 0.06);
  final pressedColor = _darken(primary, 0.12);
  final disabledColor = colorScheme.onSurface.withOpacity(0.12);

  return ButtonStyle(
    textStyle: MaterialStateProperty.all(
      const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400, // ✅ JAMAIS GRAS
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) return disabledColor;
      if (states.contains(MaterialState.pressed)) return pressedColor;
      if (states.contains(MaterialState.hovered)) return hoverColor;
      return primary;
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return colorScheme.onSurface.withOpacity(0.38);
      }
      return colorScheme.onPrimary;
    }),
    overlayColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) {
        return colorScheme.onPrimary.withOpacity(0.08);
      }
      if (states.contains(MaterialState.hovered)) {
        return colorScheme.onPrimary.withOpacity(0.04);
      }
      return null;
    }),
  );
}

// ✅ STYLE DES BOUTONS OUTLINED — NORMAL (400)
ButtonStyle _buildOutlinedButtonStyle(ColorScheme colorScheme) {
  final primary = colorScheme.primary;
  final hoverBackground = primary.withOpacity(0.08);
  final pressedBackground = primary.withOpacity(0.12);
  final disabledColor = colorScheme.onSurface.withOpacity(0.12);

  return ButtonStyle(
    textStyle: MaterialStateProperty.all(
      const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400, // ✅ JAMAIS GRAS
      ),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    side: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return BorderSide(color: disabledColor);
      }
      return BorderSide(color: primary);
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return colorScheme.onSurface.withOpacity(0.38);
      }
      return primary;
    }),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) return Colors.transparent;
      if (states.contains(MaterialState.pressed)) return pressedBackground;
      if (states.contains(MaterialState.hovered)) return hoverBackground;
      return Colors.transparent;
    }),
    overlayColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) {
        return primary.withOpacity(0.14);
      }
      if (states.contains(MaterialState.hovered)) {
        return primary.withOpacity(0.08);
      }
      return null;
    }),
  );
}

// ✅ FONCTION DE TEINTE
Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}
