import 'dart:convert';
import 'dart:io';
import 'package:aspends_tracker/models/transaction.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExporter {
  static Future<String> exportToJson() async {
    final box = Hive.box<Transaction>('transactions');
    final transactions = box.values.map((t) => {
      'amount': t.amount,
      'note': t.note,
      'category': t.category,
      'account': t.account,
      'date': t.date.toIso8601String(),
      'isIncome': t.isIncome,
      'imagePaths': t.imagePaths ?? [],
    }).toList();

    final data = jsonEncode(transactions);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aspends_backup.json');
    await file.writeAsString(data);

    return file.path;
  }

  static Future<void> shareBackupFile() async {
    final filePath = await exportToJson();
    Share.shareXFiles([XFile(filePath)], text: 'Aspends Backup File');
  }
}
