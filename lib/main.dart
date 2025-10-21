import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/transaction/presentation/bloc/transaction_bloc.dart';
import 'features/transaction/data/repositories/in_memory_transaction_repository.dart';
import 'features/statistics/presentation/bloc/statistics_bloc.dart';
import 'features/statistics/data/repositories/statistics_repository_impl.dart';
import 'features/home/presentation/bloc/summary_bloc.dart';
import 'features/home/data/repositories/summary_repository_impl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionRepository = InMemoryTransactionRepository();

    return MultiBlocProvider(
      providers: [
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
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
