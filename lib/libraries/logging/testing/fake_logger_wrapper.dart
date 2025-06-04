import '../interfaces/logger_wrapper.dart';

class FakeLoggerWrapper implements LoggerWrapper {
  final List<Map<String, dynamic>> dMessages = [];
  final List<Map<String, dynamic>> iMessages = [];
  final List<Map<String, dynamic>> wMessages = [];
  final List<Map<String, dynamic>> eMessages = [];
  final List<Map<String, dynamic>> fMessages = [];

  @override
  void d(String message, {dynamic error, StackTrace? stackTrace}) {
    dMessages.add({'message': message, 'error': error, 'stackTrace': stackTrace});
  }

  @override
  void e(String message, {dynamic error, StackTrace? stackTrace}) {
    eMessages.add({'message': message, 'error': error, 'stackTrace': stackTrace});
  }

  @override
  void f(String message, {dynamic error, StackTrace? stackTrace}) {
    fMessages.add({'message': message, 'error': error, 'stackTrace': stackTrace});
  }

  @override
  void i(String message, {dynamic error, StackTrace? stackTrace}) {
    iMessages.add({'message': message, 'error': error, 'stackTrace': stackTrace});
  }

  @override
  void w(String message, {dynamic error, StackTrace? stackTrace}) {
    wMessages.add({'message': message, 'error': error, 'stackTrace': stackTrace});
  }

  void clear() {
    dMessages.clear();
    iMessages.clear();
    wMessages.clear();
    eMessages.clear();
    fMessages.clear();
  }
}
