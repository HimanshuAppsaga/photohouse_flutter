import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../screens/events_dashboard_screen.dart';
import '../screens/upload_queue_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/preferences_screen.dart';
import '../utils/app_toast.dart';
import '../widgets/modern_tab_bar.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  final UserModel currentUser;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.currentUser = UserModel.sampleUser,
  });

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationShellState>();
    state?._onTabSelected(index);
  }

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleBackPress(bool didPop) {
    if (didPop) return;

    // If not on the primary Events tab, back button returns to Events tab
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // On primary tab: double-back to exit confirmation
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      AppToast.show(
        context,
        'Press back again to exit',
        type: ToastType.info,
      );
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      EventsDashboardScreen(currentUser: widget.currentUser),
      const UploadQueueScreen(),
      const SubscriptionScreen(),
      PreferencesScreen(currentUser: widget.currentUser),
    ];

    const tabItems = [
      TabItemData(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Events',
      ),
      TabItemData(
        icon: Icons.cloud_upload_outlined,
        activeIcon: Icons.cloud_upload_rounded,
        label: 'Queue',
      ),
      TabItemData(
        icon: Icons.credit_card_outlined,
        activeIcon: Icons.credit_card_rounded,
        label: 'Subscription',
      ),
      TabItemData(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBackPress(didPop),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        // Ultra-Modern Floating Bottom Tab Dock
        bottomNavigationBar: ModernFloatingBottomDock(
          selectedIndex: _currentIndex,
          items: tabItems,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
