import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_plugin/downloader_plugin.dart';
import 'package:downloader_plugin/downloader_plugin_platform_interface.dart';
import 'package:downloader_plugin/downloader_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDownloaderPluginPlatform
    with MockPlatformInterfaceMixin
    implements DownloaderPluginPlatform {

  @override
  Future<String> getPlatformVersion() => Future.value('42');
}

void main() {
  final DownloaderPluginPlatform initialPlatform = DownloaderPluginPlatform.instance;

  test('$MethodChannelDownloaderPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDownloaderPlugin>());
  });

  test('getPlatformVersion', () async {
    // DownloaderPlugin downloaderPlugin = DownloaderPlugin();
    MockDownloaderPluginPlatform fakePlatform = MockDownloaderPluginPlatform();
    DownloaderPluginPlatform.instance = fakePlatform;

    // expect(await downloaderPlugin.getPlatformVersion(), '42');
  });
}
