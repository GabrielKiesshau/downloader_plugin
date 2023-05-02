package com.example.downloader_plugin.models

import androidx.annotation.Keep
import com.example.downloader_plugin.models.TaskNotification

/**
 * Notification configuration object
 *
 * [running] is the notification used while the task is in progress
 * [complete] is the notification used when the task completed
 * [error] is the notification used when something went wrong,
 * including pause, failed and notFound status
 */
@Keep
class NotificationConfig(
    val running: TaskNotification?,
    val complete: TaskNotification?,
    val error: TaskNotification?,
    val paused: TaskNotification?,
    val progressBar: Boolean
) {
    override fun toString(): String {
        return "NotificationConfig(running=$running, complete=$complete, error=$error, paused=$paused, progressBar=$progressBar)"
    }
}
