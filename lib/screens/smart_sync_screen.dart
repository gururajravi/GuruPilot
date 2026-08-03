import 'package:flutter/material.dart';

import '../models/import_review_item.dart';

class SmartSyncScreen extends StatelessWidget {
  final List<ImportReviewItem> reviewItems;

  const SmartSyncScreen({super.key, required this.reviewItems});

  int get totalCount {
    return reviewItems.length;
  }

  int get duplicateCount {
    return reviewItems.where((item) {
      return item.isDuplicate;
    }).length;
  }

  int get readyCount {
    return reviewItems.where((item) {
      return !item.isDuplicate &&
          item.transactionType == ImportTransactionType.expense &&
          item.category != 'Uncategorized';
    }).length;
  }

  int get needsReviewCount {
    return reviewItems.where((item) {
      return !item.isDuplicate &&
          item.transactionType == ImportTransactionType.expense &&
          item.category == 'Uncategorized';
    }).length;
  }

  int get incomeCount {
    return reviewItems.where((item) {
      return item.transactionType == ImportTransactionType.income;
    }).length;
  }

  int get transferCount {
    return reviewItems.where((item) {
      return item.transactionType == ImportTransactionType.transfer;
    }).length;
  }

  int get refundCount {
    return reviewItems.where((item) {
      return item.transactionType == ImportTransactionType.refund;
    }).length;
  }

  double get automationRate {
    final relevantExpenses = readyCount + needsReviewCount;

    if (relevantExpenses == 0) {
      return 1;
    }

    return readyCount / relevantExpenses;
  }

  int get estimatedReviewSeconds {
    return needsReviewCount * 4;
  }

  String get estimatedReviewTime {
    final seconds = estimatedReviewSeconds;

    if (seconds == 0) {
      return 'No manual review required';
    }

    if (seconds < 60) {
      return 'About $seconds seconds';
    }

    final minutes = (seconds / 60).ceil();

    return 'About $minutes minute${minutes == 1 ? '' : 's'}';
  }

  void _startReview(BuildContext context) {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (automationRate.clamp(0.0, 1.0) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Smart Sync'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                _startReview(context);
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(
                needsReviewCount > 0
                    ? 'Start Review ($needsReviewCount)'
                    : 'Review Ready Transactions',
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          _StatementHeader(totalCount: totalCount),

          const SizedBox(height: 16),

          _AutomationCard(
            percentage: percentage,
            progress: automationRate,
            readyCount: readyCount,
            needsReviewCount: needsReviewCount,
          ),

          const SizedBox(height: 16),

          _StatisticsGrid(
            totalCount: totalCount,
            duplicateCount: duplicateCount,
            readyCount: readyCount,
            needsReviewCount: needsReviewCount,
            incomeCount: incomeCount,
            transferCount: transferCount,
            refundCount: refundCount,
          ),

          const SizedBox(height: 16),

          _ReviewTimeCard(
            estimatedReviewTime: estimatedReviewTime,
            needsReviewCount: needsReviewCount,
          ),

          const SizedBox(height: 16),

          _PrivacyCard(
            duplicateCount: duplicateCount,
            readyCount: readyCount,
            needsReviewCount: needsReviewCount,
          ),
        ],
      ),
    );
  }
}

class _StatementHeader extends StatelessWidget {
  final int totalCount;

  const _StatementHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.indigo.shade100,
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PhonePe Statement',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$totalCount transactions analysed',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Smart Sync analysis complete',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationCard extends StatelessWidget {
  final int percentage;
  final double progress;
  final int readyCount;
  final int needsReviewCount;

  const _AutomationCard({
    required this.percentage,
    required this.progress,
    required this.readyCount,
    required this.needsReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Automation Rate',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const Icon(Icons.auto_awesome, color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          Text(
            '$readyCount automatically categorized • '
            '$needsReviewCount need your attention',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  final int totalCount;
  final int duplicateCount;
  final int readyCount;
  final int needsReviewCount;
  final int incomeCount;
  final int transferCount;
  final int refundCount;

  const _StatisticsGrid({
    required this.totalCount,
    required this.duplicateCount,
    required this.readyCount,
    required this.needsReviewCount,
    required this.incomeCount,
    required this.transferCount,
    required this.refundCount,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_SmartSyncMetric>[
      _SmartSyncMetric(
        label: 'Total',
        value: totalCount,
        icon: Icons.list_alt,
        background: Colors.indigo.shade50,
        foreground: Colors.indigo,
      ),
      _SmartSyncMetric(
        label: 'Imported',
        value: duplicateCount,
        icon: Icons.check_circle_outline,
        background: Colors.grey.shade200,
        foreground: Colors.grey.shade800,
      ),
      _SmartSyncMetric(
        label: 'Ready',
        value: readyCount,
        icon: Icons.auto_awesome,
        background: Colors.green.shade50,
        foreground: Colors.green.shade800,
      ),
      _SmartSyncMetric(
        label: 'Need Review',
        value: needsReviewCount,
        icon: Icons.warning_amber,
        background: Colors.orange.shade50,
        foreground: Colors.orange.shade900,
      ),
      _SmartSyncMetric(
        label: 'Income',
        value: incomeCount,
        icon: Icons.south_west,
        background: Colors.blue.shade50,
        foreground: Colors.blue.shade800,
      ),
      _SmartSyncMetric(
        label: 'Transfers',
        value: transferCount,
        icon: Icons.swap_horiz,
        background: Colors.purple.shade50,
        foreground: Colors.purple.shade800,
      ),
    ];

    if (refundCount > 0) {
      tiles.add(
        _SmartSyncMetric(
          label: 'Refunds',
          value: refundCount,
          icon: Icons.replay,
          background: Colors.teal.shade50,
          foreground: Colors.teal.shade800,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 2;

        final childAspectRatio = constraints.maxWidth >= 700 ? 2.2 : 1.65;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _StatisticTile(metric: tiles[index]);
          },
        );
      },
    );
  }
}

class _SmartSyncMetric {
  final String label;
  final int value;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _SmartSyncMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}

class _StatisticTile extends StatelessWidget {
  final _SmartSyncMetric metric;

  const _StatisticTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: metric.background,
              child: Icon(metric.icon, color: metric.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.value.toString(),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    metric.label,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTimeCard extends StatelessWidget {
  final String estimatedReviewTime;
  final int needsReviewCount;

  const _ReviewTimeCard({
    required this.estimatedReviewTime,
    required this.needsReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: Icon(Icons.timer_outlined, color: Colors.amber.shade900),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimated Review Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estimatedReviewTime,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (needsReviewCount > 0)
                    Text(
                      '$needsReviewCount unknown '
                      'merchant${needsReviewCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final int duplicateCount;
  final int readyCount;
  final int needsReviewCount;

  const _PrivacyCard({
    required this.duplicateCount,
    required this.readyCount,
    required this.needsReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: Colors.green.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All analysis is performed locally. '
                '$duplicateCount existing transactions were detected, '
                '$readyCount were auto-categorized, and '
                '$needsReviewCount require review. '
                'No bank access or third-party financial service is used.',
                style: TextStyle(color: Colors.green.shade900, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
