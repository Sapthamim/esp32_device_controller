import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/ble_service.dart';

// DEVICE CONNECTION STATUS

enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

// DEVICE PROVIDER

class DeviceProvider extends ChangeNotifier {
  final BleService bleService;

  DeviceProvider({required this.bleService});

  // PRIVATE STATE

  BluetoothDevice? _device;

  DeviceConnectionStatus _status = DeviceConnectionStatus.disconnected;

  String? _errorMessage;

  int? _rssi;

  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  Timer? _connectionCheckTimer;

  bool _checkingConnection = false;

  // Used by HomeScreen to show the reconnect SnackBar.
  bool _unexpectedDisconnect = false;

  // GETTERS

  BluetoothDevice? get device => _device;

  DeviceConnectionStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get isConnected => _status == DeviceConnectionStatus.connected;

  bool get isConnecting => _status == DeviceConnectionStatus.connecting;

  bool get isDisconnecting => _status == DeviceConnectionStatus.disconnecting;

  bool get hasError => _status == DeviceConnectionStatus.error;

  int? get rssi => _rssi;

  bool get unexpectedDisconnect => _unexpectedDisconnect;

  // SIGNAL STRENGTH

  String get signalStrength {
    if (_rssi == null) {
      return '-- dBm';
    }

    return '$_rssi dBm';
  }

  // DEVICE NAME

  String connectedDeviceName = '';

  String get deviceName {
    if (_device == null) {
      return '';
    }

    final name = _device!.platformName.trim();

    return name;
  }

  // DEVICE ID

  //String get deviceId {
  //  return _device?.remoteId.str ?? '';
  //  }

  // LISTEN FOR BLE CONNECTION STATE

  void _listenToConnectionState(BluetoothDevice device) {
    _connectionStateSubscription?.cancel();

    _connectionStateSubscription = null;

    debugPrint('DEVICE: Starting Bluetooth connection-state listener.');

    _connectionStateSubscription = device.connectionState.listen(
      (connectionState) {
        debugPrint(
          'DEVICE: Bluetooth connection state changed: '
          '$connectionState',
        );

        // CONNECTED

        if (connectionState == BluetoothConnectionState.connected) {
          if (_status == DeviceConnectionStatus.connecting) {
            return;
          }

          if (_status == DeviceConnectionStatus.disconnecting) {
            return;
          }

          _status = DeviceConnectionStatus.connected;

          _errorMessage = null;

          notifyListeners();

          return;
        }

        // DISCONNECTED

        if (connectionState == BluetoothConnectionState.disconnected) {
          _handleDisconnected();
        }
      },
      onError: (error) {
        debugPrint('DEVICE: Connection state error: $error');
      },
    );
  }

  // HANDLE DISCONNECTED

  void _handleDisconnected() {
    // INTENTIONAL DISCONNECT

    if (_status == DeviceConnectionStatus.disconnecting) {
      debugPrint('DEVICE: Intentional Bluetooth disconnection.');

      _stopConnectionMonitoring();

      _device = null;
      _rssi = null;

      _status = DeviceConnectionStatus.disconnected;

      _errorMessage = null;
      _unexpectedDisconnect = false;

      notifyListeners();

      return;
    }

    // UNEXPECTED DISCONNECT

    if (_status == DeviceConnectionStatus.connected) {
      debugPrint('DEVICE: Unexpected Bluetooth connection lost.');

      _stopConnectionMonitoring();

      _device = null;
      _rssi = null;

      _status = DeviceConnectionStatus.disconnected;

      _errorMessage = 'Bluetooth connection lost.';

      _unexpectedDisconnect = true;

      notifyListeners();

      return;
    }

    // NORMAL DISCONNECTED STATE

    _stopConnectionMonitoring();

    _device = null;
    _rssi = null;

    _status = DeviceConnectionStatus.disconnected;

    notifyListeners();
  }

  // START ACTIVE CONNECTION CHECK

  void _startConnectionMonitoring(BluetoothDevice device) {
    _connectionCheckTimer?.cancel();

    _checkingConnection = false;

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 1), (
      _,
    ) async {
      if (_status != DeviceConnectionStatus.connected) {
        return;
      }

      if (_checkingConnection) {
        return;
      }

      _checkingConnection = true;

      try {
        final currentRssi = await device.readRssi();

        if (_status == DeviceConnectionStatus.connected) {
          _rssi = currentRssi;

          notifyListeners();
        }
      } catch (e) {
        debugPrint('DEVICE: BLE heartbeat failed: $e');

        if (_status == DeviceConnectionStatus.connected) {
          _handleDisconnected();
        }
      } finally {
        _checkingConnection = false;
      }
    });
  }

  // STOP CONNECTION MONITORING

  void _stopConnectionMonitoring() {
    _connectionCheckTimer?.cancel();

    _connectionCheckTimer = null;

    _checkingConnection = false;
  }

  // CLEAR UNEXPECTED DISCONNECT

  void clearUnexpectedDisconnect() {
    _unexpectedDisconnect = false;

    if (_errorMessage == 'Bluetooth connection lost.') {
      _errorMessage = null;
    }
  }

  // CONNECT TO ESP32

  Future<void> connect(BluetoothDevice device, {int? rssi}) async {
    // SAVE DEVICE INFORMATION

    _status = DeviceConnectionStatus.connecting;

    _errorMessage = null;
    _unexpectedDisconnect = false;

    notifyListeners();

    // LISTEN BEFORE CONNECTING

    _listenToConnectionState(device);

    // DEBUG

    debugPrint('────────────────────────────────');
    debugPrint('DEVICE: Starting connection...');
    debugPrint('DEVICE NAME: ${device.platformName}');
    debugPrint('DEVICE ID: ${device.remoteId.str}');
    debugPrint('DEVICE RSSI: $rssi dBm');
    debugPrint('────────────────────────────────');

    // CONNECT

    try {
      await bleService.connect(device);

      // if (device.isConnected) {
      //   _device = device;
      //   _rssi = rssi;
      // }

      debugPrint('DEVICE: BLE connection successful.');

      debugPrint('DEVICE: Services discovered successfully.');

      _device = device;
      _rssi = rssi;

      connectedDeviceName = _device!.advName;
      notifyListeners();

      _status = DeviceConnectionStatus.connected;

      _errorMessage = null;
      _unexpectedDisconnect = false;

      // Start active BLE monitoring.
      _startConnectionMonitoring(device);

      debugPrint('DEVICE: Device is now CONNECTED.');
    } catch (e) {
      debugPrint('────────────────────────────────');
      debugPrint('DEVICE CONNECTION ERROR:');
      debugPrint('$e');
      debugPrint('────────────────────────────────');

      _stopConnectionMonitoring();

      _status = DeviceConnectionStatus.error;

      _errorMessage = 'Connection failed: $e';

      _device = null;
      _rssi = null;
      _unexpectedDisconnect = false;
    }

    notifyListeners();
  }

  // DISCONNECT FROM ESP32

  Future<void> disconnect() async {
    // PREVENT DUPLICATE DISCONNECT

    if (_status == DeviceConnectionStatus.disconnecting) {
      return;
    }

    // ALREADY DISCONNECTED

    if (_device == null && !bleService.isConnected) {
      _stopConnectionMonitoring();

      _status = DeviceConnectionStatus.disconnected;

      _errorMessage = null;
      _unexpectedDisconnect = false;

      notifyListeners();

      return;
    }

    // SET DISCONNECTING

    _status = DeviceConnectionStatus.disconnecting;

    _errorMessage = null;
    _unexpectedDisconnect = false;

    _stopConnectionMonitoring();

    notifyListeners();

    debugPrint('DEVICE: Disconnecting...');

    // DISCONNECT

    try {
      await bleService.disconnect();

      _device = null;
      _rssi = null;

      _status = DeviceConnectionStatus.disconnected;

      _errorMessage = null;
      _unexpectedDisconnect = false;

      debugPrint('DEVICE: Disconnected successfully.');
    } catch (e) {
      debugPrint('DEVICE DISCONNECT ERROR: $e');

      _status = DeviceConnectionStatus.error;

      _errorMessage = 'Unable to disconnect from ESP32.';
    }

    notifyListeners();
  }

  // UPDATE RSSI

  void updateRssi(int rssi) {
    _rssi = rssi;

    notifyListeners();
  }

  // CLEAR ERROR

  void clearError() {
    _errorMessage = null;

    if (_status == DeviceConnectionStatus.error) {
      _status = DeviceConnectionStatus.disconnected;
    }

    notifyListeners();
  }

  // RESET PROVIDER

  void reset() {
    _connectionStateSubscription?.cancel();

    _connectionStateSubscription = null;

    _stopConnectionMonitoring();

    _device = null;
    _rssi = null;

    _status = DeviceConnectionStatus.disconnected;

    _errorMessage = null;
    _unexpectedDisconnect = false;

    notifyListeners();
  }

  // DISPOSE

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();

    _connectionStateSubscription = null;

    _stopConnectionMonitoring();

    super.dispose();
  }
}
