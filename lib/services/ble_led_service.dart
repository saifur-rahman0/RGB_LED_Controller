import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';
import '../protocol/elk_protocol.dart';

/// Connection states for the BLE controller
enum BleLedStatus {
  offline,
  scanning,
  connecting,
  reconnecting,
  connected,
}

/// Active software animated scenes
enum ActiveScene {
  none,
  cozyFire,
  cyberpunkPulse,
  oceanBreathe,
  rgbCycle,
}

/// Log entry for live hex packet inspection
class BleHexLogEntry {
  final DateTime timestamp;
  final String direction; // 'TX', 'RX', 'INFO', 'ERR'
  final String hexPayload;
  final String description;

  const BleHexLogEntry({
    required this.timestamp,
    required this.direction,
    required this.hexPayload,
    required this.description,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

/// Internal queued packet wrapper
class _QueuedBlePacket {
  final Uint8List bytes;
  final String description;

  _QueuedBlePacket(this.bytes, this.description);
}

/// Primary BLE LED controller service managing scan, connection,
/// 55ms coalescing throttling queue, hardware effects, software scenes,
/// and live hex telemetry.
class BleLedService extends ChangeNotifier {
  // Connection and device state
  BleLedStatus _status = BleLedStatus.offline;
  BleLedStatus get status => _status;

  final List<BleDevice> _scannedDevices = [];
  List<BleDevice> get scannedDevices => List.unmodifiable(_scannedDevices);

  BleDevice? _selectedDevice;
  BleDevice? get selectedDevice => _selectedDevice;

  String? _lastConnectedDeviceId;
  String? get lastConnectedDeviceId => _lastConnectedDeviceId;
  bool _isUserDisconnect = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Active GATT UUIDs
  String _activeServiceUuid = ElkProtocol.serviceUuid;
  String _activeCharUuid = ElkProtocol.writeCharacteristicUuid;

  // LED Light Controls
  bool _isPoweredOn = true;
  bool get isPoweredOn => _isPoweredOn;

  Color _currentColor = const Color(0xFFFF0055);
  Color get currentColor => _currentColor;

  int _currentBrightness = 100; // 1..100
  int get currentBrightness => _currentBrightness;

  int _currentEffectMode = 0x87; // 7-Color Crossfade
  int get currentEffectMode => _currentEffectMode;

  int _currentEffectSpeed = 50; // 1..100
  int get currentEffectSpeed => _currentEffectSpeed;

  // Software Scene Engine
  ActiveScene _activeScene = ActiveScene.none;
  ActiveScene get activeScene => _activeScene;
  Timer? _sceneTimer;
  double _sceneStep = 0.0;
  final Random _random = Random();

  // Custom User Swatches
  List<Color> _customSwatches = [
    const Color(0xFFFF0000), // Red
    const Color(0xFF00FF00), // Green
    const Color(0xFF0000FF), // Blue
    const Color(0xFFFF007F), // Neon Pink
    const Color(0xFF00F0FF), // Neon Cyan
    const Color(0xFFFFD700), // Gold
    const Color(0xFF8A2BE2), // Violet
    const Color(0xFFFFFFFF), // Pure White
  ];
  List<Color> get customSwatches => List.unmodifiable(_customSwatches);

  // System settings
  bool _autoConnectOnLaunch = true;
  bool get autoConnectOnLaunch => _autoConnectOnLaunch;

  bool _turnOffOnClose = false;
  bool get turnOffOnClose => _turnOffOnClose;

  // Throttled 55ms packet queue
  final Queue<_QueuedBlePacket> _discreteQueue = Queue<_QueuedBlePacket>();
  _QueuedBlePacket? _pendingStreamPacket;
  Timer? _throttleTimer;
  bool _isSending = false;
  static const Duration throttleDuration = Duration(milliseconds: 55);

  // Hex packet log
  final List<BleHexLogEntry> _hexLogs = [];
  List<BleHexLogEntry> get hexLogs => List.unmodifiable(_hexLogs);

  BleLedService() {
    _initService();
  }

  Future<void> _initService() async {
    _setupBleListeners();
    await _loadPreferences();

    if (_autoConnectOnLaunch) {
      logInfo('Auto-connect on launch enabled. Starting device scan...');
      startScan();
    }
  }

  // -------------------------------------------------------------
  // PREFERENCES PERSISTENCE
  // -------------------------------------------------------------
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoConnectOnLaunch = prefs.getBool('autoConnectOnLaunch') ?? true;
      _turnOffOnClose = prefs.getBool('turnOffOnClose') ?? false;

      final savedColorHex = prefs.getString('lastColorHex');
      if (savedColorHex != null && savedColorHex.isNotEmpty) {
        final parsed = int.tryParse(savedColorHex.replaceFirst('#', ''), radix: 16);
        if (parsed != null) {
          _currentColor = Color(0xFF000000 | parsed);
        }
      }

      _currentBrightness = (prefs.getInt('lastBrightness') ?? 100).clamp(1, 100);
      _lastConnectedDeviceId = prefs.getString('lastConnectedDeviceId');

      final savedSwatches = prefs.getStringList('customSwatches');
      if (savedSwatches != null && savedSwatches.isNotEmpty) {
        final loaded = <Color>[];
        for (final hex in savedSwatches) {
          final val = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
          if (val != null) {
            loaded.add(Color(0xFF000000 | val));
          }
        }
        if (loaded.isNotEmpty) {
          _customSwatches = loaded;
        }
      }
      notifyListeners();
    } catch (e) {
      logError('Failed to load preferences: $e');
    }
  }

  Future<void> setAutoConnectOnLaunch(bool value) async {
    _autoConnectOnLaunch = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoConnectOnLaunch', value);
  }

  Future<void> setTurnOffOnClose(bool value) async {
    _turnOffOnClose = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('turnOffOnClose', value);
  }

  Future<void> saveCustomSwatch(Color color) async {
    if (_customSwatches.any((c) => c.toARGB32() == color.toARGB32())) return;
    _customSwatches.insert(0, color);
    if (_customSwatches.length > 20) {
      _customSwatches.removeLast();
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final hexList = _customSwatches.map((c) {
      final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
      return '#$r$g$b'.toUpperCase();
    }).toList();
    await prefs.setStringList('customSwatches', hexList);
  }

  Future<void> removeCustomSwatch(Color color) async {
    _customSwatches.removeWhere((c) => c.toARGB32() == color.toARGB32());
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final hexList = _customSwatches.map((c) {
      final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
      return '#$r$g$b'.toUpperCase();
    }).toList();
    await prefs.setStringList('customSwatches', hexList);
  }

  Future<void> _persistLastColor(Color c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final r = (c.r * 255).toInt().toRadixString(16).padLeft(2, '0');
      final g = (c.g * 255).toInt().toRadixString(16).padLeft(2, '0');
      final b = (c.b * 255).toInt().toRadixString(16).padLeft(2, '0');
      await prefs.setString('lastColorHex', '#$r$g$b'.toUpperCase());
    } catch (_) {}
  }

  Future<void> _persistLastBrightness(int b) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastBrightness', b);
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // BLE SCANNING & SETUP
  // -------------------------------------------------------------
  void _setupBleListeners() {
    UniversalBle.onScanResult = (BleDevice device) {
      final existingIndex = _scannedDevices.indexWhere((d) => d.deviceId == device.deviceId);
      if (existingIndex >= 0) {
        _scannedDevices[existingIndex] = device;
      } else {
        _scannedDevices.add(device);
      }

      // Check if target device FF:FF:10:C5:29:1F, last connected device, or ELK-BLEDOM
      final isTargetMac = device.deviceId.toUpperCase() == ElkProtocol.targetDeviceAddress;
      final isLastDevice = _lastConnectedDeviceId != null && device.deviceId.toLowerCase() == _lastConnectedDeviceId!.toLowerCase();
      final isElkNamed = (device.name ?? '').toUpperCase().contains(ElkProtocol.targetDeviceNamePrefix);

      if (isTargetMac || (_selectedDevice == null && (isElkNamed || isLastDevice))) {
        _selectedDevice = device;
        logInfo('Discovered Target BLE Device: ${device.name ?? 'Unnamed'} [${device.deviceId}]');

        if (_autoConnectOnLaunch && _status != BleLedStatus.connected && _status != BleLedStatus.connecting) {
          logInfo('Auto-connecting to discovered target device [${device.deviceId}]...');
          connectDevice(device);
        }
      }

      notifyListeners();
    };

    UniversalBle.onConnectionChange = (BleConnectionChange change) {
      logInfo('BLE Connection Event: device=${change.deviceId}, connected=${change.isConnected}, error=${change.error ?? 'none'}');

      if (_selectedDevice != null && _selectedDevice!.deviceId.toLowerCase() == change.deviceId.toLowerCase()) {
        if (!change.isConnected) {
          if (!_isUserDisconnect) {
            _status = BleLedStatus.reconnecting;
            logError('Connection lost unexpectedly to ${change.deviceId}. Scheduling auto-reconnect...');
            _scheduleReconnect();
          } else {
            _status = BleLedStatus.offline;
          }
          notifyListeners();
        }
      }
    };
  }

  Future<void> startScan() async {
    try {
      _scannedDevices.clear();
      _status = BleLedStatus.scanning;
      logInfo('Starting WinRT BLE Scan for ELK-BLEDOM devices...');
      notifyListeners();

      await UniversalBle.startScan();

      // Stop scan after 12 seconds automatically to save radio resources
      Future.delayed(const Duration(seconds: 12), () {
        if (_status == BleLedStatus.scanning) {
          stopScan();
        }
      });
    } catch (e) {
      logError('Failed to start scan: $e');
      _status = BleLedStatus.offline;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
      if (_status == BleLedStatus.scanning) {
        _status = BleLedStatus.offline;
      }
      logInfo('BLE Scan stopped. ${_scannedDevices.length} devices found.');
      notifyListeners();
    } catch (e) {
      logError('Failed to stop scan: $e');
    }
  }

  void selectDevice(BleDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // CONNECTION & HANDSHAKE
  // -------------------------------------------------------------
  Future<void> connectDevice(BleDevice device) async {
    _reconnectTimer?.cancel();
    _isUserDisconnect = false;
    _selectedDevice = device;
    _status = BleLedStatus.connecting;
    notifyListeners();

    try {
      logInfo('Stopping active scan prior to connection...');
      await UniversalBle.stopScan();

      logInfo('Connecting to BLE peripheral [${device.deviceId}]...');
      await UniversalBle.connect(device.deviceId);

      logInfo('Discovering GATT services and characteristics...');
      final services = await UniversalBle.discoverServices(device.deviceId);

      // Search for ELK-BLEDOM service (0000fff0 / fff0) and characteristic (0000fff3 / fff3)
      String? matchedServiceUuid;
      String? matchedCharUuid;

      for (final service in services) {
        if (ElkProtocol.isServiceMatch(service.uuid)) {
          matchedServiceUuid = service.uuid;
          for (final char in service.characteristics) {
            if (ElkProtocol.isWriteCharMatch(char.uuid)) {
              matchedCharUuid = char.uuid;
              break;
            }
          }
          break;
        }
      }

      _activeServiceUuid = matchedServiceUuid ?? ElkProtocol.serviceUuid;
      _activeCharUuid = matchedCharUuid ?? ElkProtocol.writeCharacteristicUuid;

      logInfo('Resolved GATT: Service=$_activeServiceUuid, WriteChar=$_activeCharUuid');

      // Mandatory 300ms delay prior to Handshake packet
      logInfo('Waiting 300ms mandatory handshake delay...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Mandatory Handshake: 7E 07 83 02 01 01 01 00 EF
      final handshakePacket = ElkProtocol.handshake();
      logInfo('Sending mandatory initialization handshake: 7E 07 83 02 01 01 01 00 EF');
      await UniversalBle.write(
        device.deviceId,
        _activeServiceUuid,
        _activeCharUuid,
        handshakePacket,
        withoutResponse: true,
      );
      _logPacket(handshakePacket, 'Handshake (0x83 Init)');

      _status = BleLedStatus.connected;
      _reconnectAttempts = 0;
      logInfo('Successfully connected and authenticated with ${device.name ?? 'ELK-BLEDOM'}!');

      // Save as last connected device in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastConnectedDeviceId', device.deviceId);

      // Restore last known light state
      if (_isPoweredOn) {
        sendRgb(_currentColor);
        sendBrightness(_currentBrightness);
      }

      notifyListeners();
    } catch (e) {
      logError('Failed to connect to ${device.deviceId}: $e');
      _status = BleLedStatus.offline;
      notifyListeners();
    }
  }

  Future<void> disconnectDevice() async {
    _isUserDisconnect = true;
    _reconnectTimer?.cancel();
    stopScene();

    if (_selectedDevice != null) {
      try {
        logInfo('Disconnecting from [${_selectedDevice!.deviceId}]...');
        await UniversalBle.disconnect(_selectedDevice!.deviceId);
      } catch (e) {
        logError('Disconnect error: $e');
      }
    }

    _status = BleLedStatus.offline;
    _clearQueues();
    notifyListeners();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_isUserDisconnect || _selectedDevice == null) return;

    _reconnectAttempts++;
    final delaySeconds = _reconnectAttempts < 3 ? 2 : 4;
    logInfo('Auto-reconnect attempt #$_reconnectAttempts in $delaySeconds seconds...');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_status == BleLedStatus.reconnecting && _selectedDevice != null) {
        await connectDevice(_selectedDevice!);
      }
    });
  }

  // -------------------------------------------------------------
  // 55MS RATE-LIMITED / COALESCING PACKET QUEUE
  // -------------------------------------------------------------
  /// Enqueues a packet.
  /// If [isContinuous] is true (color wheel drags, brightness slider), intermediate
  /// packets coalesce and drop stale frames, sending only the freshest value.
  /// If [isContinuous] is false (power, effect mode switch, handshake), the packet
  /// is queued strictly in FIFO order.
  void enqueuePacket(Uint8List packet, String description, {bool isContinuous = false}) {
    if (isContinuous) {
      _pendingStreamPacket = _QueuedBlePacket(packet, description);
    } else {
      _discreteQueue.add(_QueuedBlePacket(packet, description));
    }

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _processNextPacket();
    }
  }

  void _processNextPacket() async {
    if (_isSending || _status != BleLedStatus.connected || _selectedDevice == null) {
      return;
    }

    _QueuedBlePacket? packetToSend;

    // Discrete critical commands take FIFO priority
    if (_discreteQueue.isNotEmpty) {
      packetToSend = _discreteQueue.removeFirst();
    } else if (_pendingStreamPacket != null) {
      packetToSend = _pendingStreamPacket;
      _pendingStreamPacket = null;
    }

    if (packetToSend == null) return;

    _isSending = true;
    try {
      await UniversalBle.write(
        _selectedDevice!.deviceId,
        _activeServiceUuid,
        _activeCharUuid,
        packetToSend.bytes,
        withoutResponse: true,
      );
      _logPacket(packetToSend.bytes, packetToSend.description);
    } catch (e) {
      logError('Write error: $e');
    } finally {
      _isSending = false;
    }

    // Schedule next dispatch after 55ms throttle window
    _throttleTimer = Timer(throttleDuration, () {
      _processNextPacket();
    });
  }

  void _clearQueues() {
    _discreteQueue.clear();
    _pendingStreamPacket = null;
    _throttleTimer?.cancel();
    _isSending = false;
  }

  // -------------------------------------------------------------
  // CONTROLLER COMMANDS
  // -------------------------------------------------------------
  /// Master Power ON
  void powerOn() {
    _isPoweredOn = true;
    final packet = ElkProtocol.powerOn();
    enqueuePacket(packet, 'Power ON', isContinuous: false);
    notifyListeners();
  }

  /// Master Power OFF
  void powerOff() {
    stopScene();
    _isPoweredOn = false;
    final packet = ElkProtocol.powerOff();
    enqueuePacket(packet, 'Power OFF', isContinuous: false);
    notifyListeners();
  }

  /// Set Solid RGB Color (coalesced 55ms)
  void sendRgb(Color color, {bool fromScene = false}) {
    if (!fromScene) {
      stopScene();
    }

    _currentColor = color;
    _isPoweredOn = true;

    final r = (color.r * 255).round().clamp(0, 255);
    final g = (color.g * 255).round().clamp(0, 255);
    final b = (color.b * 255).round().clamp(0, 255);

    final hexStr = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    final packet = ElkProtocol.setRgb(r, g, b);

    enqueuePacket(packet, 'Solid RGB: $hexStr', isContinuous: true);

    if (!fromScene) {
      _persistLastColor(color);
    }
    notifyListeners();
  }

  /// Set Brightness (1-100%, coalesced 55ms)
  void sendBrightness(int level) {
    _currentBrightness = level.clamp(1, 100);
    final packet = ElkProtocol.setBrightness(_currentBrightness);
    enqueuePacket(packet, 'Brightness: $_currentBrightness%', isContinuous: true);
    _persistLastBrightness(_currentBrightness);
    notifyListeners();
  }

  /// Set Built-in Hardware Effect Mode (0x80..0x9C, discrete FIFO)
  void sendHardwareEffect(int modeId) {
    stopScene();
    _currentEffectMode = modeId.clamp(0x80, 0x9C);
    _isPoweredOn = true;

    final effect = ElkEffectCatalog.getById(_currentEffectMode);
    final packet = ElkProtocol.setEffect(_currentEffectMode);
    enqueuePacket(packet, 'HW Effect: ${effect.name} (${effect.hexId})', isContinuous: false);
    notifyListeners();
  }

  /// Set Hardware Effect Speed (1-100%, coalesced 55ms)
  void sendEffectSpeed(int speed) {
    _currentEffectSpeed = speed.clamp(1, 100);
    final packet = ElkProtocol.setEffectSpeed(_currentEffectSpeed);
    enqueuePacket(packet, 'HW Effect Speed: $_currentEffectSpeed%', isContinuous: true);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // SOFTWARE ANIMATION SCENES
  // -------------------------------------------------------------
  void startScene(ActiveScene scene) {
    stopScene();
    _activeScene = scene;
    _sceneStep = 0.0;
    _isPoweredOn = true;

    // 65ms tick feeds cleanly into 55ms coalescing sender
    _sceneTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      _tickScene();
    });

    logInfo('Started software scene: ${_sceneName(scene)}');
    notifyListeners();
  }

  void stopScene() {
    if (_activeScene != ActiveScene.none) {
      _sceneTimer?.cancel();
      _sceneTimer = null;
      _activeScene = ActiveScene.none;
      logInfo('Software animation scene stopped.');
      notifyListeners();
    }
  }

  void _tickScene() {
    _sceneStep += 0.04;
    Color generatedColor;

    switch (_activeScene) {
      case ActiveScene.cozyFire:
        // Warm flame embers: Flicker between deep crimson orange and golden amber
        final flicker = _random.nextDouble() * 0.25;
        final r = (240 + (_random.nextDouble() * 15)).clamp(200, 255).toInt();
        final g = (45 + (_random.nextDouble() * 45) + (sin(_sceneStep * 2.5) * 15)).clamp(30, 110).toInt();
        final b = (_random.nextDouble() * 12).clamp(0, 15).toInt();
        generatedColor = Color.fromARGB(255, r, (g * (1.0 - flicker)).toInt(), b);
        break;

      case ActiveScene.cyberpunkPulse:
        // Neon Pink (#FF007F) to Electric Cyan (#00F0FF) to Deep Violet (#9D00FF)
        final t = (sin(_sceneStep * 1.8) + 1.0) / 2.0; // 0..1
        if (t < 0.5) {
          final factor = t * 2.0;
          generatedColor = Color.lerp(
            const Color(0xFFFF007F), // Neon Pink
            const Color(0xFF00F0FF), // Electric Cyan
            factor,
          )!;
        } else {
          final factor = (t - 0.5) * 2.0;
          generatedColor = Color.lerp(
            const Color(0xFF00F0FF), // Electric Cyan
            const Color(0xFF9D00FF), // Neon Violet
            factor,
          )!;
        }
        break;

      case ActiveScene.oceanBreathe:
        // Deep Sea Blue to Vivid Aqua wave
        final t = (sin(_sceneStep * 1.2) + 1.0) / 2.0; // 0..1
        generatedColor = Color.lerp(
          const Color(0xFF001F3F), // Deep Oceanic Navy
          const Color(0xFF00D2FF), // Vivid Aqua
          t,
        )!;
        break;

      case ActiveScene.rgbCycle:
        // Smooth 360-degree HSV rainbow rotation
        final hue = (_sceneStep * 60.0) % 360.0;
        generatedColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        break;

      case ActiveScene.none:
        return;
    }

    sendRgb(generatedColor, fromScene: true);
  }

  String _sceneName(ActiveScene s) {
    switch (s) {
      case ActiveScene.cozyFire:
        return 'Cozy Fire';
      case ActiveScene.cyberpunkPulse:
        return 'Cyberpunk Pulse';
      case ActiveScene.oceanBreathe:
        return 'Ocean Breathe';
      case ActiveScene.rgbCycle:
        return 'RGB Cycle';
      case ActiveScene.none:
        return 'None';
    }
  }

  // -------------------------------------------------------------
  // HEX TELEMETRY LOGGING
  // -------------------------------------------------------------
  void _logPacket(Uint8List bytes, String description) {
    final entry = BleHexLogEntry(
      timestamp: DateTime.now(),
      direction: 'TX',
      hexPayload: ElkProtocol.formatHex(bytes),
      description: description,
    );
    _appendLog(entry);
  }

  void logInfo(String message) {
    final entry = BleHexLogEntry(
      timestamp: DateTime.now(),
      direction: 'INFO',
      hexPayload: '',
      description: message,
    );
    _appendLog(entry);
  }

  void logError(String message) {
    final entry = BleHexLogEntry(
      timestamp: DateTime.now(),
      direction: 'ERR',
      hexPayload: '',
      description: message,
    );
    _appendLog(entry);
  }

  void _appendLog(BleHexLogEntry entry) {
    _hexLogs.insert(0, entry);
    if (_hexLogs.length > 250) {
      _hexLogs.removeLast();
    }
    notifyListeners();
  }

  void clearLogs() {
    _hexLogs.clear();
    notifyListeners();
  }

  String getAllLogsAsText() {
    final buffer = StringBuffer();
    for (final log in _hexLogs.reversed) {
      if (log.hexPayload.isNotEmpty) {
        buffer.writeln('[${log.timeFormatted}] [${log.direction}] ${log.hexPayload} -- ${log.description}');
      } else {
        buffer.writeln('[${log.timeFormatted}] [${log.direction}] ${log.description}');
      }
    }
    return buffer.toString();
  }

  /// Called when the desktop window is closing
  Future<void> handleAppClose() async {
    if (_turnOffOnClose && _status == BleLedStatus.connected && _selectedDevice != null) {
      try {
        final offPacket = ElkProtocol.powerOff();
        await UniversalBle.write(
          _selectedDevice!.deviceId,
          _activeServiceUuid,
          _activeCharUuid,
          offPacket,
          withoutResponse: true,
        );
        // Allow brief dispatch window
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _throttleTimer?.cancel();
    _sceneTimer?.cancel();
    super.dispose();
  }
}
