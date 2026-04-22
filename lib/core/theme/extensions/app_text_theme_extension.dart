import 'package:flutter/material.dart';

@immutable
class AppTextThemeExtension extends ThemeExtension<AppTextThemeExtension> {
  const AppTextThemeExtension({
    required this.heading,
    required this.subHeading,
    required this.body,
    required this.button,
  });

  final TextStyle? heading;
  final TextStyle? subHeading;
  final TextStyle? body;
  final TextStyle? button;

  @override
  AppTextThemeExtension copyWith({
    TextStyle? heading,
    TextStyle? subHeading,
    TextStyle? body,
    TextStyle? button,
  }) {
    return AppTextThemeExtension(
      heading: heading ?? this.heading,
      subHeading: subHeading ?? this.subHeading,
      body: body ?? this.body,
      button: button ?? this.button,
    );
  }

  @override
  AppTextThemeExtension lerp(ThemeExtension<AppTextThemeExtension>? other, double t) {
    if (other is! AppTextThemeExtension) {
      return this;
    }
    return AppTextThemeExtension(
      heading: TextStyle.lerp(heading, other.heading, t),
      subHeading: TextStyle.lerp(subHeading, other.subHeading, t),
      body: TextStyle.lerp(body, other.body, t),
      button: TextStyle.lerp(button, other.button, t),
    );
  }
}
