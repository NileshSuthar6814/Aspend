import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/person_transaction.dart';

class PersonTransactionProvider extends ChangeNotifier {
  final _box = Hive.box<PersonTransaction>('personTransactions');

  List<PersonTransaction> get transactions =>
      _box.values.toList().reversed.toList();

  void addTransaction(PersonTransaction tx) {
    _box.add(tx);
    notifyListeners();
  }

  void deleteTransaction(PersonTransaction tx) {
    tx.delete();
    notifyListeners();
  }

  Map<String, List<PersonTransaction>> get groupedByPerson {
    final Map<String, List<PersonTransaction>> grouped = {};
    for (var tx in transactions) {
      if (!grouped.containsKey(tx.personName)) {
        grouped[tx.personName] = [];
      }
      grouped[tx.personName]!.add(tx);
    }
    return grouped;
  }

  double getTotalForPerson(String name) {
    return groupedByPerson[name]
        ?.fold(0.0, (sum, tx) => sum! + tx.amount) ??
        0.0;
  }
  Future<void> deleteAllData() async {
    final people = _box.values.toList();
    for (var person in people) {
      await person.delete();
    }
    await _box.clear();
    notifyListeners();
  }
}
