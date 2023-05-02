package com.example.downloader_plugin.models

/// Holds data associated with a resume
class ResumeData(val task: Task, val data: String, val requiredStartByte: Long) {
    fun toJsonMap(): MutableMap<String, Any?> {
        return mutableMapOf(
            "task" to task.toJsonMap(),
            "data" to data,
            "requiredStartByte" to requiredStartByte
        )
    }
}
