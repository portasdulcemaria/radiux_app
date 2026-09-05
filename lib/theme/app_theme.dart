import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const Color bg = Color(0xFF08080F);
  static const Color surface = Color(0xFF10101E);
  static const Color card = Color(0xFF161626);
  static const Color cardHover = Color(0xFF1E1E32);

  // Borders
  static const Color border = Color(0xFF252540);
  static const Color borderActive = Color(0xFF5C5CFF);

  // Primary — Indigo
  static const Color primary = Color(0xFF5C5CFF);
  static const Color primaryLight = Color(0xFF7B7BFF);
  static const Color primaryDark = Color(0xFF3A3AD4);
  static const Color primaryGlow = Color(0x335C5CFF);

  // Accent — Teal
  static const Color accent = Color(0xFF0AB9A0);
  static const Color accentLight = Color(0xFF16D4BA);
  static const Color accentGlow = Color(0x330AB9A0);

  // State
  static const Color error = Color(0xFFFF4C6B);
  static const Color errorGlow = Color(0x33FF4C6B);
  static const Color success = Color(0xFF00D97E);
  static const Color warning = Color(0xFFFFAD0D);

  // Text
  static const Color textPrimary = Color(0xFFEEEEFF);
  static const Color textSecondary = Color(0xFF9B9BC0); // elevado para AA en ambiente tenue
  static const Color textMuted = Color(0xFF626288);     // 3.52:1 on surface — solo para texto ≥14px
  static const Color textDisabled = Color(0xFF3A3A58);  // hints/placeholders — intencionalmente bajo
  static const Color textInverse = Color(0xFF08080F);

  // Color aliases para uso como texto (contraste garantizado ≥4.5:1 sobre surface/card)
  static const Color primaryText = Color(0xFF8080FF);   // primaryLight más brillante: 4.8:1 on surface
  static const Color accentText  = Color(0xFF16D4BA);   // accentLight: 4.96:1 on surface
  static const Color errorText   = Color(0xFFFF7A92);   // error más claro: 4.5:1 on surface

  // Critical state (zona de decisión clínica — más presencia que warning)
  static const Color critical = Color(0xFFFF8C42);   // naranja cálido — paleta interna
  static const Color criticalText = Color(0xFFFFAA70);

  // Isotope pill colors
  static const Color tcColor = Color(0xFF4EAEF5);
  static const Color iColor = Color(0xFFF59A2E);
  static const Color gaColor = Color(0xFF8E6EFF);
  static const Color luColor = Color(0xFF4EF5B9);
  static const Color f18Color = Color(0xFFFF6B8A);
  static const Color tl201Color = Color(0xFF82D9FF);
}

// ── Spacing scale ─────────────────────────────────────────────────────────────
// Base 4pt. Usar siempre estos valores — nunca hardcodear spacing.
abstract class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double base = 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Padding de pantalla — margen lateral consistente en todas las screens
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets screenPaddingFull = EdgeInsets.fromLTRB(20, 20, 20, 40);
}

// ── Radius scale ──────────────────────────────────────────────────────────────
// Jerarquía de redondeo — los elementos más grandes tienen mayor radius.
abstract class AppRadius {
  static const double xs  = 6;   // badges, chips pequeños
  static const double sm  = 8;   // pills, tags
  static const double md  = 12;  // inputs, botones secundarios
  static const double base = 14; // chips de unidad, filas picker
  static const double lg  = 16;  // cards principales
  static const double xl  = 20;  // sheets, result cards
  static const double full = 999; // completamente redondeado (dots, avatars)
}

// ── Elevation / shadow system ─────────────────────────────────────────────────
// Tres niveles: resting, raised, floating. Nunca inventar shadows fuera de esto.
abstract class AppElevation {
  // Resting — elementos en reposo sobre el fondo
  static List<BoxShadow> get resting => [
    BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  // Raised — cards, componentes interactivos
  static List<BoxShadow> get raised => [
    BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 16, offset: const Offset(0, 4)),
  ];
  // Floating — sheets, modals, tooltips
  static List<BoxShadow> get floating => [
    BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 24, offset: const Offset(0, 8)),
  ];
  // Glow — elementos activos con color propio
  static List<BoxShadow> glow(Color color, {double intensity = 0.30}) => [
    BoxShadow(color: color.withOpacity(intensity), blurRadius: 20, offset: const Offset(0, 6)),
    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}

// ── State system ──────────────────────────────────────────────────────────────
// Estados clínicos — jerarquía visual por urgencia de decisión.
// ok → attention → critical — en ese orden de peso visual.
abstract class AppState {
  // OK — margen cómodo, sin acción requerida
  static const Color ok      = AppColors.success;
  static const Color okText  = AppColors.success;

  // Attention — margen intermedio, monitorear
  static const Color attention     = AppColors.warning;
  static const Color attentionText = AppColors.warning;

  // Critical — zona de decisión, acción requerida
  static const Color critical     = AppColors.critical;
  static const Color criticalText = AppColors.criticalText;

  // Error — falla técnica del sistema (no clínica)
  static const Color error     = AppColors.error;
  static const Color errorText = AppColors.errorText;

  // Badge visual por estado — color de fondo, borde y texto
  static Color badgeBg(Color stateColor) => stateColor.withOpacity(0.12);
  static Color badgeBorder(Color stateColor) => stateColor.withOpacity(0.30);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -1.5,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryText,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
        scrimColor: Color(0xCC08080F),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.card,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primaryGlow,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
