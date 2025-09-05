import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:bluetooth_low_energy_example/utils/uuid_names.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CompactServiceView extends StatelessWidget {
  const CompactServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<ServiceViewModel>(context);
    final serviceName = UUIDNames.getDisplayName(viewModel.uuid, isService: true);
    final characteristicCount = viewModel.characteristicViewModels.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getServiceIcon(serviceName),
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${viewModel.uuid}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$characteristicCount',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final nameLower = serviceName.toLowerCase();
    if (nameLower.contains('heart') || nameLower.contains('health')) {
      return Symbols.favorite;
    } else if (nameLower.contains('battery')) {
      return Symbols.battery_full;
    } else if (nameLower.contains('device') || nameLower.contains('info')) {
      return Symbols.info;
    } else if (nameLower.contains('environmental') || nameLower.contains('sensor')) {
      return Symbols.sensors;
    } else if (nameLower.contains('glucose') || nameLower.contains('medical')) {
      return Symbols.medical_services;
    } else if (nameLower.contains('cycling') || nameLower.contains('running') || nameLower.contains('fitness')) {
      return Symbols.directions_bike;
    } else if (nameLower.contains('uart') || nameLower.contains('nordic')) {
      return Symbols.cable;
    } else {
      return Symbols.settings;
    }
  }
}