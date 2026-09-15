import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_api_service.dart';
import '../navigation/main_navigation_shell.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  final SubscriptionApiService? subscriptionApiService;

  const SubscriptionScreen({
    super.key,
    this.subscriptionApiService,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final SubscriptionApiService _apiService;
  SubscriptionModel? _subscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.subscriptionApiService ?? SubscriptionApiService();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getSubscription();
      if (mounted) {
        setState(() {
          _subscription = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.successGreen;
      case 'trialing':
        return AppColors.accentAmber;
      case 'expired':
      case 'cancelled':
        return AppColors.dangerRed;
      default:
        return AppColors.textMuted;
    }
  }

  Color _getStorageGaugeColor(double percent) {
    if (percent >= 95.0) {
      return AppColors.dangerRed;
    } else if (percent >= 80.0) {
      return AppColors.accentAmber;
    } else {
      return AppColors.successGreen;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showSwitchPlanDialog(BuildContext context, SubscriptionPlanModel targetPlan) {
    final palette = AppThemePalette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, color: palette.accentAmber, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Switch to ${targetPlan.name}',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${targetPlan.resolvedPriceFormatted} • ${targetPlan.storageLabel ?? "Cloud Storage"}',
                          style: TextStyle(color: palette.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Plan upgrades and billing adjustments are managed through PhotoHouse studio support. Contact our support team to switch to the ${targetPlan.name} plan.',
                style: TextStyle(color: palette.textSecondary, fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Support request for ${targetPlan.name} plan sent.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accentAmber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.support_agent_rounded, size: 20),
                  label: const Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
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
            'Subscription & Quota',
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
                icon: _isLoading
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.accentAmber,
                      )
                    : Icon(Icons.refresh_rounded, color: palette.textPrimary, size: 20),
                tooltip: 'Refresh Subscription',
                onPressed: _isLoading ? null : _loadSubscription,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadSubscription,
            color: palette.accentAmber,
            backgroundColor: palette.cardBg,
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final palette = AppThemePalette.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: palette.accentAmber),
            const SizedBox(height: 16),
            Text(
              'Loading subscription details...',
              style: TextStyle(color: palette.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.dangerRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.dangerRed.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.error_outline_rounded, color: palette.dangerRed, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Subscription',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accentAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final sub = _subscription;
    if (sub == null) {
      return Center(
        child: Text(
          'No subscription data available.',
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }

    final plan = sub.plan;
    final usage = sub.usage;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            'PLAN & BILLING',
            style: AppTextStyles.overlineOf(context),
          ),
          const SizedBox(height: 6),
          Text(
            'Current Plan',
            style: AppTextStyles.displayHeadingOf(context),
          ),
          const SizedBox(height: 16),

          // Hero Plan Card
          _buildCurrentPlanCard(context, sub, plan),

          const SizedBox(height: 24),

          // Storage Quota Card
          if (usage != null) ...[
            Text(
              'STORAGE & QUOTA',
              style: AppTextStyles.overlineOf(context),
            ),
            const SizedBox(height: 8),
            _buildStorageQuotaCard(context, sub, usage),
            const SizedBox(height: 24),
          ],

          // Available Plans Section (Dynamic plans matching website/desktop)
          Text(
            'AVAILABLE PLANS',
            style: AppTextStyles.overlineOf(context),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a Plan',
            style: AppTextStyles.displayHeadingOf(context),
          ),
          const SizedBox(height: 16),
          _DynamicPlansSlider(
            plans: sub.availablePlans,
            sub: sub,
            onSwitchPlan: (p) => _showSwitchPlanDialog(context, p),
          ),

          const SizedBox(height: 24),

          // Enterprise Upgrade Banner
          _buildEnterpriseSupportBanner(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Hero Current Plan Card
  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionModel sub, SubscriptionPlanModel? plan) {
    final palette = AppThemePalette.of(context);
    final statusColor = _getStatusBadgeColor(sub.status);
    final priceStr = plan?.resolvedPriceFormatted ?? (plan?.formattedPrice ?? (plan?.priceInr != null ? '₹${plan!.priceInr}' : 'Free'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: sub.isActive ? palette.accentAmber : palette.border,
          width: sub.isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: sub.isActive
                ? palette.accentAmber.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
            blurRadius: 20,
            spreadRadius: sub.isActive ? 2 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle gradient glow
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accentAmber.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sub.statusLabel,
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
                    // Price Tag
                    Text(
                      priceStr,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.accentAmber.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: palette.accentAmber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan?.name ?? 'No Plan Active',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan?.storageLabel != null ? '${plan!.storageLabel} Storage Plan' : 'Tier Membership',
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: palette.textMuted, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Billing Period: ${_formatDate(sub.startDate ?? sub.currentPeriodStart)} - ${_formatDate(sub.endDate ?? sub.currentPeriodEnd)}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sub.cancelledAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: palette.dangerRed, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Cancelled on ${_formatDate(sub.cancelledAt)}',
                        style: TextStyle(
                          color: palette.dangerRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Storage Quota Card
  Widget _buildStorageQuotaCard(BuildContext context, SubscriptionModel sub, SubscriptionUsageModel usage) {
    final palette = AppThemePalette.of(context);
    final gaugeColor = _getStorageGaugeColor(usage.storagePercent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
            blurRadius: 16,
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: gaugeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: gaugeColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      Icons.cloud_done_rounded,
                      color: gaugeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cloud Storage',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gaugeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gaugeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${usage.storagePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: gaugeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (usage.storagePercent / 100.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: palette.bgDarker,
              color: gaugeColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                usage.storageUsedFormatted,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Available: ${((usage.storageLimitBytes - usage.storageUsedBytes) / (1024 * 1024 * 1024)).clamp(0, double.infinity).toStringAsFixed(1)} GB',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (sub.isStorageWarning) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: gaugeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: gaugeColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: gaugeColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.isStorageCritical
                          ? 'Storage quota critical! Please upgrade your plan to avoid upload failures.'
                          : 'Storage quota warning! You have used over 80% of your cloud storage.',
                      style: TextStyle(
                        color: gaugeColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Enterprise Upgrade Banner
  Widget _buildEnterpriseSupportBanner(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.cardBg,
            palette.accentAmber.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.accentAmber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.accentAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.rocket_launch_rounded, color: palette.accentAmber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Higher Limits?',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Upgrade to Enterprise for unlimited storage, custom domain branding, and priority support.',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicPlansSlider extends StatefulWidget {
  final List<SubscriptionPlanModel> plans;
  final SubscriptionModel sub;
  final Function(SubscriptionPlanModel) onSwitchPlan;

  const _DynamicPlansSlider({
    required this.plans,
    required this.sub,
    required this.onSwitchPlan,
  });

  @override
  State<_DynamicPlansSlider> createState() => _DynamicPlansSliderState();
}

class _DynamicPlansSliderState extends State<_DynamicPlansSlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final currentIdx = widget.plans.indexWhere((p) => widget.sub.isCurrentPlan(p));
    _currentPage = currentIdx >= 0 ? currentIdx : 0;
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.88,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final plans = widget.plans;

    if (plans.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: plans.map((p) {
              final isCurrent = widget.sub.isCurrentPlan(p);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: _buildPlanCardItem(context, p, isCurrent),
                ),
              );
            }).toList(),
          );
        }

        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          child: Column(
            children: [
              SizedBox(
                height: 480,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isCurrent = widget.sub.isCurrentPlan(plan);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: _buildPlanCardItem(context, plan, isCurrent),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              // Dots indicator with tap navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(plans.length, (index) {
                  final isSelected = _currentPage == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      width: isSelected ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? palette.accentAmber : palette.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // Individual Plan Card matching Image 2
  Widget _buildPlanCardItem(BuildContext context, SubscriptionPlanModel plan, bool isCurrent) {
    final palette = AppThemePalette.of(context);
    final features = plan.resolvedFeatures;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? palette.accentAmber : palette.border,
          width: isCurrent ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? palette.accentAmber.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
            blurRadius: isCurrent ? 20 : 12,
            spreadRadius: isCurrent ? 1 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Plan Name & CURRENT Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.accentAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Price
          Text(
            plan.resolvedPriceFormatted,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),

          // Tagline / Best for
          Text(
            plan.resolvedTagline,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 18),

          // Features List with Checkmarks (rendered as Column to prevent scroll gesture interception)
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < features.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: palette.accentAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            features[i],
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: isCurrent
                ? ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You are currently on the ${plan.name} plan.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Current plan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.border.withValues(alpha: 0.6), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledForegroundColor: palette.textMuted.withValues(alpha: 0.6),
                    ),
                    child: Text(
                      'Switch via support',
                      style: TextStyle(
                        color: palette.textMuted.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
