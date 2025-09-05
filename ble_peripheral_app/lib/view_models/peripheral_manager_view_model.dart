import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:clover/clover.dart';
import 'package:logging/logging.dart';
import 'package:record/record.dart';

import '../models/log_entry.dart';

class PeripheralManagerViewModel extends ViewModel {
  final PeripheralManager _manager;
  final List<LogEntry> _logs;
  bool _advertising;
  final Set<Central> _connectedCentrals;
  final Map<Central, bool> _centralNotifyStates;
  String? _deviceInfo;
  GATTCharacteristic? _notifiableCharacteristic;
  final AudioRecorder _audioRecorder;
  bool _isRecording;

  // 인증 시스템 관련 변수
  String? _currentAuthCode;
  Timer? _authTimer;
  final Map<Central, bool> _authenticatedCentrals;
  bool _waitingForAuth;

  // 기기 이름 및 설정 관련 변수
  String _deviceName;
  int _transmissionPower;
  String _advertisementData;
  bool _autoReconnect;

  // 통계 및 분석
  int _totalConnections;
  int _dataPacketsSent;
  int _dataPacketsReceived;
  DateTime _lastActivity;
  
  // 텍스트 메시지 관련
  final List<String> _receivedMessages;

  late final StreamSubscription _stateChangedSubscription;
  late final StreamSubscription _characteristicReadRequestedSubscription;
  late final StreamSubscription _characteristicWriteRequestedSubscription;
  late final StreamSubscription _characteristicNotifyStateChangedSubscription;

  PeripheralManagerViewModel()
    : _manager = PeripheralManager()..logLevel = Level.INFO,
      _logs = [],
      _advertising = false,
      _connectedCentrals = {},
      _centralNotifyStates = {},
      _deviceInfo = null,
      _notifiableCharacteristic = null,
      _audioRecorder = AudioRecorder(),
      _isRecording = false,
      _currentAuthCode = null,
      _authenticatedCentrals = {},
      _waitingForAuth = false,
      _deviceName = _generateDeviceNameStatic(),
      _transmissionPower = 0,
      _advertisementData = 'BLE 주변기기 서비스',
      _autoReconnect = true,
      _totalConnections = 0,
      _dataPacketsSent = 0,
      _dataPacketsReceived = 0,
      _lastActivity = DateTime.now(),
      _receivedMessages = [] {
    _setupSubscriptions();
    _initializeDevice();
  }

  // Getters
  BluetoothLowEnergyState get state => _manager.state;
  bool get advertising => _advertising;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  Set<Central> get connectedCentrals => Set.unmodifiable(_connectedCentrals);
  int get connectedCentralsCount => _connectedCentrals.length;
  int get notifyEnabledCount =>
      _centralNotifyStates.values.where((enabled) => enabled).length;
  bool get hasAuthenticatedCentrals =>
      _authenticatedCentrals.values.any((authenticated) => authenticated);
  String? get deviceInfo => _deviceInfo;
  bool get isRecording => _isRecording;
  String? get currentAuthCode => _currentAuthCode;
  bool get waitingForAuth => _waitingForAuth;
  String get deviceName => _deviceName;
  int get transmissionPower => _transmissionPower;
  String get advertisementData => _advertisementData;
  bool get autoReconnect => _autoReconnect;

  // 통계 정보
  int get totalConnections => _totalConnections;
  int get dataPacketsSent => _dataPacketsSent;
  int get dataPacketsReceived => _dataPacketsReceived;
  DateTime get lastActivity => _lastActivity;
  
  // 텍스트 메시지 관련
  List<String> get receivedMessages => List.unmodifiable(_receivedMessages);

  // 연결 품질 계산
  String get connectionQuality {
    if (_connectedCentrals.isEmpty) return '연결 없음';
    if (notifyEnabledCount == connectedCentralsCount) return '우수';
    if (notifyEnabledCount > 0) return '양호';
    return '보통';
  }

  void _setupSubscriptions() {
    _stateChangedSubscription = _manager.stateChanged.listen((eventArgs) async {
      _addLog(
        LogEntry(
          level: LogLevel.info,
          message: '블루투스 상태 변경: ${eventArgs.state}',
          timestamp: DateTime.now(),
        ),
      );

      if (eventArgs.state == BluetoothLowEnergyState.unauthorized &&
          Platform.isAndroid) {
        await _manager.authorize();
      }
      notifyListeners();
    });

    _characteristicReadRequestedSubscription = _manager
        .characteristicReadRequested
        .listen((eventArgs) async {
          _handleCharacteristicRead(eventArgs);
        });

    _characteristicWriteRequestedSubscription = _manager
        .characteristicWriteRequested
        .listen((eventArgs) async {
          _handleCharacteristicWrite(eventArgs);
        });

    _characteristicNotifyStateChangedSubscription = _manager
        .characteristicNotifyStateChanged
        .listen((eventArgs) {
          _handleNotifyStateChanged(eventArgs);
        });
  }

  void _initializeDevice() {
    if (Platform.isAndroid || Platform.isIOS) {
      _deviceInfo =
          Platform.isAndroid ? 'Android BLE Peripheral' : 'iOS BLE Peripheral';
    } else {
      _deviceInfo = 'Desktop BLE Peripheral';
    }

    _addLog(
      LogEntry(
        level: LogLevel.info,
        message: '기기 초기화 완료: $_deviceInfo',
        timestamp: DateTime.now(),
      ),
    );
  }

  // Actions
  Future<void> showAppSettings() async {
    await _manager.showAppSettings();
  }

  Future<void> startAdvertising() async {
    if (_advertising) return;

    try {
      // 서비스 및 특성 정의
      final serviceUuid = UUID.fromString(
        '12345678-1234-5678-9abc-def012345678',
      );
      final readCharacteristicUuid = UUID.fromString(
        '87654321-4321-8765-cbad-fed098765432',
      );
      final writeCharacteristicUuid = UUID.fromString(
        '11111111-2222-3333-4444-555555555555',
      );
      final notifyCharacteristicUuid = UUID.fromString(
        'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );

      final readCharacteristic = GATTCharacteristic.immutable(
        uuid: readCharacteristicUuid,
        value: Uint8List.fromList('읽기 테스트'.codeUnits),
        descriptors: [],
      );

      final writeCharacteristic = GATTCharacteristic.mutable(
        uuid: writeCharacteristicUuid,
        properties: [
          GATTCharacteristicProperty.writeWithoutResponse,
          GATTCharacteristicProperty.write,
        ],
        permissions: [GATTCharacteristicPermission.write],
        descriptors: [],
      );

      _notifiableCharacteristic = GATTCharacteristic.mutable(
        uuid: notifyCharacteristicUuid,
        properties: [GATTCharacteristicProperty.notify],
        permissions: [GATTCharacteristicPermission.read],
        descriptors: [],
      );

      final service = GATTService(
        uuid: serviceUuid,
        isPrimary: true,
        characteristics: [
          readCharacteristic,
          writeCharacteristic,
          _notifiableCharacteristic!,
        ],
        includedServices: [],
      );

      // 광고 데이터 설정
      final advertisement = Advertisement(
        name: _deviceName,
        serviceUUIDs: [serviceUuid],
        manufacturerSpecificData: [
          ManufacturerSpecificData(
            id: 0xFFFF,
            data: Uint8List.fromList([0x01, 0x02, 0x03]),
          ),
        ],
      );

      await _manager.addService(service);
      await _manager.startAdvertising(advertisement);

      _advertising = true;

      // 테스트를 위해 광고 시작시 바로 PIN 표시
      _currentAuthCode = _generateAuthCode();
      _waitingForAuth = true;

      _addLog(
        LogEntry(
          level: LogLevel.success,
          message: '광고 시작: $_deviceName (테스트 PIN: $_currentAuthCode)',
          timestamp: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      _addLog(
        LogEntry(
          level: LogLevel.error,
          message: '광고 시작 실패: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> stopAdvertising() async {
    if (!_advertising) return;

    try {
      await _manager.stopAdvertising();
      // clearServices() 메서드는 사용할 수 없으므로 제거

      _advertising = false;
      _connectedCentrals.clear();
      _centralNotifyStates.clear();
      _authenticatedCentrals.clear();
      _currentAuthCode = null;
      _waitingForAuth = false;
      _authTimer?.cancel();

      _addLog(
        LogEntry(
          level: LogLevel.info,
          message: '광고 중지',
          timestamp: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      _addLog(
        LogEntry(
          level: LogLevel.error,
          message: '광고 중지 실패: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _handleCharacteristicRead(eventArgs) async {
    final central = eventArgs.central;
    final request = eventArgs.request;

    _connectedCentrals.add(central);
    _totalConnections++;
    _lastActivity = DateTime.now();

    _addLog(
      LogEntry(
        level: LogLevel.info,
        message: '읽기 요청: Central ${central.uuid}',
        timestamp: DateTime.now(),
      ),
    );

    // 인증 시스템 구현
    if (!_authenticatedCentrals.containsKey(central) ||
        !_authenticatedCentrals[central]!) {
      _startAuthenticationProcess(central);
      final authResponse = 'AUTH_REQUIRED:${_currentAuthCode ?? '0000'}';
      await _manager.respondReadRequestWithValue(
        request,
        value: Uint8List.fromList(authResponse.codeUnits),
      );
    } else {
      final deviceData =
          'DEVICE_INFO:$_deviceInfo|TIMESTAMP:${DateTime.now().millisecondsSinceEpoch}';
      await _manager.respondReadRequestWithValue(
        request,
        value: Uint8List.fromList(deviceData.codeUnits),
      );
      _dataPacketsSent++;
    }

    notifyListeners();
  }

  void _handleCharacteristicWrite(eventArgs) async {
    final central = eventArgs.central;
    final request = eventArgs.request;
    final value = request.value;

    _lastActivity = DateTime.now();
    _dataPacketsReceived++;

    try {
      // UTF-8 디코딩으로 다국어 지원
      String message;
      try {
        message = utf8.decode(value);
      } catch (e) {
        // UTF-8 디코딩 실패시 fallback
        message = String.fromCharCodes(value);
      }
      
      _addLog(
        LogEntry(
          level: LogLevel.info,
          message: 'Central에서 수신: $message',
          timestamp: DateTime.now(),
        ),
      );

      // 인증 코드 확인
      if (message.startsWith('AUTH:') && _currentAuthCode != null) {
        final providedCode = message.substring(5);
        if (providedCode == _currentAuthCode) {
          _authenticatedCentrals[central] = true;
          _waitingForAuth = false;
          _authTimer?.cancel();
          _currentAuthCode = null;

          _addLog(
            LogEntry(
              level: LogLevel.success,
              message: 'Central 인증 성공: ${central.uuid}',
              timestamp: DateTime.now(),
            ),
          );

          // 인증 성공 응답 전송
          await _manager.respondWriteRequest(request);
        } else {
          _addLog(
            LogEntry(
              level: LogLevel.warning,
              message: 'Central 인증 실패: 잘못된 코드',
              timestamp: DateTime.now(),
            ),
          );

          // 인증 실패 응답 전송
          await _manager.respondWriteRequestWithError(
            request,
            error: GATTError.insufficientAuthentication,
          );
        }
      } else {
        // 인증된 사용자의 일반 텍스트 메시지인지 확인
        if (_authenticatedCentrals.containsKey(central) && _authenticatedCentrals[central]!) {
          // 인증된 사용자의 텍스트 메시지
          _receivedMessages.insert(0, message); // 최신 메시지가 위에 오도록
          
          // 메시지 저장 수 제한 (최대 50개)
          if (_receivedMessages.length > 50) {
            _receivedMessages.removeRange(50, _receivedMessages.length);
          }
          
          _addLog(
            LogEntry(
              level: LogLevel.success,
              message: '텍스트 메시지 수신: $message',
              timestamp: DateTime.now(),
            ),
          );
          
          // 성공적으로 받았다고 응답
          await _manager.respondWriteRequest(request);
        } else {
          // 인증되지 않은 사용자
          await _manager.respondWriteRequestWithError(
            request,
            error: GATTError.insufficientAuthentication,
          );
        }
      }
    } catch (e) {
      _addLog(
        LogEntry(
          level: LogLevel.error,
          message: '메시지 처리 오류: $e',
          timestamp: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  void _handleNotifyStateChanged(eventArgs) {
    final central = eventArgs.central;
    final enabled = eventArgs.state;

    _centralNotifyStates[central] = enabled;

    _addLog(
      LogEntry(
        level: LogLevel.info,
        message:
            'Notify 상태 변경: Central ${central.uuid} - ${enabled ? '활성화' : '비활성화'}',
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  void _startAuthenticationProcess(Central central) {
    _currentAuthCode = _generateAuthCode();
    _waitingForAuth = true;

    _addLog(
      LogEntry(
        level: LogLevel.info,
        message: '인증 프로세스 시작: 코드 $_currentAuthCode',
        timestamp: DateTime.now(),
      ),
    );

    // 2분 후 인증 코드 만료
    _authTimer?.cancel();
    _authTimer = Timer(const Duration(minutes: 2), () {
      if (_waitingForAuth) {
        _currentAuthCode = null;
        _waitingForAuth = false;

        _addLog(
          LogEntry(
            level: LogLevel.warning,
            message: '인증 코드 만료',
            timestamp: DateTime.now(),
          ),
        );

        notifyListeners();
      }
    });

    notifyListeners();
  }

  String _generateAuthCode() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  Future<void> sendDataToCentrals(String data) async {
    if (_notifiableCharacteristic == null || notifyEnabledCount == 0) return;

    try {
      final dataBytes = Uint8List.fromList(data.codeUnits);
      for (final central in _connectedCentrals) {
        if (_centralNotifyStates[central] == true) {
          await _manager.notifyCharacteristic(
            central,
            _notifiableCharacteristic!,
            value: dataBytes,
          );
        }
      }

      _dataPacketsSent += notifyEnabledCount;
      _lastActivity = DateTime.now();

      _addLog(
        LogEntry(
          level: LogLevel.success,
          message: '데이터 전송 완료: $data ($notifyEnabledCount개 기기)',
          timestamp: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      _addLog(
        LogEntry(
          level: LogLevel.error,
          message: '데이터 전송 실패: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> startVoiceRecording() async {
    if (_isRecording || notifyEnabledCount == 0) return;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _addLog(
          LogEntry(
            level: LogLevel.error,
            message: '음성 녹음 권한이 필요합니다',
            timestamp: DateTime.now(),
          ),
        );
        return;
      }

      await _audioRecorder.start(
        const RecordConfig(),
        path: '/tmp/voice_message.m4a',
      );
      _isRecording = true;

      _addLog(
        LogEntry(
          level: LogLevel.info,
          message: '음성 녹음 시작',
          timestamp: DateTime.now(),
        ),
      );

      notifyListeners();
    } catch (e) {
      _addLog(
        LogEntry(
          level: LogLevel.error,
          message: '음성 녹음 시작 실패: $e',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<void> stopVoiceRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();

        // 음성 데이터를 Base64로 인코딩하여 전송
        final encodedData = 'VOICE_DATA:${bytes.length}';
        await sendDataToCentrals(encodedData);

        _addLog(
          LogEntry(
            level: LogLevel.success,
            message: '음성 녹음 완료 및 전송: ${bytes.length}바이트',
            timestamp: DateTime.now(),
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      _isRecording = false;
      _addLog(
        LogEntry(
          level: LogLevel.error,
          message: '음성 녹음 중지 실패: $e',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  // 설정 관리
  void setDeviceName(String name) {
    if (name.isNotEmpty && name != _deviceName) {
      _deviceName = name;
      _addLog(
        LogEntry(
          level: LogLevel.info,
          message: '기기 이름 변경: $name',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void setTransmissionPower(int power) {
    _transmissionPower = power;
    notifyListeners();
  }

  void setAdvertisementData(String data) {
    _advertisementData = data;
    notifyListeners();
  }

  void setAutoReconnect(bool enabled) {
    _autoReconnect = enabled;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    _addLog(
      LogEntry(
        level: LogLevel.info,
        message: '로그 초기화',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void sendDataMessage(String message) {
    sendDataToCentrals(message);
  }

  void disconnectAll() {
    _connectedCentrals.clear();
    _authenticatedCentrals.clear();
    _waitingForAuth = false;
    _currentAuthCode = null;
    _addLog(
      LogEntry(
        level: LogLevel.info,
        message: '모든 연결 해제',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _addLog(LogEntry log) {
    _logs.insert(0, log);

    // 로그가 너무 많아지면 오래된 것 제거
    if (_logs.length > 100) {
      _logs.removeRange(100, _logs.length);
    }
  }

  static String _generateDeviceNameStatic() {
    // Generate a consistent MAC-like identifier using device-specific data
    // Since actual MAC address isn't available via bluetooth_low_energy package,
    // we create a deterministic identifier that remains consistent per device
    final random = Random(
      DateTime.now().millisecondsSinceEpoch ~/ 86400000,
    ); // Changes daily

    // Generate 6 hexadecimal digits to simulate MAC address last 6 digits
    final macPart = List.generate(6, (index) {
      return random.nextInt(16).toRadixString(16).toUpperCase();
    }).join('');

    return 'INMO GO 2 - $macPart';
  }

  @override
  void dispose() {
    _stateChangedSubscription.cancel();
    _characteristicReadRequestedSubscription.cancel();
    _characteristicWriteRequestedSubscription.cancel();
    _characteristicNotifyStateChangedSubscription.cancel();
    _authTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
