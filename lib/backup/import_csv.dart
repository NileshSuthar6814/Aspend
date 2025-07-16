import 'dart:convert';
import 'dart:io';
import 'package:aspends_tracker/models/transaction.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class DataImporter {
  static Future<void> importFromJson(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    try {
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(content);

      final box = Hive.box<Transaction>('transactions');
      for (var item in decoded) {
        final tx = Transaction(
          amount: item['amount'],
          note: item['note'],
          category: item['category'],
          account: item['account'],
          date: DateTime.parse(item['date']),
          isIncome: item['isIncome'],
            imagePaths: (item['imagePaths'] as List?)?.map((e) => e.toString()).toList(),
        );
        box.add(tx);
    HapticFeedback.heavyImpact();
      }
      // Notify provider to reload data
      if (context.mounted) {
        context.read<TransactionProvider>().loadTransactions();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
           backgroundColor: Colors.red,
       ),
       );
      }
     }
  }
}
