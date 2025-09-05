import 'dart:convert';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:bluetooth_low_energy_example/view_models.dart';
import 'package:bluetooth_low_energy_example/utils/uuid_names.dart';
import 'package:clover/clover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CompactCharacteristicView extends StatefulWidget {
  const CompactCharacteristicView({super.key});

  @override
  State<CompactCharacteristicView> createState() => _CompactCharacteristicViewState();
}

class _CompactCharacteristicViewState extends State<CompactCharacteristicView> {
  String? _lastReadValue;
  bool _isSubscribed = false;
  bool _isLoading = false;

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
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          childrenPadding: const EdgeInsets.all(8),
          dense: true,
          title: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      characteristicName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${viewModel.uuid}'.substring(0, 23) + '...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
          subtitle: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: _buildPropertyChips(context, properties),
          ),
          children: [
            _buildActionButtons(context, viewModel, properties),
            if (_lastReadValue != null) ...[
              const SizedBox(height: 8),
              _buildValueDisplay(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CharacteristicViewModel viewModel, List<GATTCharacteristicProperty> properties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Read 버튼
        if (properties.contains(GATTCharacteristicProperty.read))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _readCharacteristic(viewModel),
              icon: _isLoading 
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Symbols.visibility, size: 16),
              label: const Text('읽기', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade700,
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        
        // Write 버튼
        if (properties.contains(GATTCharacteristicProperty.write) || 
            properties.contains(GATTCharacteristicProperty.writeWithoutResponse))
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _showWriteDialog(context, viewModel),
              icon: const Icon(Symbols.edit, size: 16),
              label: const Text('쓰기', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade700,
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        
        // Notify 버튼
        if (properties.contains(GATTCharacteristicProperty.notify) ||
            properties.contains(GATTCharacteristicProperty.indicate))
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _toggleNotify(viewModel),
            icon: Icon(_isSubscribed ? Symbols.notifications_active : Symbols.notifications, size: 16),
            label: Text(_isSubscribed ? '알림 끄기' : '알림 켜기', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubscribed ? Colors.red.shade100 : Colors.orange.shade100,
              foregroundColor: _isSubscribed ? Colors.red.shade700 : Colors.orange.shade700,
              minimumSize: const Size(0, 32),
            ),
          ),
      ],
    );
  }

  Widget _buildValueDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '마지막 읽은 값:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            _lastReadValue!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _readCharacteristic(CharacteristicViewModel viewModel) async {
    setState(() => _isLoading = true);
    
    try {
      await viewModel.read();
      // 로그에서 마지막 읽은 값을 가져옴
      if (viewModel.logs.isNotEmpty) {
        final lastLog = viewModel.logs.last;
        if (lastLog.type == 'Read') {
          if (mounted) {
            setState(() {
              _lastReadValue = lastLog.message;
              _isLoading = false;
            });
            
            _showSnackBar('읽기 성공', Colors.green);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('읽기 실패: $e', Colors.red);
      }
    }
  }

  Future<void> _showWriteDialog(BuildContext context, CharacteristicViewModel viewModel) async {
    final TextEditingController controller = TextEditingController();
    bool isHex = false;
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('값 쓰기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setDialogState(() => isHex = false),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: isHex,
                            onChanged: (value) => setDialogState(() => isHex = value!),
                          ),
                          const Text('텍스트', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setDialogState(() => isHex = true),
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: isHex,
                            onChanged: (value) => setDialogState(() => isHex = value!),
                          ),
                          const Text('Hex', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: isHex ? 'Hex 값 (예: 48656C6C6F)' : '텍스트 값',
                  hintText: isHex ? '48656C6C6F' : 'Hello',
                  border: const OutlineInputBorder(),
                ),
                maxLines: isHex ? 3 : 1,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _writeCharacteristic(viewModel, controller.text, isHex);
              },
              child: const Text('쓰기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _writeCharacteristic(CharacteristicViewModel viewModel, String input, bool isHex) async {
    if (input.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      Uint8List bytes;
      if (isHex) {
        // Hex 문자열을 바이트로 변환
        final cleanHex = input.replaceAll(' ', '').replaceAll('0x', '');
        if (cleanHex.length % 2 != 0) {
          throw Exception('Hex 문자열의 길이가 짝수여야 합니다');
        }
        bytes = Uint8List.fromList(
          List.generate(cleanHex.length ~/ 2, 
            (i) => int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16))
        );
      } else {
        // 텍스트를 UTF-8 바이트로 변환
        bytes = Uint8List.fromList(utf8.encode(input));
      }
      
      await viewModel.write(bytes);
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('쓰기 성공', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('쓰기 실패: $e', Colors.red);
      }
    }
  }

  Future<void> _toggleNotify(CharacteristicViewModel viewModel) async {
    setState(() => _isLoading = true);
    
    try {
      if (_isSubscribed) {
        await viewModel.setNotifyState(false);
        if (mounted) {
          setState(() {
            _isSubscribed = false;
            _isLoading = false;
          });
          _showSnackBar('알림 구독을 취소했습니다', Colors.orange);
        }
      } else {
        // 알림 구독 시작
        await viewModel.setNotifyState(true);
        if (mounted) {
          setState(() {
            _isSubscribed = true;
            _isLoading = false;
          });
          _showSnackBar('알림 구독을 시작했습니다', Colors.green);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('알림 설정 실패: $e', Colors.red);
      }
    }
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
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