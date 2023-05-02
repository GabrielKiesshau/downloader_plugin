import 'task_update.dart';

/// A progress update event
///
/// A successfully downloaded task will always finish with progress 1.0
/// [TaskStatus.failed] results in progress -1.0
/// [TaskStatus.canceled] results in progress -2.0
/// [TaskStatus.notFound] results in progress -3.0
/// [TaskStatus.waitingToRetry] results in progress -4.0
class TaskProgressUpdate extends TaskUpdate {
  final double progress;

  TaskProgressUpdate(super.task, this.progress);
}
