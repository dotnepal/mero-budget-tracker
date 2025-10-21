import 'package:flutter/material.dart';

/// Extension methods for [BuildContext]
extension BuildContextX on BuildContext {
  /// Gets the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Gets the current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Gets the current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Gets the screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Shows a snackbar with the given message
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}