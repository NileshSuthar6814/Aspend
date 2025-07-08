import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _settingsBoxName = 'settings';
  static const String _transactionsBoxName = 'transactions';
  static const String _balanceBoxName = 'balanceBox';
  static const String _peopleBoxName = 'people';
  static const String _personTransactionsBoxName = 'personTransactions';

  // Settings keys
  static const String _introCompletedKey = 'introCompleted';
  static const String _introCompletedAtKey = 'introCompletedAt';
  static const String _startingBalanceKey = 'startingBalance';

  // Singleton pattern
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Box instances
  late Box _settingsBox;
  late Box<dynamic> _transactionsBox;
  late Box<double> _balanceBox;
  late Box<dynamic> _peopleBox;
  late Box<dynamic> _personTransactionsBox;

  // Initialize Hive and open all boxes
  Future<void> initialize() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _transactionsBox = await Hive.openBox(_transactionsBoxName);
    _balanceBox = await Hive.openBox<double>(_balanceBoxName);
    _peopleBox = await Hive.openBox(_peopleBoxName);
    _personTransactionsBox = await Hive.openBox(_personTransactionsBoxName);
  }

  // Intro completion methods
  Future<bool> isIntroCompleted() async {
    try {
      final introCompleted = _settingsBox.get(_introCompletedKey, defaultValue: false);
      final introCompletedAt = _settingsBox.get(_introCompletedAtKey, defaultValue: 0);
      return introCompleted == true && introCompletedAt > 0;
    } catch (e) {
      print('Error checking intro completion: $e');
      return false;
    }
  }

  Future<void> markIntroCompleted() async {
    try {
      await _settingsBox.put(_introCompletedKey, true);
      await _settingsBox.put(_introCompletedAtKey, DateTime.now().millisecondsSinceEpoch);
      await _settingsBox.flush();
    } catch (e) {
      print('Error marking intro as completed: $e');
      rethrow;
    }
  }

  Future<void> resetIntro() async {
    try {
      await _settingsBox.delete(_introCompletedKey);
      await _settingsBox.delete(_introCompletedAtKey);
      await _settingsBox.flush();
    } catch (e) {
      print('Error resetting intro: $e');
      rethrow;
    }
  }

  // Balance methods
  Future<double> getStartingBalance() async {
    try {
      final balance = _balanceBox.get(_startingBalanceKey, defaultValue: 0.0);
      return balance ?? 0.0;
    } catch (e) {
      print('Error getting starting balance: $e');
      return 0.0;
    }
  }

  Future<void> setStartingBalance(double balance) async {
    try {
      await _balanceBox.put(_startingBalanceKey, balance);
      await _balanceBox.flush();
    } catch (e) {
      print('Error setting starting balance: $e');
      rethrow;
    }
  }

  // Transaction methods
  Future<List<dynamic>> getAllTransactions() async {
    try {
      return _transactionsBox.values.toList();
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }

  Future<void> saveTransaction(dynamic transaction) async {
    try {
      await _transactionsBox.add(transaction);
      await _transactionsBox.flush();
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteAllTransactions() async {
    try {
      await _transactionsBox.clear();
      await _transactionsBox.flush();
    } catch (e) {
      print('Error deleting all transactions: $e');
      rethrow;
    }
  }

  // People methods
  Future<List<dynamic>> getAllPeople() async {
    try {
      return _peopleBox.values.toList();
    } catch (e) {
      print('Error getting all people: $e');
      return [];
    }
  }

  Future<void> savePerson(dynamic person) async {
    try {
      await _peopleBox.add(person);
      await _peopleBox.flush();
    } catch (e) {
      print('Error saving person: $e');
      rethrow;
    }
  }

  Future<void> deleteAllPeople() async {
    try {
      await _peopleBox.clear();
      await _personTransactionsBox.clear();
      await _peopleBox.flush();
      await _personTransactionsBox.flush();
    } catch (e) {
      print('Error deleting all people: $e');
      rethrow;
    }
  }

  // Person transaction methods
  Future<List<dynamic>> getAllPersonTransactions() async {
    try {
      return _personTransactionsBox.values.toList();
    } catch (e) {
      print('Error getting all person transactions: $e');
      return [];
    }
  }

  Future<void> savePersonTransaction(dynamic personTransaction) async {
    try {
      await _personTransactionsBox.add(personTransaction);
      await _personTransactionsBox.flush();
    } catch (e) {
      print('Error saving person transaction: $e');
      rethrow;
    }
  }

  // Utility methods
  Future<void> clearAllData() async {
    try {
      await deleteAllTransactions();
      await deleteAllPeople();
      await setStartingBalance(0.0);
      await resetIntro();
    } catch (e) {
      print('Error clearing all data: $e');
      rethrow;
    }
  }

  Future<bool> hasAnyData() async {
    try {
      final hasTransactions = _transactionsBox.isNotEmpty;
      final hasPeople = _peopleBox.isNotEmpty;
      final hasBalance = await getStartingBalance() > 0;
      return hasTransactions || hasPeople || hasBalance;
    } catch (e) {
      print('Error checking if app has data: $e');
      return false;
    }
  }

  // Close all boxes
  Future<void> close() async {
    try {
      await _settingsBox.close();
      await _transactionsBox.close();
      await _balanceBox.close();
      await _peopleBox.close();
      await _personTransactionsBox.close();
    } catch (e) {
      print('Error closing Hive boxes: $e');
    }
  }
} 