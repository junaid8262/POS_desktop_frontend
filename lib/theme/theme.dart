import 'package:flutter/material.dart';

class AppTheme {
  // Define primary colors
  static const Color primaryColor = Color(0xFF4A90E2); // A soft blue
  //static const Color primaryColor = Color(0xFF26a59a); // teal green
  static const Color primaryColorLight = Color(0xFFB3C6E0); // Light blue
  static const Color primaryColorDark = Color(0xFF003C71); // Dark blue
  static const Color secondaryColor = Color(0xFF50E3C2); // Soft green
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light gray
  static const Color textColor = Color(0xFF333333); // Dark gray
  static const Color errorColor = Color(0xFFDC3D3D); // Modern red
  // Define text styles
  static const TextStyle headline1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle headline6 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    color: Colors.white,
  );

  // Define button styles
  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    textStyle: button,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  );

  // Define input decoration
  static InputDecoration inputDecoration(String labelText) {
    return InputDecoration(
      border: OutlineInputBorder(),
      labelText: labelText,
      labelStyle: TextStyle(color: textColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
    );
  }

  // Define the overall theme
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: secondaryColor,
        error: errorColor,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
        labelStyle: TextStyle(color: textColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
