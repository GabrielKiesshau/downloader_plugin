package com.example.downloader_plugin

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.util.Patterns
import androidx.core.app.ActivityCompat
import androidx.preference.PreferenceManager
import androidx.work.*
import com.example.downloader_plugin.TaskWorker.Companion.keyNotificationConfig
import com.example.downloader_plugin.TaskWorker.Companion.keyStartByte
import com.example.downloader_plugin.TaskWorker.Companion.keyTempFilename
import com.example.downloader_plugin.enums.TaskStatus
import com.example.downloader_plugin.models.ResumeData
import com.example.downloader_plugin.models.Task
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.lang.Long.min
import java.util.concurrent.TimeUnit
import java.util.concurrent.locks.ReentrantReadWriteLock
import kotlin.concurrent.write


/** DownloaderPlugin */
class DownloaderPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  companion object {
    const val TAG = "DownloaderPlugin"
    const val keyTasksMap = "com.example.downloader_plugin.taskMap"
    const val keyResumeDataMap = "com.example.downloader_plugin.resumeDataMap"
    const val keyStatusUpdateMap = "com.example.downloader_plugin.statusUpdateMap"
    const val keyProgressUpdateMap = "com.example.downloader_plugin.progressUpdateMap"
    const val notificationChannel = "downloader_plugin"
    const val notificationPermissionRequestCode = 373921
    const val externalStoragePermissionRequestCode = 373922

    /**
     * [activity] is being set to null on detach
     */
    @SuppressLint("StaticFieldLeak")
    var activity: Activity? = null
    var canceledTaskIds = HashMap<String, Long>() // <taskId, timeMillis>
    var pausedTaskIds = HashSet<String>() // <taskId>
    var backgroundChannel: MethodChannel? = null

    var backgroundChannelCounter = 0  // reference counter
    var forceFailPostOnBackgroundChannel = false
    val prefsLock = ReentrantReadWriteLock()
    val gson = Gson()
    val jsonMapType = object : TypeToken<Map<String, Any>>() {}.type
    var requestingNotificationPermission = false
    var externalStoragePermissionCompleter = CompletableFutureCompat<Boolean>()
    var localResumeData = HashMap<String, ResumeData>()

    /**
     * Enqueue a WorkManager task based on the provided parameters
     */
    suspend fun doEnqueue(
      context: Context,
      taskJsonMapString: String,
      notificationConfigJsonString: String?,
      tempFilePath: String?,
      startByte: Long?,
      initialDelayMillis: Long = 0
    ): Boolean {
      val task = Task(gson.fromJson(taskJsonMapString, jsonMapType))
      Log.i(TAG, "Enqueuing task with ID ${task.taskId}")
      if (!Patterns.WEB_URL.matcher(task.url).matches()) {
        Log.i(TAG, "Invalid url: ${task.url}")
        return false
      }

      canceledTaskIds.remove(task.taskId)
      val dataBuilder = Data.Builder().putString(TaskWorker.keyTask, taskJsonMapString)
      if (notificationConfigJsonString != null) {
        dataBuilder.putString(keyNotificationConfig, notificationConfigJsonString)
      }

      if (tempFilePath != null && startByte != null) {
        dataBuilder.putString(keyTempFilename, tempFilePath)
          .putLong(keyStartByte, startByte)
      }
      val data = dataBuilder.build()
      val constraints = Constraints.Builder().setRequiredNetworkType( // AndroidX Library
        if (task.requiresWiFi) NetworkType.UNMETERED else NetworkType.CONNECTED
      ).build()

      val requestBuilder = OneTimeWorkRequestBuilder<TaskWorker>().setInputData(data)
        .setConstraints(constraints).addTag(TAG).addTag("taskId=${task.taskId}")
        .addTag("group=${task.group}")
      if (initialDelayMillis != 0L) {
        requestBuilder.setInitialDelay(initialDelayMillis, TimeUnit.MILLISECONDS)
      }

      val workManager = WorkManager.getInstance(context)
      val operation = workManager.enqueue(requestBuilder.build())
      try {
        withContext(Dispatchers.IO) {
          operation.result.get()
        }
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        if (initialDelayMillis == 0L) {
          TaskWorker.processStatusUpdate(
            task, TaskStatus.enqueued, prefs
          )
        } else {
          delay(min(100L, initialDelayMillis))
          TaskWorker.processStatusUpdate(task, TaskStatus.enqueued, prefs)
        }
      } catch (e: Throwable) {
        Log.w(
          TAG,
          "Unable to start background request for taskId ${task.taskId} in operation: $operation"
        )
        return false
      }

      // Store Task in persistent storage, as Json representation keyed by taskID
      prefsLock.write {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val jsonString = prefs.getString(keyTasksMap, "{}")
        val tasksMap =
          gson.fromJson<Map<String, Any>>(jsonString, jsonMapType).toMutableMap()
        tasksMap[task.taskId] = gson.toJson(task.toJsonMap())
        val editor = prefs.edit()
        editor.putString(keyTasksMap, gson.toJson(tasksMap))
        editor.apply()
      }

      return true
    }

    /**
     * Cancel task with [taskId] and return true if successful
     *
     * The [taskId] must be managed by the [workManager]
     */
    suspend fun cancelActiveTaskWithId(
      context: Context, taskId: String, workManager: WorkManager
    ): Boolean {
      val workInfoList = withContext(Dispatchers.IO) {
        workManager.getWorkInfosByTag("taskId=$taskId").get()
      }
      if (workInfoList.isEmpty()) {
        Log.d(TAG, "Could not find tasks to cancel")
        return false
      }
      for (workInfo in workInfoList) {
        if (workInfo.state != WorkInfo.State.SUCCEEDED) {
          // send cancellation update for tasks that have not yet succeeded
          Log.d(TAG, "Canceling active task and sending status update")
          prefsLock.write {
            val prefs = PreferenceManager.getDefaultSharedPreferences(context)
            val tasksMap = getTaskMap(prefs)
            val taskJsonMap = tasksMap[taskId] as String?
            if (taskJsonMap != null) {
              val task = Task(
                gson.fromJson(taskJsonMap, jsonMapType)
              )
              TaskWorker.processStatusUpdate(task, TaskStatus.canceled, prefs)
            } else {
              Log.d(TAG, "Could not find taskId $taskId to cancel")
            }
          }
        }
      }
      val operation = workManager.cancelAllWorkByTag("taskId=$taskId")
      try {
        withContext(Dispatchers.IO) {
          operation.result.get()
        }
      } catch (e: Throwable) {
        Log.w(TAG, "Unable to cancel taskId $taskId in operation: $operation")
        return false
      }
      return true
    }

    /**
     * Cancel [task] that is not active
     *
     * Because this [task] is not managed by a [WorkManager] it is cancelled directly. This
     * is normally called from a notification when the task is paused (which is why it is
     * inactive), and therefore the caller must remove the notification that triggered the
     * cancellation. See NotificationReceiver
     */
    suspend fun cancelInactiveTask(context: Context, task: Task) {
      prefsLock.write {
        Log.d(TAG, "Canceling inactive task")
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        TaskWorker.processStatusUpdate(task, TaskStatus.canceled, prefs)
      }
    }

    /**
     * Pause the task with this [taskId]
     *
     * Marks the task for pausing, actual pausing happens in [TaskWorker]
     */
    fun pauseTaskWithId(taskId: String): Boolean {
      Log.v(TAG, "Marking taskId $taskId for pausing")
      pausedTaskIds.add(taskId)
      return true
    }
  }

  private var channel: MethodChannel? = null
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // Create channels and handler
    backgroundChannelCounter++

    if (backgroundChannel == null) {
      // Set background channel once, as it has to be static field
      // and per https://github.com/firebase/flutterfire/issues/9689
      // other plugins can create multiple instances of the plugin
      backgroundChannel = MethodChannel(
        flutterPluginBinding.binaryMessenger,
        "downloader_plugin.background"
      )
    }

    channel = MethodChannel(
      flutterPluginBinding.binaryMessenger, "downloader_plugin"
    )

    channel?.setMethodCallHandler(this)

    applicationContext = flutterPluginBinding.applicationContext

    // Clear expired items
    val workManager = WorkManager.getInstance(applicationContext)
    val prefs = PreferenceManager.getDefaultSharedPreferences(applicationContext)
    val workInfoList = workManager.getWorkInfosByTag(TAG).get()
    if (workInfoList.isEmpty()) {
      // Remove persistent storage if no jobs found at all
      val editor = prefs.edit()
      editor.remove(keyTasksMap)
      editor.apply()
    }
  }

  /** Processes the methodCall coming from Dart */
  override fun onMethodCall(call: MethodCall, result: Result) {
    runBlocking {
      when (call.method) {
        "hasWritePermission" -> methodHasWritePermission(result)
        "requestWritePermission" -> methodRequestWritePermission()
        "enqueue" -> methodEnqueue(call, result)
        "reset" -> methodReset(call, result)
        "allTasks" -> methodAllTasks(call, result)
        "cancelTasksWithIds" -> methodCancelTasksWithIds(call, result)
        "taskForId" -> methodTaskForId(call, result)
        "pause" -> methodPause(call, result)
        "popResumeData" -> methodPopResumeData(result)
        "popStatusUpdates" -> methodPopStatusUpdates(result)
        "popProgressUpdates" -> methodPopProgressUpdates(result)
        "getTaskTimeout" -> methodGetTaskTimeout(result)
        "moveToSharedStorage" -> methodMoveToSharedStorage(call, result)
        "forceFailPostOnBackgroundChannel" -> methodForceFailPostOnBackgroundChannel(
          call, result
        )
        else -> result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
    backgroundChannelCounter--
    if (backgroundChannelCounter == 0) {
      backgroundChannel = null
    }
  }

  // ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  // RequestPermissionsResultListener
  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    val granted =
      (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
    return when (requestCode) {
      notificationPermissionRequestCode -> {
        requestingNotificationPermission = false
        true
      }
      externalStoragePermissionRequestCode -> {
        externalStoragePermissionCompleter.complete(granted)
        true
      }
      else -> {
        false
      }
    }
  }

  /**
   * Starts one task, passed as map of values representing a [Task]
   *
   * Returns true if successful, and will emit a status update that the task is running.
   */
  private suspend fun methodEnqueue(call: MethodCall, result: Result) {
    // Arguments are a list of Task, NotificationConfig?, optionally followed
    // by tempFilePath and startByte if this enqueue is a resume from pause
    val args = call.arguments as List<*>
    val taskJsonMapString = args[0] as String
    val notificationConfigJsonString = args[1] as String?
    val isResume = args.size == 4
    val startByte: Long?
    val tempFilePath: String?
    if (isResume) {
      tempFilePath = args[2] as String
      startByte = if (args[3] is Long) args[3] as Long else (args[3] as Int).toLong()
    } else {
      tempFilePath = null
      startByte = null
    }
    result.success(
      doEnqueue(
        applicationContext,
        taskJsonMapString,
        notificationConfigJsonString,
        tempFilePath,
        startByte
      )
    )
  }

  /**
   * Resets the download worker by cancelling all ongoing download tasks for the group
   *
   * Returns the number of tasks canceled
   */
  private fun methodReset(call: MethodCall, result: Result) {
    Log.i(TAG, "methodReset: $call")
    result.success("Android: methodReset")
  }

  /**
   * Returns a list of tasks for all tasks in progress, as a list of JSON strings
   */
  private fun methodAllTasks(call: MethodCall, result: Result) {
    Log.i(TAG, "methodAllTasks: $call")
    result.success("Android: methodAllTasks b")
  }

  /**
   * Cancels ongoing tasks whose taskId is in the list provided with this call
   *
   * Returns true if all cancellations were successful
   */
  private suspend fun methodCancelTasksWithIds(call: MethodCall, result: Result) {
    @Suppress("UNCHECKED_CAST") val taskIds = call.arguments as List<String>
    val workManager = WorkManager.getInstance(applicationContext)
    Log.v(TAG, "Canceling taskIds $taskIds")
    var success = true
    for (taskId in taskIds) {
      success = success && cancelActiveTaskWithId(applicationContext, taskId, workManager)
    }
    result.success(success)
  }

  /** Returns Task for this taskId, or nil */
  private fun methodTaskForId(call: MethodCall, result: Result) {
    Log.i(TAG, "methodTaskForId: $call")
    result.success("Android: methodTaskForId")
  }

  /**
   * Marks the taskId for pausing
   *
   * The pause action is taken in the [TaskWorker]
   */
  private fun methodPause(call: MethodCall, result: Result) {
    Log.i(TAG, "methodPause: $call")
    result.success("Android: methodPause")
  }

  /**
   * Returns a JSON String of a map of [ResumeData], keyed by taskId, that has been stored
   * in local shared preferences because they could not be delivered to the Dart side.
   * Local storage of this map is then cleared
   */
  private fun methodPopResumeData(result: Result) {
    result.success("Android: methodPopResumeData")
  }

  /**
   * Returns a JSON String of a map of [Task] and [TaskStatus], keyed by taskId, stored
   * in local shared preferences because they could not be delivered to the Dart side.
   * Local storage of this map is then cleared
   */
  private fun methodPopStatusUpdates(result: Result) {
    result.success("Android: methodPopStatusUpdates")
  }

  /**
   * Returns a JSON String of a map of [ResumeData], keyed by taskId, that has been stored
   * in local shared preferences because they could not be delivered to the Dart side.
   * Local storage of this map is then cleared
   */
  private fun methodPopProgressUpdates(result: Result) {
    result.success("Android: methodPopProgressUpdates")
  }

  /**
   * Returns the [TaskWorker] timeout value in milliseconds
   *
   * For testing only
   */
  private fun methodGetTaskTimeout(result: Result) {
    result.success("Android: methodGetTaskTimeout")
  }

  /**
   * Move a file to Android scoped/shared storage and return the path to that file, or null
   *
   * Call arguments:
   * - filePath (String): full path to file to be moved
   * - destination (Int as index into [SharedStorage] enum)
   * - directory (String): subdirectory within scoped storage
   */
  private fun methodMoveToSharedStorage(call: MethodCall, result: Result) {
    val args = call.arguments as List<*>
    val filePath = args[0] as String
    val destination = SharedStorage.values()[args[1] as Int]
    val directory = args[2] as String
    val mimeType = args[3] as String?

    if (Build.VERSION.SDK_INT in 23..29) {
      if (ActivityCompat.checkSelfPermission(
          applicationContext, Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED) {
        result.success(
          moveToSharedStorage(
            applicationContext,
            filePath,
            destination,
            directory,
            mimeType,
          )
        )
      }
      return
    }

    result.success(moveToSharedStorage(applicationContext, filePath, destination, directory, mimeType))
  }

  private fun methodHasWritePermission(result: Result) {
    val permission = ActivityCompat.checkSelfPermission(applicationContext, Manifest.permission.WRITE_EXTERNAL_STORAGE)

    if (permission == PackageManager.PERMISSION_GRANTED) {
      result.success(true)
    } else {
      result.success(false)
    }
  }

  private fun methodRequestWritePermission() {
    if (Build.VERSION.SDK_INT in 23..29) {
      if (activity != null) {
        activity?.requestPermissions(
          arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
          externalStoragePermissionRequestCode
        )
      }
    }
  }

  /**
   * Sets or resets flag to force failing posting on background channel
   *
   * For testing only
   */
  private fun methodForceFailPostOnBackgroundChannel(call: MethodCall, result: Result) {
    Log.i(TAG, "methodForceFailPostOnBackgroundChannel: $call")
    result.success("Android: methodForceFailPostOnBackgroundChannel")
  }
}
