extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  bool isAllMatched(bool Function(T e) predict) {
    for (var el in this) {
      if (!predict(el)) {
        return false;
      }
    }
    return true;
  }

  bool exist(bool Function(T e) cb) {
    for (var i in this) {
      if (cb(i)) {
        return true;
      }
    }
    return false;
  }
}

extension MapWithIndex<E> on List<E> {
  Iterable<T> build<T>(T Function(E e, int index) f) sync* {
    for (int i = 0; i < length; i++) {
      yield f(this[i], i);
    }
  }
}
