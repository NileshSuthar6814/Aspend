import 'dart:io';
//import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction.dart';
import '../models/person.dart';
import '../models/person_transaction.dart';

class PDFService {
  static Future<File> generateHomeTransactionPDF() async {
    final box = Hive.box<Transaction>('transactions');
    final pdf = pw.Document();
    final txList = box.values.toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Aspends Tracker - All Transactions'),
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(
            headers: ['Date', 'Note', 'Amount', 'Account', 'Category'],
            data: txList.map((tx) {
              return [
                tx.date.toString().split('.').first,
                tx.note,
                '${tx.isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                tx.account,
                tx.category,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/home_transactions.pdf');
    return file.writeAsBytes(await pdf.save());
  }

  static Future<File> generatePeopleTransactionPDF() async {
    final personBox = Hive.box<Person>('people');
    final txBox = Hive.box<PersonTransaction>('personTransactions');
    final pdf = pw.Document();

    for (var person in personBox.values) {
      final txs = txBox.values
          .where((tx) => tx.personName == person.name)
          .toList();

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, text: 'Transactions for ${person.name}'),
            txs.isEmpty
                ? pw.Paragraph(text: 'No transactions yet.')
                // ignore: deprecated_member_use
                : pw.Table.fromTextArray(
              headers: ['Date', 'Note', 'Amount'],
              data: txs.map((tx) {
                return [
                  tx.date.toString().split('.').first,
                  tx.note,
                  '${tx.amount >= 0 ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/person_transactions.pdf');
    return file.writeAsBytes(await pdf.save());
  }
}
