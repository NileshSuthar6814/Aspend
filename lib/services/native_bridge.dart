import 'package:flutter/services.dart';

import 'transaction_detection_service.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('transaction_detection');

  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        final title = call.arguments['title'] as String? ?? '';
        final text = call.arguments['text'] as String? ?? '';
        final bigText = call.arguments['bigText'] as String? ?? '';
        final fullText = call.arguments['fullText'] as String? ?? '';
        final packageName = call.arguments['packageName'] as String? ?? '';

        // Process the notification through our service
        await TransactionDetectionService.processNotification(title, text);
        break;

      case 'onSmsReceived':
        final sender = call.arguments['sender'] as String? ?? '';
        final body = call.arguments['body'] as String? ?? '';
        final timestamp = call.arguments['timestamp'] as int? ?? 0;

        // Process the notification through our service
        await TransactionDetectionService.processSmsMessage(body);
        break;

      default:
        print('Unknown method call: ${call.method}');
    }
  }

  static Future<bool> requestNotificationPermission() async {
    try {
      final result =
          await _channel.invokeMethod('requestNotificationPermission');
      return result as bool? ?? false;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  static Future<bool> checkNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod('checkNotificationPermission');
      return result as bool? ?? false;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  static Future<bool> requestBatteryOptimization() async {
    try {
      final result = await _channel.invokeMethod('requestBatteryOptimization');
      return result as bool? ?? false;
    } catch (e) {
      print('Error requesting battery optimization: $e');
      return false;
    }
  }

  static Future<bool> startKeepAliveService() async {
    try {
      final result = await _channel.invokeMethod('startKeepAliveService');
      return result as bool? ?? false;
    } catch (e) {
      print('Error starting keep alive service: $e');
      return false;
    }
  }

  static Future<bool> stopKeepAliveService() async {
    try {
      final result = await _channel.invokeMethod('stopKeepAliveService');
      return result as bool? ?? false;
    } catch (e) {
      print('Error stopping keep alive service: $e');
      return false;
    }
  }
}
