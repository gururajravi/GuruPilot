import '../models/ai_suggestion.dart';

class AiLearningService {
  static AiSuggestion? suggest(String merchantName) {
    final normalized = _normalize(merchantName);

    if (normalized.isEmpty || _looksLikePersonName(normalized)) {
      return null;
    }

    final exact = _exactMerchants[normalized];
    if (exact != null) {
      return _suggestion(
        category: exact.category,
        person: exact.person,
        confidence: 0.98,
        reason: 'Recognized merchant: $merchantName',
      );
    }

    final rule = _keywordRules.firstWhere(
      (rule) => rule.keywords.any(normalized.contains),
      orElse: () => const _KeywordRule(
        keywords: <String>[],
        category: '',
        person: 'Shared',
        confidence: 0,
        reason: '',
      ),
    );

    if (rule.category.isEmpty) {
      return null;
    }

    return _suggestion(
      category: rule.category,
      person: rule.person,
      confidence: rule.confidence,
      reason: rule.reason,
    );
  }

  static AiSuggestion _suggestion({
    required String category,
    required String person,
    required double confidence,
    required String reason,
  }) {
    return AiSuggestion(
      category: category,
      person: person,
      paymentMethod: 'UPI',
      confidence: confidence,
      reason: reason,
    );
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikePersonName(String value) {
    if (RegExp(r'x{3,}\d{3,}').hasMatch(value)) {
      return true;
    }

    if (RegExp(r'^\d{10}$').hasMatch(value.replaceAll(' ', ''))) {
      return true;
    }

    return false;
  }

  static const Map<String, _MerchantPreset> _exactMerchants = {
    'zomato': _MerchantPreset(category: 'Food'),
    'blinkit': _MerchantPreset(category: 'Grocery'),
    'amazon india': _MerchantPreset(category: 'Shopping'),
    'amazon pay balance': _MerchantPreset(category: 'Shopping'),
    'tobox ventures private limited': _MerchantPreset(
      category: 'Guru Office Food',
      person: 'Guru',
    ),
    'tobox ventures pvt ltd': _MerchantPreset(
      category: 'Guru Office Food',
      person: 'Guru',
    ),
    'megha fuel park': _MerchantPreset(category: 'Fuel'),
    'dream mart hyper market hk2': _MerchantPreset(category: 'Grocery'),
    'dream mart hyper market': _MerchantPreset(category: 'Grocery'),
    'all market': _MerchantPreset(category: 'Grocery'),
  };

  static const List<_KeywordRule> _keywordRules = [
    _KeywordRule(
      keywords: [
        'zomato',
        'swiggy',
        'restaurant',
        'biryani',
        'pizza',
        'burger',
        'cafe',
        'coffee',
        'bakery',
        'sweet',
        'sweets',
        'vada pav',
        'food',
        'hotel',
        'kanti',
      ],
      category: 'Food',
      confidence: 0.90,
      reason: 'Merchant name looks like a restaurant or food outlet.',
    ),
    _KeywordRule(
      keywords: [
        'blinkit',
        'zepto',
        'bigbasket',
        'grocery',
        'super market',
        'supermarket',
        'hyper market',
        'hypermarket',
        'mart',
        'provision',
        'vegetable',
        'vegetables',
        'fruits',
        'milk',
        'dairy',
      ],
      category: 'Grocery',
      confidence: 0.88,
      reason: 'Merchant name looks like a grocery or supermarket purchase.',
    ),
    _KeywordRule(
      keywords: [
        'fuel',
        'petrol',
        'diesel',
        'indian oil',
        'indianoil',
        'bharat petroleum',
        'bpcl',
        'hp petrol',
        'hindustan petroleum',
        'service station',
      ],
      category: 'Fuel',
      confidence: 0.94,
      reason: 'Merchant name looks like a fuel station.',
    ),
    _KeywordRule(
      keywords: [
        'amazon',
        'flipkart',
        'myntra',
        'ajio',
        'meesho',
        'shopping',
        'fashion',
        'retail',
      ],
      category: 'Shopping',
      confidence: 0.86,
      reason: 'Merchant name looks like an online or retail shopping purchase.',
    ),
    _KeywordRule(
      keywords: [
        'zee entertainment',
        'zee20entertainment',
        'netflix',
        'prime video',
        'hotstar',
        'spotify',
        'bookmyshow',
        'cinema',
        'multiplex',
        'pvr',
        'inox',
      ],
      category: 'Entertainment',
      confidence: 0.88,
      reason: 'Merchant name looks like entertainment or media spending.',
    ),
    _KeywordRule(
      keywords: [
        'airtel',
        'jio',
        'vodafone',
        'vi recharge',
        'bescom',
        'electricity',
        'broadband',
        'internet',
        'recharge',
        'gas bill',
        'water bill',
      ],
      category: 'Bills',
      confidence: 0.88,
      reason: 'Merchant name looks like a recurring utility or recharge bill.',
    ),
    _KeywordRule(
      keywords: [
        'apollo',
        'pharmacy',
        'medical',
        'hospital',
        'clinic',
        'diagnostic',
        'medplus',
        'netmeds',
        '1mg',
      ],
      category: 'Medical',
      confidence: 0.91,
      reason: 'Merchant name looks like medical or pharmacy spending.',
    ),
    _KeywordRule(
      keywords: [
        'uber',
        'ola',
        'rapido',
        'irctc',
        'railway',
        'redbus',
        'makemytrip',
        'goibibo',
        'airlines',
        'airways',
        'metro',
        'toll',
      ],
      category: 'Travel',
      confidence: 0.86,
      reason: 'Merchant name looks like travel or transportation spending.',
    ),
    _KeywordRule(
      keywords: [
        'automobiles',
        'automobile',
        'car care',
        'car wash',
        'tyre',
        'tyres',
        'four wheeler',
      ],
      category: 'Car',
      confidence: 0.82,
      reason: 'Merchant name looks related to car expenses.',
    ),
    _KeywordRule(
      keywords: [
        'bike service',
        'two wheeler',
        'motorcycle',
        'bajaj auto',
        'hero motocorp',
        'royal enfield',
      ],
      category: 'Bike',
      confidence: 0.82,
      reason: 'Merchant name looks related to bike expenses.',
    ),
  ];
}

class _MerchantPreset {
  final String category;
  final String person;

  const _MerchantPreset({required this.category, this.person = 'Shared'});
}

class _KeywordRule {
  final List<String> keywords;
  final String category;
  final String person;
  final double confidence;
  final String reason;

  const _KeywordRule({
    required this.keywords,
    required this.category,
    this.person = 'Shared',
    required this.confidence,
    required this.reason,
  });
}
