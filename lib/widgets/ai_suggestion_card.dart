import 'package:flutter/material.dart';

import '../models/ai_suggestion.dart';
import 'ai_confidence_badge.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiSuggestion suggestion;

  const AiSuggestionCard({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Suggestion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              AiConfidenceBadge(confidence: suggestion.confidence),
            ],
          ),
          const SizedBox(height: 12),
          _SuggestionRow(label: 'Category', value: suggestion.category),
          _SuggestionRow(label: 'Expense For', value: suggestion.person),
          _SuggestionRow(label: 'Payment', value: suggestion.paymentMethod),
          const SizedBox(height: 8),
          Text(
            suggestion.reason,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final String label;
  final String value;

  const _SuggestionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
