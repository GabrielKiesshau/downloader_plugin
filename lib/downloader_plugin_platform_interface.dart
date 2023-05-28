import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'downloader_plugin_method_channel.dart';

abstract class DownloaderPluginPlatform extends PlatformInterface {
  /// Constructs a DownloaderPluginPlatform.
  DownloaderPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static DownloaderPluginPlatform _instance = MethodChannelDownloaderPlugin();

  /// The default instance of [DownloaderPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelDownloaderPlugin].
  static DownloaderPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DownloaderPluginPlatform] when
  /// they register themselves.
  static set instance(DownloaderPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
