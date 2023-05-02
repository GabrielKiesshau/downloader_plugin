/// Signature for a function you can provide to the [downloadBatch] or
/// [uploadBatch] that will be called upon completion of each task
/// in the batch.
///
/// [succeeded] will count the number of successful downloads, and
/// [failed] counts the number of failed downloads (for any reason).
typedef BatchProgressCallback = void Function(int succeeded, int failed);
