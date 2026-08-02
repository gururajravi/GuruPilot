import 'package:hive/hive.dart';

import '../models/investment.dart';

class InvestmentService {
  static const String boxName = 'investments';

  static Box<Investment> get _box {
    return Hive.box<Investment>(boxName);
  }

  static Future<void> addInvestment(Investment investment) async {
    await _box.add(investment);
  }

  static Future<void> updateInvestment(
    Investment existingInvestment,
    Investment updatedInvestment,
  ) async {
    final key = existingInvestment.key;

    if (key == null) {
      throw Exception('Investment key was not found.');
    }

    await _box.put(key, updatedInvestment);
  }

  static Future<void> deleteInvestment(Investment investment) async {
    final key = investment.key;

    if (key == null) {
      throw Exception('Investment key was not found.');
    }

    await _box.delete(key);
  }

  static List<Investment> getInvestments() {
    final investments = _box.values.toList();

    investments.sort((first, second) => second.date.compareTo(first.date));

    return investments;
  }

  static double get totalInvested {
    return _box.values.fold<double>(
      0,
      (sum, investment) => sum + investment.investedAmount,
    );
  }

  static double get totalCurrentValue {
    return _box.values.fold<double>(
      0,
      (sum, investment) => sum + investment.currentValue,
    );
  }

  static double get totalGainOrLoss {
    return totalCurrentValue - totalInvested;
  }

  static Future<int> importInvestments(Iterable<Investment> investments) async {
    final existingImportIds = _box.values
        .map((investment) => investment.importId)
        .whereType<String>()
        .toSet();

    final newInvestments = investments.where((investment) {
      final importId = investment.importId;

      if (importId == null || importId.trim().isEmpty) {
        return true;
      }

      return !existingImportIds.contains(importId);
    }).toList();

    if (newInvestments.isEmpty) {
      return 0;
    }

    await _box.addAll(newInvestments);

    return newInvestments.length;
  }

  static Future<void> clearInvestments() async {
    await _box.clear();
  }
}
