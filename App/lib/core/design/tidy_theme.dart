import 'package:flutter/material.dart';

import 'tidy_colors.dart';
import 'tidy_radii.dart';
import 'tidy_spacing.dart';

abstract final class TidyTheme {
  static ThemeData get light {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: TidyColors.primary,
      onPrimary: Colors.white,
      secondary: TidyColors.emerald,
      onSecondary: TidyColors.primaryText,
      error: TidyColors.destructive,
      onError: Colors.white,
      surface: TidyColors.surface,
      onSurface: TidyColors.primaryText,
      outline: TidyColors.divider,
    );

    final TextTheme textTheme = Typography.material2021().black
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 48,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -1.2,
          ),
          headlineLarge: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.8,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            height: 1.55,
            letterSpacing: 0,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            height: 1.45,
            letterSpacing: 0,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelSmall: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
            letterSpacing: 0,
          ),
        )
        .apply(
          bodyColor: TidyColors.primaryText,
          displayColor: TidyColors.primaryText,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TidyColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: TidyColors.background,
        foregroundColor: TidyColors.primaryText,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 51,
        backgroundColor: TidyColors.background,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          return IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? TidyColors.primary
                : TidyColors.secondaryText,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          return TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: states.contains(WidgetState.selected)
                ? TidyColors.primary
                : TidyColors.secondaryText,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: TidySpacing.lg,
            vertical: TidySpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TidyRadii.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerColor: TidyColors.divider,
    );
  }
}
