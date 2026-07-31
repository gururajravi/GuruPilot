import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/expense.dart';
import 'screens/home_screen.dart';
import 'services/expense_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

  await Hive.openBox<Expense>(ExpenseService.boxName);
  final expenseBox = Hive.box<Expense>(ExpenseService.boxName);

  debugPrint('Hive box name: ${expenseBox.name}');
  debugPrint('Hive box length: ${expenseBox.length}');
  debugPrint('Hive box keys: ${expenseBox.keys.toList()}');

  for (final expense in expenseBox.values) {
    debugPrint(
      'Loaded expense: '
      '${expense.title}, ₹${expense.amount}, '
      '${expense.category}, ${expense.date}',
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
