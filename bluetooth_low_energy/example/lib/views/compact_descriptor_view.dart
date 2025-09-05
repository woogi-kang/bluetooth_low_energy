import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:bluetooth_low_energy_example/utils/uuid_names.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CompactDescriptorView extends StatelessWidget {
  const CompactDescriptorView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModel.of<DescriptorViewModel>(context);
    final descriptorName = UUIDNames.getDisplayName(viewModel.uuid, isService: false);
    
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 2),
      child: Card(
        elevation: 0.5,
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  _getDescriptorIcon(descriptorName),
                  size: 10,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descriptorName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${viewModel.uuid}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  IconData _getDescriptorIcon(String name) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('config') || nameLower.contains('configuration')) {
      return Symbols.tune;
    } else if (nameLower.contains('user') || nameLower.contains('description')) {
      return Symbols.description;
    } else if (nameLower.contains('format') || nameLower.contains('presentation')) {
      return Symbols.format_shapes;
    } else if (nameLower.contains('client') || nameLower.contains('characteristic')) {
      return Symbols.settings;
    } else if (nameLower.contains('server') || nameLower.contains('characteristic')) {
      return Symbols.dns;
    } else if (nameLower.contains('aggregate') || nameLower.contains('format')) {
      return Symbols.format_list_bulleted;
    } else if (nameLower.contains('extended') || nameLower.contains('properties')) {
      return Symbols.extension;
    } else if (nameLower.contains('report') || nameLower.contains('reference')) {
      return Symbols.link;
    } else {
      return Symbols.more_horiz;
    }
  }
}