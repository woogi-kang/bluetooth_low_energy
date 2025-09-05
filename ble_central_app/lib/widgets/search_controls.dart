import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../view_models/central_scanner_view_model.dart';

class SearchControls extends StatefulWidget {
  final CentralScannerViewModel viewModel;

  const SearchControls({
    super.key,
    required this.viewModel,
  });

  @override
  State<SearchControls> createState() => _SearchControlsState();
}

class _SearchControlsState extends State<SearchControls> {
  late final TextEditingController _searchController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      widget.viewModel.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '기기 이름으로 검색...',
                      prefixIcon: const Icon(Symbols.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.viewModel.setSearchQuery('');
                              },
                              icon: const Icon(Symbols.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: _isExpanded
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        _isExpanded ? Symbols.expand_less : Symbols.expand_more,
                        color: _isExpanded
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      widget.viewModel.clearDiscoveries();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('검색 결과가 지워졌습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Symbols.refresh,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isExpanded ? null : 0,
            child: _isExpanded ? _buildExpandedControls() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildRSSIFilter(),
          const SizedBox(height: 16),
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildRSSIFilter() {
    final filterEnabled = widget.viewModel.filterByRSSI;
    final threshold = widget.viewModel.rssiThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.signal_cellular_alt,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'RSSI 필터',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: filterEnabled,
              onChanged: (value) {
                widget.viewModel.setRSSIFilter(value, threshold);
              },
            ),
          ],
        ),
        if (filterEnabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '최소 신호 강도: ${threshold}dBm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                _getSignalStrengthLabel(threshold),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getSignalColor(threshold),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Slider(
            value: threshold.toDouble(),
            min: -100,
            max: -30,
            divisions: 14,
            onChanged: (value) {
              widget.viewModel.setRSSIFilter(true, value.round());
            },
          ),
        ],
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.filter_alt,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              '빠른 필터',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('강한 신호만', () {
              widget.viewModel.setRSSIFilter(true, -65);
            }),
            _buildFilterChip('즐겨찾기만', () {
              // 이 기능은 탭 전환으로 대체됨
            }),
            _buildFilterChip('서비스 있는 것만', () {
              // 서비스 UUID가 있는 기기만 필터링하는 로직 추가 필요
            }),
            _buildFilterChip('모든 필터 해제', () {
              widget.viewModel.setRSSIFilter(false);
              widget.viewModel.setSearchQuery('');
              _searchController.clear();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  String _getSignalStrengthLabel(int rssi) {
    if (rssi >= -50) return '매우 강함';
    if (rssi >= -65) return '강함';
    if (rssi >= -80) return '보통';
    if (rssi >= -95) return '약함';
    return '매우 약함';
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -65) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    if (rssi >= -95) return Colors.red;
    return Colors.red.shade700;
  }
}