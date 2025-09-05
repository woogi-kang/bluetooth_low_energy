import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../view_models/central_scanner_view_model.dart';

class FilterDrawer extends StatefulWidget {
  final CentralScannerViewModel viewModel;

  const FilterDrawer({
    super.key,
    required this.viewModel,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  final List<String> _commonServiceUUIDs = [
    '0000180F-0000-1000-8000-00805F9B34FB', // Battery Service
    '0000180A-0000-1000-8000-00805F9B34FB', // Device Information
    '0000180D-0000-1000-8000-00805F9B34FB', // Heart Rate
    '0000181C-0000-1000-8000-00805F9B34FB', // User Data
    '0000FE59-0000-1000-8000-00805F9B34FB', // Nordic UART
  ];

  final Map<String, String> _serviceNames = {
    '0000180F-0000-1000-8000-00805F9B34FB': '배터리 서비스',
    '0000180A-0000-1000-8000-00805F9B34FB': '기기 정보',
    '0000180D-0000-1000-8000-00805F9B34FB': '심박수',
    '0000181C-0000-1000-8000-00805F9B34FB': '사용자 데이터',
    '0000FE59-0000-1000-8000-00805F9B34FB': 'Nordic UART',
  };

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRSSISection(),
                      const SizedBox(height: 24),
                      _buildServiceFilterSection(),
                      const SizedBox(height: 24),
                      _buildDeviceTypeSection(),
                      const SizedBox(height: 24),
                      _buildScanSettingsSection(),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Symbols.tune,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '고급 필터',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Symbols.close),
        ),
      ],
    );
  }

  Widget _buildRSSISection() {
    final filterEnabled = widget.viewModel.filterByRSSI;
    final threshold = widget.viewModel.rssiThreshold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.signal_cellular_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'RSSI 신호 강도 필터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              const SizedBox(height: 16),
              Text(
                '최소 신호 강도: ${threshold}dBm',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Slider(
                value: threshold.toDouble(),
                min: -100,
                max: -30,
                divisions: 14,
                label: '${threshold}dBm',
                onChanged: (value) {
                  widget.viewModel.setRSSIFilter(true, value.round());
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRSSIPreset('약함', -95),
                  _buildRSSIPreset('보통', -80),
                  _buildRSSIPreset('강함', -65),
                  _buildRSSIPreset('매우강함', -50),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRSSIPreset(String label, int value) {
    final isSelected = widget.viewModel.rssiThreshold == value;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: () {
            widget.viewModel.setRSSIFilter(true, value);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected 
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            foregroundColor: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
            padding: const EdgeInsets.symmetric(vertical: 8),
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'BLE 서비스 필터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '특정 서비스를 가진 기기만 표시',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ..._commonServiceUUIDs.map((uuidString) {
              final serviceName = _serviceNames[uuidString] ?? uuidString;
              return CheckboxListTile(
                title: Text(serviceName),
                subtitle: Text(
                  uuidString.substring(0, 8).toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
                value: false, // TODO: 실제 필터 상태와 연결
                onChanged: (value) {
                  // TODO: 서비스 필터 구현
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTypeSection() {
    const deviceTypes = [
      {'name': '스마트폰', 'icon': Symbols.smartphone},
      {'name': '웨어러블', 'icon': Symbols.watch},
      {'name': '오디오 기기', 'icon': Symbols.headphones},
      {'name': '입력 장치', 'icon': Symbols.mouse},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.category,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '기기 유형 필터',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: deviceTypes.map((type) {
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(type['name'] as String),
                    ],
                  ),
                  selected: false, // TODO: 실제 필터 상태와 연결
                  onSelected: (selected) {
                    // TODO: 기기 유형 필터 구현
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.radar,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '스캔 설정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('이름 없는 기기 표시'),
              subtitle: const Text('이름이 설정되지 않은 기기도 표시'),
              value: true, // TODO: 실제 설정과 연결
              onChanged: (value) {
                // TODO: 이름 없는 기기 표시 설정 구현
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('중복 기기 제거'),
              subtitle: const Text('같은 기기의 중복 항목 제거'),
              value: true, // TODO: 실제 설정과 연결
              onChanged: (value) {
                // TODO: 중복 기기 제거 설정 구현
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // 모든 필터 초기화
                  widget.viewModel.setRSSIFilter(false);
                  widget.viewModel.setSearchQuery('');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 필터가 초기화되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Symbols.clear_all),
                label: const Text('초기화'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Symbols.done),
                label: const Text('적용'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}