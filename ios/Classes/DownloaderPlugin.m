#import "DownloaderPlugin.h"
#if __has_include(<downloader_plugin/downloader_plugin-Swift.h>)
#import <downloader_plugin/downloader_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "downloader_plugin-Swift.h"
#endif

@implementation DownloaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [DownloaderPlugin registerWithRegistrar:registrar];
}
@end
