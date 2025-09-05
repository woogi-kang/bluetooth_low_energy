import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

class DeviceInfo {
  final UUID uuid;
  final String name;
  final int rssi;
  final List<UUID> serviceUUIDs;
  final bool isConnectable;
  final List<ManufacturerSpecificData> manufacturerData;
  final DateTime lastSeen;
  final int txPowerLevel;

  const DeviceInfo({
    required this.uuid,
    required this.name,
    required this.rssi,
    required this.serviceUUIDs,
    required this.isConnectable,
    required this.manufacturerData,
    required this.lastSeen,
    this.txPowerLevel = 0,
  });

  factory DeviceInfo.fromDiscoveryArgs(DiscoveredEventArgs args) {
    return DeviceInfo(
      uuid: args.peripheral.uuid,
      name: args.advertisement.name ?? '알 수 없는 기기',
      rssi: args.rssi,
      serviceUUIDs: args.advertisement.serviceUUIDs,
      isConnectable: true, // BLE 기본값
      manufacturerData: args.advertisement.manufacturerSpecificData,
      lastSeen: DateTime.now(),
      txPowerLevel: 0, // txPowerLevel은 Advertisement에서 사용할 수 없음
    );
  }

  String get displayName => name.isNotEmpty ? name : '알 수 없는 기기';

  String get deviceType {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('phone') || nameLower.contains('iphone') || nameLower.contains('android')) {
      return '스마트폰';
    } else if (nameLower.contains('watch') || nameLower.contains('band')) {
      return '웨어러블';
    } else if (nameLower.contains('earbuds') || nameLower.contains('headphone') || nameLower.contains('airpods')) {
      return '오디오';
    } else if (nameLower.contains('mouse') || nameLower.contains('keyboard')) {
      return '입력장치';
    } else if (nameLower.contains('tv') || nameLower.contains('display')) {
      return '디스플레이';
    } else if (serviceUUIDs.isNotEmpty) {
      return 'BLE 기기';
    } else {
      return '블루투스 기기';
    }
  }

  String get signalStrength {
    if (rssi >= -50) return '매우 강함';
    if (rssi >= -65) return '강함';
    if (rssi >= -80) return '보통';
    if (rssi >= -95) return '약함';
    return '매우 약함';
  }

  double get signalPercentage {
    // RSSI를 0-100% 범위로 변환
    const int minRSSI = -100;
    const int maxRSSI = -30;
    
    final clampedRSSI = rssi.clamp(minRSSI, maxRSSI);
    return ((clampedRSSI - minRSSI) / (maxRSSI - minRSSI)) * 100;
  }
}