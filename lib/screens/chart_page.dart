import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

class ChartPage extends StatelessWidget {
  ChartPage({super.key});

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

      grouped.putIfAbsent(formattedDate, () => []);
      grouped[formattedDate]!.add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).transactions;
    final spends = transactions.where((t) => !t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    ;
    final incomes = transactions.where((t) => t.isIncome).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    ;
    final totalSpend = spends.fold(0.0, (sum, tx) => sum + tx.amount);
    final totalIncome = incomes.fold(0.0, (sum, tx) => sum + tx.amount);
    final hasData = totalSpend > 0 || totalIncome > 0;
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Charts"),
        backgroundColor: isDark ? Colors.teal[900] : Colors.teal[100],
      ),
      body: hasData
          ? Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Income vs Spend",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalSpend,
                          title: 'Spend\n₹${totalSpend.toStringAsFixed(2)}',
                          color: Colors.redAccent,
                          radius: 80,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalIncome,
                          title: 'Income\n₹${totalIncome.toStringAsFixed(2)}',
                          color: Colors.green,
                          radius: 80,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      sectionsSpace: 5,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const Divider(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      _buildColumn("Spends", spends, isDark),
                      const VerticalDivider(width: 1),
                      _buildColumn("Incomes", incomes, isDark),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                "No Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
    );
  }

  Widget _buildColumn(String title, List<Transaction> txList, bool isDark) {
    final grouped = _groupTransactionsByDate(txList);

    return Expanded(
      child: grouped.isEmpty
          ? Center(
              child: Text(
                "No Transaction\nfor $title\nPlease add",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            )
          : ListView.builder(
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                String dateKey = grouped.keys.elementAt(index);
                List<Transaction> dayTxs = grouped[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Section Header: Spend/Income
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
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

                    /// Date label
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Text(
                        dateKey,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.teal[200] : Colors.teal[800],
                        ),
                      ),
                    ),

                    /// Transactions
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
    );
  }
}
