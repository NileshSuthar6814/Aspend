import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  double _currentBalance = 0;
  
  // Memoization for expensive computations
  List<Transaction>? _cachedSpends;
  List<Transaction>? _cachedIncomes;
  Map<String, List<Transaction>>? _cachedGroupedTransactions;
  double? _cachedTotalSpend;
  double? _cachedTotalIncome;
  bool _isDirty = true;

  TransactionProvider() {
    loadTransactions();
  }

  List<Transaction> get transactions => _transactions;

  double get totalBalance => _currentBalance;

  // Memoized getters for expensive computations
  List<Transaction> get spends {
    if (_cachedSpends == null || _isDirty) {
      _cachedSpends = _transactions.where((t) => !t.isIncome).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return _cachedSpends!;
  }

  List<Transaction> get incomes {
    if (_cachedIncomes == null || _isDirty) {
      _cachedIncomes = _transactions.where((t) => t.isIncome).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return _cachedIncomes!;
  }

  // Get all transactions sorted by date (newest first)
  List<Transaction> get sortedTransactions {
    if (_isDirty) {
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }
    return _transactions;
  }

  double get totalSpend {
    if (_cachedTotalSpend == null || _isDirty) {
      final spendList = _cachedSpends ?? _transactions.where((t) => !t.isIncome).toList();
      _cachedTotalSpend = spendList.fold(0.0, (sum, tx) => sum! + tx.amount);
    }
    return _cachedTotalSpend ?? 0.0;
  }

  double get totalIncome {
    if (_cachedTotalIncome == null || _isDirty) {
      final incomeList = _cachedIncomes ?? _transactions.where((t) => t.isIncome).toList();
      _cachedTotalIncome = incomeList.fold(0.0, (sum, tx) => sum! + tx.amount);
    }
    return _cachedTotalIncome ?? 0.0;
  }

  Map<String, List<Transaction>> get groupedTransactions {
    if (_cachedGroupedTransactions == null || _isDirty) {
      _cachedGroupedTransactions = _groupTransactionsByDate(_transactions);
      // Sort transactions within each group by date (newest first)
      _cachedGroupedTransactions!.forEach((key, transactions) {
        transactions.sort((a, b) => b.date.compareTo(a.date));
      });
    }
    return _cachedGroupedTransactions!;
  }

  void _markDirty() {
    _isDirty = true;
    _cachedSpends = null;
    _cachedIncomes = null;
    _cachedGroupedTransactions = null;
    _cachedTotalSpend = null;
    _cachedTotalIncome = null;
  }

  void loadTransactions() async {
    try {
      // Load transactions from Hive
      final box = Hive.box<Transaction>('transactions');
      final transactions = box.values.toList();
      _transactions = transactions.cast<Transaction>();

      // Load current balance from Hive
      final balanceBox = Hive.box<double>('balanceBox');
      _currentBalance = balanceBox.get('currentBalance', defaultValue: 0.0) ?? 0.0;

      _markDirty();
      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
      // Fallback to direct Hive access
      try {
        final txBox = Hive.box<Transaction>('transactions');
        final balanceBox = Hive.box<double>('balanceBox');
        _transactions = txBox.values.toList();
        _currentBalance = balanceBox.get('currentBalance', defaultValue: 0.0) ?? 0.0;
        _markDirty();
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error loading transactions: $fallbackError');
        // Initialize with empty state
        _transactions = [];
        _currentBalance = 0.0;
        _markDirty();
        notifyListeners();
      }
    }
  }

  void addTransaction(Transaction tx) async {
    try {
      // Add to Hive first
      final txBox = Hive.box<Transaction>('transactions');
      await txBox.add(tx);
      
      // Add to local list
      _transactions.add(tx);
      _markDirty();
      
      // Update balance and persist
      addOrMinusBalance(tx.amount, tx.isIncome);
      
      // Update home widget
      _updateHomeWidget();
      
      notifyListeners();
    } catch (e) {
      print('Error adding transaction: $e');
      // Fallback to direct Hive access
      try {
        final txBox = Hive.box<Transaction>('transactions');
        txBox.add(tx);
        _transactions.add(tx);
        _markDirty();
        addOrMinusBalance(tx.amount, tx.isIncome);
        _updateHomeWidget();
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error adding transaction: $fallbackError');
      }
    }
  }

  void deleteTransaction(Transaction transaction) async {
    try {
      final txBox = Hive.box<Transaction>('transactions');

      // Update balance before deletion
      addOrMinusBalance(-transaction.amount, transaction.isIncome);

      // Delete from Hive
      await txBox.delete(transaction.key);
      
      // Remove from local list
      _transactions.removeWhere((tx) => tx.key == transaction.key);
      _markDirty();

      // Update home widget
      _updateHomeWidget();
      
      notifyListeners();
    } catch (e) {
      print('Error deleting transaction: $e');
      // Fallback to direct Hive access
      try {
        final txBox = Hive.box<Transaction>('transactions');
        addOrMinusBalance(-transaction.amount, transaction.isIncome);
        txBox.delete(transaction.key);
        _transactions.removeWhere((tx) => tx.key == transaction.key);
        _markDirty();
        _updateHomeWidget();
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error deleting transaction: $fallbackError');
      }
    }
  }

  void updateBalance(double newBalance) {
    try {
      _currentBalance = newBalance;

      final balanceBox = Hive.box<double>('balanceBox');
      balanceBox.put('currentBalance', newBalance);

      notifyListeners();
    } catch (e) {
      print('Error updating balance: $e');
      // Fallback to direct Hive access
      try {
        _currentBalance = newBalance;
        final balanceBox = Hive.box<double>('balanceBox');
        balanceBox.put('currentBalance', newBalance);
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error updating balance: $fallbackError');
      }
    }
  }

  void addOrMinusBalance(double amount, bool isIncome) {
    try {
      _currentBalance += isIncome ? amount : -amount;

      final balanceBox = Hive.box<double>('balanceBox');
      balanceBox.put('currentBalance', _currentBalance);

      notifyListeners();
    } catch (e) {
      print('Error updating balance: $e');
      // Fallback to direct Hive access
      try {
        _currentBalance += isIncome ? amount : -amount;
        final balanceBox = Hive.box<double>('balanceBox');
        balanceBox.put('currentBalance', _currentBalance);
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error updating balance: $fallbackError');
      }
    }
  }

  Future<void> deleteAllData() async {
    try {
      final txBox = Hive.box<Transaction>('transactions');
      await txBox.clear();
      _transactions.clear();
      _markDirty();

      final balanceBox = Hive.box<double>('balanceBox');
      await balanceBox.put('currentBalance', 0.0);
      _currentBalance = 0.0;

      // Update home widget
      _updateHomeWidget();
      
      notifyListeners();
    } catch (e) {
      print('Error deleting all data: $e');
      // Fallback to direct Hive access
      try {
        final txBox = Hive.box<Transaction>('transactions');
        txBox.clear();
        _transactions.clear();
        _markDirty();

        final balanceBox = Hive.box<double>('balanceBox');
        balanceBox.put('currentBalance', 0.0);
        _currentBalance = 0.0;

        _updateHomeWidget();
        notifyListeners();
      } catch (fallbackError) {
        print('Fallback error deleting all data: $fallbackError');
      }
    }
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

  // Optimized transaction grouping method
  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    
    for (var tx in transactions) {
      final DateTime txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String formattedDate;
      
      if (txDate == today) {
        formattedDate = "Today";
      } else if (txDate == yesterday) {
        formattedDate = "Yesterday";
      } else {
        formattedDate = _formatDate(tx.date);
      }
      
      grouped.putIfAbsent(formattedDate, () => []).add(tx);
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void updateTransaction(Transaction oldTx, Transaction newTx) async {
    try {
      final txBox = Hive.box<Transaction>('transactions');
      // Update in Hive
      await txBox.put(oldTx.key, newTx);
      // Update in local list
      final idx = _transactions.indexWhere((t) => t.key == oldTx.key);
      if (idx != -1) {
        _transactions[idx] = newTx;
        _markDirty();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }
}
