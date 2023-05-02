/// Notification specification for a [Task]
///
/// [body] may contain special string {filename] to insert the filename
///   and/or special string {progress} to insert progress in %
///   and/or special trailing string {progressBar} to add a progress bar under
///   the body text in the notification
///
/// Actual appearance of notification is dependent on the platform, e.g.
/// on iOS {progress} and {progressBar} are not available and ignored
class TaskNotification {
  final String title;
  final String body;

  TaskNotification(this.title, this.body);

  /// Return JSON Map representing object
  Map<String, dynamic> toJsonMap() => {"title": title, "body": body};
}
