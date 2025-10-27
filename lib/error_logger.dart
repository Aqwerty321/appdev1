import 'dart:collection';

class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  final ListQueue<String> _errors = ListQueue(20);
  int _rebuilds = 0;

  void logError(Object error, StackTrace stack) {
    final msg = '[${DateTime.now().toIso8601String()}] $error\n${stack.toString().split('\n').take(4).join('\n')}';
    _errors.addFirst(msg);
    while (_errors.length > 20) {
      _errors.removeLast();
    }
    // ignore: avoid_print
    print('!LOGGED_ERROR => $msg');
  }

  void incRebuild() => _rebuilds++;
  int get rebuilds => _rebuilds;
  List<String> get recentErrors => _errors.toList(growable: false);
  void clear() => _errors.clear();
}
