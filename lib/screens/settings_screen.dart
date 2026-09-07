import 'package:flutter/material.dart';

import '../models/health_model.dart';
import '../models/platform_branding_model.dart';
import '../services/public_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import 'desktop_release_screen.dart';
import 'endpoint_summary_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppThemePalette get palette => AppThemePalette.of(context);

  Color get _bgDark => palette.bgDarker;
  Color get _bgPanel => palette.cardBg;
  Color get _border => palette.border;
  Color get _accentOrange => palette.accentPrimary;
  Color get _textMuted => palette.textMuted;

  final PublicApiService _publicApiService = PublicApiService();

  bool _autoSyncEnabled = true;
  bool _wifiOnly = true;
  bool _notificationsEnabled = true;

  bool _isCheckingHealth = false;
  HealthModel? _healthModel;
  PlatformBrandingModel? _brandingModel;
  String? _healthCheckError;

  @override
  void initState() {
    super.initState();
    _performHealthCheck();
  }

  Future<void> _performHealthCheck() async {
    setState(() {
      _isCheckingHealth = true;
      _healthCheckError = null;
    });

    try {
      final health = await _publicApiService.getHealthStatus(
        timeout: const Duration(seconds: 5),
      );
      final branding = await _publicApiService.getPlatformBranding(
        timeout: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _healthModel = health;
          _brandingModel = branding;
          _isCheckingHealth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _healthCheckError = e.toString().replaceFirst('Exception: ', '');
          _isCheckingHealth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Text(
                'PREFERENCES',
                style: TextStyle(
                  color: _accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'App Settings',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Settings Group Card
              Container(
                decoration: BoxDecoration(
                  color: _bgPanel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.white,
                      activeTrackColor: _accentOrange,
                      value: _autoSyncEnabled,
                      onChanged: (val) => setState(() => _autoSyncEnabled = val),
                      title: Text('Auto Watch Folder Sync', style: TextStyle(color: palette.textPrimary)),
                      subtitle: Text('Automatically upload new photos from watch folder', style: TextStyle(color: _textMuted, fontSize: 12)),
                    ),
                    Divider(color: _border, height: 1),
                    SwitchListTile(
                      activeThumbColor: Colors.white,
                      activeTrackColor: _accentOrange,
                      value: _wifiOnly,
                      onChanged: (val) => setState(() => _wifiOnly = val),
                      title: Text('Upload over Wi-Fi Only', style: TextStyle(color: palette.textPrimary)),
                      subtitle: Text('Save cellular data bandwidth', style: TextStyle(color: _textMuted, fontSize: 12)),
                    ),
                    Divider(color: _border, height: 1),
                    SwitchListTile(
                      activeThumbColor: Colors.white,
                      activeTrackColor: _accentOrange,
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                      title: Text('Upload Notifications', style: TextStyle(color: palette.textPrimary)),
                      subtitle: Text('Receive alerts when uploads complete or fail', style: TextStyle(color: _textMuted, fontSize: 12)),
                    ),
                    Divider(color: _border, height: 1),
                    ListTile(
                      leading: Icon(Icons.desktop_windows, color: _accentOrange),
                      title: Text('Desktop Releases & Auto-Update', style: TextStyle(color: palette.textPrimary)),
                      subtitle: Text('Inspect Tauri desktop updates & signed download URLs', style: TextStyle(color: _textMuted, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: _textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DesktopReleaseScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(color: _border, height: 1),
                    ListTile(
                      leading: Icon(Icons.api, color: _accentOrange),
                      title: Text('Endpoint Summary & API Catalog', style: TextStyle(color: palette.textPrimary)),
                      subtitle: Text('Catalog of 23 API endpoints, live smoke testing & cURL docs', style: TextStyle(color: _textMuted, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: _textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EndpointSummaryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 32),

              // System Health Section
              Text(
                'SYSTEM & API HEALTH',
                style: TextStyle(
                  color: _accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Platform & Server Status',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildHealthCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCheckingHealth
                          ? _accentOrange
                          : (_healthModel?.isHealthy == true
                              ? Colors.greenAccent
                              : Colors.redAccent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _healthModel != null
                        ? 'Status: ${_healthModel!.status.toUpperCase()}'
                        : (_isCheckingHealth ? 'Checking health...' : 'Status: Unknown'),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: _isCheckingHealth
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accentOrange,
                        ),
                      )
                    : Icon(Icons.refresh, color: _accentOrange, size: 20),
                onPressed: _isCheckingHealth ? null : () {
                  _performHealthCheck();
                  AppToast.show(context, 'Checking server status...', type: ToastType.info);
                },
                tooltip: 'Check API Status',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _border, height: 1),
          const SizedBox(height: 12),
          if (_healthModel != null) ...[
            _buildDetailRow('App Name', _healthModel!.app),
            const SizedBox(height: 6),
          ],
          if (_brandingModel != null) ...[
            _buildDetailRow('Branding Platform', _brandingModel!.appName),
            const SizedBox(height: 6),
            _buildDetailRow('White-Label Logo', _brandingModel!.logoUrl != null ? 'Configured' : 'Default'),
          ] else if (_healthCheckError != null) ...[
            Text(
              'Diagnostic notice: $_healthCheckError',
              style: TextStyle(color: palette.accentPrimary, fontSize: 12),
            ),
          ] else ...[
            Text(
              'Public endpoints: /api/v1/health & /api/v1/platform/branding',
              style: TextStyle(color: _textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _textMuted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
