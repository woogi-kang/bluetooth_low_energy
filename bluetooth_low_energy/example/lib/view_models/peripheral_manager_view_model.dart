import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:bluetooth_low_energy_example/models.dart';
import 'package:clover/clover.dart';
import 'package:logging/logging.dart';
import 'package:record/record.dart';

class PeripheralManagerViewModel extends ViewModel {
  final PeripheralManager _manager;
  final List<Log> _logs;
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
      _waitingForAuth = false {
    _stateChangedSubscription = _manager.stateChanged.listen((eventArgs) async {
      if (eventArgs.state == BluetoothLowEnergyState.unauthorized &&
          Platform.isAndroid) {
        await _manager.authorize();
      }
      notifyListeners();
    });
    _characteristicReadRequestedSubscription = _manager
        .characteristicReadRequested
        .listen((eventArgs) async {
          final central = eventArgs.central;
          final characteristic = eventArgs.characteristic;
          final request = eventArgs.request;
          final offset = request.offset;
          
          // Central 연결 추적
          _connectedCentrals.add(central);
          
          final log = Log(
            type: 'Characteristic read requested',
            message: '${central.uuid}, ${characteristic.uuid}, $offset',
          );
          _logs.add(log);
          notifyListeners();
          final elements = List.generate(100, (i) => i % 256);
          final value = Uint8List.fromList(elements);
          final trimmedValue = value.sublist(offset);
          await _manager.respondReadRequestWithValue(
            request,
            value: trimmedValue,
          );
        });
    _characteristicWriteRequestedSubscription = _manager
        .characteristicWriteRequested
        .listen((eventArgs) async {
          final central = eventArgs.central;
          final characteristic = eventArgs.characteristic;
          final request = eventArgs.request;
          final offset = request.offset;
          final value = request.value;
          
          // Central 연결 추적
          _connectedCentrals.add(central);
          
          // 데이터를 텍스트로 변환 시도
          String displayMessage;
          String? textData;
          try {
            textData = String.fromCharCodes(value);
            displayMessage = 'Central에서 받은 메시지: "$textData"';
          } catch (e) {
            displayMessage = '[${value.length}] ${central.uuid}, ${characteristic.uuid}, $offset, $value';
          }
          
          // 인증 코드 검증 처리
          if (textData != null && textData.startsWith('AUTH:') && _waitingForAuth) {
            final inputCode = textData.substring(5); // 'AUTH:' 제거
            if (_verifyAuthCode(inputCode)) {
              _completeAuthentication(central);
            } else {
              _failAuthentication(central, inputCode);
            }
          }
          
          final log = Log(
            type: 'Characteristic write requested',
            message: displayMessage,
          );
          _logs.add(log);
          notifyListeners();
          await _manager.respondWriteRequest(request);
        });
    _characteristicNotifyStateChangedSubscription = _manager
        .characteristicNotifyStateChanged
        .listen((eventArgs) async {
          final central = eventArgs.central;
          final characteristic = eventArgs.characteristic;
          final state = eventArgs.state;
          
          // Central 연결 추적 및 notify 상태 추적
          _connectedCentrals.add(central);
          _centralNotifyStates[central] = state;
          
          final log = Log(
            type: 'Characteristic notify state changed',
            message: '${central.uuid}, ${characteristic.uuid}, $state',
          );
          _logs.add(log);
          
          // Notify가 활성화되고 아직 인증되지 않은 경우 인증 시작
          if (state && !(_authenticatedCentrals[central] ?? false)) {
            _startAuthenticationForCentral(central);
          }
          
          notifyListeners();
          // Write someting to the central when notify started.
          if (state) {
            final maximumNotifyLength = await _manager.getMaximumNotifyLength(
              central,
            );
            final elements = List.generate(maximumNotifyLength, (i) => i % 256);
            final value = Uint8List.fromList(elements);
            await _manager.notifyCharacteristic(
              central,
              characteristic,
              value: value,
            );
          }
        });
  }

  BluetoothLowEnergyState get state => _manager.state;
  bool get advertising => _advertising;
  List<Log> get logs => _logs;
  int get connectedCentralsCount => _connectedCentrals.length;
  int get notifyEnabledCount => _centralNotifyStates.values.where((enabled) => enabled).length;
  String? get deviceInfo => _deviceInfo;
  bool get isRecording => _isRecording;

  Future<void> showAppSettings() async {
    await _manager.showAppSettings();
  }

  Future<void> startAdvertising() async {
    if (_advertising) {
      return;
    }
    await _manager.removeAllServices();
    final elements = List.generate(100, (i) => i % 256);
    final value = Uint8List.fromList(elements);
    final notifiableCharacteristic = GATTCharacteristic.mutable(
      uuid: UUID.short(201),
      properties: [
        GATTCharacteristicProperty.read,
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
        GATTCharacteristicProperty.notify,
        GATTCharacteristicProperty.indicate,
      ],
      permissions: [
        GATTCharacteristicPermission.read,
        GATTCharacteristicPermission.write,
      ],
      descriptors: [],
    );
    _notifiableCharacteristic = notifiableCharacteristic;
    
    final service = GATTService(
      uuid: UUID.short(100),
      isPrimary: true,
      includedServices: [],
      characteristics: [
        GATTCharacteristic.immutable(
          uuid: UUID.short(200),
          value: value,
          descriptors: [],
        ),
        notifiableCharacteristic,
      ],
    );
    await _manager.addService(service);
    final advertisement = Advertisement(
      name: Platform.isWindows ? null : 'BLE-12138',
      manufacturerSpecificData:
          Platform.isIOS || Platform.isMacOS
              ? []
              : [
                ManufacturerSpecificData(
                  id: 0x2e19,
                  data: Uint8List.fromList([0x01, 0x02, 0x03]),
                ),
              ],
    );
    await _manager.startAdvertising(advertisement);
    _advertising = true;
    
    // 기기 정보 설정
    final deviceName = advertisement.name ?? 'BLE-12138';
    _deviceInfo = '기기명: $deviceName';
    
    notifyListeners();
  }

  Future<void> stopAdvertising() async {
    if (!_advertising) {
      return;
    }
    await _manager.stopAdvertising();
    _advertising = false;
    _deviceInfo = null;
    _connectedCentrals.clear();
    _centralNotifyStates.clear();
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  Future<void> sendDataToCentrals(String text) async {
    if (_notifiableCharacteristic == null) {
      return;
    }
    
    final notifyEnabledCentrals = _centralNotifyStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key);
    
    if (notifyEnabledCentrals.isEmpty) {
      final log = Log(
        type: 'Send failed',
        message: 'Notify가 활성화된 Central이 없습니다',
      );
      _logs.add(log);
      notifyListeners();
      return;
    }
    
    final data = Uint8List.fromList(text.codeUnits);
    for (final central in notifyEnabledCentrals) {
      try {
        await _manager.notifyCharacteristic(
          central,
          _notifiableCharacteristic!,
          value: data,
        );
        final log = Log(
          type: 'Data sent to central',
          message: 'To ${central.uuid}: $text',
        );
        _logs.add(log);
      } catch (e) {
        final log = Log(
          type: 'Send failed',
          message: 'Failed to send to ${central.uuid}: $e',
        );
        _logs.add(log);
      }
    }
    notifyListeners();
  }

  Future<void> startVoiceRecording() async {
    if (_isRecording || _notifiableCharacteristic == null) {
      return;
    }
    
    // Notify가 활성화된 central이 있는지 확인
    final notifyEnabledCentrals = _centralNotifyStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key);
        
    if (notifyEnabledCentrals.isEmpty) {
      final log = Log(
        type: 'Voice recording',
        message: 'Central에서 Notify를 먼저 활성화해주세요',
      );
      _logs.add(log);
      notifyListeners();
      return;
    }

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        final log = Log(
          type: 'Voice recording',
          message: '음성 녹음 권한이 필요합니다',
        );
        _logs.add(log);
        notifyListeners();
        return;
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: '${Directory.systemTemp.path}/voice_recording.wav',
      );
      
      _isRecording = true;
      final log = Log(
        type: 'Voice recording',
        message: '음성 녹음 시작',
      );
      _logs.add(log);
      notifyListeners();
    } catch (e) {
      final log = Log(
        type: 'Voice recording error',
        message: '녹음 시작 실패: $e',
      );
      _logs.add(log);
      notifyListeners();
    }
  }

  Future<void> stopVoiceRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      
      if (path != null) {
        final log = Log(
          type: 'Voice recording',
          message: '음성 녹음 완료',
        );
        _logs.add(log);
        notifyListeners();
        
        // 음성 파일을 읽어서 200바이트 청크로 전송
        await _sendVoiceFile(path);
      }
    } catch (e) {
      _isRecording = false;
      final log = Log(
        type: 'Voice recording error',
        message: '녹음 중지 실패: $e',
      );
      _logs.add(log);
      notifyListeners();
    }
  }

  Future<void> _sendVoiceFile(String filePath) async {
    try {
      final file = File(filePath);
      final audioData = await file.readAsBytes();
      
      final log = Log(
        type: 'Voice transmission',
        message: '음성 데이터 전송 시작 (${audioData.length} bytes)',
      );
      _logs.add(log);
      notifyListeners();

      // 200바이트 청크로 분할 전송
      const chunkSize = 200;
      final totalChunks = (audioData.length / chunkSize).ceil();
      
      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize < audioData.length) 
            ? start + chunkSize 
            : audioData.length;
        final chunk = audioData.sublist(start, end);
        
        // Notify가 활성화된 central에게만 전송
        final notifyEnabledCentrals = _centralNotifyStates.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key);
            
        for (final central in notifyEnabledCentrals) {
          try {
            await _manager.notifyCharacteristic(
              central,
              _notifiableCharacteristic!,
              value: chunk,
            );
          } catch (e) {
            final log = Log(
              type: 'Voice transmission error',
              message: 'Chunk ${i + 1} 전송 실패 to ${central.uuid}: $e',
            );
            _logs.add(log);
            notifyListeners();
          }
        }
        
        // 전송 간격 조절 (선택사항)
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      final completeLog = Log(
        type: 'Voice transmission',
        message: '음성 데이터 전송 완료 ($totalChunks chunks)',
      );
      _logs.add(completeLog);
      notifyListeners();
      
      // 임시 파일 삭제
      await file.delete();
      
    } catch (e) {
      final log = Log(
        type: 'Voice transmission error',
        message: '음성 파일 처리 실패: $e',
      );
      _logs.add(log);
      notifyListeners();
    }
  }

  // 인증 시스템 관련 getter들
  String? get currentAuthCode => _currentAuthCode;
  bool get waitingForAuth => _waitingForAuth;
  bool get hasAuthenticatedCentrals => _authenticatedCentrals.values.any((auth) => auth);

  // 인증 코드 생성 (4자리 랜덤 숫자)
  String _generateAuthCode() {
    final random = Random();
    return (random.nextInt(9000) + 1000).toString();
  }

  // 새 연결에 대한 인증 시작
  void _startAuthenticationForCentral(Central central) {
    if (_currentAuthCode != null) return; // 이미 인증 진행 중
    
    _currentAuthCode = _generateAuthCode();
    _waitingForAuth = true;
    _authenticatedCentrals[central] = false;
    
    final log = Log(
      type: 'Authentication Started',
      message: 'Central ${central.uuid}에 대한 인증 시작됨. 코드: $_currentAuthCode',
    );
    _logs.add(log);
    
    // 2분 타이머 시작
    _authTimer?.cancel();
    _authTimer = Timer(const Duration(minutes: 2), () {
      _timeoutAuthentication(central);
    });
    
    // Notify 알림 전송 (인증 코드 포함)
    _sendAuthenticationNotification();
    
    notifyListeners();
  }

  // 인증 타임아웃 처리
  void _timeoutAuthentication(Central central) {
    final log = Log(
      type: 'Authentication Timeout',
      message: 'Central ${central.uuid} 인증 타임아웃 - 연결 해제',
    );
    _logs.add(log);
    
    _currentAuthCode = null;
    _waitingForAuth = false;
    _authenticatedCentrals.remove(central);
    _connectedCentrals.remove(central);
    _centralNotifyStates.remove(central);
    
    // 실제 연결 해제는 블루투스 스택에서 처리되므로 여기서는 상태만 업데이트
    notifyListeners();
  }

  // 인증 코드 확인
  bool _verifyAuthCode(String inputCode) {
    return _currentAuthCode == inputCode;
  }

  // 인증 완료 처리
  void _completeAuthentication(Central central) {
    _authenticatedCentrals[central] = true;
    _currentAuthCode = null;
    _waitingForAuth = false;
    _authTimer?.cancel();
    
    final log = Log(
      type: 'Authentication Completed',
      message: 'Central ${central.uuid} 인증 성공',
    );
    _logs.add(log);
    
    _sendAuthenticationNotification(); // 성공 알림
    notifyListeners();
  }

  // 인증 실패 처리
  void _failAuthentication(Central central, String inputCode) {
    final log = Log(
      type: 'Authentication Failed',
      message: 'Central ${central.uuid} 잘못된 코드: $inputCode (정답: $_currentAuthCode)',
    );
    _logs.add(log);
    
    // 실패해도 재시도 가능하도록 유지 (타임아웃까지)
    _sendAuthenticationNotification(); // 실패 알림
    notifyListeners();
  }

  // 인증 알림 전송
  Future<void> _sendAuthenticationNotification() async {
    if (_notifiableCharacteristic == null) return;
    
    String message;
    if (_waitingForAuth && _currentAuthCode != null) {
      message = 'AUTH_REQUIRED:$_currentAuthCode';
    } else if (hasAuthenticatedCentrals) {
      message = 'AUTH_SUCCESS';
    } else {
      message = 'AUTH_FAILED';
    }
    
    final value = Uint8List.fromList(message.codeUnits);
    await _sendNotificationToAllCentrals(value);
  }

  // 모든 연결된 Central에게 알림 전송
  Future<void> _sendNotificationToAllCentrals(Uint8List value) async {
    if (_notifiableCharacteristic == null) return;
    
    for (final central in _connectedCentrals) {
      if (_centralNotifyStates[central] == true) {
        try {
          await _manager.notifyCharacteristic(
            central,
            _notifiableCharacteristic!,
            value: value,
          );
        } catch (e) {
          final log = Log(
            type: 'Notification Error',
            message: 'Central ${central.uuid}에게 알림 전송 실패: $e',
          );
          _logs.add(log);
        }
      }
    }
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    _audioRecorder.dispose();
    _stateChangedSubscription.cancel();
    _characteristicReadRequestedSubscription.cancel();
    _characteristicWriteRequestedSubscription.cancel();
    _characteristicNotifyStateChangedSubscription.cancel();
    super.dispose();
  }
}
