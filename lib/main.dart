import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/historical_expenses_2026.dart';
import 'models/expense.dart';
import 'screens/home_screen.dart';
import 'services/expense_service.dart';
import 'models/investment.dart';
import 'services/investment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(InvestmentAdapter());
  }
  await Hive.openBox<Expense>(ExpenseService.boxName);
  await Hive.openBox<Investment>(InvestmentService.boxName);
  final importedCount = await ExpenseService.importExpenses(
    buildHistoricalExpenses2026(),
  );

  final expenseBox = Hive.box<Expense>(ExpenseService.boxName);

  debugPrint('Historical expenses imported: $importedCount');
  debugPrint('Hive box name: ${expenseBox.name}');
  debugPrint('Hive box length: ${expenseBox.length}');
  debugPrint('Hive box keys: ${expenseBox.keys.toList()}');

  for (final expense in expenseBox.values) {
    debugPrint(
      'Loaded expense: '
      '${expense.title}, ₹${expense.amount}, '
      '${expense.category}, ${expense.date}, '
      '${expense.source}, ${expense.transactionId}',
    );
  }

  runApp(const GuruPilotApp());
}

class GuruPilotApp extends StatelessWidget {
  const GuruPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuruPilot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
