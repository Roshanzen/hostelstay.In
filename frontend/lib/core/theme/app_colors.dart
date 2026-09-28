import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Terracotta / Burnt Orange Brand Palette
  static const Color primary = Color(0xFFC2410C); // Burnt orange
  static const Color primaryDark = Color(0xFFA73A00); // Deep rust
  static const Color primaryAccent = Color(0xFFEA580C); // Vibrant accent
  static const Color primaryLight = Color(0xFFFFF7ED); // Light orange tint
  static const Color primaryBorder = Color(0xFFFFEDD5);

  // Secondary & Accents
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE6F7ED);
  static const Color tealBg = Color(0xFFE6F7ED);
  static const Color tealText = Color(0xFF0D9488);

  static const Color orange = Color(0xFFEA580C);
  static const Color orangeBg = Color(0xFFFFF7ED);

  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color greenDark = Color(0xFF15803D);

  static const Color red = Color(0xFFDC2626);
  static const Color redLight = Color(0xFFFEE2E2);
  static const Color redBg = Color(0xFFFEE2E2);
  static const Color redAccent = Color(0xFFEF4444);

  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amberDark = Color(0xFFB45309);

  static const Color blue = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFFEFF6FF);
  static const Color blueBg = Color(0xFFEFF6FF);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFF3E8FF);

  static const Color slate = Color(0xFF334155);
  static const Color slateLight = Color(0xFFF1F5F9);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status Badges
  static const Color paidBg = Color(0xFFE6F7ED);
  static const Color paidText = Color(0xFF0D9488);
  static const Color overdueBg = Color(0xFFFEE2E2);
  static const Color overdueText = Color(0xFFDC2626);
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color pendingText = Color(0xFFD97706);
  static const Color vacantBg = Color(0xFFCCFBF1);
  static const Color vacantText = Color(0xFF0F766E);
  static const Color exitNoticeBg = Color(0xFFEEF2FF);
  static const Color exitNoticeText = Color(0xFF4F46E5);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkSurfaceSecondary = Color(0xFF0F172A);
  static const Color darkElevated = Color(0xFF273549);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF334155);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Dark Mode Tints & Status Badges
  static const Color darkPrimaryLight = Color(0xFF3B1D11);
  static const Color darkPrimaryBorder = Color(0xFF7C2D12);
  static const Color darkTealBg = Color(0xFF0D2E2B);
  static const Color darkTealText = Color(0xFF2DD4BF);
  static const Color darkOrangeBg = Color(0xFF3B1D11);
  static const Color darkOrangeText = Color(0xFFFB923C);
  static const Color darkRedBg = Color(0xFF3B1219);
  static const Color darkRedText = Color(0xFFF87171);
  static const Color darkPendingBg = Color(0xFF3B280C);
  static const Color darkPendingText = Color(0xFFFBBF24);
  static const Color darkIndigoBg = Color(0xFF1E1B4B);
  static const Color darkIndigoText = Color(0xFF818CF8);
  static const Color darkPurpleBg = Color(0xFF2E1065);
  static const Color darkPurpleText = Color(0xFFC084FC);
}

extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;
  Color get surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get cardColor =>
      isDarkMode ? AppColors.darkCard : AppColors.surface;
  Color get surfaceSecondaryColor =>
      isDarkMode ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary;
  Color get elevatedSurfaceColor =>
      isDarkMode ? AppColors.darkElevated : AppColors.surfaceSecondary;
  Color get borderColor =>
      isDarkMode ? AppColors.darkBorder : AppColors.cardBorder;
  Color get dividerColor =>
      isDarkMode ? AppColors.darkDivider : AppColors.divider;

  Color get textPrimaryColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondaryColor =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textMutedColor =>
      isDarkMode ? AppColors.darkTextMuted : AppColors.textMuted;

  Color get primaryTintColor =>
      isDarkMode ? AppColors.darkPrimaryLight : AppColors.primaryLight;
  Color get primaryBorderTintColor =>
      isDarkMode ? AppColors.darkPrimaryBorder : AppColors.primaryBorder;
  Color get tealTintColor =>
      isDarkMode ? AppColors.darkTealBg : AppColors.tealBg;
  Color get tealFgColor =>
      isDarkMode ? AppColors.darkTealText : AppColors.tealText;
  Color get orangeTintColor =>
      isDarkMode ? AppColors.darkOrangeBg : AppColors.orangeBg;
  Color get orangeFgColor =>
      isDarkMode ? AppColors.darkOrangeText : AppColors.orange;
  Color get redTintColor =>
      isDarkMode ? AppColors.darkRedBg : AppColors.redBg;
  Color get redFgColor =>
      isDarkMode ? AppColors.darkRedText : AppColors.red;
  Color get pendingTintColor =>
      isDarkMode ? AppColors.darkPendingBg : AppColors.pendingBg;
  Color get pendingFgColor =>
      isDarkMode ? AppColors.darkPendingText : AppColors.pendingText;
  Color get indigoTintColor =>
      isDarkMode ? AppColors.darkIndigoBg : AppColors.exitNoticeBg;
  Color get indigoFgColor =>
      isDarkMode ? AppColors.darkIndigoText : AppColors.exitNoticeText;
  Color get purpleTintColor =>
      isDarkMode ? AppColors.darkPurpleBg : AppColors.purpleLight;
  Color get purpleFgColor =>
      isDarkMode ? AppColors.darkPurpleText : AppColors.purple;

  List<BoxShadow> get cardShadow => isDarkMode
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ];
}


