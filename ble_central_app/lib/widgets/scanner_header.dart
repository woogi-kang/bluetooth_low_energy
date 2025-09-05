import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../view_models/central_scanner_view_model.dart';

class ScannerHeader extends StatelessWidget {
  final CentralScannerViewModel viewModel;

  const ScannerHeader({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final discovering = viewModel.discovering;
    final deviceCount = viewModel.discoveries.length;
    final favoriteCount = viewModel.favoriteDevices.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            context,
            icon: discovering ? Symbols.radar : Symbols.bluetooth_searching,
            title: discovering ? '스캔 중' : '대기 중',
            subtitle: discovering ? '기기 검색 중...' : '스캔 대기',
            color: discovering ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        _buildCountCard(
          context,
          icon: Symbols.devices,
          count: deviceCount,
          label: '기기',
          color: deviceCount > 0 ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        _buildCountCard(
          context,
          icon: Symbols.favorite,
          count: favoriteCount,
          label: '즐겨찾기',
          color: favoriteCount > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}