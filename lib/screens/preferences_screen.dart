import 'package:flutter/material.dart';
import 'package:photohouse/utils/app_toast.dart';
import '../models/user_model.dart';
import '../models/watermark_settings_model.dart';
import '../services/theme_service.dart';
import '../services/watermark_api_service.dart';
import '../navigation/main_navigation_shell.dart';
import '../theme/app_theme.dart';
import '../widgets/user_account_card.dart';

class PreferencesScreen extends StatefulWidget {
  final UserModel currentUser;
  final WatermarkApiService? watermarkApiService;

  const PreferencesScreen({
    super.key,
    this.currentUser = UserModel.sampleUser,
    this.watermarkApiService,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // Dynamic Theme Colors
  AppThemePalette get palette => AppThemePalette.of(context);

  Color get _bgDark => palette.bgDarker;
  Color get _cardBg => palette.cardBg;
  Color get _inputBg => palette.cardSurface;
  Color get _border => palette.border;
  Color get _accentAmber => palette.accentAmber;
  Color get _textPrimary => palette.textPrimary;
  Color get _textMuted => palette.textMuted;

  late final WatermarkApiService _watermarkApiService;

  // Watermark Form State Values
  bool _enableWatermark = true;
  String _watermarkType = 'Text';
  String _watermarkPosition = 'Bottom right';
  final TextEditingController _watermarkTextController = TextEditingController(
    text: '',
  );
  final TextEditingController _fontSizeController = TextEditingController(
    text: '32',
  );
  final TextEditingController _textColorController = TextEditingController(
    text: '#FFFFFF',
  );
  final TextEditingController _rotationController = TextEditingController(
    text: '0',
  );
  final TextEditingController _opacityController = TextEditingController(
    text: '50',
  );
  final TextEditingController _scaleController = TextEditingController(
    text: '20',
  );
  final TextEditingController _marginController = TextEditingController(
    text: '20',
  );
  String _guestDownloadOption = 'Watermarked photo';

  bool _isLoadingWatermark = true;
  bool _isSavingWatermark = false;
  String? _watermarkFetchError;
  WatermarkSettingsModel? _watermarkSettings;

  String _themeOption = 'Dark';
  bool _computeAiEmbeddings = false;

  @override
  void initState() {
    super.initState();
    _themeOption = ThemeService.instance.currentThemeOption;
    _watermarkApiService = widget.watermarkApiService ?? WatermarkApiService();
    _loadWatermarkSettings();
  }

  @override
  void dispose() {
    _watermarkTextController.dispose();
    _fontSizeController.dispose();
    _textColorController.dispose();
    _rotationController.dispose();
    _opacityController.dispose();
    _scaleController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  Future<void> _loadWatermarkSettings() async {
    setState(() {
      _isLoadingWatermark = true;
      _watermarkFetchError = null;
    });

    try {
      final settings = await _watermarkApiService.getWatermarkSettings();
      if (!mounted) return;

      setState(() {
        _watermarkSettings = settings;
        _enableWatermark = settings.enabled;
        _watermarkType = settings.typeDisplayLabel;
        _watermarkPosition = settings.positionDisplayLabel;
        _watermarkTextController.text = settings.textContent ?? '';
        _fontSizeController.text = settings.textFontSize?.toString() ?? '32';
        _textColorController.text = settings.textColor ?? '#FFFFFF';
        _rotationController.text = settings.textRotation?.toString() ?? '0';
        _opacityController.text = settings.opacity.toString();
        _scaleController.text = settings.scale.toString();
        _marginController.text = settings.margin.toString();
        _guestDownloadOption = settings.downloadOptionDisplayLabel;
        _isLoadingWatermark = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _watermarkFetchError = errorMsg;
        _isLoadingWatermark = false;
      });
    }
  }

  Color _parseHexColor(String hexString) {
    try {
      String cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  Future<void> _saveWatermarkSettings() async {
    if (_isSavingWatermark) return;

    // Validate inputs per API specs
    final opacityVal = int.tryParse(_opacityController.text);
    if (opacityVal == null || opacityVal < 0 || opacityVal > 100) {
      AppToast.show(
        context,
        'Opacity must be an integer between 0 and 100.',
        type: ToastType.error,
      );
      return;
    }

    final scaleVal = int.tryParse(_scaleController.text);
    if (scaleVal == null || scaleVal < 1 || scaleVal > 100) {
      AppToast.show(
        context,
        'Scale must be an integer between 1 and 100.',
        type: ToastType.error,
      );
      return;
    }

    final marginVal = int.tryParse(_marginController.text);
    if (marginVal == null || marginVal < 0 || marginVal > 500) {
      AppToast.show(
        context,
        'Margin must be an integer between 0 and 500.',
        type: ToastType.error,
      );
      return;
    }

    int? fontSizeVal;
    if (_fontSizeController.text.trim().isNotEmpty) {
      fontSizeVal = int.tryParse(_fontSizeController.text);
      if (fontSizeVal == null || fontSizeVal < 8 || fontSizeVal > 200) {
        AppToast.show(
          context,
          'Font size must be between 8 and 200.',
          type: ToastType.error,
        );
        return;
      }
    }

    int? rotationVal;
    if (_rotationController.text.trim().isNotEmpty) {
      rotationVal = int.tryParse(_rotationController.text);
      if (rotationVal == null || rotationVal < -180 || rotationVal > 180) {
        AppToast.show(
          context,
          'Rotation must be between -180° and 180°.',
          type: ToastType.error,
        );
        return;
      }
    }

    if (_watermarkTextController.text.length > 255) {
      AppToast.show(
        context,
        'Watermark text cannot exceed 255 characters.',
        type: ToastType.error,
      );
      return;
    }

    String hexColor = _textColorController.text.trim();
    if (hexColor.isNotEmpty &&
        !RegExp(r'^#([A-Fa-f0-9]{6})$').hasMatch(hexColor)) {
      if (!hexColor.startsWith('#')) {
        hexColor = '#$hexColor';
      }
      if (!RegExp(r'^#([A-Fa-f0-9]{6})$').hasMatch(hexColor)) {
        AppToast.show(
          context,
          'Text color must be in #RRGGBB format (e.g. #FFFFFF).',
          type: ToastType.error,
        );
        return;
      }
    }

    final updatedModel = WatermarkSettingsModel(
      enabled: _enableWatermark,
      type: WatermarkSettingsModel.displayToType(_watermarkType),
      position: WatermarkSettingsModel.displayToPosition(_watermarkPosition),
      opacity: opacityVal,
      scale: scaleVal,
      margin: marginVal,
      textContent: _watermarkTextController.text,
      textFontSize: fontSizeVal,
      textColor: hexColor.isEmpty ? null : hexColor,
      textRotation: rotationVal,
      downloadOption: WatermarkSettingsModel.displayToDownloadOption(
        _guestDownloadOption,
      ),
      logoPath: _watermarkSettings?.logoPath,
      hasLogo: _watermarkSettings?.hasLogo ?? false,
    );

    setState(() => _isSavingWatermark = true);

    try {
      final savedSettings = await _watermarkApiService.updateWatermarkSettings(
        updatedModel,
      );
      if (!mounted) return;

      setState(() {
        _watermarkSettings = savedSettings;
        _isSavingWatermark = false;
      });

      AppToast.show(
        context,
        'Watermark settings saved successfully!',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingWatermark = false);
      final msg = e.toString().replaceAll('Exception: ', '');
      AppToast.show(
        context,
        'Failed to save settings: $msg',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          MainNavigationShell.switchTab(context, 0);
        }
      },
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          backgroundColor: _bgDark,
          elevation: 0,
          leading: Center(
            child: Container(
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: _cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: palette.isDark ? 0.2 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: _textPrimary, size: 18),
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
          'Preferences',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // 1. Connection & User Account Section
              UserAccountCard(initialUser: widget.currentUser),
              const SizedBox(height: 20),

              // 2. Watermark Section
              _buildWatermarkSection(),
              const SizedBox(height: 20),

              // 3. Appearance Section
              _buildAppearanceSection(),
              const SizedBox(height: 20),

              // 4. On-device AI Section
              _buildAiSection(),
              const SizedBox(height: 20),

              // 5. Sync Configuration Section
              _buildSyncConfigSection(),
              const SizedBox(height: 20),

              // 6. About Section
              _buildAboutSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // Header Widget
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: AppTextStyles.overlineOf(context),
        ),
        const SizedBox(height: 6),
        Text(
          'Preferences',
          style: AppTextStyles.displayHeadingOf(context),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage connection, appearance, and sync configuration.',
          style: AppTextStyles.subTitleOf(context),
        ),
      ],
    );
  }

  // 2. Watermark Section
  Widget _buildWatermarkSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                      color: _accentAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accentAmber.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      Icons.branding_watermark_rounded,
                      color: _accentAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Watermark',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (_isLoadingWatermark)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accentAmber,
                  ),
                )
              else if (_watermarkFetchError != null)
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.accentAmber,
                    size: 20,
                  ),
                  tooltip: 'Retry loading watermark settings',
                  onPressed: _loadWatermarkSettings,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Applied to uploaded photos on the server. Changes here update the same settings as the web dashboard.',
            style: TextStyle(color: _textMuted, fontSize: 13, height: 1.45),
          ),
          if (_watermarkFetchError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.dangerRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.dangerRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _watermarkFetchError!,
                      style: const TextStyle(
                        color: AppColors.dangerRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          // Toggle Row Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _enableWatermark
                          ? Icons.check_circle_rounded
                          : Icons.do_not_disturb_on_rounded,
                      color: _enableWatermark ? AppColors.successGreen : _textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Enable watermarking',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _enableWatermark,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.accentAmber,
                  onChanged: (val) => setState(() => _enableWatermark = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Form fields (Type & Position)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type',
                      style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _watermarkType,
                      items: const ['Text', 'Logo'],
                      onChanged: (val) => setState(() => _watermarkType = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Position',
                      style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _watermarkPosition,
                      items: WatermarkSettingsModel.displayToPositionMap.keys
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _watermarkPosition = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Watermark Text input
          Text(
            'Watermark text',
            style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildTextField(_watermarkTextController, hintText: 'Enter custom watermark text'),
          const SizedBox(height: 14),

          // Font size & Text color
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Font size (8-200)',
                      style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _fontSizeController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text color (#RRGGBB)',
                      style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _textColorController,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _parseHexColor(_textColorController.text),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rotation
          Text(
            'Rotation (-180° to 180°)',
            style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildTextField(
            _rotationController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          // Opacity, Scale, Margin
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opacity (0-100%)',
                      style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _opacityController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scale (1-100%)',
                      style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _scaleController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Margin (0-500px)',
                      style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      _marginController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Guest Download
          Text(
            'Guest download',
            style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildDropdown(
            value: _guestDownloadOption,
            items: WatermarkSettingsModel.displayToDownloadOptionMap.keys
                .toList(),
            onChanged: (val) => setState(() => _guestDownloadOption = val!),
          ),
          const SizedBox(height: 4),
          Text(
            'Which file guests receive when downloading.',
            style: TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Save Watermark Settings Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingWatermark ? null : _saveWatermarkSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentAmber,
                disabledBackgroundColor: _accentAmber.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSavingWatermark
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Save Watermark Settings',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Appearance Section
  Widget _buildAppearanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentAmber.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: _accentAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Appearance',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Theme',
            style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildThemeOptionCard('System', Icons.brightness_auto_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildThemeOptionCard('Dark', Icons.dark_mode_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildThemeOptionCard('Light', Icons.light_mode_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionCard(String modeLabel, IconData icon) {
    final isSelected = _themeOption == modeLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          setState(() => _themeOption = modeLabel);
          await ThemeService.instance.saveThemeOption(modeLabel);
          if (mounted) {
            AppToast.show(
              context,
              'Appearance set to $modeLabel mode',
              type: ToastType.success,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _accentAmber.withValues(alpha: 0.15)
                : _inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _accentAmber : _border.withValues(alpha: 0.6),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? _accentAmber : _textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                modeLabel,
                style: TextStyle(
                  color: isSelected ? _textPrimary : _textMuted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. On-device AI Section
  Widget _buildAiSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentAmber.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: _accentAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'On-device AI',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(color: AppColors.accentAmber, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border.withValues(alpha: 0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Switch(
                  value: _computeAiEmbeddings,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.accentAmber,
                  onChanged: (val) => setState(() => _computeAiEmbeddings = val),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compute face embeddings on this computer during upload',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Speeds up selfie search by indexing faces locally while photos upload, so results are ready almost instantly. The face model (~190 MB) downloads once. Uploads work normally whether this is on or off.',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Sync Configuration Section
  Widget _buildSyncConfigSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentAmber.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.sync_rounded,
                  color: _accentAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Sync Configuration',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Event', style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                'Maulik',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Watch folder',
                style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                'Manual upload only',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit on Sync page',
                  style: TextStyle(
                    color: _accentAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: _accentAmber, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. About Section
  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentAmber.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: _accentAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'About',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'PhotoHouse Desktop Sync Agent · v0.1.5',
                  style: TextStyle(color: _textMuted, fontSize: 13),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  AppToast.show(
                    context,
                    'Agent is up to date (v0.1.5)',
                    type: ToastType.info,
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Check for updates',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Open web dashboard',
                  style: TextStyle(
                    color: _accentAmber,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.open_in_new_rounded, color: _accentAmber, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Dropdown Select
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          dropdownColor: _cardBg,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
          style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
        ),
      ),
    );
  }

  // Helper Widget for Text Fields
  Widget _buildTextField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    Function(String)? onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
