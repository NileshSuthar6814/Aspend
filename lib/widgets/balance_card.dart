import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final Function(double) onBalanceUpdate;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.onBalanceUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final isDark = context.watch<AppThemeProvider>().isDarkMode;

    return GestureDetector(
      onLongPress: () => _showEditBalanceDialog(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.teal[900] : Colors.teal[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Balance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                color: isPositive ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBalanceDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Balance",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "New Balance"),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.teal)),
          ),
          ElevatedButton(
            onPressed: () {
              final newBalance = double.tryParse(controller.text);
              if (newBalance != null) {
                onBalanceUpdate(newBalance);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid number")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
