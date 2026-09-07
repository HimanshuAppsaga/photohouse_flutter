import 'package:flutter/material.dart';
import 'package:photohouse/utils/app_toast.dart';
import '../models/event_model.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';
import '../services/events_api_service.dart';
import '../services/subscription_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_account_card.dart';
import 'event_overview_screen.dart';

class EventsDashboardScreen extends StatefulWidget {
  final Function(EventItem)? onEventSelected;
  final UserModel currentUser;
  final EventsApiService? eventsApiService;
  final SubscriptionApiService? subscriptionApiService;

  const EventsDashboardScreen({
    super.key,
    this.onEventSelected,
    this.currentUser = UserModel.sampleUser,
    this.eventsApiService,
    this.subscriptionApiService,
  });

  @override
  State<EventsDashboardScreen> createState() => _EventsDashboardScreenState();
}

class _EventsDashboardScreenState extends State<EventsDashboardScreen> {
  late final EventsApiService _eventsApiService;
  late final SubscriptionApiService _subscriptionApiService;
  List<EventItem> _events = EventItem.sampleEvents;
  String _searchQuery = '';
  bool _isRefreshing = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _eventsApiService = widget.eventsApiService ?? EventsApiService();
    _subscriptionApiService =
        widget.subscriptionApiService ?? SubscriptionApiService();
    _fetchEvents();
  }

  Future<void> _fetchEvents({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final response = await _eventsApiService.getEvents();

      if (mounted) {
        setState(() {
          _events = response.events.isNotEmpty
              ? response.events
              : EventItem.sampleEvents;
          _isRefreshing = false;
        });

        if (isRefresh) {
          AppToast.show(
            context,
            'Events refreshed successfully!',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _events = EventItem.sampleEvents;
          _isRefreshing = false;
        });

        if (isRefresh) {
          AppToast.show(
            context,
            'Using cached events (${e.toString().replaceAll("Exception: ", "")})',
            type: ToastType.info,
          );
        }
      }
    }
  }

  Future<void> _refreshEvents() async {
    await _fetchEvents(isRefresh: true);
  }

  /// Checks if the tenant is eligible to create new events based on quota limits
  Future<bool> checkEventCreationQuota() async {
    try {
      final SubscriptionModel sub = await _subscriptionApiService
          .getSubscription();
      return sub.canCreateEvent;
    } catch (_) {
      return true;
    }
  }

  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: UserAccountCard(initialUser: widget.currentUser),
            ),
          ),
        );
      },
    );
  }

  void _handleSelectEvent(EventItem event) {
    if (widget.onEventSelected != null) {
      widget.onEventSelected!(event);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventOverviewScreen(event: event),
        ),
      );
    }
  }

  List<EventItem> get _filteredEvents {
    return _events.where((event) {
      return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.tag.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int get _totalPhotosCount {
    return _events.fold(0, (sum, item) => sum + item.photoCount);
  }

  int get _readyToShareCount {
    return _events.where((item) => item.isReadyToShare).length;
  }

  IconData _getEventIcon(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('ring') || lower.contains('wedding')) {
      return Icons.favorite_rounded;
    } else if (lower.contains('birthday') || lower.contains('party')) {
      return Icons.cake_rounded;
    } else if (lower.contains('corporate') || lower.contains('business')) {
      return Icons.business_center_rounded;
    } else if (lower.contains('school') || lower.contains('grad')) {
      return Icons.school_rounded;
    } else if (lower.contains('sport')) {
      return Icons.sports_soccer_rounded;
    }
    return Icons.photo_library_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bgDarker,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshEvents,
          color: palette.accentAmber,
          backgroundColor: palette.cardBg,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(palette),
                const SizedBox(height: 16),
                // Summary Overview Banner
                _buildSummaryHeaderCard(palette),
                const SizedBox(height: 20),
                // Search Bar with Grid/List Toggle
                _buildSearchBarWithToggle(palette, filtered.length),
                const SizedBox(height: 20),
                // Event Content
                filtered.isEmpty
                    ? _buildEmptyEventsView(palette)
                    : _isGridView
                    ? _buildGridView(palette, filtered)
                    : _buildListView(palette, filtered),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page Header Widget
  Widget _buildHeader(AppThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EVENT DIRECTORY', style: AppTextStyles.overlineOf(context)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh Button
                InkWell(
                  onTap: _isRefreshing ? null : _refreshEvents,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
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
                          : Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: palette.accentAmber,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Account Profile Chip Next to Refresh Button
                InkWell(
                  onTap: _showAccountDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border),
                    ),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF78350F),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.currentUser.firstLetter,
                            style: const TextStyle(
                              color: Color(0xFFFEF3C7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Events', style: AppTextStyles.displayHeadingOf(context)),
        const SizedBox(height: 4),
        Text(
          'Choose an event to view photo albums and manage uploads.',
          style: AppTextStyles.subTitleOf(context),
        ),
      ],
    );
  }

  // Summary Metrics Banner Widget
  Widget _buildSummaryHeaderCard(AppThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
        gradient: LinearGradient(
          colors: [
            palette.cardBg,
            palette.cardBg.withValues(alpha: 0.8),
            palette.accentAmber.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              palette: palette,
              icon: Icons.calendar_today_rounded,
              label: 'Total Events',
              value: '${_events.length}',
              iconColor: palette.accentAmber,
            ),
          ),
          Container(width: 1, height: 32, color: palette.border),
          Expanded(
            child: _buildStatItem(
              palette: palette,
              icon: Icons.photo_library_outlined,
              label: 'Total Photos',
              value: '$_totalPhotosCount',
              iconColor: const Color(0xFF60A5FA),
            ),
          ),
          Container(width: 1, height: 32, color: palette.border),
          Expanded(
            child: _buildStatItem(
              palette: palette,
              icon: Icons.verified_rounded,
              label: 'Ready to Share',
              value: '$_readyToShareCount',
              iconColor: palette.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required AppThemePalette palette,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Search Bar with Toggle Button Widget
  Widget _buildSearchBarWithToggle(AppThemePalette palette, int count) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: palette.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search events or tags...',
                hintStyle: TextStyle(
                  color: palette.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: palette.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: palette.textMuted,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Toggle view mode button
        Container(
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.view_list_rounded,
                  size: 20,
                  color: !_isGridView
                      ? palette.accentAmber
                      : palette.textMuted,
                ),
                tooltip: 'List View',
                onPressed: () {
                  if (_isGridView) {
                    setState(() => _isGridView = false);
                  }
                },
              ),
              Container(width: 1, height: 20, color: palette.border),
              IconButton(
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: _isGridView
                      ? palette.accentAmber
                      : palette.textMuted,
                ),
                tooltip: 'Grid View',
                onPressed: () {
                  if (!_isGridView) {
                    setState(() => _isGridView = true);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Empty Search View
  Widget _buildEmptyEventsView(AppThemePalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            'No matching events found',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query.',
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // List View Widget
  Widget _buildListView(AppThemePalette palette, List<EventItem> events) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventListCard(palette, event);
      },
    );
  }

  // Grid View Widget
  Widget _buildGridView(AppThemePalette palette, List<EventItem> events) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventGridCard(palette, event);
      },
    );
  }

  // Modern Card Widget (List View)
  Widget _buildEventListCard(AppThemePalette palette, EventItem event) {
    final eventIcon = _getEventIcon(event.tag);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSelectEvent(event),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Event Avatar Tile
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.accentAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        eventIcon,
                        color: palette.accentAmber,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.date,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Category Tag Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: palette.accentAmber.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      event.tag,
                      style: TextStyle(
                        color: palette.accentAmber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Photos & Albums & Ready-to-share metrics row
              Row(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 15,
                        color: palette.accentAmber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${event.photoCount} photos',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 15,
                        color: palette.accentAmber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${event.albumCount} albums',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (event.isReadyToShare)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: palette.successGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: palette.successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ready',
                            style: TextStyle(
                              color: palette.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: palette.border, height: 1),
              const SizedBox(height: 10),
              // Action Arrow Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Select Event',
                    style: TextStyle(
                      color: palette.accentAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: palette.accentAmber,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Grid Card View
  Widget _buildEventGridCard(AppThemePalette palette, EventItem event) {
    final eventIcon = _getEventIcon(event.tag);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSelectEvent(event),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: palette.isDark ? 0.15 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: palette.accentAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      eventIcon,
                      color: palette.accentAmber,
                      size: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: palette.accentAmber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      event.tag,
                      style: TextStyle(
                        color: palette.accentAmber,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                event.date,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${event.photoCount} photos',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: palette.accentAmber,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
