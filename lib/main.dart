import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_service.dart';
import 'features/category/presentation/bloc/category_bloc.dart';
import 'features/category/presentation/bloc/category_event.dart';
import 'features/category/data/repositories/sqlite_category_repository.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/data/repositories/sqlite_transaction_repository.dart';
import 'features/statistics/presentation/bloc/statistics_bloc.dart';
import 'features/statistics/data/repositories/statistics_repository_impl.dart';
import 'features/home/presentation/bloc/summary_bloc.dart';
import 'features/home/data/repositories/summary_repository_impl.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';

class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionRepository = SqliteTransactionRepository();
    final categoryRepository = SqliteCategoryRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SettingsBloc()..add(const LoadSettings()),
        ),
        BlocProvider(
          create: (context) => CategoryBloc(
            repository: categoryRepository,
          )..add(const LoadCategories()),
        ),
        BlocProvider(
          create: (context) => TransactionBloc(
            repository: transactionRepository,
          )..add(const LoadTransactions()),
        ),
        BlocProvider(
          create: (context) => StatisticsBloc(
            repository: StatisticsRepositoryImpl(
              transactionRepository: transactionRepository,
            ),
          ),
        ),
        BlocProvider(
          create: (context) => SummaryBloc(
            repository: SummaryRepositoryImpl(
              transactionRepository: transactionRepository,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mero Budget Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        scrollBehavior: _NoOverscrollBehavior(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
