import 'package:flutter/material.dart';

final lightColorScheme = ColorScheme(
  primary: Colors.pink,
  primaryVariant: Colors.pink[900]!,
  secondary: Colors.deepPurple,
  secondaryVariant: Colors.deepPurple[900]!,
  surface: Colors.grey[350]!,
  background: Colors.grey[200]!,
  error: Colors.red[900]!,
  onPrimary: Colors.grey[200]!,
  onSecondary: Colors.grey[300]!,
  onSurface: Colors.grey[900]!,
  onBackground: Colors.grey[900]!,
  onError: Colors.grey[300]!,
  brightness: Brightness.light,
);

final lightTheme = ThemeData(
  colorScheme: lightColorScheme,
  appBarTheme: AppBarTheme(
    foregroundColor: lightColorScheme.onPrimary,
    backgroundColor: lightColorScheme.primary,
  ),
);
