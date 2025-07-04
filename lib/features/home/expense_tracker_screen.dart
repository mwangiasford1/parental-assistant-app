// features/home/expense_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/expense_model.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  CollectionReference get expenseCol => FirebaseFirestore.instance.collection('expenses');

  void _showExpenseDialog({ExpenseModel? expense}) {
    final amountController = TextEditingController(text: expense?.amount.toString() ?? '');
    final categoryController = TextEditingController(text: expense?.category ?? '');
    final descController = TextEditingController(text: expense?.description ?? '');
    DateTime date = expense?.date ?? DateTime.now();
    String type = expense?.type ?? 'expense';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense == null ? 'Add Transaction' : 'Edit Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Date:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          date = picked;
                        });
                      }
                    },
                    child: Text('${date.month}/${date.day}/${date.year}'),
                  ),
                ],
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'expense',
                    groupValue: type,
                    onChanged: (v) => setState(() => type = v ?? 'expense'),
                  ),
                  const Text('Expense'),
                  Radio<String>(
                    value: 'income',
                    groupValue: type,
                    onChanged: (v) => setState(() => type = v ?? 'expense'),
                  ),
                  const Text('Income'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (expense != null)
            TextButton(
              onPressed: () async {
                await expenseCol.doc(expense.id).delete();
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text.trim()) ?? 0;
              if (amt == 0) return;
              final newExpense = ExpenseModel(
                id: expense?.id ?? '',
                userId: userId,
                amount: amt,
                category: categoryController.text.trim(),
                description: descController.text.trim(),
                date: date,
                type: type,
              );
              if (expense == null) {
                await expenseCol.add(newExpense.toMap());
              } else {
                await expenseCol.doc(expense.id).update(newExpense.toMap());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showExpenseDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expenseCol.where('userId', isEqualTo: userId).orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No transactions yet.'));
          final expenses = docs.map((d) => ExpenseModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
          final totalIncome = expenses.where((e) => e.type == 'income').fold<double>(0, (sum, e) => sum + e.amount);
          final totalExpense = expenses.where((e) => e.type == 'expense').fold<double>(0, (sum, e) => sum + e.amount);
          final balance = totalIncome - totalExpense;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryTile(label: 'Income', value: totalIncome),
                    _SummaryTile(label: 'Expense', value: totalExpense),
                    _SummaryTile(label: 'Balance', value: balance),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final e = expenses[index];
                    return ListTile(
                      leading: Icon(e.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward, color: e.type == 'income' ? Colors.green : Colors.red),
                      title: Text('${e.category} - ${e.description}'),
                      subtitle: Text('${e.date.month}/${e.date.day}/${e.date.year}'),
                      trailing: Text((e.type == 'income' ? '+' : '-') + e.amount.toStringAsFixed(2), style: TextStyle(color: e.type == 'income' ? Colors.green : Colors.red)),
                      onTap: () => _showExpenseDialog(expense: e),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 18)),
      ],
    );
  }
} 