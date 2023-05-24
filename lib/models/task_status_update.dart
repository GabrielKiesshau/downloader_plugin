import '../enums/task_status.dart';
import 'task.dart';
import 'task_update.dart';

/// A status update event
class TaskStatusUpdate extends TaskUpdate {
  final TaskStatus status;

  TaskStatusUpdate(Task task, this.status) : super(task);
}
