import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'downloader_plugin_platform_interface.dart';

/// An implementation of [DownloaderPluginPlatform] that uses method channels.
class MethodChannelDownloaderPlugin extends DownloaderPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('downloader_plugin');

  @override
  Future<String> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
