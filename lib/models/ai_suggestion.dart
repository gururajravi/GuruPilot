class AiSuggestion {
  final String category;
  final String person;
  final String paymentMethod;
  final double confidence;
  final String reason;

  const AiSuggestion({
    required this.category,
    required this.person,
    required this.paymentMethod,
    required this.confidence,
    required this.reason,
  });

  bool get isHighConfidence => confidence >= 90;

  bool get isMediumConfidence => confidence >= 70 && confidence < 90;

  bool get needsReview => confidence < 70;
}
