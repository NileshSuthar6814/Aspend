import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  double _currentBalance = 0;

  TransactionProvider() {
    loadTransactions();
  }

  List<Transaction> get transactions => _transactions;

  double get totalBalance => _currentBalance;

  void loadTransactions() {
    final txBox = Hive.box<Transaction>('transactions');
    final balanceBox = Hive.box<double>('balanceBox');

    // Load transactions
    _transactions = txBox.values.toList();

    // Load current balance from Hive
    _currentBalance =
        balanceBox.get('currentBalance', defaultValue: 0.0) ?? 0.0;

    notifyListeners();
  }

  void addTransaction(Transaction tx) {
    final txBox = Hive.box<Transaction>('transactions');
    txBox.add(tx);
    _transactions.add(tx);

    // Update balance and persist
    addOrMinusBalance(tx.amount, tx.isIncome);
    notifyListeners();
  }

  void deleteTransaction(Transaction transaction) async {
    final txBox = Hive.box<Transaction>('transactions');

    // Update balance before deletion
    addOrMinusBalance(-transaction.amount, transaction.isIncome);

    await txBox.delete(transaction.key);
    _transactions.removeWhere((tx) => tx.key == transaction.key);

    notifyListeners();
  }

  void updateBalance(double newBalance) {
    _currentBalance = newBalance;

    final balanceBox = Hive.box<double>('balanceBox');
    balanceBox.put('currentBalance', newBalance);

    notifyListeners();
  }

  void addOrMinusBalance(double amount, bool isIncome) {
    _currentBalance += isIncome ? amount : -amount;

    final balanceBox = Hive.box<double>('balanceBox');
    balanceBox.put('currentBalance', _currentBalance);

    notifyListeners();
  }

  Future<void> deleteAllData() async {
    final txBox = Hive.box<Transaction>('transactions');
    await txBox.clear();
    _transactions.clear();

    final balanceBox = Hive.box<double>('balanceBox');
    await balanceBox.put('currentBalance', 0.0);
    _currentBalance = 0.0;

    notifyListeners();
  }
}
