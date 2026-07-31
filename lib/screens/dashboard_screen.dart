import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;

  const DashboardScreen({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    double total = 0;

    for (var expense in expenses) {
      total += expense["amount"];
    }

    return Scaffold(
      appBar: AppBar(title: const Text("GuruPilot"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Total Expenses",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "₹${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text("No expenses yet"))
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.payments),
                            title: Text(expense["title"]),
                            trailing: Text("₹${expense["amount"]}"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
