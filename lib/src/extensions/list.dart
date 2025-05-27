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

}