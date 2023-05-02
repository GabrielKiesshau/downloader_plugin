import 'task.dart';

/// Base class for events related to [task]. Actual events are
/// either a status update or a progress update.
///
/// When receiving an update, test if the update is a
/// [TaskStatusUpdate] or a [TaskProgressUpdate]
/// and treat the update accordingly
class TaskUpdate {
  final Task task;

  TaskUpdate(this.task);
}
