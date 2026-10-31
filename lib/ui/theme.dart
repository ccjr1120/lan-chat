import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App 与网页 CSS 使用同一套明暗视觉变量，所有资源离线可用。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.selfBubble,
    required this.otherBubble,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color primary;
  final Color background;
  final Color surface;
  final Color selfBubble;
  final Color otherBubble;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color success;
  final Color warning;
  final Color danger;

  static const light = AppColors(
    primary: Color(0xFF4F6FF0),
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    selfBubble: Color(0xFFEEF2FF),
    otherBubble: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF2B3544),
    textSecondary: Color(0xFF707A8C),
    divider: Color(0xFFEEF0F3),
    success: Color(0xFF16865C),
    warning: Color(0xFF9A6700),
    danger: Color(0xFFD92D20),
  );

  static const dark = AppColors(
    primary: Color(0xFF8BA4FF),
    background: Color(0xFF1A1F29),
    surface: Color(0xFF222834),
    selfBubble: Color(0xFF2D3A5C),
    otherBubble: Color(0xFF222834),
    textPrimary: Color(0xFFE6EAF2),
    textSecondary: Color(0xFFA4AFC0),
    divider: Color(0xFF2E3645),
    success: Color(0xFF5BD4A2),
    warning: Color(0xFFF4C66A),
    danger: Color(0xFFFF8A80),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? primary,
    Color? background,
    Color? surface,
    Color? selfBubble,
    Color? otherBubble,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? success,
    Color? warning,
    Color? danger,
  }) => AppColors(
    primary: primary ?? this.primary,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    selfBubble: selfBubble ?? this.selfBubble,
    otherBubble: otherBubble ?? this.otherBubble,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    divider: divider ?? this.divider,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      selfBubble: Color.lerp(selfBubble, other.selfBubble, t)!,
      otherBubble: Color.lerp(otherBubble, other.otherBubble, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final colors = dark ? AppColors.dark : AppColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.primary,
    brightness: brightness,
    onPrimary: dark ? colors.background : Colors.white,
    onError: dark ? colors.background : Colors.white,
    primary: colors.primary,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.divider,
    outlineVariant: colors.divider,
    error: colors.danger,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[colors],
    scaffoldBackgroundColor: colors.background,
    textTheme: base.textTheme
        .apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary)
        .copyWith(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.8,
            color: colors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: colors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: colors.textSecondary,
          ),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.divider),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 48),
        shape: buttonShape,
        side: BorderSide(color: colors.divider),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: buttonShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.background,
      hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.textPrimary,
      contentTextStyle: TextStyle(color: colors.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: colors.divider, space: 1),
  );
}
