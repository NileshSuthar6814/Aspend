import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/person_transaction.dart';

class PersonTransactionProvider extends ChangeNotifier {
  List<PersonTransaction> _transactions = [];
  Map<String, List<PersonTransaction>>? _cachedGroupedByPerson;
  Map<String, double>? _cachedTotals;
  bool _isDirty = true;

  PersonTransactionProvider() {
    loadTransactions();
  }

  List<PersonTransaction> get transactions {
    if (_isDirty) {
      _transactions = _box.values.toList().reversed.toList();
      // Sort by date (newest first)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _isDirty = false;
    }
    return _transactions;
  }

  Box<PersonTransaction> get _box => Hive.box<PersonTransaction>('personTransactions');

  void loadTransactions() {
    try {
      // Load transactions from Hive
      _transactions = _box.values.toList();
      // Sort by date (newest first)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _markDirty();
      notifyListeners();
    } catch (e) {
      print('Error loading person transactions: $e');
      // Fallback to empty state
      _transactions = [];
      _markDirty();
      notifyListeners();
    }
  }

  void addTransaction(PersonTransaction tx) {
    try {
      // Add to Hive first
      _box.add(tx);
      
      // Add to local list
      _transactions.insert(0, tx);
      _markDirty();
      notifyListeners();
    } catch (e) {
      print('Error adding person transaction: $e');
      // Fallback to direct Hive access
      try {
    _box.add(tx);
        _transactions.insert(0, tx);
        _markDirty();
    notifyListeners();
      } catch (fallbackError) {
        print('Fallback error adding person transaction: $fallbackError');
      }
    }
  }

  void deleteTransaction(PersonTransaction tx) {
    try {
      // Delete from Hive first
      tx.delete();
      
      // Remove from local list
      _transactions.remove(tx);
      _markDirty();
      notifyListeners();
    } catch (e) {
      print('Error deleting person transaction: $e');
      // Fallback to direct Hive access
      try {
    tx.delete();
        _transactions.remove(tx);
        _markDirty();
    notifyListeners();
      } catch (fallbackError) {
        print('Fallback error deleting person transaction: $fallbackError');
      }
    }
  }

  Map<String, List<PersonTransaction>> get groupedByPerson {
    if (_cachedGroupedByPerson == null || _isDirty) {
    final Map<String, List<PersonTransaction>> grouped = {};
    for (var tx in transactions) {
      if (!grouped.containsKey(tx.personName)) {
        grouped[tx.personName] = [];
      }
      grouped[tx.personName]!.add(tx);
    }
      _cachedGroupedByPerson = grouped;
    }
    return _cachedGroupedByPerson!;
  }

  double getTotalForPerson(String name) {
    if (_cachedTotals == null || _isDirty) {
      _cachedTotals = {};
      for (var tx in transactions) {
        _cachedTotals![tx.personName] = (_cachedTotals![tx.personName] ?? 0.0) + (tx.isIncome ? tx.amount : -tx.amount);
      }
    }
    return _cachedTotals![name] ?? 0.0;
  }

  void _markDirty() {
    _isDirty = true;
    _cachedGroupedByPerson = null;
    _cachedTotals = null;
  }

  Future<void> deleteAllData() async {
    try {
    final people = _box.values.toList();
    for (var person in people) {
      await person.delete();
    }
    await _box.clear();
      _transactions.clear();
      _markDirty();
      notifyListeners();
    } catch (e) {
      print('Error deleting all person transaction data: $e');
      // Fallback to direct Hive access
      try {
        final people = _box.values.toList();
        for (var person in people) {
          person.delete();
        }
        _box.clear();
        _transactions.clear();
        _markDirty();
    notifyListeners();
      } catch (fallbackError) {
        print('Fallback error deleting all person transaction data: $fallbackError');
      }
    }
  }
}
