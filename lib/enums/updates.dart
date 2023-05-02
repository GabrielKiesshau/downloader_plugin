/// Type of updates requested for a task or group of tasks
enum Updates {
  /// no status change or progress updates
  none,

  /// only status changes
  status,

  /// only progress updates while downloading, no status change updates
  progress,

  /// Status change updates and progress updates while downloading
  statusAndProgress,
}
