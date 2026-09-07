import 'dart:async';
import 'dart:convert';
import '../models/upload_models.dart';
import 'secure_storage_service.dart';

class LocalUploadQueueService {
  final SecureStorageService _storage;

  static final StreamController<List<QueueUploadFile>> _streamController =
      StreamController<List<QueueUploadFile>>.broadcast();

  static List<QueueUploadFile> _cachedQueue = [];

  LocalUploadQueueService({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  /// Stream of queue changes for real-time reactive UI updates
  Stream<List<QueueUploadFile>> get queueStream => _streamController.stream;

  /// Current in-memory queue cache
  List<QueueUploadFile> get currentQueue => List.unmodifiable(_cachedQueue);

  /// Loads persisted upload queue items from secure storage
  Future<List<QueueUploadFile>> loadQueue() async {
    try {
      final jsonStr = await _storage.getUploadQueue();
      if (jsonStr == null || jsonStr.isEmpty) {
        _cachedQueue = [];
        _notifyStream();
        return [];
      }

      final List decoded = jsonDecode(jsonStr);
      _cachedQueue = decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => QueueUploadFile.fromJson(item))
          .toList();
      _notifyStream();
      return _cachedQueue;
    } catch (_) {
      _cachedQueue = [];
      _notifyStream();
      return [];
    }
  }

  /// Saves the active upload queue items to secure storage and broadcasts change
  Future<void> saveQueue(List<QueueUploadFile> queue) async {
    try {
      _cachedQueue = List.from(queue);
      final jsonList = _cachedQueue.map((item) => item.toJson()).toList();
      await _storage.saveUploadQueue(jsonEncode(jsonList));
      _notifyStream();
    } catch (_) {
      // Ignore storage write errors gracefully
    }
  }

  /// Clears the persisted upload queue
  Future<void> clearQueue() async {
    _cachedQueue.clear();
    await _storage.deleteUploadQueue();
    _notifyStream();
  }

  /// Clears completed/done items from queue
  Future<void> clearDoneItems() async {
    final queue = await loadQueue();
    queue.removeWhere((item) =>
        item.status == 'registered' ||
        item.status == 'completed' ||
        item.status == 'done');
    await saveQueue(queue);
  }

  /// Removes a single item by clientId
  Future<void> removeItem(String clientId) async {
    final queue = await loadQueue();
    queue.removeWhere((item) => item.clientId == clientId);
    await saveQueue(queue);
  }

  /// Resets all failed items to pending status for retry
  Future<void> resetFailedItemsToPending() async {
    final queue = await loadQueue();
    for (final item in queue) {
      if (item.status == 'failed') {
        item.status = 'pending';
        item.error = null;
        item.progress = 0.0;
      }
    }
    await saveQueue(queue);
  }

  /// Appends new items to the persisted upload queue
  Future<List<QueueUploadFile>> addToQueue(
    List<QueueUploadFile> newItems,
  ) async {
    final current = await loadQueue();
    current.addAll(newItems);
    await saveQueue(current);
    return current;
  }

  /// Updates status of a specific item in the queue
  Future<void> updateItemStatus(
    String clientId, {
    required String status,
    double? progress,
    String? error,
    String? storagePath,
    String? presignedUrl,
    DateTime? presignedAt,
  }) async {
    final queue = await loadQueue();
    final index = queue.indexWhere((f) => f.clientId == clientId);
    if (index != -1) {
      queue[index].status = status;
      if (progress != null) queue[index].progress = progress;
      if (error != null) queue[index].error = error;
      if (storagePath != null) queue[index].storagePath = storagePath;
      if (presignedUrl != null) queue[index].presignedUrl = presignedUrl;
      if (presignedAt != null) queue[index].presignedAt = presignedAt;
      await saveQueue(queue);
    }
  }

  void _notifyStream() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_cachedQueue));
    }
  }
}
