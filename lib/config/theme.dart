import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  APP COLOR TOKENS
//  All colors live here. To change any color app-wide, edit this file only.
// ═════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF6C63FF);
  static const Color primaryLight   = Color(0xFF9D97FF);
  static const Color primaryDark    = Color(0xFF4B44CC);
  static const Color secondary      = Color(0xFF00BFA6);
  static const Color secondaryLight = Color(0xFF4DD9C9);
  static const Color secondaryDark  = Color(0xFF008C79);
  static const Color error          = Color(0xFFE53935);
  static const Color errorLight     = Color(0xFFFF6F68);
  static const Color errorDark      = Color(0xFFB71C1C);

  // ── Scaffold / Surface ─────────────────────────────────────────────────────
  static const Color scaffoldLight  = Color(0xFFF8F9FA);
  static const Color scaffoldDark   = Color(0xFF1E1E2C);

  static const Color surfaceLight   = Color(0xFFFFFFFF);
  static const Color surfaceDark    = Color(0xFF272736);

  static const Color surfaceVariantLight = Color(0xFFEEEFF3);
  static const Color surfaceVariantDark  = Color(0xFF2E2E40);

  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color cardDark       = Color(0xFF2A2A3C);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textDisabledLight  = Color(0xFFB0B7C3);

  static const Color textPrimaryDark    = Color(0xFFF1F1F5);
  static const Color textSecondaryDark  = Color(0xFF9CA3AF);
  static const Color textDisabledDark   = Color(0xFF4B5563);

  // ── Divider / Outline ─────────────────────────────────────────────────────
  static const Color outlineLight   = Color(0xFFE5E7EB);
  static const Color outlineDark    = Color(0xFF374151);

  // ── Icon tints (used for profile tiles, stat icons, etc.) ─────────────────
  static const Color iconPurple  = Color(0xFF6C63FF);   // primary
  static const Color iconTeal    = Color(0xFF00BFA6);   // secondary
  static const Color iconBlue    = Color(0xFF3B82F6);
  static const Color iconGreen   = Color(0xFF22C55E);
  static const Color iconYellow  = Color(0xFFF59E0B);
  static const Color iconPink    = Color(0xFFEC4899);
  static const Color iconOrange  = Color(0xFFF97316);
  static const Color iconRed     = Color(0xFFE53935);
  static const Color iconCyan    = Color(0xFF06B6D4);
  static const Color iconSlate   = Color(0xFF64748B);
  static const Color iconIndigo  = Color(0xFF6366F1);

  // ── Dashboard: Header gradient ────────────────────────────────────────────
  /// Light-mode header: rich violet → teal
  static const Color dashHeaderGradientStartLight = Color(0xFF6C63FF);
  static const Color dashHeaderGradientEndLight   = Color(0xFF00BFA6);

  /// Dark-mode header: deeper violet → deep teal
  static const Color dashHeaderGradientStartDark  = Color(0xFF4B44CC);
  static const Color dashHeaderGradientEndDark    = Color(0xFF007A6A);

  // ── Dashboard: Stat card backgrounds ──────────────────────────────────────
  static const Color dashStatCard1Light = Color(0xFFEDE9FF); // soft purple
  static const Color dashStatCard2Light = Color(0xFFD1FAF5); // soft teal
  static const Color dashStatCard3Light = Color(0xFFFFEDD5); // soft orange
  static const Color dashStatCard4Light = Color(0xFFDCFCE7); // soft green

  static const Color dashStatCard1Dark  = Color(0xFF2C2848);
  static const Color dashStatCard2Dark  = Color(0xFF1A3330);
  static const Color dashStatCard3Dark  = Color(0xFF3A2A18);
  static const Color dashStatCard4Dark  = Color(0xFF162618);

  // ── Dashboard: Stat icon foregrounds ──────────────────────────────────────
  static const Color dashStatIcon1 = Color(0xFF6C63FF);
  static const Color dashStatIcon2 = Color(0xFF00BFA6);
  static const Color dashStatIcon3 = Color(0xFFF97316);
  static const Color dashStatIcon4 = Color(0xFF22C55E);

  // ── Dashboard: Action/quick-access tiles ──────────────────────────────────
  static const Color dashActionBgLight = Color(0xFFFFFFFF);
  static const Color dashActionBgDark  = Color(0xFF2A2A3C);

  // ── Online indicator ──────────────────────────────────────────────────────
  static const Color onlineGreen = Color(0xFF22C55E);
}

// ═════════════════════════════════════════════════════════════════════════════
//  THEME EXTENSION  — exposes custom tokens via Theme.of(context).extension
// ═════════════════════════════════════════════════════════════════════════════

class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,

    // Surface
    required this.card,
    required this.surfaceVariant,
    required this.outline,

    // Dashboard header
    required this.dashHeaderStart,
    required this.dashHeaderEnd,

    // Dashboard stat cards
    required this.dashStatCard1,
    required this.dashStatCard2,
    required this.dashStatCard3,
    required this.dashStatCard4,

    // Dashboard action tiles
    required this.dashActionBg,

    // Misc
    required this.onlineIndicator,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color card;
  final Color surfaceVariant;
  final Color outline;

  final Color dashHeaderStart;
  final Color dashHeaderEnd;

  final Color dashStatCard1;
  final Color dashStatCard2;
  final Color dashStatCard3;
  final Color dashStatCard4;

  final Color dashActionBg;
  final Color onlineIndicator;

  // ── Light preset ────────────────────────────────────────────────────────
  static const AppColorExtension light = AppColorExtension(
    textPrimary:    AppColors.textPrimaryLight,
    textSecondary:  AppColors.textSecondaryLight,
    textDisabled:   AppColors.textDisabledLight,

    card:           AppColors.cardLight,
    surfaceVariant: AppColors.surfaceVariantLight,
    outline:        AppColors.outlineLight,

    dashHeaderStart: AppColors.dashHeaderGradientStartLight,
    dashHeaderEnd:   AppColors.dashHeaderGradientEndLight,

    dashStatCard1: AppColors.dashStatCard1Light,
    dashStatCard2: AppColors.dashStatCard2Light,
    dashStatCard3: AppColors.dashStatCard3Light,
    dashStatCard4: AppColors.dashStatCard4Light,

    dashActionBg:    AppColors.dashActionBgLight,
    onlineIndicator: AppColors.onlineGreen,
  );

  // ── Dark preset ─────────────────────────────────────────────────────────
  static const AppColorExtension dark = AppColorExtension(
    textPrimary:    AppColors.textPrimaryDark,
    textSecondary:  AppColors.textSecondaryDark,
    textDisabled:   AppColors.textDisabledDark,

    card:           AppColors.cardDark,
    surfaceVariant: AppColors.surfaceVariantDark,
    outline:        AppColors.outlineDark,

    dashHeaderStart: AppColors.dashHeaderGradientStartDark,
    dashHeaderEnd:   AppColors.dashHeaderGradientEndDark,

    dashStatCard1: AppColors.dashStatCard1Dark,
    dashStatCard2: AppColors.dashStatCard2Dark,
    dashStatCard3: AppColors.dashStatCard3Dark,
    dashStatCard4: AppColors.dashStatCard4Dark,

    dashActionBg:    AppColors.dashActionBgDark,
    onlineIndicator: AppColors.onlineGreen,
  );

  @override
  AppColorExtension copyWith({
    Color? textPrimary, Color? textSecondary, Color? textDisabled,
    Color? card, Color? surfaceVariant, Color? outline,
    Color? dashHeaderStart, Color? dashHeaderEnd,
    Color? dashStatCard1, Color? dashStatCard2,
    Color? dashStatCard3, Color? dashStatCard4,
    Color? dashActionBg, Color? onlineIndicator,
  }) {
    return AppColorExtension(
      textPrimary:     textPrimary    ?? this.textPrimary,
      textSecondary:   textSecondary  ?? this.textSecondary,
      textDisabled:    textDisabled   ?? this.textDisabled,
      card:            card           ?? this.card,
      surfaceVariant:  surfaceVariant ?? this.surfaceVariant,
      outline:         outline        ?? this.outline,
      dashHeaderStart: dashHeaderStart ?? this.dashHeaderStart,
      dashHeaderEnd:   dashHeaderEnd   ?? this.dashHeaderEnd,
      dashStatCard1:   dashStatCard1  ?? this.dashStatCard1,
      dashStatCard2:   dashStatCard2  ?? this.dashStatCard2,
      dashStatCard3:   dashStatCard3  ?? this.dashStatCard3,
      dashStatCard4:   dashStatCard4  ?? this.dashStatCard4,
      dashActionBg:    dashActionBg   ?? this.dashActionBg,
      onlineIndicator: onlineIndicator ?? this.onlineIndicator,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      textPrimary:     Color.lerp(textPrimary,     other.textPrimary,     t)!,
      textSecondary:   Color.lerp(textSecondary,   other.textSecondary,   t)!,
      textDisabled:    Color.lerp(textDisabled,     other.textDisabled,    t)!,
      card:            Color.lerp(card,            other.card,            t)!,
      surfaceVariant:  Color.lerp(surfaceVariant,  other.surfaceVariant,  t)!,
      outline:         Color.lerp(outline,         other.outline,         t)!,
      dashHeaderStart: Color.lerp(dashHeaderStart, other.dashHeaderStart, t)!,
      dashHeaderEnd:   Color.lerp(dashHeaderEnd,   other.dashHeaderEnd,   t)!,
      dashStatCard1:   Color.lerp(dashStatCard1,   other.dashStatCard1,   t)!,
      dashStatCard2:   Color.lerp(dashStatCard2,   other.dashStatCard2,   t)!,
      dashStatCard3:   Color.lerp(dashStatCard3,   other.dashStatCard3,   t)!,
      dashStatCard4:   Color.lerp(dashStatCard4,   other.dashStatCard4,   t)!,
      dashActionBg:    Color.lerp(dashActionBg,    other.dashActionBg,    t)!,
      onlineIndicator: Color.lerp(onlineIndicator, other.onlineIndicator, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Convenience extension so you can write:
//    context.appColors.dashHeaderStart
//  instead of:
//    Theme.of(context).extension<AppColorExtension>()!.dashHeaderStart
// ─────────────────────────────────────────────────────────────────────────────
extension AppColorContext on BuildContext {
  AppColorExtension get appColors =>
      Theme.of(this).extension<AppColorExtension>()!;
}

// ═════════════════════════════════════════════════════════════════════════════
//  APP THEME
// ═════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Light ────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary:          AppColors.primary,
        onPrimary:        Colors.white,
        primaryContainer: AppColors.primaryLight.withValues(alpha: 0.2),
        secondary:        AppColors.secondary,
        onSecondary:      Colors.white,
        tertiary:         AppColors.secondary,
        error:            AppColors.error,
        surface:          AppColors.surfaceLight,
        onSurface:        AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        surfaceContainerLow:     AppColors.surfaceLight,
        surfaceContainerHighest: AppColors.surfaceVariantLight,
        outline:          AppColors.outlineLight,
        outlineVariant:   AppColors.outlineLight,
      ),
      extensions: const [AppColorExtension.light],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:     AppColors.textPrimaryLight,
        displayColor:  AppColors.textPrimaryLight,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondaryLight);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.outlineLight.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineLight, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineLight,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondaryLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondaryLight),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Dark ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary:          AppColors.primary,
        onPrimary:        Colors.white,
        primaryContainer: AppColors.primaryDark.withValues(alpha: 0.35),
        secondary:        AppColors.secondary,
        onSecondary:      Colors.white,
        tertiary:         AppColors.secondary,
        error:            AppColors.errorLight,
        surface:          AppColors.surfaceDark,
        onSurface:        AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        surfaceContainerLow:     AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        outline:          AppColors.outlineDark,
        outlineVariant:   AppColors.outlineDark,
      ),
      extensions: const [AppColorExtension.dark],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight);
          }
          return const IconThemeData(color: AppColors.textSecondaryDark);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.primaryLight),
          foregroundColor: AppColors.primaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.outlineDark.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineDark, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineDark,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondaryDark,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: AppColors.primary.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimaryDark, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}