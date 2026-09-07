import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photohouse/utils/app_toast.dart';
import '../models/event_model.dart';
import '../models/album_model.dart';
import '../services/events_api_service.dart';
import '../theme/app_theme.dart';
import 'upload_photos_screen.dart';
import 'upload_history_screen.dart';

class EventOverviewScreen extends StatefulWidget {
  final EventItem event;
  final EventsApiService? eventsApiService;

  const EventOverviewScreen({
    super.key,
    required this.event,
    this.eventsApiService,
  });

  @override
  State<EventOverviewScreen> createState() => _EventOverviewScreenState();
}

class _EventOverviewScreenState extends State<EventOverviewScreen> {
  late final EventsApiService _eventsApiService;
  late EventItem _currentEvent;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _eventsApiService = widget.eventsApiService ?? EventsApiService();
    _currentEvent = widget.event;
    _fetchLiveAlbums();
  }

  Future<void> _fetchLiveAlbums({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final albums = await _eventsApiService.getEventAlbums(_currentEvent.id);
      if (mounted) {
        setState(() {
          _currentEvent = _currentEvent.copyWith(
            albums: albums,
            albumCount: albums.isNotEmpty ? albums.length : _currentEvent.albumCount,
          );
          _isRefreshing = false;
        });

        if (isRefresh) {
          AppToast.show(
            context,
            'Overview refreshed successfully!',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        if (isRefresh) {
          AppToast.show(
            context,
            'Using cached albums (${e.toString().replaceAll("Exception: ", "")})',
            type: ToastType.info,
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchLiveAlbums(isRefresh: true);
  }

  void _handleUpload({AlbumItem? album}) {
    final palette = AppThemePalette.of(context);
    final targetName = album != null ? album.title : widget.event.title;
    final isAlbum = album != null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: palette.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: palette.border, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Glowing Amber Accent Bar
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: palette.accentAmber,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accentAmber,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Icon Container, Title & Close Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.accentAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: palette.accentAmber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              color: palette.accentAmber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Confirm Upload Target',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: palette.textMuted, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Message Text Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.bgDarker,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: isAlbum
                                    ? 'Are you sure you want to upload images to album '
                                    : 'Are you sure you want to upload images directly to event ',
                              ),
                              TextSpan(
                                text: '"$targetName"',
                                style: TextStyle(
                                  color: palette.accentAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: '?'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Responsive Action Buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 300;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildConfirmButton(targetName, album: album),
                                const SizedBox(height: 10),
                                _buildCancelButton(context),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildCancelButton(context),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildConfirmButton(targetName, album: album),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        backgroundColor: palette.cardSurface,
        side: BorderSide(color: palette.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Cancel',
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(String targetName, {AlbumItem? album}) {
    final palette = AppThemePalette.of(context);
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UploadPhotosScreen(
              eventTitle: targetName,
              eventUuid: widget.event.id,
              albumId: album != null
                  ? (int.tryParse(album.id) ??
                      int.tryParse(album.id.replaceAll(RegExp(r'[^0-9]'), '')))
                  : null,
            ),
          ),
        );
      },
      icon: const Icon(
        Icons.cloud_upload_outlined,
        color: Colors.black,
        size: 18,
      ),
      label: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Confirm & Choose Images',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accentAmber,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Scaffold(
      backgroundColor: palette.bgDarker,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildTopHeader(),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    _buildTitleSection(),
                    const SizedBox(height: 20),
                    // Direct Upload Card
                    _buildDirectUploadCard(),
                    const SizedBox(height: 16),
                    // Album Cards
                    ..._currentEvent.albums.map(
                      (album) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildAlbumCard(album),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final palette = AppThemePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: palette.bgDarker,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: palette.border, width: 1),
              ),
              child: Center(
                child: Icon(Icons.arrow_back_rounded, size: 18, color: palette.textPrimary),
              ),
            ),
          ),
          Row(
            children: [
              // Upload History Button
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UploadHistoryScreen(
                        eventUuid: _currentEvent.id,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: palette.accentAmber),
                      const SizedBox(width: 6),
                      Text(
                        'History',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh Button
              InkWell(
                onTap: _isRefreshing ? null : _handleRefresh,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border, width: 1),
                  ),
                  child: Center(
                    child: _isRefreshing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.accentAmber,
                            ),
                          )
                        : Icon(Icons.refresh_rounded, size: 18, color: palette.accentAmber),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    final palette = AppThemePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVENT OVERVIEW',
          style: AppTextStyles.overlineOf(context),
        ),
        const SizedBox(height: 6),
        Text(
          _currentEvent.title,
          style: AppTextStyles.displayHeadingOf(context),
        ),
        const SizedBox(height: 12),
        // Event Meta Chips Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.accentAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.accentAmber.withValues(alpha: 0.4)),
              ),
              child: Text(
                _currentEvent.tag,
                style: AppTextStyles.cardTag,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: palette.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    _currentEvent.date,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 12, color: palette.accentAmber),
                  const SizedBox(width: 5),
                  Text(
                    '${_currentEvent.photoCount} photos',
                    style: TextStyle(color: palette.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Select an album to upload to, or upload directly to the event.',
          style: AppTextStyles.subTitleOf(context),
        ),
      ],
    );
  }

  Widget _buildDirectUploadCard() {
    final palette = AppThemePalette.of(context);
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: palette.accentAmber,
        borderRadius: 16.0,
        strokeWidth: 1.2,
        dash: 6.0,
        gap: 4.0,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.cloud_upload_rounded,
                    color: palette.accentAmber,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.accentAmber.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Direct Upload',
                    style: AppTextStyles.cardTag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Upload to Event',
              style: AppTextStyles.cardTitleOf(context),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(color: palette.textMuted, fontSize: 13.5, height: 1.4),
                children: [
                  const TextSpan(text: 'Upload images directly to '),
                  TextSpan(
                    text: widget.event.title,
                    style: TextStyle(
                      color: palette.accentAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' without selecting a specific album.'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'No album — unorganised',
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
                InkWell(
                  onTap: () => _handleUpload(album: null),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(
                        'Upload',
                        style: AppTextStyles.buttonText,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 15, color: palette.accentAmber),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(AlbumItem album) {
    final palette = AppThemePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon & Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.accentAmber.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: palette.accentAmber,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  'Album',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            album.title,
            style: AppTextStyles.cardTitleOf(context),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.image_outlined, size: 14, color: palette.accentAmber),
              const SizedBox(width: 5),
              Text(
                '${album.photoCount} photos',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select album',
                style: TextStyle(color: palette.textMuted, fontSize: 13),
              ),
              InkWell(
                onTap: () => _handleUpload(album: album),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Text(
                      'Upload',
                      style: AppTextStyles.buttonText,
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: palette.accentAmber),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.borderRadius,
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
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
