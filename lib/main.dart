import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/historical_expenses_2026.dart';
import 'firebase_options.dart';

import 'models/account.dart';
import 'models/expense.dart';
import 'models/import_history.dart';
import 'models/investment.dart';
import 'models/merchant_rule.dart';
import 'models/pending_transaction.dart';
import 'models/reviewed_transaction.dart';

import 'screens/home_screen.dart';

import 'services/account_service.dart';
import 'services/expense_service.dart';
import 'services/import_history_service.dart';
import 'services/investment_service.dart';
import 'services/merchant_rule_service.dart';
import 'services/pending_transaction_service.dart';
import 'services/reviewed_transaction_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------------
  // Initialize Firebase
  // --------------------------------------------------------

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Firebase initialized successfully.');

  // --------------------------------------------------------
  // Initialize Hive
  // --------------------------------------------------------

  await Hive.initFlutter();

  // --------------------------------------------------------
  // Register Hive Adapters
  // --------------------------------------------------------

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(InvestmentAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MerchantRuleAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(PendingTransactionAdapter());
  }

  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(AccountAdapter());
  }

  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ReviewedTransactionAdapter());
  }

  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(ImportHistoryAdapter());
  }

  // --------------------------------------------------------
  // Open Hive Boxes Safely
  // --------------------------------------------------------

  if (!Hive.isBoxOpen(ExpenseService.boxName)) {
    await Hive.openBox(ExpenseService.boxName);
  }

  if (!Hive.isBoxOpen(InvestmentService.boxName)) {
    await Hive.openBox(InvestmentService.boxName);
  }

  if (!Hive.isBoxOpen(MerchantRuleService.boxName)) {
    await Hive.openBox(MerchantRuleService.boxName);
  }

  if (!Hive.isBoxOpen(PendingTransactionService.boxName)) {
    await Hive.openBox(PendingTransactionService.boxName);
  }

  if (!Hive.isBoxOpen(AccountService.boxName)) {
    await Hive.openBox(AccountService.boxName);
  }

  if (!Hive.isBoxOpen(ReviewedTransactionService.boxName)) {
    await Hive.openBox(ReviewedTransactionService.boxName);
  }

  if (!Hive.isBoxOpen(ImportHistoryService.boxName)) {
    await Hive.openBox(ImportHistoryService.boxName);
  }

  // --------------------------------------------------------
  // Load Historical Data
  // Only if the local expense box is empty
  // --------------------------------------------------------

  final expenseBox = Hive.box(ExpenseService.boxName);

  if (expenseBox.isEmpty) {
    final importedCount = await ExpenseService.importExpenses(
      buildHistoricalExpenses2026(),
    );

    debugPrint('Historical expenses imported: $importedCount');
  }

  // --------------------------------------------------------
  // Debug Logs
  // --------------------------------------------------------

  debugPrint('Expense count : ${expenseBox.length}');

  debugPrint(
    'Merchant rules : '
    '${Hive.box(MerchantRuleService.boxName).length}',
  );

  debugPrint(
    'Accounts : '
    '${Hive.box(AccountService.boxName).length}',
  );

  debugPrint(
    'Reviewed Transactions : '
    '${Hive.box(ReviewedTransactionService.boxName).length}',
  );

  debugPrint(
    'Import History : '
    '${Hive.box(ImportHistoryService.boxName).length}',
  );

  // --------------------------------------------------------
  // Start GuruFin
  // --------------------------------------------------------

  runApp(const GuruFinApp());
}

class GuruFinApp extends StatelessWidget {
  const GuruFinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuruFin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomeScreen(),
    );
  }
}
