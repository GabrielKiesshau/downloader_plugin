/// Base directory in which files will be stored, based on their relative
/// path.
///
/// These correspond to the directories provided by the path_provider package
enum BaseDirectory {
  /// As returned by getApplicationDocumentsDirectory()
  applicationDocuments,

  /// As returned by getTemporaryDirectory()
  temporary,

  /// As returned by getApplicationSupportDirectory()
  applicationSupport,

  /// As returned by getApplicationLibrary() on iOS. For other platforms
  /// this resolves to the subdirectory 'Library' created in the directory
  /// returned by getApplicationSupportDirectory()
  applicationLibrary
}
