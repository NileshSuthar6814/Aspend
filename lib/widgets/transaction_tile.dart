import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final int index;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.isIncome;
    final amountText =
        "${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}";
    final amountStyle = TextStyle(
      color: isIncome ? Colors.green : Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetailsSheet(context, isDark);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: 1.0,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isDark? Colors.teal.shade900 : Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// First row: Note + Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        transaction.note.isNotEmpty
                            ? transaction.note
                            : transaction.category,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(amountText, style: amountStyle),
                  ],
                ),

                const SizedBox(height: 4),

                /// Second row: Account • Category + Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${transaction.account} • ${transaction.category}",
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      DateFormat.jm().format(transaction.date),
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle(
          style: TextStyle(color: textColor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 40,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow("Amount", "₹${transaction.amount.toStringAsFixed(2)}", textColor),
              _buildDetailRow("Note", transaction.note.isNotEmpty ? transaction.note : "—", textColor),
              _buildDetailRow("Category", transaction.category, textColor),
              _buildDetailRow("Account", transaction.account, textColor),
              _buildDetailRow("Date", DateFormat.yMMMMEEEEd().format(transaction.date), textColor),
              _buildDetailRow("Time", DateFormat.jm().format(transaction.date), textColor),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Provider.of<TransactionProvider>(context, listen: false)
                      .deleteTransaction(transaction);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction deleted")),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
