import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../view_models/central_scanner_view_model.dart';
import '../models/device_info.dart';
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

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -65) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    if (rssi >= -95) return Colors.red;
    return Colors.red.shade700;
  }
}