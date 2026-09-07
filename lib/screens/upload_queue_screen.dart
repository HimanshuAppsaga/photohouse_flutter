import 'dart:async';
import 'package:flutter/material.dart';
import '../models/upload_models.dart';
import '../services/local_upload_queue_service.dart';
import '../services/upload_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_tab_bar.dart';
import 'upload_history_screen.dart';
import 'upload_photos_screen.dart';
import '../navigation/main_navigation_shell.dart';
import '../utils/app_toast.dart';

class UploadQueueItem {
  final String id;
  final String fileName;
  final String fileSize;
  final double progress; // 0.0 to 1.0
  final String status; // 'uploading', 'failed', 'done'
  final String? errorMessage;
  final QueueUploadFile? originalFile;

  UploadQueueItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.progress = 0.0,
    required this.status,
    this.errorMessage,
    this.originalFile,
  });

  factory UploadQueueItem.fromQueueFile(QueueUploadFile f) {
    String uiStatus = 'uploading';
    if (f.status == 'registered' ||
        f.status == 'completed' ||
        f.status == 'done') {
      uiStatus = 'done';
    } else if (f.status == 'failed') {
      uiStatus = 'failed';
    }

    final kb = (f.fileSize / 1024).toStringAsFixed(1);
    final mb = (f.fileSize / (1024 * 1024)).toStringAsFixed(2);
    final sizeStr = f.fileSize >= 1024 * 1024 ? '$mb MB' : '$kb KB';

    return UploadQueueItem(
      id: f.clientId,
      fileName: f.filename,
      fileSize: sizeStr,
      progress: f.progress.clamp(0.0, 1.0),
      status: uiStatus,
      errorMessage: f.error,
      originalFile: f,
    );
  }
}

class UploadQueueScreen extends StatefulWidget {
  final List<UploadQueueItem>? initialQueue;

  const UploadQueueScreen({super.key, this.initialQueue});

  @override
  State<UploadQueueScreen> createState() => _UploadQueueScreenState();
}

class _UploadQueueScreenState extends State<UploadQueueScreen> {
  final LocalUploadQueueService _localQueueService = LocalUploadQueueService();
  final UploadApiService _uploadApiService = UploadApiService();

  StreamSubscription<List<QueueUploadFile>>? _queueSubscription;
  Timer? _refreshTimer;

  int _selectedTabIndex = 0; // 0: Active, 1: Failed, 2: Done
  bool _isProcessingQueue = false;

  List<UploadQueueItem> _queueItems = [];
  final List<Map<String, String>> _logEntries = [
    {
      'time': '09:56 AM',
      'type': 'info',
      'message': 'Upload queue initialized with real-time stream listener.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPersistedQueue();

    // Subscribe to live queue updates
    _queueSubscription = _localQueueService.queueStream.listen((queue) {
      if (!mounted) return;
      setState(() {
        _queueItems = queue
            .map((f) => UploadQueueItem.fromQueueFile(f))
            .toList();
      });
    });

    // Heartbeat timer for fallback state syncing
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted) _loadPersistedQueue();
    });

    // Auto-process queue if any active/pending items exist on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingQueue();
    });
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPersistedQueue() async {
    if (widget.initialQueue != null &&
        widget.initialQueue!.isNotEmpty &&
        _queueItems.isEmpty) {
      setState(() {
        _queueItems = widget.initialQueue!;
      });
      return;
    }

    final localFiles = await _localQueueService.loadQueue();
    if (mounted) {
      setState(() {
        _queueItems = localFiles
            .map((f) => UploadQueueItem.fromQueueFile(f))
            .toList();
      });
    }
  }

  List<UploadQueueItem> get _activeItems =>
      _queueItems.where((item) => item.status == 'uploading').toList();

  List<UploadQueueItem> get _failedItems =>
      _queueItems.where((item) => item.status == 'failed').toList();

  List<UploadQueueItem> get _doneItems =>
      _queueItems.where((item) => item.status == 'done').toList();

  void _clearLogs() {
    setState(() {
      _logEntries.clear();
    });
    AppToast.show(
      context,
      'Upload log cleared',
      type: ToastType.info,
    );
  }

  Future<void> _processPendingQueue() async {
    if (_isProcessingQueue) return;

    final rawQueue = await _localQueueService.loadQueue();
    if (!mounted) return;

    final pendingOrUploading = rawQueue
        .where(
          (f) =>
              f.status == 'pending' ||
              f.status == 'uploading' ||
              f.status == 'presigned',
        )
        .toList();

    if (pendingOrUploading.isEmpty) return;

    setState(() {
      _isProcessingQueue = true;
      _logEntries.insert(0, {
        'time': TimeOfDay.now().format(context),
        'type': 'progress',
        'message':
            'Starting dynamic upload pipeline for ${pendingOrUploading.length} file(s)...',
      });
    });

    try {
      await _uploadApiService.uploadBatchPipeline(
        eventUuid: '9f1c0f0e-1a2b-4c3d-8e9f-000000000001',
        files: pendingOrUploading,
        albumId: pendingOrUploading.first.albumId,
        onProgress: (total, completed, failed, message) {
          if (!mounted) return;
          setState(() {
            _logEntries.insert(0, {
              'time': TimeOfDay.now().format(context),
              'type': failed > 0 ? 'error' : 'progress',
              'message': message,
            });
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _logEntries.insert(0, {
            'time': TimeOfDay.now().format(context),
            'type': 'error',
            'message': 'Upload pipeline error: $e',
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingQueue = false;
        });
        await _loadPersistedQueue();
      }
    }
  }

  Future<void> _clearDoneItems() async {
    await _localQueueService.clearDoneItems();
    await _loadPersistedQueue();
    if (mounted) {
      AppToast.show(
        context,
        'Completed items cleared from queue',
        type: ToastType.success,
      );
    }
  }

  Future<void> _removeItem(UploadQueueItem item) async {
    await _localQueueService.removeItem(item.id);
    await _loadPersistedQueue();
    if (mounted) {
      AppToast.show(
        context,
        'Removed ${item.fileName} from queue',
        type: ToastType.info,
      );
    }
  }

  Future<void> _retryAllFailed() async {
    await _localQueueService.resetFailedItemsToPending();
    await _loadPersistedQueue();
    await _processPendingQueue();
  }

  Future<void> _retryFailedUpload(UploadQueueItem item) async {
    final original = item.originalFile;
    if (original == null) return;

    setState(() {
      _logEntries.insert(0, {
        'time': TimeOfDay.now().format(context),
        'type': 'progress',
        'message': 'Retrying upload for ${item.fileName}...',
      });
    });

    original.status = 'pending';
    original.error = null;
    original.progress = 0.0;

    try {
      await _uploadApiService.uploadBatchPipeline(
        eventUuid: '9f1c0f0e-1a2b-4c3d-8e9f-000000000001',
        files: [original],
        albumId: original.albumId,
        onProgress: (total, completed, failed, message) {
          if (!mounted) return;
          setState(() {
            _logEntries.insert(0, {
              'time': TimeOfDay.now().format(context),
              'type': message.contains('failed') ? 'error' : 'progress',
              'message': message,
            });
          });
        },
      );
      await _loadPersistedQueue();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logEntries.insert(0, {
          'time': TimeOfDay.now().format(context),
          'type': 'error',
          'message': 'Retry failed: $e',
        });
      });
      await _loadPersistedQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          MainNavigationShell.switchTab(context, 0);
        }
      },
      child: Scaffold(
        backgroundColor: palette.bgDarker,
        appBar: AppBar(
          backgroundColor: palette.bgDarker,
          elevation: 0,
          leading: Center(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: palette.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary, size: 18),
                onPressed: () {
                  if (canPop) {
                    Navigator.of(context).pop();
                  } else {
                    MainNavigationShell.switchTab(context, 0);
                  }
                },
              ),
            ),
          ),
        title: Text(
          'Upload Queue',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isProcessingQueue
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.accentAmber,
                      ),
                    )
                  : Icon(
                      Icons.play_arrow_rounded,
                      color: palette.accentAmber,
                      size: 22,
                    ),
              tooltip: 'Resume / Process Queue',
              onPressed: _isProcessingQueue ? null : _processPendingQueue,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.history_rounded, color: palette.accentAmber, size: 20),
              tooltip: 'Upload Session History',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UploadHistoryScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(palette),
              const SizedBox(height: 16),
              _buildMetricSummaryCards(palette),
              const SizedBox(height: 20),
              _buildQueuePanel(palette),
              const SizedBox(height: 20),
              _buildUploadLogSection(palette),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // Header Section
  Widget _buildHeader(AppThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUEUE MANAGER',
          style: AppTextStyles.overlineOf(context),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload Queue',
          style: AppTextStyles.displayHeadingOf(context),
        ),
        const SizedBox(height: 6),
        Text(
          'Monitor real-time upload progress, view completed files, or retry failed items.',
          style: AppTextStyles.subTitleOf(context),
        ),
      ],
    );
  }

  // Metric Summary Cards Row
  Widget _buildMetricSummaryCards(AppThemePalette palette) {
    final total = _queueItems.length;
    final active = _activeItems.length;
    final failed = _failedItems.length;
    final done = _doneItems.length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            palette: palette,
            label: 'Active',
            value: '$active',
            color: palette.accentAmber,
            icon: Icons.sync_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            palette: palette,
            label: 'Failed',
            value: '$failed',
            color: palette.dangerRed,
            icon: Icons.error_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            palette: palette,
            label: 'Done',
            value: '$done',
            color: palette.successGreen,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            palette: palette,
            label: 'Total',
            value: '$total',
            color: palette.textPrimary,
            icon: Icons.folder_open_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required AppThemePalette palette,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Queue Panel Widget (Tabs + List/Empty state)
  Widget _buildQueuePanel(AppThemePalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Segmented Tabs Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ModernSegmentedTabBar(
                    selectedIndex: _selectedTabIndex,
                    tabs: const ['Active', 'Failed', 'Done'],
                    counts: [
                      _activeItems.length,
                      _failedItems.length,
                      _doneItems.length,
                    ],
                    onTabSelected: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                ),
                if (_selectedTabIndex == 2 && _doneItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton.icon(
                      onPressed: _clearDoneItems,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: palette.cardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: palette.border),
                        ),
                      ),
                      icon: Icon(
                        Icons.cleaning_services_outlined,
                        size: 14,
                        color: palette.textMuted,
                      ),
                      label: Text(
                        'Clear Done',
                        style: TextStyle(color: palette.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (_selectedTabIndex == 1 && _failedItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton.icon(
                      onPressed: _retryAllFailed,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: palette.accentAmber.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: palette.accentAmber.withValues(alpha: 0.3)),
                        ),
                      ),
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: palette.accentAmber,
                      ),
                      label: Text(
                        'Retry All',
                        style: TextStyle(color: palette.accentAmber, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Tab View Body
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSelectedTabContent(palette),
          ),
        ],
      ),
    );
  }

  // Selected Tab Body Content
  Widget _buildSelectedTabContent(AppThemePalette palette) {
    List<UploadQueueItem> items;
    if (_selectedTabIndex == 0) {
      items = _activeItems;
    } else if (_selectedTabIndex == 1) {
      items = _failedItems;
    } else {
      items = _doneItems;
    }

    if (items.isEmpty) {
      return _buildEmptyState(palette);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildQueueItemCard(palette, item);
      },
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(AppThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: palette.accentAmber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: palette.accentAmber.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: palette.accentAmber.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.accentAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  color: palette.accentAmber,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No files in this section',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Select images to upload, or monitor active background transfers here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UploadPhotosScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accentAmber.withValues(alpha: 0.15),
              foregroundColor: palette.accentAmber,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: palette.accentAmber.withValues(alpha: 0.3)),
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
            label: const Text(
              'Add Photos to Queue',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Queue Item Card
  Widget _buildQueueItemCard(AppThemePalette palette, UploadQueueItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.accentAmber.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.image_rounded, color: palette.accentAmber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          item.fileSize,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (item.errorMessage != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '• ${item.errorMessage}',
                              style: TextStyle(
                                color: palette.dangerRed,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (item.status == 'failed')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.dangerRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: palette.dangerRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Failed',
                        style: TextStyle(
                          color: palette.dangerRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _retryFailedUpload(item),
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: palette.accentAmber,
                        size: 20,
                      ),
                      tooltip: 'Retry upload',
                    ),
                    IconButton(
                      onPressed: () => _removeItem(item),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: palette.textMuted,
                        size: 20,
                      ),
                      tooltip: 'Remove item',
                    ),
                  ],
                ),
              if (item.status == 'done')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.successGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: palette.successGreen, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: TextStyle(
                              color: palette.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _removeItem(item),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.textMuted,
                        size: 18,
                      ),
                      tooltip: 'Dismiss item',
                    ),
                  ],
                ),
              if (item.status == 'uploading')
                IconButton(
                  onPressed: () => _removeItem(item),
                  icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 18),
                  tooltip: 'Cancel item',
                ),
            ],
          ),
          if (item.status == 'uploading') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: item.progress > 0 ? item.progress : null,
                backgroundColor: palette.bgDarker,
                valueColor: AlwaysStoppedAnimation<Color>(palette.accentAmber),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uploading...',
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
                Text(
                  '${(item.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: palette.accentAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Upload Log Section Widget
  Widget _buildUploadLogSection(AppThemePalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: palette.accentAmber, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Log',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.cardSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        '${_logEntries.length}',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _clearLogs,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: palette.textMuted, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(color: palette.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: palette.border, height: 1),
          // Entries List
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: _logEntries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No logs recorded.',
                        style: TextStyle(color: palette.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                : Column(
                    children: _logEntries.map((log) {
                      final type = log['type'] ?? 'info';
                      final message = log['message'] ?? '';

                      IconData icon = Icons.info_outline_rounded;
                      Color iconColor = palette.isDark ? palette.accentPrimary : const Color(0xFF64748B);
                      Color iconBg = palette.isDark
                          ? palette.accentPrimary.withValues(alpha: 0.18)
                          : const Color(0xFFF1F5F9);

                      if (type == 'warning' ||
                          message.startsWith('Warning') ||
                          message.contains('fallback') ||
                          message.contains('404')) {
                        icon = Icons.warning_amber_rounded;
                        iconColor = palette.accentAmber;
                        iconBg = palette.accentAmber.withValues(alpha: palette.isDark ? 0.22 : 0.14);
                      } else if (type == 'success' ||
                          message.contains('successfully') ||
                          message.contains('completed')) {
                        icon = Icons.check_circle_outline_rounded;
                        iconColor = palette.successGreen;
                        iconBg = palette.successGreen.withValues(alpha: palette.isDark ? 0.22 : 0.12);
                      } else if (type == 'error' ||
                          message.contains('failed') ||
                          message.contains('Exception') ||
                          message.contains('Error')) {
                        icon = Icons.error_outline_rounded;
                        iconColor = palette.dangerRed;
                        iconBg = palette.dangerRed.withValues(alpha: palette.isDark ? 0.22 : 0.12);
                      } else if (type == 'progress' ||
                          message.contains('Starting') ||
                          message.contains('Requesting') ||
                          message.contains('Closing')) {
                        icon = Icons.sync_rounded;
                        iconColor = palette.accentAmber;
                        iconBg = palette.accentAmber.withValues(alpha: palette.isDark ? 0.22 : 0.14);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: palette.isDark ? palette.cardSurface : const Color(0xFFF4F6FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.border.withValues(alpha: 0.7)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: palette.isDark
                                      ? palette.accentAmber.withValues(alpha: 0.2)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log['time'] ?? '',
                                  style: TextStyle(
                                    color: palette.isDark
                                        ? palette.accentAmber
                                        : const Color(0xFFB45309),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
