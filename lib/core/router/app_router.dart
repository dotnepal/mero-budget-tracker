import 'package:flutter/material.dart';
import '../../features/category/presentation/pages/category_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transaction/presentation/pages/home_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/settings/presentation/pages/database_settings_page.dart';
import '../../features/budget/presentation/pages/budget_status_page.dart';
import '../../features/budget/presentation/pages/budget_form_page.dart';

class AppRouter {
  static const String home = '/';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String categorySettings = '/settings/categories';
  static const String databaseSettings = '/settings/database';
  static const String budget = '/budget';
  static const String budgetNew = '/budget/new';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case statistics:
        return MaterialPageRoute(
          builder: (_) => const StatisticsPage(),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        );
      case categorySettings:
        return MaterialPageRoute(
          builder: (_) => const CategorySettingsPage(),
        );
      case databaseSettings:
        return MaterialPageRoute(
          builder: (_) => const DatabaseSettingsPage(),
        );
      case budget:
        return MaterialPageRoute(
          builder: (_) => const BudgetStatusPage(),
        );
      case budgetNew:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BudgetFormPage(
            initialMonth: args?['month'] as int?,
            initialYear: args?['year'] as int?,
            initialIncomeCents: args?['incomeCents'] as int?,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }

  // Private constructor to prevent instantiation
  AppRouter._();
}