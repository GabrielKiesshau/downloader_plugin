import '../enums/task_status.dart';
import 'batch_progress_callback.dart';
import 'task.dart';

/// Contains tasks and results related to a batch of tasks
class Batch {
  final List<Task> tasks;
  final BatchProgressCallback? batchProgressCallback;
  final results = <Task, TaskStatus>{};

  Batch(this.tasks, this.batchProgressCallback);

  /// Returns an Iterable with successful tasks in this batch
  Iterable<Task> get succeeded => results.entries.where((entry) => entry.value == TaskStatus.complete).map((e) => e.key);

  /// Returns the number of successful tasks in this batch
  int get numSucceeded => results.values.where((result) => result == TaskStatus.complete).length;

  /// Returns an Iterable with failed tasks in this batch
  Iterable<Task> get failed => results.entries.where((entry) => entry.value != TaskStatus.complete).map((e) => e.key);

  /// Returns the number of failed downloads in this batch
  int get numFailed => results.values.length - numSucceeded;
}
