import '../enums/base_directory.dart';
import '../enums/updates.dart';
import 'task.dart';

/// Information related to a download task
class DownloadTask extends Task {
  /// Creates a [DownloadTask]
  ///
  /// [taskId] must be unique. A unique id will be generated if omitted
  /// [url] properly encoded if necessary, can include query parameters
  /// [urlQueryParameters] may be added and will be appended to the [url], must
  ///   be properly encoded if necessary
  /// [filename] of the file to save. If omitted, a random filename will be
  /// generated
  /// [headers] an optional map of HTTP request headers
  /// [post] if set, uses POST instead of GET. Post must be one of the
  /// following:
  /// - true: POST request without a body
  /// - a String: POST request with [post] as the body, encoded in utf8 and
  ///   content-type 'text/plain'
  /// - a List of bytes: POST request with [post] as the body
  /// - a Map: POST request with [post] as form fields, encoded in utf8 and
  ///   content-type 'application/x-www-form-urlencoded'
  ///
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, will not start download until WiFi is available.
  /// If not set may start download over cellular network
  /// [retries] if >0 will retry a failed download this many times
  /// [metaData] user data
  DownloadTask({
    String? taskId,
    required super.url,
    super.urlQueryParameters,
    String? filename,
    super.headers,
    super.post,
    super.directory,
    super.baseDirectory,
    super.group,
    super.updates,
    super.requiresWiFi,
    super.retries,
    super.allowPause,
    super.metaData,
    super.creationTime,
  }) : super(taskId: taskId, filename: filename);

  /// Creates [DownloadTask] object from JsonMap
  DownloadTask.fromJsonMap(Map<String, dynamic> jsonMap)
      : assert(
            jsonMap['taskType'] == 'DownloadTask',
            'The provided JSON map is not'
            ' a DownloadTask, because key "taskType" is not "DownloadTask".'),
        super.fromJsonMap(jsonMap);

  @override
  Map<String, dynamic> toJsonMap() => {...super.toJsonMap(), 'taskType': 'DownloadTask'};

  @override
  DownloadTask copyWith({
    String? taskId,
    String? url,
    String? filename,
    Map<String, String>? headers,
    Object? post,
    String? directory,
    BaseDirectory? baseDirectory,
    String? group,
    Updates? updates,
    bool? requiresWiFi,
    int? retries,
    int? retriesRemaining,
    bool? allowPause,
    String? metaData,
    DateTime? creationTime,
  }) =>
      DownloadTask(
        taskId: taskId ?? this.taskId,
        url: url ?? this.url,
        filename: filename ?? this.filename,
        headers: headers ?? this.headers,
        post: post ?? this.post,
        directory: directory ?? this.directory,
        baseDirectory: baseDirectory ?? this.baseDirectory,
        group: group ?? this.group,
        updates: updates ?? this.updates,
        requiresWiFi: requiresWiFi ?? this.requiresWiFi,
        retries: retries ?? this.retries,
        allowPause: allowPause ?? this.allowPause,
        metaData: metaData ?? this.metaData,
        creationTime: creationTime ?? this.creationTime,
      )..retriesRemaining = retriesRemaining ?? this.retriesRemaining;

  @override
  String toString() => 'Download${super.toString()}';
}
