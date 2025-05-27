class MapUtilities {
  static Map<K, V>? convert<K, V>(Map? map) {
    if (map == null) return null;
    Map<K, V> temp = {};
    for (var entry in map.entries) {
      temp[entry.key] = entry.value as V;
    }
    return temp;
  }
}
