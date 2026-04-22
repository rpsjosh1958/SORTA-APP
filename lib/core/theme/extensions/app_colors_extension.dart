import 'package:flutter/material.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.success,
    required this.danger,
    required this.border,
    required this.shadow,
  });

  final Color? primary;
  final Color? secondary;
  final Color? accent;
  final Color? background;
  final Color? surface;
  final Color? onSurface;
  final Color? success;
  final Color? danger;
  final Color? border;
  final Color? shadow;

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? success,
    Color? danger,
    Color? border,
    Color? shadow,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t),
      secondary: Color.lerp(secondary, other.secondary, t),
      accent: Color.lerp(accent, other.accent, t),
      background: Color.lerp(background, other.background, t),
      surface: Color.lerp(surface, other.surface, t),
      onSurface: Color.lerp(onSurface, other.onSurface, t),
      success: Color.lerp(success, other.success, t),
      danger: Color.lerp(danger, other.danger, t),
      border: Color.lerp(border, other.border, t),
      shadow: Color.lerp(shadow, other.shadow, t),
    );
  }
}
