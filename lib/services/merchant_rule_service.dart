import 'package:hive/hive.dart';

import '../models/merchant_rule.dart';

class MerchantRuleService {
  static const String boxName = 'merchant_rules';

  static Box<MerchantRule> get _box {
    return Hive.box<MerchantRule>(boxName);
  }

  static String normalizeMerchantName(String merchantName) {
    return merchantName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<MerchantRule> getRules() {
    final rules = _box.values.toList();

    rules.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));

    return rules;
  }

  static MerchantRule? findRule(String merchantName) {
    final normalizedMerchant = normalizeMerchantName(merchantName);

    if (normalizedMerchant.isEmpty) {
      return null;
    }

    for (final rule in _box.values) {
      final normalizedRule = normalizeMerchantName(rule.merchantName);

      if (normalizedRule == normalizedMerchant) {
        return rule;
      }
    }

    return null;
  }

  static MerchantRule? suggestRule(String merchantName) {
    final normalizedMerchant = normalizeMerchantName(merchantName);

    if (normalizedMerchant.isEmpty) {
      return null;
    }

    MerchantRule? bestMatch;
    var bestScore = 0;

    for (final rule in _box.values) {
      final normalizedRule = normalizeMerchantName(rule.merchantName);

      if (normalizedMerchant == normalizedRule) {
        return rule;
      }

      if (normalizedMerchant.contains(normalizedRule) ||
          normalizedRule.contains(normalizedMerchant)) {
        final score = normalizedRule.length;

        if (score > bestScore) {
          bestScore = score;
          bestMatch = rule;
        }
      }
    }

    return bestMatch;
  }

  static Future<void> saveRule({
    required String merchantName,
    required String category,
    String person = 'Shared',
    String paymentMethod = 'UPI',
  }) async {
    final normalizedMerchant = normalizeMerchantName(merchantName);

    if (normalizedMerchant.isEmpty) {
      throw Exception('Merchant name cannot be empty.');
    }

    dynamic existingKey;

    for (final entry in _box.toMap().entries) {
      final rule = entry.value;

      if (normalizeMerchantName(rule.merchantName) == normalizedMerchant) {
        existingKey = entry.key;
        break;
      }
    }

    final rule = MerchantRule(
      merchantName: merchantName.trim(),
      category: category,
      person: person,
      paymentMethod: paymentMethod,
      updatedAt: DateTime.now(),
    );

    if (existingKey != null) {
      await _box.put(existingKey, rule);
    } else {
      await _box.add(rule);
    }
  }

  static Future<void> deleteRule(MerchantRule rule) async {
    final key = rule.key;

    if (key == null) {
      throw Exception('Merchant rule key was not found.');
    }

    await _box.delete(key);
  }

  static Future<void> clearRules() async {
    await _box.clear();
  }
}
