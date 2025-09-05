import 'package:flutter/material.dart';
import 'package:clover/clover.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../view_models/peripheral_manager_view_model.dart';
import '../widgets/status_dashboard.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<PeripheralManagerViewModel>(context);
    final state = viewModel.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('INMO GO 2'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () => _showSettingsDialog(context, viewModel),
            icon: const Icon(Symbols.settings),
            tooltip: '설정',
          ),
        ],
      ),
      body: _buildCompactContent(context, viewModel, state),
      floatingActionButton: _buildFloatingActionButton(context, viewModel, state),
    );
  }

  Widget _buildCompactContent(BuildContext context, PeripheralManagerViewModel viewModel, BluetoothLowEnergyState state) {
    if (state != BluetoothLowEnergyState.poweredOn) {
      return _buildStateView(context, state, viewModel);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PIN 인증 상태 - 가장 중요한 정보를 맨 위에
          StatusDashboard(viewModel: viewModel),
          const SizedBox(height: 12),
          
          // 연결 상태 요약
          _buildConnectionSummary(context, viewModel),
          const SizedBox(height: 12),
          
          // 기본 통계
          _buildCompactStats(context, viewModel),
          const SizedBox(height: 12),
          
          // 제어 버튼들
          _buildQuickControls(context, viewModel),
          
          const SizedBox(height: 80), // FloatingActionButton을 위한 여백
        ],
      ),
    );
  }

  Widget _buildConnectionSummary(BuildContext context, PeripheralManagerViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Symbols.devices, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '연결: ${viewModel.connectedCentralsCount}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            Icon(Symbols.notifications, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 4),
            Text('${viewModel.notifyEnabledCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStats(BuildContext context, PeripheralManagerViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(Symbols.upload, size: 16, color: Colors.green),
                  Text('${viewModel.dataPacketsSent}',
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('송신', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(Symbols.download, size: 16, color: Colors.orange),
                  Text('${viewModel.dataPacketsReceived}',
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('수신', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickControls(BuildContext context, PeripheralManagerViewModel viewModel) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => viewModel.sendDataMessage('안녕하세요!'),
                icon: const Icon(Symbols.send, size: 16),
                label: const Text('인사 전송', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => viewModel.disconnectAll(),
                icon: const Icon(Symbols.link_off, size: 16),
                label: const Text('연결 해제', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
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

}