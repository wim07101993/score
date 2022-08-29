import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = Colors.pink;
const secondaryColor = Colors.deepPurple;

final lightColorScheme = ColorScheme(
  primary: primaryColor,
  primaryContainer: primaryColor[900],
  secondary: secondaryColor,
  secondaryContainer: secondaryColor[900],
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

final textTheme = TextTheme(
  headline1: GoogleFonts.merriweather(
      fontSize: 92, fontWeight: FontWeight.w300, letterSpacing: -1.5),
  headline2: GoogleFonts.merriweather(
      fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -0.5),
  headline3:
      GoogleFonts.merriweather(fontSize: 46, fontWeight: FontWeight.w400),
  headline4: GoogleFonts.merriweather(
      fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  headline5:
      GoogleFonts.merriweather(fontSize: 23, fontWeight: FontWeight.w400),
  headline6: GoogleFonts.merriweather(
      fontSize: 19, fontWeight: FontWeight.w500, letterSpacing: 0.15),
  subtitle1: GoogleFonts.merriweather(
      fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.15),
  subtitle2: GoogleFonts.merriweather(
      fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.1),
  bodyText1: GoogleFonts.roboto(
      fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
  bodyText2: GoogleFonts.roboto(
      fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
  button: GoogleFonts.roboto(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
  caption: GoogleFonts.roboto(
      fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
  overline: GoogleFonts.roboto(
      fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
);

final lightTheme = ThemeData(
  colorScheme: lightColorScheme,
  toggleableActiveColor: primaryColor[400],
  appBarTheme: AppBarTheme(
    toolbarHeight: 96,
    foregroundColor: lightColorScheme.onPrimary,
    backgroundColor: lightColorScheme.primary,
    titleTextStyle: textTheme.headline4,
    actionsIconTheme: IconThemeData(
      color: lightColorScheme.onPrimary,
      size: 32,
    ),
    iconTheme: IconThemeData(
      color: lightColorScheme.onPrimary,
      size: 32,
    ),
  ),
);
