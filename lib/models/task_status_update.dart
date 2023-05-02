import '../enums/task_status.dart';
import 'task_update.dart';

/// A status update event
class TaskStatusUpdate extends TaskUpdate {
  final TaskStatus status;

  TaskStatusUpdate(super.task, this.status);
}
