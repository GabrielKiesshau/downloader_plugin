import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_plugin/downloader_plugin_method_channel.dart';

void main() {
  MethodChannelDownloaderPlugin platform = MethodChannelDownloaderPlugin();
  const MethodChannel channel = MethodChannel('downloader_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
