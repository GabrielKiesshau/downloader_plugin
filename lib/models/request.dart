import 'package:flutter/foundation.dart';

import '../utils.dart';

/// A server Request
///
/// An equality test on a [Request] is an equality test on the [url]
class Request {
  /// String representation of the url, urlEncoded
  final String url;

  /// potential additional headers to send with the request
  final Map<String, String> headers;

  /// Set [post] to make the request using POST instead of GET.
  /// In the constructor, [post] must be one of the following:
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a List of bytes: POST request with [post] as the body
  ///
  /// The field [post] will be a UInt8List representing the bytes, or the String
  final String post;

  /// Maximum number of retries the downloader should attempt
  ///
  /// Defaults to 0, meaning no retry will be attempted
  final int retries;

  /// Number of retries remaining
  int retriesRemaining;

  /// Time at which this request was first created
  final DateTime creationTime;

  /// Creates a [Request]
  ///
  /// [url] must not be encoded and can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url]
  /// [headers] an optional map of HTTP request headers
  /// [post] if set, uses POST instead of GET. Post must be one of the
  /// following:
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a List of bytes: POST request with [post] as the body
  ///
  /// [retries] if >0 will retry a failed download this many times
  Request({@required String url, Map<String, String> urlQueryParameters, this.headers = const {}, post, this.retries = 0, DateTime creationTime})
      : url = urlWithQueryParameters(url, urlQueryParameters),
        post = post is Uint8List ? String.fromCharCodes(post) : post,
        retriesRemaining = retries,
        creationTime = creationTime ?? DateTime.now() {
    if (retries < 0 || retries > 10) {
      throw ArgumentError('Number of retries must be in range 1 through 10');
    }
  }

  /// Creates object from JsonMap
  Request.fromJsonMap(Map<String, dynamic> jsonMap)
      : url = jsonMap['url'] ?? '',
        headers = Map<String, String>.from(jsonMap['headers'] ?? {}),
        post = jsonMap['post'],
        retries = jsonMap['retries'] ?? 0,
        retriesRemaining = jsonMap['retriesRemaining'] ?? 0,
        creationTime = DateTime.fromMillisecondsSinceEpoch(jsonMap['creationTime'] ?? 0);

  /// Creates JSON map of this object
  Map<String, dynamic> toJsonMap() => {'url': url, 'headers': headers, 'post': post, 'retries': retries, 'retriesRemaining': retriesRemaining, 'creationTime': creationTime.millisecondsSinceEpoch};

  /// Decrease [retriesRemaining] by one
  void decreaseRetriesRemaining() => retriesRemaining--;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Request && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() {
    return 'Request{url: $url, headers: $headers, post: ${post == null ? "null" : "not null"}, '
        'retries: $retries, retriesRemaining: $retriesRemaining}';
  }
}
