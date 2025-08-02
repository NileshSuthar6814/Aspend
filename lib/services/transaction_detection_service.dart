import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/transaction.dart';
import 'native_bridge.dart';

class TransactionDetectionService {
  static const String _settingsBoxName = 'settings';
  static const String _autoDetectionKey = 'autoDetectionEnabled';

  // Transaction patterns for different banks and services
  static final List<RegExp> _transactionPatterns = [
    RegExp(r'Rs\.?(\d+(?:\.\d{2})?)\s*(?:credited|debited|paid|sent|received)',
        caseSensitive: false),
    RegExp(r'₹(\d+(?:\.\d{2})?)\s*(?:credited|debited|paid|sent|received)',
        caseSensitive: false),
    RegExp(r'(\d+(?:\.\d{2})?)\s*(?:credited|debited|paid|sent|received)',
        caseSensitive: false),
  ];

  // Bank keywords for categorization
  static final Map<String, String> _bankKeywords = {
    'hdfc': 'HDFC Bank',
    'sbi': 'State Bank of India',
    'icici': 'ICICI Bank',
    'axis': 'Axis Bank',
    'kotak': 'Kotak Bank',
    'yes': 'Yes Bank',
    'paytm': 'Paytm',
    'phonepe': 'PhonePe',
    'googlepay': 'Google Pay',
    'amazonpay': 'Amazon Pay',
    'bhim': 'BHIM UPI',
  };

  static Future<void> initialize() async {
    // Check if auto-detection is enabled
    final settingsBox = await Hive.openBox(_settingsBoxName);
    final isEnabled = settingsBox.get(_autoDetectionKey, defaultValue: false);

    if (isEnabled) {
      await startMonitoring();
    }
  }

  static Future<void> startMonitoring() async {
    try {
      // Request permissions
      await _requestPermissions();

      // Start notification monitoring
      await _startNotificationMonitoring();

      // Start keep alive service to prevent app from being killed
      await NativeBridge.startKeepAliveService();

      print('Transaction detection monitoring started successfully');
    } catch (e) {
      print('Error starting transaction detection: $e');
    }
  }

  static Future<void> stopMonitoring() async {
    try {
      // Stop keep alive service
      await NativeBridge.stopKeepAliveService();
      print('Transaction detection monitoring stopped');
    } catch (e) {
      print('Error stopping transaction detection: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    // Request notification access permission
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      throw Exception(
          'Notification permission is required for automatic transaction detection');
    }

    // For now, we'll rely on the native Android implementation
    // which handles permissions through the system settings
  }

  static Future<void> _startNotificationMonitoring() async {
    // Notification monitoring will be handled through native bridge
    print('Notification monitoring started through native bridge');
  }

  static Future<void> processNotification(String title, String body) async {
    try {
      final fullText = '$title $body';
      final detectedTransaction = _extractTransactionFromText(fullText);
      if (detectedTransaction != null) {
        await _addDetectedTransaction(detectedTransaction, 'Notification');
      }
    } catch (e) {
      print('Error processing notification: $e');
    }
  }

  static Future<void> processSmsMessage(String body) async {
    try {
      final detectedTransaction = _extractTransactionFromText(body);
      if (detectedTransaction != null) {
        await _addDetectedTransaction(detectedTransaction, 'SMS');
      }
    } catch (e) {
      print('Error processing SMS message: $e');
    }
  }

  static Transaction? _extractTransactionFromText(String text) {
    try {
      // Try different patterns
      for (final pattern in _transactionPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final amountStr = match.group(1);
          if (amountStr != null) {
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0) {
              // Determine if it's income or expense based on keywords
              final isIncome = text.toLowerCase().contains('credited') ||
                  text.toLowerCase().contains('received');

              // Extract category from bank keywords
              String category = 'Bank Transaction';
              for (final entry in _bankKeywords.entries) {
                if (text.toLowerCase().contains(entry.key)) {
                  category = entry.value;
                  break;
                }
              }

              // Extract account info
              String account = 'Auto Detected';
              if (text.toLowerCase().contains('upi')) {
                account = 'UPI';
              } else if (text.toLowerCase().contains('atm')) {
                account = 'ATM';
              } else if (text.toLowerCase().contains('net banking')) {
                account = 'Net Banking';
              }

              return Transaction(
                amount: amount,
                note: 'Auto-detected from ${isIncome ? "credit" : "debit"}',
                category: category,
                account: account,
                date: DateTime.now(),
                isIncome: isIncome,
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting transaction from text: $e');
    }
    return null;
  }

  static Future<void> _addDetectedTransaction(
      Transaction transaction, String source) async {
    try {
      // Open transaction box
      final transactionBox = await Hive.openBox<Transaction>('transactions');

      // Add the transaction
      await transactionBox.add(transaction);

      // Update balance
      final balanceBox = await Hive.openBox<double>('balanceBox');
      final currentBalance =
          balanceBox.get('balance', defaultValue: 0.0) ?? 0.0;
      final newBalance = transaction.isIncome
          ? currentBalance + transaction.amount
          : currentBalance - transaction.amount;
      await balanceBox.put('balance', newBalance);

      print(
          'Auto-detected transaction added: ${transaction.amount} from $source');

      // Show notification to user
      await _showTransactionNotification(transaction, source);
    } catch (e) {
      print('Error adding detected transaction: $e');
    }
  }

  static Future<void> _showTransactionNotification(
      Transaction transaction, String source) async {
    // For now, we'll just print to console
    // In a future update, we can implement a custom notification system
    print('New transaction detected from $source: ₹${transaction.amount}');
  }

  static Future<bool> isEnabled() async {
    final settingsBox = await Hive.openBox(_settingsBoxName);
    return settingsBox.get(_autoDetectionKey, defaultValue: false);
  }

  static Future<void> setEnabled(bool enabled) async {
    final settingsBox = await Hive.openBox(_settingsBoxName);
    await settingsBox.put(_autoDetectionKey, enabled);

    if (enabled) {
      await startMonitoring();
    } else {
      await stopMonitoring();
    }
  }

  // Method to manually process recent notifications
  static Future<void> processRecentSms() async {
    try {
      // This will be handled through native bridge
      print('Processing recent notifications through native bridge');
    } catch (e) {
      print('Error processing recent notifications: $e');
    }
  }
}

// Background message handler for notifications
@pragma('vm:entry-point')
void backgroundMessageHandler(String messageBody) {
  TransactionDetectionService.processSmsMessage(messageBody);
}
