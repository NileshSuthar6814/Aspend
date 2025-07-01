import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/person.dart';
import '../models/person_transaction.dart';

class PersonBackupHelper {
  static Future<void> exportToJsonAndShare() async {
    final peopleBox = Hive.box<Person>('people');
    final transactionsBox = Hive.box<PersonTransaction>('personTransactions');

    final exportData = peopleBox.values.map((person) {
      final personTxs = transactionsBox.values
          .where((tx) => tx.personName == person.name)
          .toList();

      return {
        'person': person.toJson(),
        'transactions': personTxs.map((tx) => tx.toJson()).toList(),
      };
    }).toList();

    final jsonStr = jsonEncode(exportData);

    final dir = await getExternalStorageDirectory();
    if (dir == null) return;

    final file = File('${dir.path}/person_data_backup.json');
    await file.writeAsString(jsonStr);

    // Share the file using the system share sheet
    await Share.shareXFiles([XFile(file.path)], text: 'Aspends Tracker Backup');
  }

  static Future<void> importFromJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final contents = await file.readAsString();

      final List<dynamic> jsonData = jsonDecode(contents);

      final peopleBox = Hive.box<Person>('people');
      final txBox = Hive.box<PersonTransaction>('personTransactions');

      for (var entry in jsonData) {
        final person = Person.fromJson(entry['person']);
        final personName = person.name;

        if (!peopleBox.values.any((p) => p.name == personName)) {
          await peopleBox.add(person);
        }

        for (var txJson in entry['transactions']) {
          final tx = PersonTransaction.fromJson(txJson);
          txBox.add(tx);
        }
      }
    }
  }
}
