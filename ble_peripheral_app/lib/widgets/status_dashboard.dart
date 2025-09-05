import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../view_models/peripheral_manager_view_model.dart';

class StatusDashboard extends StatelessWidget {
  final PeripheralManagerViewModel viewModel;

  const StatusDashboard({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final advertising = viewModel.advertising;
    final connectedCount = viewModel.connectedCentralsCount;
    final notifyCount = viewModel.notifyEnabledCount;
    final waitingForAuth = viewModel.waitingForAuth;
    final currentAuthCode = viewModel.currentAuthCode;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                context,
                icon: advertising ? Symbols.broadcast_on_personal : Symbols.sensors,
                title: advertising ? '광고 중' : '대기 중',
                subtitle: advertising ? '클라이언트 검색 가능' : '서비스 대기',
                color: advertising ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            _buildCountCard(
              context,
              icon: Symbols.devices,
              count: connectedCount,
              label: '연결',
              color: connectedCount > 0 ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            _buildCountCard(
              context,
              icon: Symbols.notifications,
              count: notifyCount,
              label: 'Notify',
              color: notifyCount > 0 ? Colors.purple : Colors.grey,
            ),
          ],
        ),
        if (waitingForAuth && currentAuthCode != null) ...[
          const SizedBox(height: 12),
          _buildAuthCodeCard(context, currentAuthCode),
        ],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  
  Widget _buildAuthCodeCard(BuildContext context, String authCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.lock,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '인증 PIN',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              authCode,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
                fontFamily: 'monospace',
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Central 앱에 입력하세요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}