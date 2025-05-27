import 'dart:async';

extension CompleterExtension<T> on Completer<T> {
  void finish([T? result]) {
    if (!isCompleted) {
      complete(result);
    }
  }
}