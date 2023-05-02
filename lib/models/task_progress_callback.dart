import 'task.dart';

/// Signature for a function you can register to be called
/// for every progress change of a [task].
///
/// A successfully completed task will always finish with progress 1.0
/// [TaskStatus.failed] results in progress -1.0
/// [TaskStatus.canceled] results in progress -2.0
/// [TaskStatus.notFound] results in progress -3.0
/// [TaskStatus.waitingToRetry] results in progress -4.0
/// These constants are available as [progressFailed] etc
typedef TaskProgressCallback = void Function(Task task, double progress);
