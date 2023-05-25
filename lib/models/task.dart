import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../downloader_plugin.dart';
import '../enums/base_directory.dart';
import '../enums/updates.dart';
import '../utils.dart';
import 'download_task.dart';
import 'request.dart';

/// Information related to a [Task]
///
/// A [Task] is the base class for [DownloadTask] and
/// [UploadTask]
///
/// An equality test on a [Task] is a test on the [taskId]
/// only - all other fields are ignored in that test
abstract class Task extends Request {
  // Progress values representing a status
  /// 1.0
  static const progressComplete = 1.0;
  /// -1.0
  static const progressFailed = -1.0;
  /// -2.0
  static const progressCanceled = -2.0;
  /// -3.0
  static const progressNotFound = -3.0;
  /// -4.0
  static const progressWaitingToRetry = -4.0;
  /// -5.0
  static const progressPaused = -5.0;

  /// Identifier for the task - auto generated if omitted
  final String taskId;

  /// Filename of the file to store
  final String filename;

  /// Optional directory, relative to the base directory
  final String directory;

  /// Base directory
  final BaseDirectory baseDirectory;

  /// Group that this task belongs to
  final String group;

  /// Type of progress updates desired
  final Updates updates;

  /// If true, will not download over cellular (metered) network
  final bool requiresWiFi;

  /// If true, task will pause if the task fails partly through the execution,
  /// when some but not all bytes have transferred, provided the server supports
  /// partial transfers. Such failures are typically temporary, eg due to
  /// connectivity issues, and may be resumed when connectivity returns.
  /// If false, task fails on any issue, and task cannot be paused
  final bool allowPause;

  /// User-defined metadata
  final String metaData;

  /// Creates a [Task]
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
  /// - a String: POST request with [post] as the body, encoded in utf8
  /// - a List of bytes: POST request with [post] as the body
  /// [directory] optional directory name, precedes [filename]
  /// [baseDirectory] one of the base directories, precedes [directory]
  /// [group] if set allows different callbacks or processing for different
  /// groups
  /// [updates] the kind of progress updates requested
  /// [requiresWiFi] if set, will not start download until WiFi is available.
  /// If not set may start download over cellular network
  /// [retries] if >0 will retry a failed download this many times
  /// [allowPause]
  /// If true, task will pause if the task fails partly through the execution,
  /// when some but not all bytes have transferred, provided the server supports
  /// partial transfers. Such failures are typically temporary, eg due to
  /// connectivity issues, and may be resumed when connectivity returns
  /// [metaData] user data
  /// [creationTime] time of task creation, 'now' by default.
  Task({
    String taskId,
    @required String url,
    Map<String, String> urlQueryParameters,
    String filename,
    Map<String, String> headers = const {},
    dynamic post,
    this.directory = '',
    this.baseDirectory = BaseDirectory.applicationDocuments,
    this.group = 'default',
    this.updates = Updates.status,
    this.requiresWiFi = false,
    int retries = 0,
    this.metaData = '',
    this.allowPause = false,
    DateTime creationTime,
  })  : taskId = taskId ?? Random().nextInt(1 << 32).toString(),
        filename = filename ?? Random().nextInt(1 << 32).toString(),
        super(
          url: url,
          urlQueryParameters: urlQueryParameters,
          headers: headers,
          post: post,
          retries: retries,
          creationTime: creationTime,
        ) {
    if (filename?.isEmpty == true) {
      throw ArgumentError('Filename cannot be empty');
    }
    if (pathSeparator.hasMatch(this.filename)) {
      throw ArgumentError('Filename cannot contain path separators');
    }
    if (startsWithPathSeparator.hasMatch(directory)) {
      throw ArgumentError('Directory must be relative to the baseDirectory specified in the baseDirectory argument');
    }
    if (allowPause && post != null) {
      throw ArgumentError('Tasks that can pause must be GET requests');
    }
  }

  /// Create a new [Task] subclass from the provided [jsonMap]
  factory Task.createFromJsonMap(Map<String, dynamic> jsonMap) => DownloadTask.fromJsonMap(jsonMap);

  /// Returns the absolute path to the file represented by this task
  Future<String> filePath() async {
    Directory baseDir;
    switch (baseDirectory) {
      case BaseDirectory.applicationDocuments:
        baseDir = await getApplicationDocumentsDirectory();
        break;
      case BaseDirectory.temporary:
        baseDir = await getTemporaryDirectory();
        break;
      case BaseDirectory.applicationSupport:
        baseDir = await getApplicationSupportDirectory();
        break;
      case BaseDirectory.applicationLibrary:
        baseDir = Platform.isMacOS || Platform.isIOS ? await getLibraryDirectory() : Directory(path.join((await getApplicationSupportDirectory()).path, 'Library'));
    }
    return path.join(baseDir.path, directory, filename);
  }

  /// Returns a copy of the [Task] with optional changes to specific fields
  Task copyWith({
    String taskId,
    String url,
    String filename,
    Map<String, String> headers,
    Object post,
    String directory,
    BaseDirectory baseDirectory,
    String group,
    Updates updates,
    bool requiresWiFi,
    int retries,
    int retriesRemaining,
    bool allowPause,
    String metaData,
    DateTime creationTime,
  });

  /// Creates [Task] object from JsonMap
  ///
  /// Only used by subclasses. Use [createFromJsonMap] to create a properly
  /// subclassed [Task] from the [jsonMap]
  Task.fromJsonMap(Map<String, dynamic> jsonMap)
      : taskId = jsonMap['taskId'] ?? '',
        filename = jsonMap['filename'] ?? '',
        directory = jsonMap['directory'] ?? '',
        baseDirectory = BaseDirectory.values[jsonMap['baseDirectory'] ?? 0],
        group = jsonMap['group'] ?? DownloaderPlugin.defaultGroup,
        updates = Updates.values[jsonMap['updates'] ?? 0],
        requiresWiFi = jsonMap['requiresWiFi'] ?? false,
        allowPause = jsonMap['allowPause'] ?? false,
        metaData = jsonMap['metaData'] ?? '',
        super.fromJsonMap(jsonMap);

  /// Creates JSON map of this object
  @override
  Map<String, dynamic> toJsonMap() => {
        ...super.toJsonMap(),
        'taskId': taskId,
        'filename': filename,
        'directory': directory,
        'baseDirectory': baseDirectory.index, // stored as int
        'group': group,
        'updates': updates.index, // stored as int
        'requiresWiFi': requiresWiFi,
        'allowPause': allowPause,
        'metaData': metaData
      };

  /// If true, task expects progress updates
  bool get providesProgressUpdates => updates == Updates.progress || updates == Updates.statusAndProgress;

  /// If true, task expects status updates
  bool get providesStatusUpdates => updates == Updates.status || updates == Updates.statusAndProgress;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Task && runtimeType == other.runtimeType && taskId == other.taskId;

  @override
  int get hashCode => taskId.hashCode;

  @override
  String toString() {
    return 'Task{taskId: $taskId, url: $url, filename: $filename, headers: $headers, post: ${post == null ? "null" : "not null"}, directory: $directory, baseDirectory: $baseDirectory, group: $group, updates: $updates, requiresWiFi: $requiresWiFi, retries: $retries, retriesRemaining: $retriesRemaining, metaData: $metaData}';
  }
}
