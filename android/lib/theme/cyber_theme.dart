import 'package:flutter/material.dart';

class CyberTheme {
  // ── Core palette ──────────────────────────────────────────
  static const Color bg = Color(0xFF0A0A0F);
  static const Color bgTerminal = Color(0xFF0D0D14);
  static const Color bgCard = Color(0xFF12121A);
  static const Color bgCardHover = Color(0xFF1A1A25);

  static const Color neonCyan = Color(0xFF00FFCC);
  static const Color neonPink = Color(0xFFFF0080);
  static const Color neonPurple = Color(0xFFBB00FF);
  static const Color neonYellow = Color(0xFFFFE600);
  static const Color neonBlue = Color(0xFF00AAFF);

  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF7A7A8A);
  static const Color textDim = Color(0xFF4A4A5A);
  static const Color textTerminal = Color(0xFF00FFCC);

  static const Color border = Color(0xFF2A2A3A);
  static const Color borderActive = Color(0xFF00FFCC);

  static const Color error = Color(0xFFFF3355);
  static const Color success = Color(0xFF00FF88);

  static const Color scanline = Color(0x0800FFCC);

  // ── Text styles ───────────────────────────────────────────
  static const String fontFamily = 'JetBrainsMono';

  static TextStyle terminalText({
    double size = 14,
    Color color = textTerminal,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.5,
      height: 1.4,
    );
  }

  static TextStyle headerText({double size = 18}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      color: neonCyan,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
      shadows: [
        Shadow(color: neonCyan.withOpacity(0.5), blurRadius: 8),
        Shadow(color: neonCyan.withOpacity(0.3), blurRadius: 16),
      ],
    );
  }

  static TextStyle labelText({Color color = textSecondary}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      color: color,
      letterSpacing: 1.2,
    );
  }

  // ── Decorations ───────────────────────────────────────────
  static BoxDecoration cardDecoration({bool active = false}) {
    return BoxDecoration(
      color: active ? bgCardHover : bgCard,
      border: Border.all(
        color: active ? borderActive : border,
        width: active ? 1.0 : 0.5,
      ),
      borderRadius: BorderRadius.circular(2),
      boxShadow: active
          ? [
              BoxShadow(
                color: neonCyan.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration terminalDecoration() {
    return BoxDecoration(
      color: bgTerminal,
      border: Border.all(color: border, width: 0.5),
      borderRadius: BorderRadius.circular(2),
    );
  }

  static InputDecoration searchInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: terminalText(color: textDim, size: 13),
      prefixIcon: const Icon(Icons.search, color: neonCyan, size: 18),
      prefixText: '> ',
      prefixStyle: terminalText(color: neonCyan, size: 13),
      filled: true,
      fillColor: bgTerminal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: neonCyan, width: 1),
      ),
    );
  }

  // ── ThemeData ─────────────────────────────────────────────
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: bgCard,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        titleTextStyle: headerText(size: 16),
        iconTheme: const IconThemeData(color: neonCyan),
      ),
      iconTheme: const IconThemeData(color: neonCyan, size: 20),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonCyan,
        inactiveTrackColor: border,
        thumbColor: neonCyan,
        overlayColor: neonCyan.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 2,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: neonCyan,
        unselectedItemColor: textDim,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
