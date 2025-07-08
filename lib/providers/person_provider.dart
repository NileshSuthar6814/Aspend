import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/person.dart';
import '../models/person_transaction.dart';

class PersonProvider with ChangeNotifier {
  List<Person> _people = [];

  PersonProvider() {
    loadPeople();
  }

  List<Person> get people => _people;

  void loadPeople() async {
    try {
      // Load people from Hive
      final box = Hive.box<Person>('people');
      _people = box.values.toList();
      notifyListeners();
    } catch (e) {
      print('Error loading people: $e');
      // Fallback to direct Hive access
      try {
        final peopleBox = Hive.box<Person>('people');
        _people = peopleBox.values.toList();
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error loading people: $fallbackError');
        // Initialize with empty state
        _people = [];
        notifyListeners();
      }
    }
  }

  void addPerson(Person person) async {
    try {
      // Add to Hive first
      final box = Hive.box<Person>('people');
      await box.add(person);
      
      // Add to local list
      _people.add(person);
      notifyListeners();
    } catch (e) {
      print('Error adding person: $e');
      // Fallback to direct Hive access
      try {
        final peopleBox = Hive.box<Person>('people');
        peopleBox.add(person);
        _people.add(person);
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error adding person: $fallbackError');
      }
    }
  }

  void deletePerson(Person person) async {
    try {
      // Delete from Hive first
      final box = Hive.box<Person>('people');
      await box.delete(person.key);
      
      // Remove from local list
      _people.removeWhere((p) => p.key == person.key);
      notifyListeners();
    } catch (e) {
      print('Error deleting person: $e');
      // Fallback to direct Hive access
      try {
        final peopleBox = Hive.box<Person>('people');
        peopleBox.delete(person.key);
        _people.removeWhere((p) => p.key == person.key);
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error deleting person: $fallbackError');
      }
    }
  }

  List<PersonTransaction> transactionsFor(String personName) {
    final personTransactionBox = Hive.box<PersonTransaction>('personTransactions');
    final transactions = personTransactionBox.values
        .where((tx) => tx.personName == personName)
        .toList();
    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<void> deleteAllData() async {
    try {
      final peopleBox = Hive.box<Person>('people');
      await peopleBox.clear();
      _people.clear();
      notifyListeners();
    } catch (e) {
      print('Error deleting all people data: $e');
      // Fallback to direct Hive access
      try {
        final peopleBox = Hive.box<Person>('people');
        peopleBox.clear();
        _people.clear();
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error deleting all people data: $fallbackError');
      }
    }
  }

  double totalFor(String name) {
    return transactionsFor(name).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> addTransaction(PersonTransaction tx) async {
    try {
      // Add to Hive first
      final txBox = Hive.box<PersonTransaction>('personTransactions');
      await txBox.add(tx);
      
      notifyListeners();
    } catch (e) {
      print('Error adding person transaction: $e');
      // Fallback to direct Hive access
      try {
        Hive.box<PersonTransaction>('personTransactions').add(tx);
    notifyListeners();
      } catch (fallbackError) {
        print('Fallback error adding person transaction: $fallbackError');
      }
    }
  }

  Future<void> deleteTransaction(PersonTransaction tx) async {
    final txBox = Hive.box<PersonTransaction>('personTransactions');
    await tx.delete();
    notifyListeners();
  }
}
