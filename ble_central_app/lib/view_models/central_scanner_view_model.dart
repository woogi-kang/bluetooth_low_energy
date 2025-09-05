import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:clover/clover.dart';
import 'package:logging/logging.dart';

class CentralScannerViewModel extends ViewModel {
  final CentralManager _manager;
  final List<DiscoveredEventArgs> _discoveries;
  final Set<String> _favoriteDevices;
  bool _discovering;
  bool _filterByRSSI;
  int _rssiThreshold;
  String _searchQuery;
  List<UUID>? _serviceFilter;
  bool _hideUnnamedDevices;

  late final StreamSubscription _stateChangedSubscription;
  late final StreamSubscription _discoveredSubscription;

  CentralScannerViewModel()
      : _manager = CentralManager()..logLevel = Level.INFO,
        _discoveries = [],
        _favoriteDevices = <String>{},
        _discovering = false,
        _filterByRSSI = false,
        _rssiThreshold = -80,
        _searchQuery = '',
        _serviceFilter = null,
        _hideUnnamedDevices = true {
    _stateChangedSubscription = _manager.stateChanged.listen((eventArgs) async {
      if (eventArgs.state == BluetoothLowEnergyState.unauthorized &&
          Platform.isAndroid) {
        await _manager.authorize();
      }
      notifyListeners();
    });
    _discoveredSubscription = _manager.discovered.listen((eventArgs) {
      _handleDeviceDiscovered(eventArgs);
    });
  }

  // Getters
  BluetoothLowEnergyState get state => _manager.state;
  bool get discovering => _discovering;
  bool get filterByRSSI => _filterByRSSI;
  int get rssiThreshold => _rssiThreshold;
  String get searchQuery => _searchQuery;
  List<UUID>? get serviceFilter => _serviceFilter;
  Set<String> get favoriteDevices => _favoriteDevices;
  bool get hideUnnamedDevices => _hideUnnamedDevices;

  List<DiscoveredEventArgs> get discoveries {
    var filtered = _discoveries.where((discovery) {
      final name = discovery.advertisement.name ?? '';
      final rssi = discovery.rssi;
      
      // INMO Go 2 필터 - 이 기기들만 표시
      if (!name.toLowerCase().contains('inmo go 2')) {
        return false;
      }
      
      // 이름 없는 기기 필터
      if (_hideUnnamedDevices && (name.isEmpty || name.trim().isEmpty)) {
        return false;
      }
      
      // RSSI 필터
      if (_filterByRSSI && rssi < _rssiThreshold) {
        return false;
      }
      
      // 검색어 필터
      if (_searchQuery.isNotEmpty && 
          !name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      return true;
    }).toList();
    
    // 즐겨찾기된 기기를 맨 위로 정렬
    filtered.sort((a, b) {
      final aIsFavorite = _favoriteDevices.contains(a.peripheral.uuid.toString());
      final bIsFavorite = _favoriteDevices.contains(b.peripheral.uuid.toString());
      
      if (aIsFavorite && !bIsFavorite) return -1;
      if (!aIsFavorite && bIsFavorite) return 1;
      
      // RSSI로 정렬 (강한 신호순)
      return b.rssi.compareTo(a.rssi);
    });
    
    return filtered;
  }

  List<DiscoveredEventArgs> get favoriteDiscoveries {
    return _discoveries.where((discovery) {
      return _favoriteDevices.contains(discovery.peripheral.uuid.toString());
    }).toList();
  }

  // Actions
  Future<void> showAppSettings() async {
    await _manager.showAppSettings();
  }

  Future<void> startDiscovery({List<UUID>? serviceUUIDs}) async {
    if (_discovering) return;
    
    _discoveries.clear();
    _serviceFilter = serviceUUIDs;
    await _manager.startDiscovery(serviceUUIDs: serviceUUIDs);
    _discovering = true;
    notifyListeners();
  }

  Future<void> stopDiscovery() async {
    if (!_discovering) return;
    
    await _manager.stopDiscovery();
    _discovering = false;
    notifyListeners();
  }

  void setRSSIFilter(bool enabled, [int threshold = -80]) {
    _filterByRSSI = enabled;
    _rssiThreshold = threshold;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleFavorite(String deviceUuid) {
    if (_favoriteDevices.contains(deviceUuid)) {
      _favoriteDevices.remove(deviceUuid);
    } else {
      _favoriteDevices.add(deviceUuid);
    }
    notifyListeners();
  }
  
  void toggleHideUnnamedDevices() {
    _hideUnnamedDevices = !_hideUnnamedDevices;
    notifyListeners();
  }
  
  // Connection management
  Future<void> connectToDevice(DiscoveredEventArgs discovery) async {
    try {
      await _manager.connect(discovery.peripheral);
      // Connection successful - will be handled by connection state listener
    } catch (e) {
      // Handle connection error
      rethrow;
    }
  }
  
  Future<void> disconnectFromDevice(Peripheral peripheral) async {
    try {
      await _manager.disconnect(peripheral);
    } catch (e) {
      // Handle disconnection error
      rethrow;
    }
  }
  
  Future<List<GATTService>> discoverServices(Peripheral peripheral) async {
    try {
      return await _manager.discoverGATT(peripheral);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> writeCharacteristic(
    Peripheral peripheral,
    GATTCharacteristic characteristic,
    Uint8List value,
  ) async {
    try {
      // 최대 쓰기 길이 확인
      final fragmentSize = await _manager.getMaximumWriteLength(
        peripheral,
        type: GATTCharacteristicWriteType.withResponse,
      );
      
      // 값을 조각화하여 전송
      var start = 0;
      while (start < value.length) {
        final end = start + fragmentSize;
        final fragmentedValue = end < value.length
            ? value.sublist(start, end)
            : value.sublist(start);
        
        await _manager.writeCharacteristic(
          peripheral,
          characteristic,
          value: fragmentedValue,
          type: GATTCharacteristicWriteType.withResponse,
        );
        
        start = end;
      }
    } catch (e) {
      rethrow;
    }
  }

  bool isFavorite(String deviceUuid) {
    return _favoriteDevices.contains(deviceUuid);
  }

  void clearDiscoveries() {
    _discoveries.clear();
    notifyListeners();
  }

  void _handleDeviceDiscovered(DiscoveredEventArgs eventArgs) {
    final peripheral = eventArgs.peripheral;
    final name = eventArgs.advertisement.name;
    
    // 기기 이름이 없는 경우 필터링 (선택사항)
    if (name == null || name.isEmpty) {
      // 이름이 없어도 표시하도록 변경
    }
    
    final index = _discoveries.indexWhere((i) => i.peripheral == peripheral);
    if (index < 0) {
      _discoveries.add(eventArgs);
    } else {
      _discoveries[index] = eventArgs;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stateChangedSubscription.cancel();
    _discoveredSubscription.cancel();
    super.dispose();
  }
}