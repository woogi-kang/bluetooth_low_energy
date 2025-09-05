import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../view_models/peripheral_manager_view_model.dart';

class ControlPanel extends StatefulWidget {
  final PeripheralManagerViewModel viewModel;

  const ControlPanel({
    super.key,
    required this.viewModel,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMessageSendingCard(),
        const SizedBox(height: 16),
        _buildVoiceControlCard(),
        const SizedBox(height: 16),
        _buildSettingsCard(),
      ],
    );
  }

  Widget _buildMessageSendingCard() {
    final connectedCount = widget.viewModel.connectedCentralsCount;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.send,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '메시지 전송',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: connectedCount > 0 ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$connectedCount개 기기',
                    style: TextStyle(
                      fontSize: 12,
                      color: connectedCount > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (connectedCount == 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Symbols.link_off,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '연결된 기기가 없습니다',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Central에게 보낼 메시지 입력',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _messageController.text.isNotEmpty ? _sendMessage : null,
                    icon: const Icon(Symbols.send),
                    label: const Text('전송'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickMessageChip('안녕하세요!'),
                  _buildQuickMessageChip('연결 확인'),
                  _buildQuickMessageChip('테스트 메시지'),
                  _buildQuickMessageChip('상태 확인'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessageChip(String message) {
    return ActionChip(
      label: Text(message),
      onPressed: () {
        _messageController.text = message;
        _sendMessage();
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildVoiceControlCard() {
    final isRecording = widget.viewModel.isRecording;
    final notifyCount = widget.viewModel.notifyEnabledCount;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.mic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '음성 메시지',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (notifyCount > 0)
                    ? (isRecording 
                        ? () async => await widget.viewModel.stopVoiceRecording()
                        : () async => await widget.viewModel.startVoiceRecording())
                    : null,
                icon: Icon(isRecording ? Symbols.stop : Symbols.mic),
                label: Text(
                  isRecording 
                      ? '녹음 중지 및 전송' 
                      : (notifyCount > 0 
                          ? '음성 녹음 시작' 
                          : 'Central에서 Notify 활성화 필요'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecording ? Colors.red : 
                                 (notifyCount > 0 ? Colors.blue : Colors.grey),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (notifyCount == 0) ...[
              const SizedBox(height: 8),
              Text(
                '음성 메시지를 보내려면 먼저 Central 기기에서 Notify를 활성화해야 합니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.tune,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '광고 설정',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingRow(
              '기기 이름',
              widget.viewModel.deviceName,
              Symbols.edit,
              () => _showDeviceNameDialog(),
            ),
            const SizedBox(height: 8),
            _buildSettingRow(
              '전송 파워',
              '${widget.viewModel.transmissionPower} dBm',
              Symbols.settings_power,
              () => _showTransmissionPowerDialog(),
            ),
            const SizedBox(height: 8),
            _buildSettingRow(
              '광고 데이터',
              widget.viewModel.advertisementData,
              Symbols.data_object,
              () => _showAdvertisementDataDialog(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('자동 재연결'),
              subtitle: const Text('연결이 끊어지면 자동으로 재연결 시도'),
              value: widget.viewModel.autoReconnect,
              onChanged: (value) => widget.viewModel.setAutoReconnect(value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: widget.viewModel.advertising ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: widget.viewModel.advertising ? Colors.grey : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: widget.viewModel.advertising ? Colors.grey : null,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.chevron_right,
              size: 16,
              color: widget.viewModel.advertising ? Colors.grey : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      await widget.viewModel.sendDataToCentrals(text);
      _messageController.clear();
    }
  }

  void _showDeviceNameDialog() {
    final controller = TextEditingController(text: widget.viewModel.deviceName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '새 기기 이름',
            hintText: 'BLE-Peripheral-1234',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                widget.viewModel.setDeviceName(newName);
              }
              Navigator.of(context).pop();
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _showTransmissionPowerDialog() {
    final currentPower = widget.viewModel.transmissionPower;
    double sliderValue = currentPower.toDouble();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('전송 파워 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('현재: ${sliderValue.round()} dBm'),
              Slider(
                value: sliderValue,
                min: -20,
                max: 8,
                divisions: 28,
                label: '${sliderValue.round()} dBm',
                onChanged: (value) {
                  setState(() {
                    sliderValue = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.viewModel.setTransmissionPower(sliderValue.round());
                Navigator.of(context).pop();
              },
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvertisementDataDialog() {
    final controller = TextEditingController(text: widget.viewModel.advertisementData);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 데이터 설정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '광고 데이터',
            hintText: 'BLE 주변기기 서비스',
          ),
          maxLength: 31,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newData = controller.text.trim();
              if (newData.isNotEmpty) {
                widget.viewModel.setAdvertisementData(newData);
              }
              Navigator.of(context).pop();
            },
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }
}