/// RegEx to match a path separator
final pathSeparator = RegExp(r'[/\\]');
final startsWithPathSeparator = RegExp(r'^[/\\]');

/// Return url String composed of the [url] and the
/// [urlQueryParameters], if given
String urlWithQueryParameters(String url, Map<String, String>? urlQueryParameters) {
  if (urlQueryParameters == null || urlQueryParameters.isEmpty) {
    return url;
  }
  final separator = url.contains('?') ? '&' : '?';
  return '$url$separator${urlQueryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';
}
