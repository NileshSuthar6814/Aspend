import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/balance_card.dart';
import 'package:hive/hive.dart';
//import 'chart_page.dart';
//import 'settings_page.dart';

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
    _currentBalance; // ✅ Load from Hive
  }

  void balance() {
    final box = Hive.box<double>('_currentBalance');
    setState(() {
      _currentBalance = box.get('_currentBalance', defaultValue: 0.0)!;
    });
  }

  void onBalanceUpdate(double newBalance) {
    final box = Hive.box<double>('_currentBalance');
    box.put('_currentBalance', newBalance); // ✅ Save to Hive
    setState(() {
      _currentBalance = newBalance;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    setState(() {});
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
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          child: Icon(Icons.remove),
          onPressed: () {
            _showAddTransactionDialog(context, isIncome: false);
            HapticFeedback.lightImpact();
          },
          heroTag: null,
        ),
        SizedBox(
          height: 10,
        ),
        FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _showAddTransactionDialog(context, isIncome: true);
            HapticFeedback.lightImpact();
          },
          heroTag: null,
        ),
            SizedBox(
              height: 50,
            )
      ]),
    );
  }

  void _showAddTransactionDialog(BuildContext context,
      {required bool isIncome}) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    String _category = "General";
    String _account = "Cash";
    bool _isIncome = isIncome;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Transaction",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final isDark = context.watch<AppThemeProvider>().isDarkMode;
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Add Transaction",
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              content: Form(
                key: _formKey,
                child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          decoration:
                              const InputDecoration(labelText: "Amount"),
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || val.isEmpty
                              ? "Enter amount"
                              : null,
                        ),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(labelText: "Note"),
                        ),
                        DropdownButtonFormField(
                          value: _account,
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
                          onChanged: (val) => _account = val!,
                          decoration:
                              const InputDecoration(labelText: "Account"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),
                ElevatedButton(
                  child: Text(
                    "Add",
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_formKey.currentState!.validate()) {
                      final tx = Transaction(
                        amount: double.parse(_amountController.text),
                        note: _noteController.text,
                        category: _category,
                        account: _account,
                        date: DateTime.now(),
                        isIncome: _isIncome,
                      );
                      Provider.of<TransactionProvider>(context, listen: false)
                          .addTransaction(tx);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionView extends StatefulWidget {
  final double balance;
  final Function(double) onBalanceUpdate;
  const _TransactionView({
    required this.balance,
    required this.onBalanceUpdate,
  });

  @override
  State<_TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<_TransactionView> {
  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    Map<String, List<Transaction>> grouped = {};

    for (var tx in transactions) {
      String formattedDate;
      DateTime now = DateTime.now();
      DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));

      if (txDate == today) {
        formattedDate = "Today";
      } else if (txDate == yesterday) {
        formattedDate = "Yesterday";
      } else {
        formattedDate = DateFormat.yMMMMd().format(tx.date);
      }

      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final txns = context.watch<TransactionProvider>().transactions;
    final spends = txns.where((t) => !t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 👈 newest first

    final incomes = txns.where((t) => t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 👈 newest first

    final balance = context.watch<TransactionProvider>().totalBalance;
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
          child: incomes.isNotEmpty || spends.isNotEmpty
              ? Row(
                  children: [
                    _buildColumn("Spends", spends),
                    VerticalDivider(
                      width: 0,
                    ),
                    _buildColumn("Incomes", incomes),
                  ],
                )
              : Center(
                  child: Text(
                    "Make the First Transaction",
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<Transaction> txList) {
    final grouped = _groupTransactionsByDate(txList);
    final isDark = context.watch<AppThemeProvider>().isDarkMode;
    return grouped.isNotEmpty
        ? Expanded(
            child: ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                String dateKey = grouped.keys.elementAt(index);
                List<Transaction> dayTxs = grouped[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.teal[900] : Colors.teal[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Text(
                        dateKey,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    ...dayTxs
                        .map((tx) => TransactionTile(
                              transaction: tx,
                              index: index,
                            ))
                        .toList(),
                  ],
                );
              },
            ),
          )
        : Expanded(
            child: Center(
              child: Text(
                "No Transaction \n for $title "
                "\n plz add ",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
  }
}
