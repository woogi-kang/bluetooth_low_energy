import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../view_models/peripheral_manager_view_model.dart';
import '../models/log_entry.dart';

class LogViewer extends StatelessWidget {
  final PeripheralManagerViewModel viewModel;

  const LogViewer({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final logs = viewModel.logs;
    
    return Column(
      children: [
        Container(
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => viewModel.clearLogs(),
                icon: const Icon(Symbols.delete),
                tooltip: '로그 지우기',
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
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '활동 로그가 없습니다',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '광고를 시작하면 로그가 표시됩니다',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogCard(context, log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, LogEntry log) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (log.level) {
      case LogLevel.info:
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue;
        icon = Symbols.info;
        break;
      case LogLevel.warning:
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        icon = Symbols.warning;
        break;
      case LogLevel.error:
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red;
        icon = Symbols.error;
        break;
      case LogLevel.success:
        backgroundColor = Colors.green.shade50;
        iconColor = Colors.green;
        icon = Symbols.check_circle;
        break;
    }

    return Card(
      elevation: 1,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.levelName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.formattedTime,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}