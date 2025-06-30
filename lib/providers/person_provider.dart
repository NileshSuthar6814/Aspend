import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/person.dart';
import '../models/person_transaction.dart';

class PersonProvider extends ChangeNotifier {
  final Box<Person> _peopleBox = Hive.box<Person>('people');
  final Box<PersonTransaction> _txBox = Hive.box<PersonTransaction>('personTransactions');

  List<Person> get people => _peopleBox.values.toList();

  List<PersonTransaction> transactionsFor(String name) {
    return _txBox.values
        .where((tx) => tx.personName == name)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double totalFor(String name) {
    return transactionsFor(name).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> addPerson(String name) async {
    await _peopleBox.add(Person(name: name));
    notifyListeners();
  }

  Future<void> deletePerson(Person p) async {
    await _peopleBox.delete(p.key);
    _txBox.values
        .where((tx) => tx.personName == p.name)
        .forEach((tx) => tx.delete());
    notifyListeners();
  }

  Future<void> addTransaction(PersonTransaction tx) async {
    await _txBox.add(tx);
    notifyListeners();
  }

  Future<void> deleteTransaction(PersonTransaction tx) async {
    await tx.delete();
    notifyListeners();
  }
}
