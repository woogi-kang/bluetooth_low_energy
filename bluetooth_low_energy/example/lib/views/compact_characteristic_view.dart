import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:bluetooth_low_energy_example/utils/uuid_names.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CompactCharacteristicView extends StatelessWidget {
  const CompactCharacteristicView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<CharacteristicViewModel>(context);
    final characteristicName = UUIDNames.getDisplayName(viewModel.uuid, isService: false);
    final characteristic = viewModel.characteristic;
    final properties = characteristic.properties;
    final descriptorCount = viewModel.descriptorViewModels.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Card(
        elevation: 0.5,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(
                      _getCharacteristicIcon(characteristicName, properties),
                      size: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      characteristicName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (descriptorCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${descriptorCount}D',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${viewModel.uuid}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: _buildPropertyChips(context, properties),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCharacteristicIcon(String name, List<GATTCharacteristicProperty> properties) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('heart') || nameLower.contains('rate')) {
      return Symbols.favorite;
    } else if (nameLower.contains('temperature') || nameLower.contains('temp')) {
      return Symbols.device_thermostat;
    } else if (nameLower.contains('battery') || nameLower.contains('level')) {
      return Symbols.battery_full;
    } else if (nameLower.contains('humidity')) {
      return Symbols.humidity_percentage;
    } else if (nameLower.contains('pressure')) {
      return Symbols.compress;
    } else if (nameLower.contains('write') || properties.contains(GATTCharacteristicProperty.write)) {
      return Symbols.edit;
    } else if (nameLower.contains('read') || properties.contains(GATTCharacteristicProperty.read)) {
      return Symbols.visibility;
    } else if (nameLower.contains('notify') || properties.contains(GATTCharacteristicProperty.notify)) {
      return Symbols.notifications;
    } else if (nameLower.contains('indicate') || properties.contains(GATTCharacteristicProperty.indicate)) {
      return Symbols.notification_important;
    } else {
      return Symbols.data_object;
    }
  }

  List<Widget> _buildPropertyChips(BuildContext context, List<GATTCharacteristicProperty> properties) {
    return properties.map((property) {
      final (color, icon) = _getPropertyStyle(property);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 2),
            Text(
              _getPropertyName(property),
              style: TextStyle(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  (Color, IconData) _getPropertyStyle(GATTCharacteristicProperty property) {
    switch (property) {
      case GATTCharacteristicProperty.read:
        return (Colors.blue, Symbols.visibility);
      case GATTCharacteristicProperty.write:
      case GATTCharacteristicProperty.writeWithoutResponse:
        return (Colors.green, Symbols.edit);
      case GATTCharacteristicProperty.notify:
        return (Colors.orange, Symbols.notifications);
      case GATTCharacteristicProperty.indicate:
        return (Colors.red, Symbols.notification_important);
    }
  }

  String _getPropertyName(GATTCharacteristicProperty property) {
    switch (property) {
      case GATTCharacteristicProperty.read:
        return 'R';
      case GATTCharacteristicProperty.write:
        return 'W';
      case GATTCharacteristicProperty.writeWithoutResponse:
        return 'W_NR';
      case GATTCharacteristicProperty.notify:
        return 'N';
      case GATTCharacteristicProperty.indicate:
        return 'I';
    }
  }
}