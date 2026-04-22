import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_palette.dart';
import 'app_typography.dart';
import 'extensions/app_colors_extension.dart';
import 'extensions/app_text_theme_extension.dart';

final appThemeProvider = NotifierProvider<AppThemeNotifier, ThemeMode>(() {
  return AppThemeNotifier();
});

class AppThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppPalette.softGrey,
        extensions: [
          const AppColorsExtension(
            primary: AppPalette.yellow,
            secondary: AppPalette.cyan,
            accent: AppPalette.pink,
            background: AppPalette.softGrey,
            surface: AppPalette.white,
            onSurface: AppPalette.black,
            success: AppPalette.green,
            danger: AppPalette.red,
            border: AppPalette.black,
            shadow: AppPalette.black,
          ),
          AppTextThemeExtension(
            heading: AppTypography.chunkyHeading,
            subHeading: AppTypography.chunkySubHeading,
            body: AppTypography.bodyBold,
            button: AppTypography.buttonText,
          ),
        ],
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppPalette.black,
        extensions: [
          const AppColorsExtension(
            primary: AppPalette.yellow,
            secondary: AppPalette.cyan,
            accent: AppPalette.pink,
            background: AppPalette.black,
            surface: Color(0xFF1A1A1A),
            onSurface: AppPalette.white,
            success: AppPalette.green,
            danger: AppPalette.red,
            border: AppPalette.white,
            shadow: AppPalette.white,
          ),
          AppTextThemeExtension(
            heading: AppTypography.chunkyHeading.copyWith(color: AppPalette.white),
            subHeading: AppTypography.chunkySubHeading.copyWith(color: AppPalette.white),
            body: AppTypography.bodyBold.copyWith(color: AppPalette.white),
            button: AppTypography.buttonText.copyWith(color: AppPalette.black),
          ),
        ],
      );
}

extension AppThemeExtension on ThemeData {
  AppColorsExtension get appColors => extension<AppColorsExtension>()!;
  AppTextThemeExtension get appTextTheme => extension<AppTextThemeExtension>()!;
}
