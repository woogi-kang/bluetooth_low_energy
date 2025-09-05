import 'dart:io';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'log_view.dart';

class PeripheralManagerView extends StatefulWidget {
  const PeripheralManagerView({super.key});

  @override
  State<PeripheralManagerView> createState() => _PeripheralManagerViewState();
}

class _PeripheralManagerViewState extends State<PeripheralManagerView> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<PeripheralManagerViewModel>(context);
    final state = viewModel.state;
    final advertising = viewModel.advertising;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Row(
          children: [
            Icon(
              Symbols.sensors,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peripheral 관리자'),
                  if (advertising)
                    Text(
                      '활성 상태',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _buildAdvertisingButton(context, viewModel, state, advertising),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: buildBody(context),
      ),
      floatingActionButton: state == BluetoothLowEnergyState.poweredOn
          ? FloatingActionButton.extended(
              onPressed: () => viewModel.clearLogs(),
              icon: const Icon(Symbols.delete),
              label: const Text('로그 지우기'),
            )
          : null,
    );
  }

  Widget buildBody(BuildContext context) {
    final viewModel = ViewModel.of<PeripheralManagerViewModel>(context);
    final state = viewModel.state;
    final isMobile = Platform.isAndroid || Platform.isIOS;
    
    if (state == BluetoothLowEnergyState.unauthorized && isMobile) {
      return _buildPermissionView(context, viewModel);
    } else if (state == BluetoothLowEnergyState.poweredOn) {
      final advertising = viewModel.advertising;
      return Column(
        children: [
          _buildStatusHeader(context, viewModel, advertising),
          if (advertising) ...[
            _buildDeviceInfoCard(context, viewModel),
            if (viewModel.waitingForAuth || viewModel.hasAuthenticatedCentrals)
              _buildAuthenticationCard(context, viewModel),
            _buildControlsSection(context, viewModel),
          ] else
            _buildInactiveState(context),
          Expanded(
            child: _buildLogsSection(context, viewModel),
          ),
        ],
      );
    } else {
      return _buildStateView(context, state);
    }
  }

  Widget _buildAdvertisingButton(
    BuildContext context, 
    PeripheralManagerViewModel viewModel, 
    BluetoothLowEnergyState state, 
    bool advertising
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: state == BluetoothLowEnergyState.poweredOn
            ? () async {
                if (advertising) {
                  await viewModel.stopAdvertising();
                } else {
                  await viewModel.startAdvertising();
                }
              }
            : null,
        icon: advertising
            ? const Icon(Symbols.stop)
            : const Icon(Symbols.broadcast_on_personal),
        label: Text(advertising ? '중지' : '광고 시작'),
        style: ElevatedButton.styleFrom(
          backgroundColor: advertising ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context, 
    PeripheralManagerViewModel viewModel, 
    bool advertising
  ) {
    final connectedCount = viewModel.connectedCentralsCount;
    final notifyCount = viewModel.notifyEnabledCount;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: advertising ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  advertising ? Symbols.broadcast_on_personal : Symbols.sensors,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  advertising ? '광고 중' : '대기 중',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: connectedCount > 0 ? Colors.blue : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '연결: $connectedCount',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: notifyCount > 0 ? Colors.purple : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Notify: $notifyCount',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, PeripheralManagerViewModel viewModel) {
    final deviceInfo = viewModel.deviceInfo;
    if (deviceInfo == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Symbols.info,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기기 정보',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceInfo,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticationCard(BuildContext context, PeripheralManagerViewModel viewModel) {
    final currentAuthCode = viewModel.currentAuthCode;
    final waitingForAuth = viewModel.waitingForAuth;
    final hasAuthenticatedCentrals = viewModel.hasAuthenticatedCentrals;
    
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String title;
    String description;
    
    if (waitingForAuth && currentAuthCode != null) {
      backgroundColor = Colors.orange.shade50;
      iconColor = Colors.orange;
      icon = Symbols.lock;
      title = '인증 대기 중';
      description = 'Central 기기에서 다음 코드를 입력해주세요';
    } else if (hasAuthenticatedCentrals) {
      backgroundColor = Colors.green.shade50;
      iconColor = Colors.green;
      icon = Symbols.verified;
      title = '인증 완료';
      description = 'Central 기기가 성공적으로 인증되었습니다';
    } else {
      backgroundColor = Colors.red.shade50;
      iconColor = Colors.red;
      icon = Symbols.error;
      title = '인증 실패';
      description = '인증에 실패했습니다. 다시 시도해주세요';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (waitingForAuth && currentAuthCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '인증 코드',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentAuthCode,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 8,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2분 내에 입력해주세요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context, PeripheralManagerViewModel viewModel) {
    final connectedCount = viewModel.connectedCentralsCount;
    final isRecording = viewModel.isRecording;
    
    if (connectedCount == 0) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '메시지 전송',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Central에게 보낼 메시지 입력',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        await viewModel.sendDataToCentrals(text);
                        _textController.clear();
                      }
                    },
                    icon: const Icon(Symbols.send),
                    label: const Text('전송'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isRecording || viewModel.notifyEnabledCount > 0)
                      ? (isRecording 
                          ? () async => await viewModel.stopVoiceRecording()
                          : () async => await viewModel.startVoiceRecording())
                      : null,
                  icon: Icon(isRecording ? Symbols.stop : Symbols.mic),
                  label: Text(
                    isRecording 
                        ? '녹음 중지 및 전송' 
                        : (viewModel.notifyEnabledCount > 0 
                            ? '음성 녹음 시작' 
                            : 'Central에서 Notify 활성화 필요'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.red : 
                                   (viewModel.notifyEnabledCount > 0 ? Colors.blue : Colors.grey),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.sensors,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Peripheral 서비스가 비활성 상태입니다',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '광고 시작 버튼을 눌러 다른 기기가\n이 기기를 검색할 수 있도록 하세요',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection(BuildContext context, PeripheralManagerViewModel viewModel) {
    final logs = viewModel.logs;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Symbols.list_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '활동 로그',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${logs.length}개',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.inbox,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '활동 로그가 없습니다',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        return LogView(log: log);
                      },
                      separatorBuilder: (context, i) => const Divider(height: 1),
                      itemCount: logs.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionView(BuildContext context, PeripheralManagerViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.bluetooth_disabled,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '블루투스 권한이 필요합니다',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '설정에서 블루투스 권한을 허용해주세요',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => viewModel.showAppSettings(),
            icon: Icon(Symbols.settings),
            label: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  Widget _buildStateView(BuildContext context, BluetoothLowEnergyState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getStateIcon(state),
            size: 64,
            color: _getStateColor(state),
          ),
          const SizedBox(height: 16),
          Text(
            _getStateMessage(state),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getStateIcon(BluetoothLowEnergyState state) {
    switch (state) {
      case BluetoothLowEnergyState.poweredOff:
        return Symbols.bluetooth_disabled;
      case BluetoothLowEnergyState.unauthorized:
        return Symbols.block;
      case BluetoothLowEnergyState.unsupported:
        return Symbols.error;
      default:
        return Symbols.bluetooth;
    }
  }

  Color _getStateColor(BluetoothLowEnergyState state) {
    switch (state) {
      case BluetoothLowEnergyState.poweredOff:
        return Colors.orange;
      case BluetoothLowEnergyState.unauthorized:
        return Colors.red;
      case BluetoothLowEnergyState.unsupported:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStateMessage(BluetoothLowEnergyState state) {
    switch (state) {
      case BluetoothLowEnergyState.poweredOff:
        return '블루투스가 꺼져있습니다\n설정에서 블루투스를 켜주세요';
      case BluetoothLowEnergyState.unauthorized:
        return '블루투스 권한이 필요합니다\n설정에서 권한을 허용해주세요';
      case BluetoothLowEnergyState.unsupported:
        return '이 기기는 블루투스를 지원하지 않습니다';
      default:
        return '블루투스 상태: $state';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
