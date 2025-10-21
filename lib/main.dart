import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/home/data/repositories/in_memory_transaction_repository.dart';
import 'features/home/presentation/bloc/transaction_bloc.dart';
import 'features/home/presentation/bloc/transaction_event.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionBloc(
        repository: InMemoryTransactionRepository(),
      )..add(LoadTransactions()),
      child: MaterialApp(
        title: 'Mero Budget Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
      ),
    );
  }
}
