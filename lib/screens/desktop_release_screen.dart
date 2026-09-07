import 'package:flutter/material.dart';
import '../models/desktop_release_model.dart';
import '../services/api_config.dart';
import '../services/desktop_release_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';

class DesktopReleaseScreen extends StatefulWidget {
  final DesktopReleaseApiService? apiService;

  const DesktopReleaseScreen({
    super.key,
    this.apiService,
  });

  @override
  State<DesktopReleaseScreen> createState() => _DesktopReleaseScreenState();
}

class _DesktopReleaseScreenState extends State<DesktopReleaseScreen> {
  AppThemePalette get palette => AppThemePalette.of(context);

  Color get _bgDark => palette.bgDarker;
  Color get _bgPanel => palette.cardBg;
  Color get _border => palette.border;
  Color get _accentOrange => palette.accentAmber;
  Color get _textMuted => palette.textMuted;

  late final DesktopReleaseApiService _apiService;

  String _selectedPlatform = ApiConfig.desktopPlatforms.first;
  final TextEditingController _currentVersionController = TextEditingController(text: '1.0.0');
  String _downloadType = 'installer';

  bool _isLoadingCheckUpdate = false;
  bool _isLoadingLatestBuild = false;
  bool _isLoadingDownloadUrl = false;
  bool _isLoadingManifest = false;

  DesktopCheckUpdateModel? _checkUpdateResult;
  DesktopLatestBuildModel? _latestBuildResult;
  DesktopDownloadResponseModel? _downloadResult;
  TauriUpdaterManifestModel? _manifestResult;

  String? _checkUpdateError;
  String? _latestBuildError;
  String? _downloadError;
  String? _manifestError;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? DesktopReleaseApiService();
    _fetchLatestBuild();
  }

  @override
  void dispose() {
    _currentVersionController.dispose();
    super.dispose();
  }

  Future<void> _fetchCheckUpdate() async {
    setState(() {
      _isLoadingCheckUpdate = true;
      _checkUpdateError = null;
    });

    try {
      final res = await _apiService.checkUpdate(
        platform: _selectedPlatform,
        currentVersion: _currentVersionController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _checkUpdateResult = res;
          _isLoadingCheckUpdate = false;
        });
        AppToast.show(context, 'Update check completed', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkUpdateError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingCheckUpdate = false;
        });
      }
    }
  }

  Future<void> _fetchLatestBuild() async {
    setState(() {
      _isLoadingLatestBuild = true;
      _latestBuildError = null;
    });

    try {
      final res = await _apiService.getLatestBuild(
        platform: _selectedPlatform,
      );
      if (mounted) {
        setState(() {
          _latestBuildResult = res;
          _isLoadingLatestBuild = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _latestBuildError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingLatestBuild = false;
        });
      }
    }
  }

  Future<void> _fetchDownloadUrl() async {
    setState(() {
      _isLoadingDownloadUrl = true;
      _downloadError = null;
    });

    try {
      final res = await _apiService.getDownloadUpdateUrl(
        platform: _selectedPlatform,
        type: _downloadType,
      );
      if (mounted) {
        setState(() {
          _downloadResult = res;
          _isLoadingDownloadUrl = false;
        });
        AppToast.show(context, 'Download link retrieved', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingDownloadUrl = false;
        });
      }
    }
  }

  Future<void> _fetchUpdaterManifest() async {
    setState(() {
      _isLoadingManifest = true;
      _manifestError = null;
    });

    try {
      final res = await _apiService.getUpdaterManifest();
      if (mounted) {
        setState(() {
          _manifestResult = res;
          _isLoadingManifest = false;
        });
        AppToast.show(context, 'Updater manifest loaded', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _manifestError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingManifest = false;
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
        title: const Text(
          'Desktop Release APIs',
          style: TextStyle(
            color: Colors.white,
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
                'DESKTOP AUTO-UPDATE & RELEASES',
                style: TextStyle(
                  color: _accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Desktop Release Endpoints',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Used by Tauri desktop agents to check updates, retrieve signed R2 downloads, and fetch updater manifests.',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Platform Selector Card
              _buildPlatformSelectorCard(),
              const SizedBox(height: 20),

              // 1. Check Update API Card
              _buildCheckUpdateCard(),
              const SizedBox(height: 20),

              // 2. Latest Build Metadata Card
              _buildLatestBuildCard(),
              const SizedBox(height: 20),

              // 3. Download Release Card
              _buildDownloadUpdateCard(),
              const SizedBox(height: 20),

              // 4. Tauri Updater Manifest Card
              _buildUpdaterManifestCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Platform Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Platform', style: TextStyle(color: _textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _bgDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: _bgPanel,
                          isExpanded: true,
                          value: _selectedPlatform,
                          items: ApiConfig.desktopPlatforms.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPlatform = val;
                              });
                              _fetchLatestBuild();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Version', style: TextStyle(color: _textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _currentVersionController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: _bgDark,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _accentOrange),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Text(
                'GET /desktop/check-update',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: _isLoadingCheckUpdate ? null : _fetchCheckUpdate,
                icon: _isLoadingCheckUpdate
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.sync, size: 16),
                label: const Text('Check Update', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_checkUpdateResult != null) ...[
            _buildResultRow('Update Available', _checkUpdateResult!.hasUpdate ? 'YES' : 'NO',
                valueColor: _checkUpdateResult!.hasUpdate ? Colors.greenAccent : Colors.white),
            _buildResultRow('Latest Version', _checkUpdateResult!.latestVersion),
            if (_checkUpdateResult!.downloadUrl != null)
              _buildResultRow('Download URL', _checkUpdateResult!.downloadUrl!),
            if (_checkUpdateResult!.releaseNotes != null)
              _buildResultRow('Release Notes', _checkUpdateResult!.releaseNotes!),
          ] else if (_checkUpdateError != null) ...[
            Text('Error: $_checkUpdateError', style: TextStyle(color: palette.dangerRed, fontSize: 12)),
          ] else ...[
            Text('Click "Check Update" to query build availability.',
                style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildLatestBuildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'GET /desktop/latest-build',
                style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: _isLoadingLatestBuild
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _accentOrange))
                    : Icon(Icons.refresh, color: _accentOrange),
                onPressed: _isLoadingLatestBuild ? null : _fetchLatestBuild,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_latestBuildResult != null) ...[
            _buildResultRow('Platform', _latestBuildResult!.platform),
            _buildResultRow('Version', _latestBuildResult!.version),
            if (_latestBuildResult!.pubDate != null) _buildResultRow('Release Date', _latestBuildResult!.pubDate!),
            if (_latestBuildResult!.downloadUrl != null) _buildResultRow('Download URL', _latestBuildResult!.downloadUrl!),
            if (_latestBuildResult!.notes != null) _buildResultRow('Notes', _latestBuildResult!.notes!),
          ] else if (_latestBuildError != null) ...[
            Text('Error: $_latestBuildError', style: TextStyle(color: palette.dangerRed, fontSize: 12)),
          ] else ...[
            Text('Loading latest build info...', style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GET /desktop/download-update',
            style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Download Type: ', style: TextStyle(color: _textMuted, fontSize: 13)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Installer'),
                selected: _downloadType == 'installer',
                onSelected: (val) => setState(() => _downloadType = 'installer'),
                selectedColor: _accentOrange,
                backgroundColor: _bgDark,
                labelStyle: TextStyle(color: _downloadType == 'installer' ? Colors.black : palette.textPrimary),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Updater'),
                selected: _downloadType == 'updater',
                onSelected: (val) => setState(() => _downloadType = 'updater'),
                selectedColor: _accentOrange,
                backgroundColor: _bgDark,
                labelStyle: TextStyle(color: _downloadType == 'updater' ? Colors.black : palette.textPrimary),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isLoadingDownloadUrl ? null : _fetchDownloadUrl,
                child: _isLoadingDownloadUrl
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Get URL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_downloadResult != null) ...[
            _buildResultRow('Redirect / R2 URL', _downloadResult!.downloadUrl),
            _buildResultRow('HTTP Status', '${_downloadResult!.statusCode}'),
          ] else if (_downloadError != null) ...[
            Text('Error: $_downloadError', style: TextStyle(color: palette.dangerRed, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdaterManifestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'GET /desktop/updater-manifest',
                style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isLoadingManifest ? null : _fetchUpdaterManifest,
                child: _isLoadingManifest
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Fetch Manifest', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_manifestResult != null) ...[
            _buildResultRow('Manifest Version', _manifestResult!.version),
            if (_manifestResult!.notes != null) _buildResultRow('Notes', _manifestResult!.notes!),
            _buildResultRow('Platforms Configured', _manifestResult!.platforms.keys.join(", ")),

          ] else if (_manifestError != null) ...[
            Text('Error: $_manifestError', style: TextStyle(color: palette.dangerRed, fontSize: 12)),
          ] else ...[
            Text('Click "Fetch Manifest" to read Tauri auto-updater JSON manifest.',
                style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
