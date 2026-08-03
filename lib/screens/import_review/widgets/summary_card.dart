import 'package:flutter/material.dart';

class ImportReviewSummaryCard extends StatelessWidget {
  final int totalCount;
  final int selectedCount;
  final int needsReviewCount;
  final int readyCount;
  final int importedCount;
  final int incomeCount;
  final int transferCount;
  final double progress;

  const ImportReviewSummaryCard({
    super.key,
    required this.totalCount,
    required this.selectedCount,
    required this.needsReviewCount,
    required this.readyCount,
    required this.importedCount,
    required this.incomeCount,
    required this.transferCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final percentage = (safeProgress * 100).round();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Review Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: safeProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: [
              _SummaryMetric(label: 'Total', value: totalCount),
              _SummaryMetric(label: 'Selected', value: selectedCount),
              _SummaryMetric(label: 'Need Review', value: needsReviewCount),
              _SummaryMetric(label: 'Ready', value: readyCount),
              _SummaryMetric(label: 'Imported', value: importedCount),
              _SummaryMetric(label: 'Income', value: incomeCount),
              _SummaryMetric(label: 'Transfers', value: transferCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
