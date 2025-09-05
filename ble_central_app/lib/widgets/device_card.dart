import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../view_models/central_scanner_view_model.dart';
import '../models/device_info.dart';
import '../views/device_detail_view.dart';
import 'signal_indicator.dart';

class DeviceCard extends StatelessWidget {
  final DiscoveredEventArgs discovery;
  final CentralScannerViewModel viewModel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DeviceCard({
    super.key,
    required this.discovery,
    required this.viewModel,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = DeviceInfo.fromDiscoveryArgs(discovery);
    final isFavorite = viewModel.isFavorite(deviceInfo.uuid.toString());
    
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildDeviceIcon(deviceInfo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                deviceInfo.displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isFavorite)
                              Icon(
                                Symbols.favorite,
                                size: 16,
                                color: Colors.red,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deviceInfo.deviceType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SignalIndicator(
                        rssi: deviceInfo.rssi,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${deviceInfo.rssi} dBm',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDeviceDetails(context, deviceInfo),
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(DeviceInfo deviceInfo) {
    IconData icon;
    Color backgroundColor;
    Color iconColor;

    switch (deviceInfo.deviceType) {
      case '스마트폰':
        icon = Symbols.smartphone;
        backgroundColor = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        break;
      case '웨어러블':
        icon = Symbols.watch;
        backgroundColor = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        break;
      case '오디오':
        icon = Symbols.headphones;
        backgroundColor = Colors.purple.shade100;
        iconColor = Colors.purple.shade700;
        break;
      case '입력장치':
        icon = Symbols.mouse;
        backgroundColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        break;
      case '디스플레이':
        icon = Symbols.tv;
        backgroundColor = Colors.indigo.shade100;
        iconColor = Colors.indigo.shade700;
        break;
      default:
        icon = Symbols.bluetooth;
        backgroundColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 24,
        color: iconColor,
      ),
    );
  }

  Widget _buildDeviceDetails(BuildContext context, DeviceInfo deviceInfo) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Symbols.fingerprint,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                deviceInfo.uuid.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (deviceInfo.serviceUUIDs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Symbols.settings,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '서비스 ${deviceInfo.serviceUUIDs.length}개',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: deviceInfo.serviceUUIDs.take(3).map((uuid) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        uuid.toString().substring(0, 8).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip(
              icon: Symbols.signal_cellular_alt,
              label: deviceInfo.signalStrength,
              color: _getSignalColor(deviceInfo.rssi),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              icon: Symbols.access_time,
              label: '방금 전',
              color: Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DeviceDetailView(
                    discovery: discovery,
                    viewModel: viewModel,
                  ),
                ),
              );
            },
            icon: const Icon(Symbols.info, size: 16),
            label: const Text('상세정보'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await _handleConnect(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('연결 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Symbols.link, size: 16),
            label: const Text('연결하기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _handleConnect(BuildContext context) async {
    // 연결 시작 시 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('기기에 연결하는 중...'),
          ],
        ),
      ),
    );
    
    try {
      await viewModel.connectToDevice(discovery);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 대화상자 닫기
        
        // 연결 성공 시 PIN 인증 대화상자 표시
        _showPinAuthDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 대화상자 닫기
      }
      rethrow;
    }
  }
  
  void _showPinAuthDialog(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PIN 인증'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${discovery.advertisement.name ?? "기기"}와 연결하기 위해\n4자리 PIN을 입력하세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: const InputDecoration(
                hintText: '••••',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 연결 해제
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text;
              if (pin.length == 4) {
                Navigator.of(context).pop();
                _handlePinAuthentication(context, pin);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('4자리 PIN을 입력해주세요'),
                  ),
                );
              }
            },
            child: const Text('인증'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handlePinAuthentication(BuildContext context, String pin) async {
    try {
      // GATT 서비스 탐지  
      // CentralManager에 직접 접근하는 대신 viewModel을 통해 접근
      final services = await viewModel.discoverServices(discovery.peripheral);
      
      // 기본 서비스 UUID를 사용해서 쓰기 가능한 특성 찾기
      GATTCharacteristic? writeCharacteristic;
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          // 쓰기 가능한 특성 찾기
          if (characteristic.properties.contains(GATTCharacteristicProperty.write) ||
              characteristic.properties.contains(GATTCharacteristicProperty.writeWithoutResponse)) {
            writeCharacteristic = characteristic;
            break;
          }
        }
        if (writeCharacteristic != null) break;
      }
      
      if (writeCharacteristic != null) {
        // PIN 인증 메시지 전송
        final authMessage = 'AUTH:$pin';
        final bytes = authMessage.codeUnits;
        
        await viewModel.writeCharacteristic(
          discovery.peripheral,
          writeCharacteristic,
          Uint8List.fromList(bytes),
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PIN $pin으로 인증 요청을 전송했습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('쓰기 가능한 GATT 특성을 찾을 수 없습니다');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PIN 인증 전송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -65) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    if (rssi >= -95) return Colors.red;
    return Colors.red.shade700;
  }
}