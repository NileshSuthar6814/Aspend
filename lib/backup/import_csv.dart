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
        );
        box.add(tx);
        // Fluttertoast.showToast(
        //     msg: "No File Selected",
        //     toastLength: Toast.LENGTH_SHORT,
        //     gravity: ToastGravity.CENTER,
        //     timeInSecForIosWeb: 1,
        //     backgroundColor: Colors.red,
        //     textColor: Colors.white,
        //     fontSize: 16.0
        // );
    HapticFeedback.heavyImpact();
      }
      
      // Notify provider to reload data
      if (context.mounted) {
        context.read<TransactionProvider>().loadTransactions();
      }
    }
    else if (result == null) {
      (
       Fluttertoast.showToast(
           msg: "No File Selected",
           toastLength: Toast.LENGTH_SHORT,
           gravity: ToastGravity.CENTER,
           timeInSecForIosWeb: 1,
           backgroundColor: Colors.red,
           textColor: Colors.white,
           fontSize: 16.0
       ),
       HapticFeedback.heavyImpact(),
       );
     }
  }
}
