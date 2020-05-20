import 'debugLog.dart';

class NoOpLogger implements DebugLog {
  @override
  void log(String sMessage) {
    // No operation: ignore
  }
}
