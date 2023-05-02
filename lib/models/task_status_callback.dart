import '../enums/task_status.dart';
import 'task.dart';

/// Signature for a function you can register to be called
/// when the state of a [task] changes.
typedef TaskStatusCallback = void Function(Task task, TaskStatus status);
