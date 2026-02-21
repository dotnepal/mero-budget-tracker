import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/database/database_service.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/category/presentation/bloc/category_bloc.dart';
import 'features/category/presentation/bloc/category_event.dart';
import 'features/category/data/repositories/sqlite_category_repository.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/data/repositories/sqlite_transaction_repository.dart';
import 'features/transaction/presentation/pages/home_page.dart';
import 'features/statistics/presentation/bloc/statistics_bloc.dart';
import 'features/statistics/data/repositories/statistics_repository_impl.dart';
import 'features/home/presentation/bloc/summary_bloc.dart';
import 'features/home/data/repositories/summary_repository_impl.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    final authRepository = FirebaseAuthRepository();
    final transactionRepository = SqliteTransactionRepository();
    final categoryRepository = SqliteCategoryRepository();

    return BlocProvider<AuthBloc>(
      create: (_) =>
          AuthBloc(authRepository: authRepository)..add(const AuthStarted()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          // Wipe local transactions when user signs out
          if (state is AuthUnauthenticated) {
            await databaseService.clearTransactions();
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final userId = state.user.uid;

            // Feature blocs are above MaterialApp so all pushed routes
            // (statistics, settings, etc.) can access them.
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => CategoryBloc(
                    repository: categoryRepository,
                  )..add(const LoadCategories()),
                ),
                BlocProvider(
                  create: (_) => TransactionBloc(
                    repository: transactionRepository,
                    userId: userId,
                  )..add(const LoadTransactions()),
                ),
                BlocProvider(
                  create: (_) => StatisticsBloc(
                    repository: StatisticsRepositoryImpl(
                      transactionRepository: transactionRepository,
                    ),
                    userId: userId,
                  ),
                ),
                BlocProvider(
                  create: (_) => SummaryBloc(
                    repository: SummaryRepositoryImpl(
                      transactionRepository: transactionRepository,
                    ),
                    userId: userId,
                  ),
                ),
                BlocProvider(
                  create: (_) => SettingsBloc(
                    SettingsRepositoryImpl(DatabaseHelper.instance),
                  )..add(const LoadSettings()),
                ),
              ],
              child: MaterialApp(
                title: 'Mero Budget Tracker',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                onGenerateRoute: AppRouter.onGenerateRoute,
                home: const HomePage(),
                debugShowCheckedModeBanner: false,
              ),
            );
          }

          // AuthInitial / AuthLoading → splash; AuthUnauthenticated → login
          final isLoading =
              state is AuthInitial || state is AuthLoading;

          return MaterialApp(
            title: 'Mero Budget Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            home: isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : const LoginPage(),
          );
        },
      ),
    );
  }
}
