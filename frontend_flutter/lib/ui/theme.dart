import 'package:flutter/material.dart';

/// How the app is coloured, which is not how a score is.
///
/// A score is black on white, or as near as makes no difference the other way
/// round on a dark page, and it carries those two colours itself — see
/// `SheetPalette`. This is the chrome around it.
ThemeData appTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B5BA5),
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}
