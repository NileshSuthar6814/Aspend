import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/balance_card.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _currentBalance;
    balance();
  }

  void balance() {
    final box = Hive.box<double>('_currentBalance');
    setState(() {
      _currentBalance = box.get('_currentBalance', defaultValue: 0.0)!;
    });
  }

  void onBalanceUpdate(double newBalance) {
    final box = Hive.box<double>('_currentBalance');
    box.put('_currentBalance', newBalance);
    setState(() => _currentBalance = newBalance);
  }
  // double _currentBalance = 0;
  // @override
  // void initState() {
  //   super.initState();
  //   _currentBalance; // ✅ Load from Hive
  // }
  //
  // void balance() {
  //   final box = Hive.box<double>('_currentBalance');
  //   setState(() {
  //     _currentBalance = box.get('_currentBalance', defaultValue: 0.0)!;
  //   });
  // }
  //
  // void onBalanceUpdate(double newBalance) {
  //   final box = Hive.box<double>('_currentBalance');
  //   box.put('_currentBalance', newBalance); // ✅ Save to Hive
  //   setState(() {
  //     _currentBalance = newBalance;
  //   });
  // }

  void _showAddTransactionDialog(BuildContext context,
      {required bool isIncome}) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    String _account = "Cash";

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Transaction",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final isDark = context.watch<AppThemeProvider>().isDarkMode;

        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Add Transaction",
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black),
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: "Amount"),
                      validator: (val) => val == null || val.isEmpty
                          ? "Enter amount"
                          : null,
                    ),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: "Note"),
                    ),
                    DropdownButtonFormField<String>(
                      value: _account,
                      decoration: const InputDecoration(labelText: "Account"),
                      items: ['Online', 'Cash']
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => _account = val ?? "Cash",
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final tx = Transaction(
                        amount: double.parse(_amountController.text),
                        note: _noteController.text,
                        category: "General",
                        account: _account,
                        date: DateTime.now(),
                        isIncome: isIncome,
                      );
                      Provider.of<TransactionProvider>(context,
                          listen: false)
                          .addTransaction(tx);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "Add",
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aspends Tracker"),
        backgroundColor: isDark ? Colors.teal[900] : Colors.teal[100],
      ),
      body: _TransactionView(
        balance: _currentBalance,
        onBalanceUpdate: (val) {
          setState(() {
            onBalanceUpdate(val);
          });
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'spend',
            child: const Icon(Icons.remove),
            onPressed: () {
              _showAddTransactionDialog(context, isIncome: false);
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'income',
            child: const Icon(Icons.add),
            onPressed: () {
              _showAddTransactionDialog(context, isIncome: true);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionView extends StatelessWidget {
  final double balance;
  final Function(double) onBalanceUpdate;

  const _TransactionView({
    required this.balance,
    required this.onBalanceUpdate,
  });

  Map<String, List<Transaction>> _groupTransactions(List<Transaction> txns) {
    Map<String, List<Transaction>> grouped = {};

    for (var tx in txns) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      String label;
      if (txDate == today) {
        label = "Today";
      } else if (txDate == yesterday) {
        label = "Yesterday";
      } else {
        label = DateFormat.yMMMMd().format(tx.date);
      }

      grouped[label] = [...(grouped[label] ?? []), tx];
    }

    return grouped;
  }

  Widget _buildSection(
      BuildContext context, String title, List<Transaction> txns) {
    final grouped = _groupTransactions(txns);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return Expanded(
      child: grouped.isEmpty
          ? Center(
        child: Text(
          "No Transactions\nfor $title",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      )
          : ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final dateTxs = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.teal[900]
                            : Colors.teal[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      dateKey,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
              ...dateTxs.map((tx) => TransactionTile(
                transaction: tx,
                index: index,
              )),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txns = context.watch<TransactionProvider>().transactions;
    final spends = txns.where((t) => !t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final incomes = txns.where((t) => t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        BalanceCard(
          balance: balance,
          onBalanceUpdate: (newBalance) async {
            final box = Hive.box<double>('balanceBox');
            await box.put('startingBalance', newBalance);
            // Optional: trigger UI update if you're managing balance state separately
            Provider.of<TransactionProvider>(context, listen: false)
                .updateBalance(newBalance);
          },
        ),
        Expanded(
          child: Row(
            children: [
              _buildSection(context, "Spends", spends),
              const VerticalDivider(width: 1),
              _buildSection(context, "Incomes", incomes),
            ],
          ),
        ),
      ],
    );
  }
}
