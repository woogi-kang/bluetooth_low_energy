import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../view_models/central_scanner_view_model.dart';

class DeviceDetailView extends StatefulWidget {
  final DiscoveredEventArgs discovery;
  final CentralScannerViewModel viewModel;

  const DeviceDetailView({
    super.key,
    required this.discovery,
    required this.viewModel,
  });

  @override
  State<DeviceDetailView> createState() => _DeviceDetailViewState();
}

class _DeviceDetailViewState extends State<DeviceDetailView> {
  List<GATTService>? _services;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  Future<void> _discoverServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final services = await widget.viewModel.discoverServices(widget.discovery.peripheral);
      
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.discovery.advertisement.name ?? '알 수 없는 기기';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildServicesView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              '서비스 발견 실패',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _discoverServices,
              icon: const Icon(Symbols.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesView() {
    if (_services == null || _services!.isEmpty) {
      return const Center(
        child: Text('사용 가능한 GATT 서비스가 없습니다'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services!.length,
      itemBuilder: (context, index) {
        final service = _services![index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(GATTService service) {
    final serviceName = _getServiceName(service.uuid);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Symbols.settings,
            color: Colors.blue.shade700,
          ),
        ),
        title: Text(
          serviceName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          service.uuid.toString().toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        children: service.characteristics.map((characteristic) {
          return _buildCharacteristicTile(characteristic);
        }).toList(),
      ),
    );
  }

  Widget _buildCharacteristicTile(GATTCharacteristic characteristic) {
    final characteristicName = _getCharacteristicName(characteristic.uuid);
    final properties = characteristic.properties;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          leading: Icon(
            _getCharacteristicIcon(properties),
            color: Colors.green.shade700,
          ),
          title: Text(characteristicName),
          subtitle: Text(
            characteristic.uuid.toString().toUpperCase(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '속성',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: properties.map((property) {
                      return _buildPropertyChip(property);
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildCharacteristicActions(characteristic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyChip(GATTCharacteristicProperty property) {
    Color color;
    String label;

    switch (property) {
      case GATTCharacteristicProperty.read:
        color = Colors.blue;
        label = '읽기';
        break;
      case GATTCharacteristicProperty.write:
        color = Colors.green;
        label = '쓰기';
        break;
      case GATTCharacteristicProperty.writeWithoutResponse:
        color = Colors.orange;
        label = '응답없는쓰기';
        break;
      case GATTCharacteristicProperty.notify:
        color = Colors.purple;
        label = '알림';
        break;
      case GATTCharacteristicProperty.indicate:
        color = Colors.red;
        label = '지시';
        break;
      default:
        color = Colors.grey;
        label = property.toString();
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color, width: 1),
    );
  }

  Widget _buildCharacteristicActions(GATTCharacteristic characteristic) {
    final properties = characteristic.properties;
    final actions = <Widget>[];

    if (properties.contains(GATTCharacteristicProperty.read)) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => _readCharacteristic(characteristic),
          icon: const Icon(Symbols.download, size: 16),
          label: const Text('읽기'),
        ),
      );
    }

    if (properties.contains(GATTCharacteristicProperty.write) ||
        properties.contains(GATTCharacteristicProperty.writeWithoutResponse)) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _writeCharacteristic(characteristic),
          icon: const Icon(Symbols.upload, size: 16),
          label: const Text('쓰기'),
        ),
      );
    }

    if (properties.contains(GATTCharacteristicProperty.notify)) {
      actions.add(
        FilledButton.icon(
          onPressed: () => _toggleNotify(characteristic),
          icon: const Icon(Symbols.notifications, size: 16),
          label: const Text('알림'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: actions,
    );
  }

  Future<void> _readCharacteristic(GATTCharacteristic characteristic) async {
    // TODO: 읽기 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('읽기 기능이 곧 구현됩니다')),
    );
  }

  Future<void> _writeCharacteristic(GATTCharacteristic characteristic) async {
    // TODO: 쓰기 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('쓰기 기능이 곧 구현됩니다')),
    );
  }

  Future<void> _toggleNotify(GATTCharacteristic characteristic) async {
    // TODO: 알림 토글 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 기능이 곧 구현됩니다')),
    );
  }

  String _getServiceName(UUID uuid) {
    final uuidString = uuid.toString().toUpperCase();
    
    // 표준 BLE 서비스 UUID
    const serviceNames = {
      '0000180F-0000-1000-8000-00805F9B34FB': '배터리 서비스',
      '0000180A-0000-1000-8000-00805F9B34FB': '기기 정보 서비스',
      '0000180D-0000-1000-8000-00805F9B34FB': '심박수 서비스',
      '0000181C-0000-1000-8000-00805F9B34FB': '사용자 데이터 서비스',
      '0000FE59-0000-1000-8000-00805F9B34FB': 'Nordic UART 서비스',
      '00001800-0000-1000-8000-00805F9B34FB': '일반 액세스 서비스',
      '00001801-0000-1000-8000-00805F9B34FB': '일반 속성 서비스',
    };

    return serviceNames[uuidString] ?? '사용자 정의 서비스';
  }

  String _getCharacteristicName(UUID uuid) {
    final uuidString = uuid.toString().toUpperCase();
    
    // 표준 BLE 특성 UUID
    const characteristicNames = {
      '00002A00-0000-1000-8000-00805F9B34FB': '기기 이름',
      '00002A01-0000-1000-8000-00805F9B34FB': '외관',
      '00002A02-0000-1000-8000-00805F9B34FB': '주변기기 기본 연결 매개변수',
      '00002A03-0000-1000-8000-00805F9B34FB': '재연결 주소',
      '00002A04-0000-1000-8000-00805F9B34FB': '주변기기 기본 연결 매개변수',
      '00002A19-0000-1000-8000-00805F9B34FB': '배터리 레벨',
      '00002A29-0000-1000-8000-00805F9B34FB': '제조사 이름',
      '00002A24-0000-1000-8000-00805F9B34FB': '모델 번호',
      '00002A25-0000-1000-8000-00805F9B34FB': '일련 번호',
      '00002A26-0000-1000-8000-00805F9B34FB': '펌웨어 버전',
      '00002A27-0000-1000-8000-00805F9B34FB': '하드웨어 버전',
      '00002A28-0000-1000-8000-00805F9B34FB': '소프트웨어 버전',
    };

    return characteristicNames[uuidString] ?? '사용자 정의 특성';
  }

  IconData _getCharacteristicIcon(List<GATTCharacteristicProperty> properties) {
    if (properties.contains(GATTCharacteristicProperty.notify)) {
      return Symbols.notifications;
    }
    if (properties.contains(GATTCharacteristicProperty.write)) {
      return Symbols.edit;
    }
    if (properties.contains(GATTCharacteristicProperty.read)) {
      return Symbols.visibility;
    }
    return Symbols.settings;
  }
}