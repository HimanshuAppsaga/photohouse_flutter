import 'dart:async';
import 'package:flutter/material.dart';

import '../models/health_model.dart';
import '../models/platform_branding_model.dart';
import '../models/user_model.dart';
import '../navigation/main_navigation_shell.dart';
import '../services/auth_service.dart';
import '../services/public_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final PublicApiService _publicApiService = PublicApiService();
  final AuthService _authService = AuthService();

  PlatformBrandingModel? _branding;
  HealthModel? _healthStatus;
  UserModel? _currentUser;
  bool _isInitializingApi = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _initializePublicApiAndNavigate();
  }

  Future<void> _initializePublicApiAndNavigate() async {
    final startTime = DateTime.now();

    try {
      final results = await Future.wait([
        _publicApiService.getPlatformBranding(
          timeout: const Duration(seconds: 3),
        ),
        _publicApiService.getHealthStatus(
          timeout: const Duration(seconds: 3),
        ),
      ]).timeout(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _branding = results[0] as PlatformBrandingModel;
          _healthStatus = results[1] as HealthModel;
          _isInitializingApi = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _branding = PlatformBrandingModel.defaultBranding;
          _healthStatus = HealthModel.sample;
          _isInitializingApi = false;
        });
      }
    }

    // Check token and validate session via GET /user on every launch
    bool isAuthenticated = false;
    try {
      final hasToken = await _authService.hasToken();
      if (hasToken) {
        _currentUser = await _authService.getCurrentUser();
        isAuthenticated = true;
      }
    } catch (e) {
      // 401 or token invalid -> force re-login
      isAuthenticated = false;
      _currentUser = null;
    }

    final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
    final remainingMs = 1800 - elapsedMs;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }

    if (!mounted) return;

    final Widget targetScreen = isAuthenticated && _currentUser != null
        ? MainNavigationShell(currentUser: _currentUser!)
        : LoginScreen(branding: _branding);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final appDisplayName = _branding?.appName ?? 'Photo House';

    return Scaffold(
      backgroundColor: palette.bgDarker,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 140, showCard: true, padding: 20),
                const SizedBox(height: 28),
                Text(
                  appDisplayName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: palette.accentAmber,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Professional Photo & Event Synchronization',
                  style: TextStyle(fontSize: 14, color: palette.textMuted),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: palette.accentAmber,
                  ),
                ),
                if (!_isInitializingApi && _healthStatus != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _healthStatus!.isHealthy
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: _healthStatus!.isHealthy
                            ? palette.successGreen
                            : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'API Status: ${_healthStatus!.status.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _healthStatus!.isHealthy
                              ? palette.successGreen
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
