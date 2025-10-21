import 'package:flutter/material.dart';
import '../../features/transaction/presentation/pages/home_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';

class AppRouter {
  static const String home = '/';
  static const String statistics = '/statistics';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case statistics:
        return MaterialPageRoute(
          builder: (_) => const StatisticsPage(),
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

  // Private constructor to prevent instantiation
  AppRouter._();
}
