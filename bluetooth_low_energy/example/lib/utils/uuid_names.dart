import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

class UUIDNames {
  static const Map<String, String> _serviceNames = {
    // Standard Services
    '1800': 'Generic Access',
    '1801': 'Generic Attribute', 
    '1802': 'Immediate Alert',
    '1803': 'Link Loss',
    '1804': 'Tx Power',
    '1805': 'Current Time Service',
    '1806': 'Reference Time Update Service',
    '1807': 'Next DST Change Service',
    '1808': 'Glucose',
    '1809': 'Health Thermometer',
    '180A': 'Device Information',
    '180D': 'Heart Rate',
    '180F': 'Battery Service',
    '1810': 'Blood Pressure',
    '1811': 'Alert Notification Service',
    '1812': 'Human Interface Device',
    '1813': 'Scan Parameters',
    '1814': 'Running Speed and Cadence',
    '1815': 'Automation IO',
    '1816': 'Cycling Speed and Cadence',
    '1818': 'Cycling Power',
    '1819': 'Location and Navigation',
    '181A': 'Environmental Sensing',
    '181B': 'Body Composition',
    '181C': 'User Data',
    '181D': 'Weight Scale',
    '181E': 'Bond Management',
    '181F': 'Continuous Glucose Monitoring',
    '1820': 'Internet Protocol Support',
    '1821': 'Indoor Positioning',
    '1822': 'Pulse Oximeter',
    '1823': 'HTTP Proxy',
    '1824': 'Transport Discovery',
    '1825': 'Object Transfer',
    '1826': 'Fitness Machine',
    '1827': 'Mesh Provisioning',
    '1828': 'Mesh Proxy',
    '1829': 'Reconnection Configuration',
    // Custom/Example Services
    '0064': 'Example Service (100)',
  };

  static const Map<String, String> _characteristicNames = {
    // Standard Characteristics  
    '2A00': 'Device Name',
    '2A01': 'Appearance',
    '2A02': 'Peripheral Privacy Flag',
    '2A03': 'Reconnection Address',
    '2A04': 'Peripheral Preferred Connection Parameters',
    '2A05': 'Service Changed',
    '2A06': 'Alert Level',
    '2A07': 'Tx Power Level',
    '2A08': 'Date Time',
    '2A09': 'Day of Week',
    '2A0A': 'Day Date Time',
    '2A0B': 'Exact Time 100',
    '2A0C': 'Exact Time 256',
    '2A0D': 'DST Offset',
    '2A0E': 'Time Zone',
    '2A0F': 'Local Time Information',
    '2A10': 'Secondary Time Zone',
    '2A11': 'Time with DST',
    '2A12': 'Time Accuracy',
    '2A13': 'Time Source',
    '2A14': 'Reference Time Information',
    '2A15': 'Time Broadcast',
    '2A16': 'Time Update Control Point',
    '2A17': 'Time Update State',
    '2A18': 'Glucose Measurement',
    '2A19': 'Battery Level',
    '2A1A': 'Battery Power State',
    '2A1B': 'Battery Level State',
    '2A1C': 'Temperature Measurement',
    '2A1D': 'Temperature Type',
    '2A1E': 'Intermediate Temperature',
    '2A1F': 'Temperature Celsius',
    '2A20': 'Temperature Fahrenheit',
    '2A21': 'Measurement Interval',
    '2A22': 'Boot Keyboard Input Report',
    '2A23': 'System ID',
    '2A24': 'Model Number String',
    '2A25': 'Serial Number String',
    '2A26': 'Firmware Revision String',
    '2A27': 'Hardware Revision String',
    '2A28': 'Software Revision String',
    '2A29': 'Manufacturer Name String',
    '2A2A': 'IEEE 11073-20601 Regulatory Certification Data List',
    '2A2B': 'Current Time',
    '2A2C': 'Magnetic Declination',
    '2A31': 'Scan Refresh',
    '2A32': 'Boot Keyboard Output Report',
    '2A33': 'Boot Mouse Input Report',
    '2A34': 'Glucose Measurement Context',
    '2A35': 'Blood Pressure Measurement',
    '2A36': 'Intermediate Cuff Pressure',
    '2A37': 'Heart Rate Measurement',
    '2A38': 'Body Sensor Location',
    '2A39': 'Heart Rate Control Point',
    '2A3A': 'Removable',
    '2A3B': 'Service Required',
    '2A3C': 'Scientific Temperature Celsius',
    '2A3D': 'String',
    '2A3E': 'Network Availability',
    '2A3F': 'Alert Status',
    '2A40': 'Ringer Control point',
    '2A41': 'Ringer Setting',
    '2A42': 'Alert Category ID Bit Mask',
    '2A43': 'Alert Category ID',
    '2A44': 'Alert Notification Control Point',
    '2A45': 'Unread Alert Status',
    '2A46': 'New Alert',
    '2A47': 'Supported New Alert Category',
    '2A48': 'Supported Unread Alert Category',
    '2A49': 'Blood Pressure Feature',
    '2A4A': 'HID Information',
    '2A4B': 'Report Map',
    '2A4C': 'HID Control Point',
    '2A4D': 'Report',
    '2A4E': 'Protocol Mode',
    '2A4F': 'Scan Interval Window',
    '2A50': 'PnP ID',
    '2A51': 'Glucose Feature',
    '2A52': 'Record Access Control Point',
    '2A53': 'RSC Measurement',
    '2A54': 'RSC Feature',
    '2A55': 'SC Control Point',
    '2A56': 'Digital',
    '2A57': 'Digital Output',
    '2A58': 'Analog',
    '2A59': 'Analog Output',
    '2A5A': 'Aggregate',
    '2A5B': 'CSC Measurement',
    '2A5C': 'CSC Feature',
    '2A5D': 'Sensor Location',
    '2A5E': 'PLX Spot-Check Measurement',
    '2A5F': 'PLX Continuous Measurement',
    '2A60': 'PLX Features',
    '2A63': 'Cycling Power Measurement',
    '2A64': 'Cycling Power Vector',
    '2A65': 'Cycling Power Feature',
    '2A66': 'Cycling Power Control Point',
    '2A67': 'Location and Speed',
    '2A68': 'Navigation',
    '2A69': 'Position Quality',
    '2A6A': 'LN Feature',
    '2A6B': 'LN Control Point',
    '2A6C': 'Elevation',
    '2A6D': 'Pressure',
    '2A6E': 'Temperature',
    '2A6F': 'Humidity',
    '2A70': 'True Wind Speed',
    '2A71': 'True Wind Direction',
    '2A72': 'Apparent Wind Speed',
    '2A73': 'Apparent Wind Direction',
    '2A74': 'Gust Factor',
    '2A75': 'Pollen Concentration',
    '2A76': 'UV Index',
    '2A77': 'Irradiance',
    '2A78': 'Rainfall',
    '2A79': 'Wind Chill',
    '2A7A': 'Heat Index',
    '2A7B': 'Dew Point',
    // Custom/Example Characteristics
    '00C8': 'Example Read-Only (200)',
    '00C9': 'Example Read-Write-Notify (201)',
  };

  static String getServiceName(UUID uuid) {
    final shortUuid = _getShortUuid(uuid);
    return _serviceNames[shortUuid] ?? 'Unknown Service ($shortUuid)';
  }

  static String getCharacteristicName(UUID uuid) {
    final shortUuid = _getShortUuid(uuid);
    return _characteristicNames[shortUuid] ?? 'Unknown Characteristic ($shortUuid)';
  }

  static String _getShortUuid(UUID uuid) {
    final uuidString = uuid.toString().toUpperCase();
    
    // 16-bit UUID 패턴 확인 (0000xxxx-0000-1000-8000-00805F9B34FB)
    if (uuidString.startsWith('0000') && uuidString.endsWith('-0000-1000-8000-00805F9B34FB')) {
      return uuidString.substring(4, 8);
    }
    
    // 짧은 UUID 형식 확인 (예: 0064, 00C8)
    if (uuidString.length <= 4) {
      return uuidString.padLeft(4, '0');
    }
    
    // 전체 UUID의 경우 처음 4자리 반환
    return uuidString.substring(0, 4);
  }

  static String getDisplayName(UUID uuid, {bool isService = false}) {
    if (isService) {
      return getServiceName(uuid);
    } else {
      return getCharacteristicName(uuid);
    }
  }
}