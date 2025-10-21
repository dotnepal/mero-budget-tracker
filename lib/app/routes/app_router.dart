import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/home_screen.dart';

/// Handles all routing logic for the application
class AppRouter {
  static const String home = '/';
  
  /// Generates routes for the application
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}