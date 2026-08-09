import '../models/ai_suggestion.dart';
import '../models/merchant_rule.dart';
import 'merchant_rule_service.dart';

class AiLearningService {
  static AiSuggestion? suggest(String merchantName) {
    final MerchantRule? rule = MerchantRuleService.suggestRule(merchantName);

    if (rule == null) {
      return null;
    }

    return AiSuggestion(
      category: rule.category,
      person: rule.person,
      paymentMethod: rule.paymentMethod,
      confidence: 100,
      reason: 'Exact merchant rule match',
    );
  }
}
