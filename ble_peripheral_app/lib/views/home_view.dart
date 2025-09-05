import 'package:flutter/material.dart';
import 'package:clover/clover.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../view_models/peripheral_manager_view_model.dart';
import '../widgets/status_dashboard.dart';
import '../widgets/connection_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/log_viewer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<PeripheralManagerViewModel>(context);
    final state = viewModel.state;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('BLE 주변기기 관리자'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Icon(
                        Symbols.sensors,
                        size: 120,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 16,
                      right: 16,
                      child: StatusDashboard(viewModel: viewModel),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showSettingsDialog(context, viewModel),
                icon: const Icon(Symbols.settings),
                tooltip: '설정',
              ),
              IconButton(
                onPressed: () => _showInfoDialog(context),
                icon: const Icon(Symbols.info),
                tooltip: '정보',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  tabs: [
                    Tab(
                      icon: const Icon(Symbols.dashboard),
                      text: '대시보드',
                    ),
                    Tab(
                      icon: const Icon(Symbols.settings_remote),
                      text: '제어',
                    ),
                    Tab(
                      icon: const Icon(Symbols.list_alt),
                      text: '로그',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(context, viewModel, state),
                _buildControlTab(context, viewModel, state),
                _buildLogTab(context, viewModel),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, viewModel, state),
    );
  }

  Widget _buildDashboardTab(BuildContext context, PeripheralManagerViewModel viewModel, BluetoothLowEnergyState state) {
    if (state != BluetoothLowEnergyState.poweredOn) {
      return _buildStateView(context, state, viewModel);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ConnectionPanel(viewModel: viewModel),
          const SizedBox(height: 16),
          _buildStatisticsCards(context, viewModel),
          const SizedBox(height: 16),
          _buildDeviceInfoCard(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildControlTab(BuildContext context, PeripheralManagerViewModel viewModel, BluetoothLowEnergyState state) {
    if (state != BluetoothLowEnergyState.poweredOn) {
      return _buildStateView(context, state, viewModel);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ControlPanel(viewModel: viewModel),
        ],
      ),
    );
  }

  Widget _buildLogTab(BuildContext context, PeripheralManagerViewModel viewModel) {
    return LogViewer(viewModel: viewModel);
  }

  Widget _buildStateView(BuildContext context, BluetoothLowEnergyState state, PeripheralManagerViewModel viewModel) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    Widget? action;

    switch (state) {
      case BluetoothLowEnergyState.poweredOff:
        icon = Symbols.bluetooth_disabled;
        color = Colors.orange;
        title = '블루투스가 꺼져있습니다';
        subtitle = '설정에서 블루투스를 켜주세요';
        break;
      case BluetoothLowEnergyState.unauthorized:
        icon = Symbols.block;
        color = Colors.red;
        title = '블루투스 권한이 필요합니다';
        subtitle = '설정에서 권한을 허용해주세요';
        action = ElevatedButton.icon(
          onPressed: () => viewModel.showAppSettings(),
          icon: const Icon(Symbols.settings),
          label: const Text('설정으로 이동'),
        );
        break;
      case BluetoothLowEnergyState.unsupported:
        icon = Symbols.error;
        color = Colors.grey;
        title = '블루투스를 지원하지 않습니다';
        subtitle = '이 기기에서는 BLE를 사용할 수 없습니다';
        break;
      default:
        icon = Symbols.bluetooth;
        color = Colors.blue;
        title = '블루투스 준비 중';
        subtitle = '잠시만 기다려주세요';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, PeripheralManagerViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '통계',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '총 연결',
                viewModel.totalConnections.toString(),
                Symbols.devices,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '송신',
                viewModel.dataPacketsSent.toString(),
                Symbols.upload,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '수신',
                viewModel.dataPacketsReceived.toString(),
                Symbols.download,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, PeripheralManagerViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '기기 정보',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('기기 이름', viewModel.deviceName),
            _buildInfoRow('플랫폼', viewModel.deviceInfo ?? '알 수 없음'),
            _buildInfoRow('연결 품질', viewModel.connectionQuality),
            _buildInfoRow('마지막 활동', _formatLastActivity(viewModel.lastActivity)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, PeripheralManagerViewModel viewModel, BluetoothLowEnergyState state) {
    if (state != BluetoothLowEnergyState.poweredOn) {
      return null;
    }

    final advertising = viewModel.advertising;
    
    return FloatingActionButton.extended(
      onPressed: () async {
        if (advertising) {
          await viewModel.stopAdvertising();
        } else {
          await viewModel.startAdvertising();
        }
      },
      icon: advertising 
          ? const Icon(Symbols.stop) 
          : const Icon(Symbols.broadcast_on_personal),
      label: Text(advertising ? '광고 중지' : '광고 시작'),
      backgroundColor: advertising ? Colors.red : Colors.green,
      foregroundColor: Colors.white,
    );
  }

  void _showSettingsDialog(BuildContext context, PeripheralManagerViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('기기 이름 변경'),
              subtitle: Text('현재: ${viewModel.deviceName}'),
              trailing: const Icon(Symbols.edit),
              onTap: () => _showDeviceNameDialog(context, viewModel),
            ),
            SwitchListTile(
              title: const Text('자동 재연결'),
              subtitle: const Text('연결이 끊어지면 자동으로 재연결'),
              value: viewModel.autoReconnect,
              onChanged: (value) => viewModel.setAutoReconnect(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeviceNameDialog(BuildContext context, PeripheralManagerViewModel viewModel) {
    final controller = TextEditingController(text: viewModel.deviceName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '새 기기 이름',
            hintText: 'BLE-Peripheral-1234',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                viewModel.setDeviceName(newName);
              }
              Navigator.of(context).pop();
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLE 주변기기 관리자 v1.0.0'),
            SizedBox(height: 8),
            Text('Bluetooth Low Energy 주변기기 서비스를 제공하는 전문 도구입니다.'),
            SizedBox(height: 16),
            Text('주요 기능:'),
            Text('• BLE 광고 서비스'),
            Text('• 실시간 연결 관리'),
            Text('• 인증 시스템'),
            Text('• 데이터 송수신'),
            Text('• 음성 메시지 전송'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}