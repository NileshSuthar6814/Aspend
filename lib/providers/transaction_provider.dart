import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  double _currentBalance = 0;

  TransactionProvider() {
    loadTransactions();
  }

  List<Transaction> get transactions => _transactions;

  double get totalBalance => _currentBalance;

  void loadTransactions() async {
    try {
      // Load transactions
      final box = await Hive.openBox('transactions');
      final transactions = box.values.toList();
      _transactions = transactions.cast<Transaction>();

      // Load current balance from Hive
      final balanceBox = Hive.box<double>('balanceBox');
      _currentBalance = balanceBox.get('currentBalance', defaultValue: 0.0) ?? 0.0;

      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
      // Fallback to direct Hive access
      final txBox = Hive.box<Transaction>('transactions');
      final balanceBox = Hive.box<double>('balanceBox');
      _transactions = txBox.values.toList();
      _currentBalance = balanceBox.get('currentBalance', defaultValue: 0.0) ?? 0.0;
      notifyListeners();
    }
  }

  void addTransaction(Transaction tx) async {
    try {
      // Update balance and persist
      addOrMinusBalance(tx.amount, tx.isIncome);
      
      // Update home widget
      _updateHomeWidget();
      
      notifyListeners();
    } catch (e) {
      print('Error adding transaction: $e');
      // Fallback to direct Hive access
      final txBox = Hive.box<Transaction>('transactions');
      txBox.add(tx);
      _transactions.add(tx);
      addOrMinusBalance(tx.amount, tx.isIncome);
      _updateHomeWidget();
      notifyListeners();
    }
  }

  void deleteTransaction(Transaction transaction) async {
    final txBox = Hive.box<Transaction>('transactions');

    // Update balance before deletion
    addOrMinusBalance(-transaction.amount, transaction.isIncome);

    await txBox.delete(transaction.key);
    _transactions.removeWhere((tx) => tx.key == transaction.key);

    // Update home widget
    _updateHomeWidget();
    
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

    // Update home widget
    _updateHomeWidget();
    
    notifyListeners();
  }

  void _updateHomeWidget() async {
    try {
      await HomeWidget.saveWidgetData('balance', _currentBalance.toString());
      await HomeWidget.saveWidgetData('transaction_count', _transactions.length.toString());
      await HomeWidget.updateWidget(
        androidName: 'HomeWidgetProvider',
        iOSName: 'HomeWidget',
      );
    } catch (e) {
      print('Error updating home widget: $e');
    }
  }
}
