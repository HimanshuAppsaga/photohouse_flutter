import 'package:flutter/material.dart';
import '../models/upload_models.dart';
import '../services/upload_api_service.dart';
import '../theme/app_theme.dart';

class UploadHistoryScreen extends StatefulWidget {
  final String? eventUuid;
  final UploadApiService? uploadApiService;

  const UploadHistoryScreen({
    super.key,
    this.eventUuid,
    this.uploadApiService,
  });

  @override
  State<UploadHistoryScreen> createState() => _UploadHistoryScreenState();
}

class _UploadHistoryScreenState extends State<UploadHistoryScreen> {
  late final UploadApiService _apiService;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  final List<UploadSessionItem> _sessions = [];
  String? _nextCursor;

  // Selected Filters
  final String _selectedStatusFilter = 'all'; // 'all', 'pending', 'active', 'completed', 'failed'
  final String _selectedSourceFilter = 'all'; // 'all', 'desktop_agent', 'browser', 'ftp'

  @override
  void initState() {
    super.initState();
    _apiService = widget.uploadApiService ?? UploadApiService();
    _loadSessions(refresh: true);
  }

  Future<void> _loadSessions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _nextCursor = null;
      });
    }

    try {
      final statusParam = _selectedStatusFilter == 'all' ? null : _selectedStatusFilter;
      final sourceParam = _selectedSourceFilter == 'all' ? null : _selectedSourceFilter;

      final response = await _apiService.getUploadSessions(
        eventUuid: widget.eventUuid,
        status: statusParam,
        source: sourceParam,
        cursor: refresh ? null : _nextCursor,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _sessions.clear();
          }
          _sessions.addAll(response.sessions);
          _nextCursor = response.nextCursor;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_nextCursor == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });
    await _loadSessions(refresh: false);
  }

  int get _totalFilesCount =>
      _sessions.fold(0, (sum, item) => sum + item.totalFiles);
  int get _completedFilesCount =>
      _sessions.fold(0, (sum, item) => sum + item.completedFiles);
  int get _failedFilesCount =>
      _sessions.fold(0, (sum, item) => sum + item.failedFiles);

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Scaffold(
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
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Sessions',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            if (widget.eventUuid != null)
              Text(
                'Event: ${widget.eventUuid!.substring(0, widget.eventUuid!.length > 8 ? 8 : widget.eventUuid!.length)}...',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: palette.accentAmber, size: 20),
              tooltip: 'Refresh Sessions',
              onPressed: () => _loadSessions(refresh: true),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: palette.accentAmber,
          backgroundColor: palette.cardBg,
          onRefresh: () => _loadSessions(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Banner Stats
                      _buildSummaryHeader(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: palette.accentAmber),
                  ),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: _buildErrorWidget(),
                )
              else if (_sessions.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyWidget(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _sessions.length) {
                          return _buildPaginationFooter();
                        }
                        final session = _sessions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildSessionCard(session),
                        );
                      },
                      childCount: _sessions.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final palette = AppThemePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            palette.cardBg,
            palette.cardSurface.withValues(alpha: 0.9),
            palette.accentAmber.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, color: palette.accentAmber, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'UPLOAD HISTORY METRICS',
                style: AppTextStyles.overlineOf(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sessions',
                  '${_sessions.length}',
                  Icons.folder_zip_outlined,
                  const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Total Files',
                  '$_totalFilesCount',
                  Icons.insert_drive_file_outlined,
                  palette.accentAmber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '$_completedFilesCount',
                  Icons.check_circle_outline,
                  palette.successGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Failed',
                  '$_failedFilesCount',
                  Icons.error_outline,
                  palette.dangerRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final palette = AppThemePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.statLabelOf(context),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(UploadSessionItem session) {
    final palette = AppThemePalette.of(context);
    Color statusColor;
    IconData statusIcon;

    switch (session.status.toLowerCase()) {
      case 'completed':
        statusColor = palette.successGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'failed':
        statusColor = palette.dangerRed;
        statusIcon = Icons.error_rounded;
        break;
      case 'active':
        statusColor = const Color(0xFF60A5FA);
        statusIcon = Icons.sync_rounded;
        break;
      default:
        statusColor = palette.accentAmber;
        statusIcon = Icons.hourglass_empty_rounded;
    }

    final progressPercentage = (session.completionProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.18 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Session UUID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.cloud_upload_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.uuid,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$progressPercentage% Processed',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      session.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Event UUID & Album ID Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                Icons.event_note_rounded,
                'Event: ${session.eventUuid.substring(0, session.eventUuid.length > 8 ? 8 : session.eventUuid.length)}...',
              ),
              if (session.albumId != null)
                _buildBadge(Icons.photo_album_rounded, 'Album #${session.albumId}'),
              _buildBadge(Icons.devices_rounded, session.formattedSource),
            ],
          ),
          const SizedBox(height: 14),
          // Custom Progress Bar
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: palette.bgDarker,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: session.completionProgress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined, color: palette.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Files: ${session.completedFiles} / ${session.totalFiles} completed'
                        '${session.failedFiles > 0 ? " (${session.failedFiles} failed)" : ""}',
                        style: TextStyle(color: palette.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: palette.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    session.createdAt.length >= 10
                        ? session.createdAt.substring(0, 10)
                        : session.createdAt,
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    final palette = AppThemePalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: palette.textMuted, size: 12),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final palette = AppThemePalette.of(context);
    if (_nextCursor == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'All sessions loaded.',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: _isLoadingMore
            ? CircularProgressIndicator(color: palette.accentAmber)
            : ElevatedButton.icon(
                onPressed: _loadNextPage,
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                label: const Text('Load More Sessions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.cardBg,
                  foregroundColor: palette.accentAmber,
                  side: BorderSide(color: palette.accentAmber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final palette = AppThemePalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.dangerRed, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load upload history',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unknown network error',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSessions(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accentAmber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    final palette = AppThemePalette.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, color: palette.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'No upload sessions found',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your status or source filters.',
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}


