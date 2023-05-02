package com.example.downloader_plugin.models

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.Keep
import androidx.core.app.NotificationManagerCompat
import androidx.work.WorkManager
import com.example.downloader_plugin.DownloaderPlugin
import com.example.downloader_plugin.DownloaderPlugin.Companion.TAG
import kotlinx.coroutines.runBlocking

/**
 * Receiver for messages from notification, sent via intent
 *
 * Note the two cancellation actions: one for active tasks (running and managed by a
 * [WorkManager] and one for inactive (paused) tasks. Because the latter is not running in a
 * [WorkManager] job, cancellation is simpler, but the [NotificationReceiver] must remove the
 * notification that asked for cancellation directly from here. If an 'error' notification
 * was configured for the task, then it will NOT be shown (as it would when cancelling an active
 * task)
 */
@Keep
class NotificationReceiver : BroadcastReceiver() {

    companion object {
        const val actionCancelActive = "com.bbflight.background_downloader.cancelActive"
        const val actionCancelInactive = "com.bbflight.background_downloader.cancelInactive"
        const val actionPause = "com.bbflight.background_downloader.pause"
        const val actionResume = "com.bbflight.background_downloader.resume"
        const val extraBundle = "com.bbflight.background_downloader.bundle"
        const val bundleTaskId = "taskId"
        const val bundleTask = "task"
        const val bundleNotificationConfig = "notificationConfig"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val bundle = intent.getBundleExtra(extraBundle)
        val taskId = bundle?.getString(bundleTaskId)
        if (taskId != null) {
            runBlocking {
                when (intent.action) {
                    actionCancelActive -> {
                        Log.d(TAG, "active task")
                        DownloaderPlugin.cancelActiveTaskWithId(
                            context, taskId, WorkManager.getInstance(context)
                        )
                    }
                    actionCancelInactive -> {
                        val taskJsonString = bundle.getString(bundleTask)
                        if (taskJsonString != null) {
                            Log.d(TAG, "inactive task")
                            val task = Task(
                                DownloaderPlugin.gson.fromJson(
                                    taskJsonString, DownloaderPlugin.jsonMapType
                                )
                            )
                            DownloaderPlugin.cancelInactiveTask(context, task)
                            with(NotificationManagerCompat.from(context)) {
                                cancel(task.taskId.hashCode())
                            }
                        } else {
                            Log.d(TAG, "task was null")
                        }
                    }
                    actionPause -> {
                        DownloaderPlugin.pauseTaskWithId(taskId)
                    }
                    actionResume -> {
                        val resumeData = DownloaderPlugin.localResumeData[taskId]
                        if (resumeData != null) {
                            val taskJsonString = bundle.getString(bundleTask)
                            val notificationConfigJsonString = bundle.getString(
                                bundleNotificationConfig
                            )
                            if (notificationConfigJsonString != null && taskJsonString != null) {
                                DownloaderPlugin.doEnqueue(
                                    context,
                                    taskJsonString,
                                    notificationConfigJsonString,
                                    resumeData.data,
                                    resumeData.requiredStartByte
                                )
                            } else {
                                DownloaderPlugin.cancelActiveTaskWithId(
                                    context, taskId, WorkManager.getInstance(context)
                                )
                            }
                        } else {
                            DownloaderPlugin.cancelActiveTaskWithId(
                                context, taskId, WorkManager.getInstance(context)
                            )
                        }
                    }
                    else -> {}
                }
            }
        }
    }
}
