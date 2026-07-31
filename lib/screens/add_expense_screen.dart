import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  final titleController = TextEditingController();

  String selectedCategory = "Food";
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Expense Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Food", child: Text("🍔 Food")),
                DropdownMenuItem(value: "Fuel", child: Text("⛽ Fuel")),
                DropdownMenuItem(value: "Shopping", child: Text("🛒 Shopping")),
                DropdownMenuItem(value: "Bills", child: Text("💡 Bills")),
                DropdownMenuItem(value: "Travel", child: Text("✈️ Travel")),
                DropdownMenuItem(value: "Medical", child: Text("💊 Medical")),
                DropdownMenuItem(
                  value: "Entertainment",
                  child: Text("🎬 Entertainment"),
                ),
                DropdownMenuItem(value: "Other", child: Text("📦 Other")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey),
              ),
              leading: const Icon(Icons.calendar_today),
              title: Text(
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2035),
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty ||
                      amountController.text.isEmpty) {
                    return;
                  }

                  Navigator.pop(context, {
                    "title": titleController.text,
                    "amount": double.parse(amountController.text),
                    "category": selectedCategory,
                    "date": selectedDate,
                  });
                },
                child: const Text("Save Expense"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
