extension UriExtension on Uri {
  String get hostname_only {
    List<String> parts = host.split('.');
    if (parts.length > 2) {
      return parts[parts.length - 2];
    } else if (parts.length == 2) {
      return parts[0];
    }
    return host;
  }
}
