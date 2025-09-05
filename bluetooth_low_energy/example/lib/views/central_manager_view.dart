import 'dart:io';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:bluetooth_low_energy_example/widgets.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'advertisement_view.dart';

class CentralManagerView extends StatelessWidget {
  const CentralManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<CentralManagerViewModel>(context);
    final state = viewModel.state;
    final discovering = viewModel.discovering;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Row(
          children: [
            Icon(
              Symbols.bluetooth_searching,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            const Text('블루투스 스캐너'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: _buildScanButton(context, state, discovering),
          ),
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
    );
  }

  Widget buildBody(BuildContext context) {
    final viewModel = ViewModel.of<CentralManagerViewModel>(context);
    final state = viewModel.state;
    final discovering = viewModel.discovering;
    final isMobile = Platform.isAndroid || Platform.isIOS;
    
    if (state == BluetoothLowEnergyState.unauthorized && isMobile) {
      return _buildPermissionView(context, viewModel);
    } else if (state == BluetoothLowEnergyState.poweredOn) {
      final discoveries = viewModel.discoveries;
      return Column(
        children: [
          _buildStatusHeader(context, discovering, discoveries.length),
          Expanded(
            child: discoveries.isEmpty
                ? _buildEmptyState(context, discovering)
                : _buildDeviceList(context, discoveries),
          ),
        ],
      );
    } else {
      return _buildStateView(context, state);
    }
  }

  Widget _buildScanButton(BuildContext context, BluetoothLowEnergyState state, bool discovering) {
    return ElevatedButton.icon(
      onPressed: state == BluetoothLowEnergyState.poweredOn
          ? () async {
              final viewModel = ViewModel.of<CentralManagerViewModel>(context);
              if (discovering) {
                await viewModel.stopDiscovery();
              } else {
                await viewModel.startDiscovery();
              }
            }
          : null,
      icon: discovering 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Icon(discovering ? Symbols.stop : Symbols.search),
      label: Text(discovering ? '중지' : '스캔'),
      style: ElevatedButton.styleFrom(
        backgroundColor: discovering ? Colors.red : Theme.of(context).colorScheme.primary,
        foregroundColor: discovering ? Colors.white : Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, bool discovering, int deviceCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: discovering ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  discovering ? Symbols.radar : Symbols.bluetooth_disabled,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  discovering ? '스캔 중' : '대기 중',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: deviceCount > 0 ? Colors.blue : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '기기: $deviceCount개',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView(BuildContext context, CentralManagerViewModel viewModel) {
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

  Widget _buildEmptyState(BuildContext context, bool discovering) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (discovering) ...[
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              '블루투스 기기를 검색하는 중...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '주변 기기가 검색되면 여기에 표시됩니다',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Icon(
              Symbols.bluetooth_searching,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '블루투스 기기를 검색해보세요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '스캔 버튼을 눌러 주변 기기를 찾을 수 있습니다',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, List<DiscoveredEventArgs> discoveries) {
    return RefreshIndicator(
      onRefresh: () async {
        final viewModel = ViewModel.of<CentralManagerViewModel>(context);
        await viewModel.startDiscovery();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final discovery = discoveries[index];
          return _buildDeviceCard(context, discovery);
        },
        separatorBuilder: (context, i) => const SizedBox(height: 8),
        itemCount: discoveries.length,
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, DiscoveredEventArgs discovery) {
    final uuid = discovery.peripheral.uuid;
    final name = discovery.advertisement.name ?? '알 수 없는 기기';
    final rssi = discovery.rssi;
    final serviceUuids = discovery.advertisement.serviceUUIDs;
    
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTapDiscovery(context, discovery),
        onLongPress: () => onLongPressDiscovery(context, discovery),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDeviceIcon(name, serviceUuids),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getDeviceType(name, serviceUuids),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      RSSIIndicator(rssi),
                      const SizedBox(height: 4),
                      Text(
                        '$rssi dBm',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                uuid.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.grey.shade600,
                ),
              ),
              if (serviceUuids.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: serviceUuids.take(3).map((serviceUuid) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      serviceUuid.toString().substring(0, 8),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
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

  IconData _getDeviceIcon(String name, List<UUID> serviceUuids) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('phone') || nameLower.contains('iphone') || nameLower.contains('android')) {
      return Symbols.smartphone;
    } else if (nameLower.contains('watch') || nameLower.contains('band')) {
      return Symbols.watch;
    } else if (nameLower.contains('earbuds') || nameLower.contains('headphone') || nameLower.contains('airpods')) {
      return Symbols.headphones;
    } else if (nameLower.contains('mouse') || nameLower.contains('keyboard')) {
      return Symbols.mouse;
    } else if (nameLower.contains('tv') || nameLower.contains('display')) {
      return Symbols.tv;
    } else {
      return Symbols.bluetooth;
    }
  }

  String _getDeviceType(String name, List<UUID> serviceUuids) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('phone') || nameLower.contains('iphone') || nameLower.contains('android')) {
      return '스마트폰';
    } else if (nameLower.contains('watch') || nameLower.contains('band')) {
      return '웨어러블 기기';
    } else if (nameLower.contains('earbuds') || nameLower.contains('headphone') || nameLower.contains('airpods')) {
      return '오디오 기기';
    } else if (nameLower.contains('mouse') || nameLower.contains('keyboard')) {
      return '입력 장치';
    } else if (nameLower.contains('tv') || nameLower.contains('display')) {
      return '디스플레이 장치';
    } else if (serviceUuids.isNotEmpty) {
      return 'BLE 기기 (${serviceUuids.length}개 서비스)';
    } else {
      return '블루투스 기기';
    }
  }

  void onTapDiscovery(
    BuildContext context,
    DiscoveredEventArgs discovery,
  ) async {
    final viewModel = ViewModel.of<CentralManagerViewModel>(context);
    bool dialogShown = false;
    
    try {
      // 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '연결 중...',
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                Text(
                  discovery.advertisement.name ?? '알 수 없는 기기',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
      dialogShown = true;

      if (viewModel.discovering) {
        await viewModel.stopDiscovery();
        if (!context.mounted) return;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;
      
      // 다이얼로그 안전하게 닫기
      if (dialogShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        dialogShown = false;
      }
      
      final uuid = discovery.peripheral.uuid;
      context.go('/central/$uuid');
    } catch (e) {
      if (!context.mounted) return;
      
      // 다이얼로그 안전하게 닫기
      if (dialogShown && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        dialogShown = false;
      }
      
      // 에러 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('연결 실패'),
          content: Text('기기 연결에 실패했습니다.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  void onLongPressDiscovery(
    BuildContext context,
    DiscoveredEventArgs discovery,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '기기 상세 정보',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Expanded(
                  child: AdvertisementView(advertisement: discovery.advertisement),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
