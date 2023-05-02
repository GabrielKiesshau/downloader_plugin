import 'package:downloader_plugin/downloader_plugin.dart';
import 'package:downloader_plugin/enums/base_directory.dart';
import 'package:downloader_plugin/enums/shared_storage.dart';
import 'package:downloader_plugin/enums/updates.dart';
import 'package:downloader_plugin/models/download_task.dart';
import 'package:downloader_plugin/models/task_progress_update.dart';
import 'package:downloader_plugin/models/task_status_update.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final fileDownloader = DownloaderPlugin();

  @override
  void initState() {
    super.initState();

    _registerDownloadListener();
  }

  void _registerDownloadListener() async {
    fileDownloader.updates.listen((update) async {
      if (update is TaskStatusUpdate) {
        debugPrint('Status update for ${update.task} with status ${update.status}');
        return;
      }

      if (update is TaskProgressUpdate) {
        if (update.progress == 1.0) {
          debugPrint('download complete');
          final x = await fileDownloader.moveToSharedStorage(
            update.task as DownloadTask,
            SharedStorage.downloads,
          );

          debugPrint(x);
        }
        debugPrint('Progress update for ${update.task} with progress ${update.progress}');
      }
    });
  }

  void _downloadFile() async {
    final task = DownloadTask(
      url: 'https://google.com',
      filename: 'testfile.txt',
      baseDirectory: BaseDirectory.temporary,
      updates: Updates.statusAndProgress,
    );

    // final task = DownloadTask(
    //   url: 'https://t4.ftcdn.net/jpg/02/66/72/41/240_F_266724172_Iy8gdKgMa7XmrhYYxLCxyhx6J7070Pr8.jpg',
    //   filename: 'cat.jpg',
    //   baseDirectory: BaseDirectory.temporary,
    // );

    await fileDownloader.enqueue(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Press the button to download a file',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _downloadFile,
        tooltip: 'Download',
        child: const Icon(Icons.download),
      ),
    );
  }
}
