import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  /// Log simple message to Crashlytics and Console
  void log(String message) {
    debugPrint('[LOG] $message');
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.log(message);
      }
    } catch (e) {
      // Ignore crashlytics errors in dev/web
    }
  }

  /// Set user identifier for Crashlytics
  void setUser(String userId) {
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
    } catch (e) {
       // Ignore
    }
  }
  
  /// Log key-value pairs (custom keys)
  void setCustomKey(String key, Object value) {
    try {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.setCustomKey(key, value);
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason}) async {
    debugPrint('[ERROR] $exception');
    try {
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason);
      }
    } catch (e) {
      // Ignore
    }
  }
}
