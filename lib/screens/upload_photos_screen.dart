import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/album_model.dart';
import '../models/upload_models.dart';
import '../services/events_api_service.dart';
import '../services/local_upload_queue_service.dart';
import '../services/subscription_api_service.dart';
import '../services/upload_api_service.dart';
import 'upload_queue_screen.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';

class UploadPhotosScreen extends StatefulWidget {
  final String eventTitle;
  final String eventUuid;
  final int? albumId;
  final UploadApiService? uploadApiService;
  final SubscriptionApiService? subscriptionApiService;

  const UploadPhotosScreen({
    super.key,
    this.eventTitle = 'Maulik',
    this.eventUuid = '9f1c0f0e-1a2b-4c3d-8e9f-000000000001',
    this.albumId,
    this.uploadApiService,
    this.subscriptionApiService,
  });

  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  AppThemePalette get palette => AppThemePalette.of(context);

  Color get _brandDarker => palette.bgDarker;
  Color get _brandCard => palette.cardBg;
  Color get _brandAccent => palette.accentAmber;
  Color get _brandText => palette.textPrimary;
  Color get _brandMuted => palette.textMuted;
  Color get _brandBorder => palette.border;
  Color get _brandDanger => palette.dangerRed;
  late final UploadApiService _uploadApiService;
  late final SubscriptionApiService _subscriptionApiService;
  late final LocalUploadQueueService _localQueueService;
  late final EventsApiService _eventsApiService;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];
  final List<Map<String, String>> _activityLogs = [
    {
      'time': '09:56 AM',
      'message': 'Cloudflare R2 direct upload pipeline ready.',
    },
  ];

  List<AlbumItem> _eventAlbums = [];
  int? _selectedAlbumId;
  bool _isLoadingAlbums = false;

  String _lastRefreshed = '11:43 AM';
  String _watchFolder = 'None — manual upload only';
  bool _isPaused = false;
  bool _isUploading = false;
  int _completedCount = 0;
  int _failedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _uploadApiService = widget.uploadApiService ?? UploadApiService();
    _subscriptionApiService =
        widget.subscriptionApiService ?? SubscriptionApiService();
    _localQueueService = LocalUploadQueueService();
    _eventsApiService = EventsApiService();
    _selectedAlbumId = widget.albumId;
    _fetchAlbums();
  }

  Future<void> _fetchAlbums() async {
    setState(() => _isLoadingAlbums = true);
    try {
      final albums = await _eventsApiService.getEventAlbums(widget.eventUuid);
      if (mounted) {
        setState(() {
          _eventAlbums = albums;
          _isLoadingAlbums = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAlbums = false);
      }
    }
  }

  void _onBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      AppToast.show(
        context,
        'Back button pressed',
        type: ToastType.info,
      );
    }
  }

  void _onRefresh() {
    final formattedTime = TimeOfDay.now().format(context);
    setState(() {
      _lastRefreshed = formattedTime;
    });
    AppToast.show(
      context,
      'Refreshed target status at $formattedTime',
      type: ToastType.info,
    );
  }

  String _getMimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (!mounted) return;
      if (picked.isNotEmpty) {
        final formattedTime = TimeOfDay.now().format(context);
        setState(() {
          _selectedFiles.addAll(picked);
          _activityLogs.insert(0, {
            'time': formattedTime,
            'message':
                'Selected ${picked.length} file(s) for direct R2 upload.',
          });
        });
        AppToast.show(
          context,
          '${picked.length} images added. Starting Cloudflare R2 upload!',
          type: ToastType.success,
        );

        // Auto start direct R2 upload pipeline
        await _startR2UploadPipeline(picked);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Error selecting images: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _startR2UploadPipeline(List<XFile> filesToUpload) async {
    if (filesToUpload.isEmpty) return;

    // Check subscription & storage quota before starting upload
    try {
      final sub = await _subscriptionApiService.getSubscription();
      if (!mounted) return;
      if (sub.isStorageWarning || sub.isStorageExceeded) {
        final formattedTime = TimeOfDay.now().format(context);
        setState(() {
          _activityLogs.insert(0, {
            'time': formattedTime,
            'message':
                'Quota Notice: ${sub.usage?.storageUsedFormatted ?? "Storage quota near limit"}.',
          });
        });
        if (sub.isStorageCritical || sub.isStorageExceeded) {
          AppToast.show(
            context,
            'Storage Quota Warning: ${sub.usage?.storageUsedFormatted ?? "Near limit"}. Consider upgrading plan.',
            type: ToastType.warning,
          );
        }
      }
    } catch (_) {
      // Ignore quota check errors on upload to avoid blocking user if offline
    }

    setState(() {
      _isUploading = true;
      _totalCount += filesToUpload.length;
    });

    final effectiveAlbumId = _selectedAlbumId ?? widget.albumId;
    final queueItems = <QueueUploadFile>[];
    for (var i = 0; i < filesToUpload.length; i++) {
      final xfile = filesToUpload[i];
      final fileSize = await xfile.length();
      queueItems.add(
        QueueUploadFile(
          clientId: 'local-${DateTime.now().millisecondsSinceEpoch}-$i',
          filePath: xfile.path,
          filename: xfile.name,
          mimeType: _getMimeType(xfile.name),
          fileSize: fileSize,
          albumId: effectiveAlbumId,
        ),
      );
    }

    // Persist queue locally so uploads survive app restarts
    await _localQueueService.addToQueue(queueItems);

    try {
      final sessionResult = await _uploadApiService.uploadBatchPipeline(
        eventUuid: widget.eventUuid,
        files: queueItems,
        albumId: effectiveAlbumId,
        onProgress: (total, completed, failed, message) {
          if (!mounted) return;
          final timeStr = TimeOfDay.now().format(context);
          setState(() {
            _completedCount = completed;
            _failedCount = failed;
            _activityLogs.insert(0, {'time': timeStr, 'message': message});
          });
          // Update local persisted queue
          _localQueueService.saveQueue(queueItems);
        },
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        AppToast.show(
          context,
          'Upload session completed! Session UUID: ${sessionResult.sessionUuid}',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        AppToast.show(
          context,
          'Upload pipeline error: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _onBrowseFolder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _brandCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_open, color: _brandAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Select Watch Folder',
                    style: TextStyle(
                      color: _brandText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.folder_sharp, color: _brandMuted),
                title: Text(
                  'DCIM / Camera',
                  style: TextStyle(color: _brandText),
                ),
                onTap: () {
                  setState(() {
                    _watchFolder = '/DCIM/Camera';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.folder_special, color: _brandMuted),
                title: Text(
                  'Pictures / PhotoHouse',
                  style: TextStyle(color: _brandText),
                ),
                onTap: () {
                  setState(() {
                    _watchFolder = '/Pictures/PhotoHouse';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.block, color: _brandDanger),
                title: Text(
                  'None — manual upload only',
                  style: TextStyle(color: _brandDanger),
                ),
                onTap: () {
                  setState(() {
                    _watchFolder = 'None — manual upload only';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onChangeTarget() {
    AppToast.show(
      context,
      'Target change requested',
      type: ToastType.info,
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _clearLogs() {
    setState(() {
      _activityLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandDarker,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Header
            _buildTopHeader(),
            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildUploadTargetSection(),
                    const SizedBox(height: 20),
                    _buildUploadStatusSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _brandDarker,
        border: Border(bottom: BorderSide(color: _brandBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          InkWell(
            onTap: _onBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _brandCard,
                shape: BoxShape.circle,
                border: Border.all(color: _brandBorder, width: 1),
              ),
              child: Center(
                child: Icon(Icons.arrow_back_rounded, size: 18, color: _brandText),
              ),
            ),
          ),
          // Refresh Button
          InkWell(
            onTap: _onRefresh,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _brandCard,
                shape: BoxShape.circle,
                border: Border.all(color: _brandBorder, width: 1),
              ),
              child: Center(
                child: Icon(Icons.refresh_rounded, size: 18, color: _brandAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page Header Text (Modern Mobile Hero Card)
  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _brandCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _brandBorder.withValues(alpha: 0.8),
          width: 1.2,
        ),
        gradient: LinearGradient(
          colors: [
            _brandCard,
            palette.cardSurface.withValues(alpha: 0.9),
            _brandAccent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Mode Tag + Event Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _brandAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _brandAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: _brandAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'DIRECT UPLOAD MODE',
                      style: TextStyle(
                        color: _brandAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _brandDarker,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _brandBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, color: _brandMuted, size: 13),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.eventTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: _brandText,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            'Upload Photos',
            style: TextStyle(
              color: _brandText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle Description
          Text(
            'Select high-res photos manually or enable folder auto-sync to upload directly to this event.',
            style: TextStyle(color: _brandMuted, fontSize: 13.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  // Section 1: Upload Target
  Widget _buildUploadTargetSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _brandCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: _brandAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upload Target',
                    style: TextStyle(
                      color: _brandText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: _onChangeTarget,
                style: OutlinedButton.styleFrom(
                  backgroundColor: _brandDarker,
                  side: BorderSide(color: _brandBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Change Target',
                  style: TextStyle(
                    color: _brandText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Last Refreshed
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: _brandMuted),
              const SizedBox(width: 6),
              Text(
                'Last updated at $_lastRefreshed',
                style: TextStyle(color: _brandMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Selected Target Sub-Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brandDarker,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brandBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECTED TARGET',
                      style: TextStyle(
                        color: _brandMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _brandCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _brandBorder),
                      ),
                      child: Text(
                        'Direct Event Upload',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Event: ',
                      style: TextStyle(color: _brandMuted, fontSize: 14),
                    ),
                    Text(
                      widget.eventTitle,
                      style: TextStyle(
                        color: _brandText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isLoadingAlbums) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _brandAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading event albums...',
                        style: TextStyle(color: _brandMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ] else if (_eventAlbums.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Target Album:',
                    style: TextStyle(color: _brandMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _brandCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _brandBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedAlbumId,
                        dropdownColor: _brandCard,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: _brandAccent,
                        ),
                        hint: Text(
                          'Select Album (Optional)',
                          style: TextStyle(color: _brandMuted, fontSize: 13),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Entire Event (No specific album)',
                              style: TextStyle(
                                color: _brandText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ..._eventAlbums.map((album) {
                            final albumIdInt = int.tryParse(album.id) ??
                                int.tryParse(album.id.replaceAll(RegExp(r'[^0-9]'), ''));
                            return DropdownMenuItem<int?>(
                              value: albumIdInt,
                              child: Text(
                                '${album.title} (${album.photoCount} photos)',
                                style: TextStyle(
                                  color: _brandText,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedAlbumId = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Manual Photo Upload Dropzone (Dashed Box)
          CustomPaint(
            painter: DashedBorderPainter(
              color: _brandAccent,
              strokeWidth: 1.8,
              dash: 7.0,
              gap: 7.0,
              borderRadius: 14.0,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: _brandAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  // Icon Box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _brandAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _brandAccent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Manual Photo Upload',
                    style: TextStyle(
                      color: _brandText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Tap below to select images to upload directly to this event.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _brandMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Select Images Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Select Images',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandAccent,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  // Preview Selected Thumbnails if any
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedFiles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: _brandDarker,
                              child: Image.file(
                                File(file.path),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    Icon(Icons.image, color: _brandMuted),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: _brandBorder, height: 1),
          const SizedBox(height: 16),
          // Watch Folder Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_open, color: _brandMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Watch folder (optional)',
                    style: TextStyle(
                      color: _brandText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Automatically sync photos when new files appear in this folder.',
                style: TextStyle(color: _brandMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _brandDarker,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _brandBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: _brandMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _watchFolder,
                              style: TextStyle(
                                color: _brandMuted,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _onBrowseFolder,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _brandDarker,
                      side: BorderSide(color: _brandBorder),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Browse',
                      style: TextStyle(
                        color: _brandText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section 2: Upload Status
  Widget _buildUploadStatusSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _brandCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rounded, color: _brandText, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upload status',
                    style: TextStyle(
                      color: _brandText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _brandDarker,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isUploading
                        ? _brandAccent
                        : (_isPaused ? _brandDanger : _brandBorder),
                  ),
                ),
                child: Text(
                  _isUploading
                      ? 'UPLOADING...'
                      : (_isPaused ? 'PAUSED' : 'READY'),
                  style: TextStyle(
                    color: _isUploading
                        ? _brandAccent
                        : (_isPaused ? _brandDanger : _brandMuted),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Status Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brandDarker,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brandBorder),
            ),
            child: Column(
              children: [
                Text(
                  _isUploading
                      ? 'Cloudflare R2 Direct Upload in progress...'
                      : (_isPaused
                            ? 'Upload process paused.'
                            : (_selectedFiles.isEmpty
                                  ? 'Ready for manual upload. Select images to start.'
                                  : 'Queue contains ${_selectedFiles.length} file(s).')),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _brandMuted, fontSize: 13),
                ),
                if (_totalCount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Completed: $_completedCount / $_totalCount',
                        style: TextStyle(
                          color: palette.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_failedCount > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Failed: $_failedCount',
                          style: TextStyle(
                            color: _brandDanger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Actions Row (Pause & View Queue)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _togglePause,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _brandDanger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _brandDanger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: _brandDanger,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPaused ? 'Resume' : 'Pause',
                          style: TextStyle(
                            color: _brandDanger,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final queueItems = _selectedFiles.map((file) {
                      return UploadQueueItem(
                        id: file.path,
                        fileName: file.name,
                        fileSize: '2.4 MB',
                        progress: 0.65,
                        status: 'uploading',
                      );
                    }).toList();

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            UploadQueueScreen(initialQueue: queueItems),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _brandDarker,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _brandBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.format_list_bulleted_rounded,
                          color: _brandText,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View queue',
                          style: TextStyle(
                            color: _brandText,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: _brandBorder, height: 1),
          const SizedBox(height: 18),
          // Activity Log Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upload activity log',
                style: TextStyle(
                  color: _brandText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: _clearLogs,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: _brandMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(color: _brandMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Activity Log Container
          Container(
            decoration: BoxDecoration(
              color: _brandDarker,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _brandBorder),
            ),
            child: _activityLogs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Center(
                      child: Text(
                        'No recent activity',
                        style: TextStyle(color: _brandMuted, fontSize: 12),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(_activityLogs.length, (index) {
                      final item = _activityLogs[index];
                      final isLast = index == _activityLogs.length - 1;
                      final message = item['message'] ?? '';

                      IconData icon = Icons.info_outline_rounded;
                      Color iconColor = palette.isDark ? palette.accentPrimary : const Color(0xFF64748B);
                      Color iconBg = palette.isDark
                          ? palette.accentPrimary.withValues(alpha: 0.18)
                          : const Color(0xFFF1F5F9);

                      if (message.contains('failed') ||
                          message.contains('Exception') ||
                          message.contains('Error') ||
                          message.startsWith('Warning')) {
                        icon = Icons.error_outline_rounded;
                        iconColor = palette.dangerRed;
                        iconBg = palette.dangerRed.withValues(alpha: palette.isDark ? 0.22 : 0.12);
                      } else if (message.contains('Starting') ||
                          message.contains('Requesting') ||
                          message.contains('Uploading') ||
                          message.contains('Processing')) {
                        icon = Icons.sync_rounded;
                        iconColor = palette.accentAmber;
                        iconBg = palette.accentAmber.withValues(alpha: palette.isDark ? 0.22 : 0.14);
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: palette.border.withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: iconBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: palette.isDark
                                    ? palette.accentAmber.withValues(alpha: 0.2)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['time'] ?? '',
                                style: TextStyle(
                                  color: palette.isDark
                                      ? palette.accentAmber
                                      : const Color(0xFFB45309),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Dashed Border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 6.0,
    this.dash = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final Path path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dash > metric.length)
            ? metric.length - distance
            : dash;
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dash != dash ||
      oldDelegate.borderRadius != borderRadius;
}

// Animated Pulsing Dot for Online Status
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppThemePalette.of(context).accentPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
