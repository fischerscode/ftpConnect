import 'debugLog.dart';

class NoOpLogger implements FTPDebugLogger {
  @override
  void log(String sMessage) {
    // No operation: ignore
  }
}
