import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/person_transaction.dart';
import '../providers/person_provider.dart';
import '../providers/theme_provider.dart';

class PersonDetailPage extends StatelessWidget {
  final Person person;

  const PersonDetailPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonProvider>();
    final txs = provider.transactionsFor(person.name);
    final total = provider.totalFor(person.name);
    final isPositive = total >= 0;
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.teal[900] : Colors.teal[100],
        title: Text(person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              provider.deletePerson(person);
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _showAddTxDialog(context);
          HapticFeedback.lightImpact();

        }

      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 10,vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? Colors.teal[900] : Colors.teal[100],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Balance:', style: TextStyle(fontSize: 18,color: isDark ? Colors.white : Colors.black)),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: txs.isEmpty
                ? const Center(child: Text('No transactions yet'))
                : ListView.builder(
              itemCount: txs.length,
              itemBuilder: (c, i) {
                final tx = txs[i];
                final sign = tx.amount >= 0 ? '+' : '';
                return Card(
                  color: isDark ? Colors.teal[900] : Colors.teal[100],
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: GestureDetector(
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      provider.deleteTransaction(tx);
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      title: Text(tx.note),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(tx.date)),
                      trailing: Text(
                        '$sign₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: tx.amount >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTxDialog(BuildContext context) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isIncome = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amtCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              SwitchListTile(
                title: const Text('Is Income'),
                value: isIncome,
                onChanged: (v) => setSt(() => isIncome = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text);
                if (amt != null) {
                  final tx = PersonTransaction(
                    personName: person.name,
                    amount: isIncome ? amt : -amt,
                    note: noteCtrl.text,
                    date: DateTime.now(),
                  );
                  context.read<PersonProvider>().addTransaction(tx);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
