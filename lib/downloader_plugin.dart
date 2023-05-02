import 'base_downloader.dart';
import 'enums/shared_storage.dart';
import 'models/download_task.dart';
import 'models/task.dart';
import 'models/task_notification_config.dart';
import 'models/task_update.dart';

class DownloaderPlugin {
  final _downloader = BaseDownloader.instance();

  /// If no group is specified the default group name will be used
  static const defaultGroup = 'default';

  /// Stream of [TaskUpdate] updates for downloads that do
  /// not have a registered callback
  Stream<TaskUpdate> get updates => _downloader.updates.stream;

  /// Start a new task
  ///
  /// Returns true if successfully enqueued. A new task will also generate
  /// a [TaskStatus.enqueued] update to the registered callback,
  /// if requested by its [updates] property
  Future<bool> enqueue(Task task) => _downloader.enqueue(task);

  // /// Resets the downloader by cancelling all ongoing tasks within
  // /// the provided [group]
  // ///
  // /// Returns the number of tasks cancelled. Every canceled task wil emit a
  // /// [TaskStatus.canceled] update to the registered callback, if
  // /// requested
  // Future<int> reset({String group = defaultGroup}) => _downloader.reset(group);

  // /// Returns a list of all tasks currently active in this [group]
  // ///
  // /// Active means enqueued or running, and if [includeTasksWaitingToRetry] is
  // /// true also tasks that are waiting to be retried
  // Future<List<Task>> allTasks({String group = defaultGroup, bool includeTasksWaitingToRetry = true}) => _downloader.allTasks(group, includeTasksWaitingToRetry);

  // /// Cancel all tasks matching the taskIds in the list
  // ///
  // /// Every canceled task wil emit a [TaskStatus.canceled] update to
  // /// the registered callback, if requested
  // Future<bool> cancelTasksWithIds(List<String> taskIds) => _downloader.cancelTasksWithIds(taskIds);

  // /// Cancel this task
  // ///
  // /// The task will emit a [TaskStatus.canceled] update to
  // /// the registered callback, if requested
  // Future<bool> cancelTaskWithId(String taskId) => cancelTasksWithIds([taskId]);

  // /// Return [Task] for the given [taskId], or null
  // /// if not found.
  // ///
  // /// Only running tasks are guaranteed to be returned, but returning a task
  // /// does not guarantee that the task is still running. To keep track of
  // /// the status of tasks, use a [TaskStatusCallback]
  // Future<Task?> taskForId(String taskId) => _downloader.taskForId(taskId);

  // /// Pause the task
  // ///
  // /// Returns true if the pause was attempted successfully. Test the task's
  // /// status to see if it was executed successfully [TaskStatus.paused] or if
  // /// it failed after all [TaskStatus.failed]
  // ///
  // /// If the [Task.allowPause] field is set to false (default) or if this is
  // /// a POST request, this method returns false immediately.
  // Future<bool> pause(DownloadTask task) async {
  //   if (task.allowPause && task.post == null) {
  //     return _downloader.pause(task);
  //   }
  //   return false;
  // }

  // /// Resume the task
  // ///
  // /// Returns true if the pause was attempted successfully. Status will change
  // /// similar to a call to [enqueue]. If the task is able to resume, it will,
  // /// otherwise it will restart the task from scratch.
  // ///
  // /// If the [Task.allowPause] field is set to false (default) or if this is
  // /// a POST request, this method returns false immediately.
  // Future<bool> resume(DownloadTask task) async {
  //   if (task.allowPause && task.post == null) {
  //     return _downloader.resume(task, _notificationConfigForTask(task));
  //   }
  //   return false;
  // }

  // /// Returns the [TaskNotificationConfig] for this [task] or null
  // ///
  // /// Matches on task, then on group, then on default
  // TaskNotificationConfig? _notificationConfigForTask(Task task) {
  //   return _notificationConfigs
  //           .firstWhereOrNull((config) => config.taskOrGroup == task) ??
  //       _notificationConfigs
  //           .firstWhereOrNull((config) => config.taskOrGroup == task.group) ??
  //       _notificationConfigs
  //           .firstWhereOrNull((config) => config.taskOrGroup == null);
  // }

  /// Move the file represented by the [task] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [filePath] extension
  ///
  /// Returns the path to the stored file, or null if not successful
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<String?> moveToSharedStorage(
    DownloadTask task,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) async =>
      moveFileToSharedStorage(await task.filePath(), destination, directory: directory, mimeType: mimeType);

  /// Move the file represented by [filePath] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [filePath] extension
  ///
  /// Returns the path to the stored file, or null if not successful
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<String?> moveFileToSharedStorage(
    String filePath,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) async =>
      _downloader.moveToSharedStorage(filePath, destination, directory, mimeType);
}
