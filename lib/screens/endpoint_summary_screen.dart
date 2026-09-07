import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/endpoint_summary_model.dart';
import '../services/endpoint_summary_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';

class EndpointSummaryScreen extends StatefulWidget {
  final EndpointSummaryApiService? apiService;

  const EndpointSummaryScreen({
    super.key,
    this.apiService,
  });

  @override
  State<EndpointSummaryScreen> createState() => _EndpointSummaryScreenState();
}

class _EndpointSummaryScreenState extends State<EndpointSummaryScreen> with SingleTickerProviderStateMixin {
  AppThemePalette get palette => AppThemePalette.of(context);

  Color get _bgDark => palette.bgDarker;
  Color get _cardBg => palette.cardBg;
  Color get _cardBgElevated => palette.cardBgElevated;
  Color get _border => palette.border;
  Color get _accentOrange => palette.accentPrimary;
  Color get _emerald => palette.success;
  Color get _textMuted => palette.textMuted;

  late final EndpointSummaryApiService _apiService;
  late final TabController _tabController;

  List<EndpointSummaryItem> _endpoints = [];
  List<IntegrationChecklistItem> _checklistItems = [];
  
  EndpointCategory? _selectedCategory;
  bool _isRunningFullTest = false;
  int? _testingEndpointId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? EndpointSummaryApiService();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCatalog() {
    setState(() {
      _endpoints = _apiService.getEndpointCatalog();
      _checklistItems = _apiService.getIntegrationChecklist();
    });
  }

  Future<void> _runFullSmokeTest() async {
    setState(() {
      _isRunningFullTest = true;
    });

    AppToast.show(
      context,
      'Executing live diagnostic smoke test on all 23 endpoints...',
      type: ToastType.info,
    );

    try {
      final updated = await _apiService.runFullSmokeTest();
      if (!mounted) return;

      setState(() {
        _endpoints = updated;
        _isRunningFullTest = false;
      });

      final healthyCount = updated.where((e) => e.status == EndpointHealthStatus.healthy).length;
      AppToast.show(
        context,
        'Smoke test complete: $healthyCount/23 endpoints verified healthy!',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunningFullTest = false;
      });
      AppToast.show(
        context,
        'Smoke test error: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  Future<void> _testSingleEndpoint(EndpointSummaryItem item) async {
    setState(() {
      _testingEndpointId = item.id;
    });

    try {
      final result = await _apiService.testEndpoint(item);
      if (!mounted) return;

      setState(() {
        final index = _endpoints.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          _endpoints[index] = result;
        }
        _testingEndpointId = null;
      });

      AppToast.show(
        context,
        '${item.method} ${item.path} -> ${result.lastTestMessage}',
        type: result.status == EndpointHealthStatus.healthy ? ToastType.success : ToastType.warning,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testingEndpointId = null;
      });
      AppToast.show(
        context,
        'Failed to test endpoint: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  void _showCurlModal(EndpointSummaryItem item) {
    final curlCode = _apiService.generateCurlSnippet(item);

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.methodColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.method,
                          style: TextStyle(
                            color: item.methodColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${item.id} cURL Snippet',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    curlCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF34D399),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentOrange,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text(
                    'Copy cURL Snippet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: curlCode));
                    Navigator.pop(context);
                    AppToast.show(
                      context,
                      'cURL command copied to clipboard!',
                      type: ToastType.success,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<EndpointSummaryItem> get _filteredEndpoints {
    return _endpoints.where((e) {
      final matchesCategory = _selectedCategory == null || e.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          e.path.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.purpose.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.method.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final healthyCount = _endpoints.where((e) => e.status == EndpointHealthStatus.healthy).length;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        title: Text(
          'Endpoint Summary APIs',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Run Smoke Test',
            icon: _isRunningFullTest
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accentOrange,
                    ),
                  )
                : Icon(Icons.play_arrow_rounded, color: _accentOrange, size: 24),
            onPressed: _isRunningFullTest ? null : _runFullSmokeTest,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accentOrange,
          labelColor: palette.textPrimary,
          unselectedLabelColor: _textMuted,
          tabs: const [
            Tab(text: 'API Catalog (23)'),
            Tab(text: 'Integration Checklist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCatalogTab(healthyCount),
          _buildChecklistTab(),
        ],
      ),
    );
  }

  Widget _buildCatalogTab(int healthyCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat overview header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatWidget(
                    title: 'TOTAL APIS',
                    value: '${_endpoints.length}',
                    color: palette.textPrimary,
                    subtitle: '20 Auth • 3 Public',
                  ),
                ),
                Container(width: 1, height: 40, color: _border),
                Expanded(
                  child: _buildStatWidget(
                    title: 'HEALTHY',
                    value: '$healthyCount',
                    color: _emerald,
                    subtitle: healthyCount == 0 ? 'Run Smoke Test' : 'Verified OK',
                  ),
                ),
                Container(width: 1, height: 40, color: _border),
                Expanded(
                  child: _buildStatWidget(
                    title: 'SPEC VERSION',
                    value: 'v1',
                    color: _accentOrange,
                    subtitle: 'mobile-api.md',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search input field
          TextField(
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search endpoints or purpose...',
              hintStyle: TextStyle(color: _textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: _textMuted, size: 20),
              filled: true,
              fillColor: _cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accentOrange),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),

          // Category Chips Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All (23)'),
                  selected: _selectedCategory == null,
                  selectedColor: _accentOrange,
                  backgroundColor: _cardBg,
                  labelStyle: TextStyle(
                    color: _selectedCategory == null ? Colors.black : palette.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = null);
                  },
                ),
                const SizedBox(width: 8),
                ...EndpointCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final count = _endpoints.where((e) => e.category == cat).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.black : _textMuted),
                      label: Text('${cat.displayName} ($count)'),
                      selected: isSelected,
                      selectedColor: _accentOrange,
                      backgroundColor: _cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : palette.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Endpoint List
          if (_filteredEndpoints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text(
                  'No endpoints match your query.',
                  style: TextStyle(color: _textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredEndpoints.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _filteredEndpoints[index];
                return _buildEndpointCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _checklistItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final step = _checklistItems[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentOrange,
                ),
                child: Center(
                  child: Text(
                    '${step.step}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        step.endpointReference,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: _accentOrange,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: _emerald,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEndpointCard(EndpointSummaryItem item) {
    final isTesting = _testingEndpointId == item.id;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _cardBgElevated,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: Center(
            child: Text(
              '#${item.id}',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: item.methodColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.method,
                style: TextStyle(
                  color: item.methodColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.path,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(
                item.requiresAuth ? Icons.lock : Icons.public,
                size: 12,
                color: item.requiresAuth ? Colors.amber : Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                item.requiresAuth ? 'Auth' : 'Public',
                style: TextStyle(
                  color: item.requiresAuth ? Colors.amber : Colors.blue,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.purpose,
                  style: TextStyle(color: _textMuted, fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        children: [
          Divider(color: _border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detail rows
                _buildInfoRow('Purpose', item.purpose),
                const SizedBox(height: 6),
                _buildInfoRow('Category', item.category.displayName),
                const SizedBox(height: 6),
                _buildInfoRow('Authentication', item.requiresAuth ? 'Bearer Token (Required)' : 'Public (None)'),
                
                if (item.sampleParams != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow('Sample Params', item.sampleParams!),
                ],

                if (item.lastTestMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: item.status.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.network_check, size: 14, color: item.status.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.lastTestMessage!,
                            style: TextStyle(
                              color: item.status.color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.responseTimeMs != null)
                          Text(
                            '${item.responseTimeMs} ms',
                            style: TextStyle(
                              color: item.status.color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          side: BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(Icons.code, size: 16, color: _accentOrange),
                        label: const Text('cURL Code', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showCurlModal(item),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cardBgElevated,
                          foregroundColor: _accentOrange,
                          elevation: 0,
                          side: BorderSide(color: _accentOrange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: isTesting
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _accentOrange,
                                ),
                              )
                            : const Icon(Icons.play_arrow, size: 16),
                        label: Text(
                          isTesting ? 'Testing...' : 'Test Endpoint',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isTesting ? null : () => _testSingleEndpoint(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatWidget({
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: _textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: _textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: _textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
