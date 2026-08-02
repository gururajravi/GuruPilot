import 'package:hive/hive.dart';

import '../models/account.dart';

class AccountService {
  static const String boxName = 'accounts';

  static Box<Account> get _box {
    return Hive.box<Account>(boxName);
  }

  static Future<void> addAccount(Account account) async {
    await _box.add(account);
  }

  static Future<void> updateAccount(
    Account existingAccount,
    Account updatedAccount,
  ) async {
    final key = existingAccount.key;

    if (key == null) {
      throw Exception('Account key was not found.');
    }

    await _box.put(key, updatedAccount);
  }

  static Future<void> deleteAccount(Account account) async {
    final key = account.key;

    if (key == null) {
      throw Exception('Account key was not found.');
    }

    await _box.delete(key);
  }

  static List<Account> getAccounts({bool activeOnly = false}) {
    final accounts = _box.values.where((account) {
      if (!activeOnly) {
        return true;
      }

      return account.isActive;
    }).toList();

    accounts.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );

    return accounts;
  }

  static double get totalBalance {
    return _box.values
        .where((account) => account.isActive)
        .fold<double>(0, (sum, account) => sum + account.currentBalance);
  }

  static double get totalBankBalance {
    return _box.values
        .where((account) => account.isActive && account.type == 'Bank Account')
        .fold<double>(0, (sum, account) => sum + account.currentBalance);
  }

  static double get totalCashBalance {
    return _box.values
        .where((account) => account.isActive && account.type == 'Cash')
        .fold<double>(0, (sum, account) => sum + account.currentBalance);
  }

  static double get totalCreditCardOutstanding {
    return _box.values
        .where((account) => account.isActive && account.type == 'Credit Card')
        .fold<double>(0, (sum, account) => sum + account.currentBalance.abs());
  }

  static Future<void> clearAccounts() async {
    await _box.clear();
  }
}
