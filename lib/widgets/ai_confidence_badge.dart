import 'package:flutter/material.dart';

class AiConfidenceBadge extends StatelessWidget {
  final double confidence;

  const AiConfidenceBadge({super.key, required this.confidence});

  Color get color {
    if (confidence >= 90) {
      return Colors.green;
    }

    if (confidence >= 70) {
      return Colors.orange;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(Icons.psychology, size: 16, color: color),
      label: Text('${confidence.toStringAsFixed(0)}%'),
    );
  }
}
