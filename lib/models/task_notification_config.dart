import 'task_notification.dart';

/// Notification configuration object
///
/// Determines how a [taskOrGroup] or [group] of tasks needs to be notified
///
/// [running] is the notification used while the task is in progress
/// [complete] is the notification used when the task completed
/// [error] is the notification used when something went wrong,
/// including pause, failed and notFound status
class TaskNotificationConfig {
  final dynamic taskOrGroup;
  final TaskNotification running;
  final TaskNotification complete;
  final TaskNotification error;
  final TaskNotification paused;
  final bool progressBar;

  TaskNotificationConfig({this.taskOrGroup, this.running, this.complete, this.error, this.paused, this.progressBar = false}) {
    assert(running != null || complete != null || error != null || paused != null, 'At least one notification must be set');
  }

  /// Return JSON Map representing object, excluding the [taskOrGroup] field,
  /// as the JSON map is only required to pass along the config with a task
  Map<String, dynamic> toJsonMap() => {"running": running?.toJsonMap(), "complete": complete?.toJsonMap(), "error": error?.toJsonMap(), "paused": paused?.toJsonMap(), "progressBar": progressBar};
}
