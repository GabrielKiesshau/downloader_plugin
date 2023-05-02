import 'task.dart';

/// Holds data associated with a resume
class ResumeData {
  final Task task;
  final String data;
  final int requiredStartByte;

  ResumeData(this.task, this.data, this.requiredStartByte);

  /// Create object from JSON Map
  ResumeData.fromJsonMap(Map<String, dynamic> jsonMap)
      : task = Task.createFromJsonMap(jsonMap['task']),
        data = jsonMap['data'] as String,
        requiredStartByte = jsonMap['requiredStartByte'] as int;

  /// Return JSON Map representing object
  Map<String, dynamic> toJsonMap() => {'task': task.toJsonMap(), 'data': data, 'requiredStartByte': requiredStartByte};

  String get taskId => task.taskId;
}
