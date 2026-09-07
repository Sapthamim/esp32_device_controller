import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../models/wifi_network.dart';
import '../services/ble_service.dart';

enum WifiConnectionStatus { disconnected, waiting, connected, failed }

class WifiProvider extends ChangeNotifier {
  final BleService bleService;

  WifiProvider({required this.bleService});

  // WI-FI SCAN

  List<WifiNetwork> _networks = [];

  bool _isScanning = false;

  String? _selectedSsid;

  // ESP32 WI-FI CONNECTION

  String? _connectedSsid;

  String? _pendingSsid;

  WifiConnectionStatus _status = WifiConnectionStatus.disconnected;

  String? _errorMessage;

  StreamSubscription<String>? _wifiStatusSubscription;

  // GETTERS

  List<WifiNetwork> get networks => List.unmodifiable(_networks);

  bool get isScanning => _isScanning;

  String? get selectedSsid => _selectedSsid;

  String? get connectedSsid => _connectedSsid;

  WifiConnectionStatus get status => _status;

  bool get isConnecting => _status == WifiConnectionStatus.waiting;

  bool get isConnected => _status == WifiConnectionStatus.connected;

  String? get errorMessage => _errorMessage;

  // INITIALIZE WIFI STATUS LISTENER

  Future<void> initializeWifiListener() async {
    await _wifiStatusSubscription?.cancel();

    _wifiStatusSubscription = null;

    final stream = bleService.dataStream;

    if (stream == null) {
      debugPrint('WifiProvider: DATA stream is not available yet.');
      return;
    }

    _wifiStatusSubscription = stream.listen(
      _handleDataFromEsp32,
      onError: (error) {
        debugPrint('WifiProvider: ESP32 Wi-Fi data stream error: $error');
      },
    );

    debugPrint('WifiProvider: ESP32 Wi-Fi status listener initialized.');
  }

  // RECEIVE DATA FROM ESP32

  void _handleDataFromEsp32(String message) {
    try {
      final text = message.trim();

      if (text.isEmpty) {
        return;
      }

      debugPrint('WifiProvider received from ESP32: $text');

      final dynamic decoded = jsonDecode(text);

      if (decoded is! Map) {
        return;
      }

      // ESP32 WIFI MESSAGE

      final wifiMessage = decoded['message']?.toString();

      if (wifiMessage != null) {
        final lower = wifiMessage.toLowerCase();

        // WIFI CONNECTED

        if (lower.contains('successfully connected')) {
          debugPrint('WifiProvider: ESP32 confirmed Wi-Fi connection.');

          _handleWifiConnected();

          return;
        }

        // WIFI FAILED

        if (lower.contains('failed to connect')) {
          debugPrint('WifiProvider: ESP32 reported Wi-Fi connection failure.');

          _handleWifiFailed();

          return;
        }
      }

      // SENSOR PACKET WIFI STATUS

      final wifiConnected = decoded['wifi_connected'];

      if (wifiConnected is bool) {
        if (wifiConnected) {
          debugPrint('WifiProvider: wifi_connected = true');

          _handleWifiConnected();
        }

        return;
      }
    } catch (e) {
      debugPrint('WifiProvider: Unable to process ESP32 data: $e');
    }
  }

  // WIFI CONNECTED

  void _handleWifiConnected() {
    final network = _pendingSsid ?? _selectedSsid;

    if (network == null || network.trim().isEmpty) {
      debugPrint(
        'WifiProvider: ESP32 reported Wi-Fi connected, '
        'but no pending SSID exists.',
      );

      return;
    }

    final newSsid = network.trim();

    // Ignore duplicate confirmations.

    if (_status == WifiConnectionStatus.connected &&
        _connectedSsid == newSsid) {
      debugPrint(
        'WifiProvider: Wi-Fi is already connected. '
        'Ignoring duplicate confirmation.',
      );

      return;
    }

    _connectedSsid = newSsid;

    _pendingSsid = null;

    _status = WifiConnectionStatus.connected;

    _errorMessage = null;

    debugPrint('====================================');

    debugPrint('WifiProvider: ESP32 WI-FI CONNECTED');

    debugPrint('SSID: $_connectedSsid');

    debugPrint('====================================');

    notifyListeners();
  }

  // WIFI CONNECTION FAILED

  void _handleWifiFailed() {
    // Ignore duplicate failure messages
    if (_status == WifiConnectionStatus.failed) {
      debugPrint('WifiProvider: Wi-Fi failure already handled.');
      return;
    }

    // Clear the selected Wi-Fi network
    // so it returns to its normal color.
    _selectedSsid = null;

    _connectedSsid = null;
    _pendingSsid = null;

    _status = WifiConnectionStatus.failed;

    _errorMessage = 'Incorrect Wi-Fi password or connection failed.';

    debugPrint('WifiProvider: Wi-Fi connection failed.');

    notifyListeners();
  }

  // SCAN WIFI NETWORKS

  Future<void> scanNetworks() async {
    // Prevent multiple scans at the same time.

    if (_isScanning) {
      return;
    }

    // Clear previous scan results immediately.
    //
    // This means old networks will not remain visible
    // while the new scan is running.

    _networks = [];

    _isScanning = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final canStart = await WiFiScan.instance.canStartScan(
        askPermissions: true,
      );

      if (canStart != CanStartScan.yes) {
        _isScanning = false;

        _errorMessage = 'Unable to scan for Wi-Fi networks.';

        notifyListeners();

        return;
      }

      await WiFiScan.instance.startScan();

      await Future.delayed(const Duration(seconds: 2));

      final canGet = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );

      if (canGet != CanGetScannedResults.yes) {
        _isScanning = false;

        _errorMessage = 'Unable to get Wi-Fi networks.';

        notifyListeners();

        return;
      }

      final accessPoints = await WiFiScan.instance.getScannedResults();

      final Map<String, WifiNetwork> uniqueNetworks = {};

      for (final accessPoint in accessPoints) {
        final ssid = accessPoint.ssid.trim();

        if (ssid.isEmpty) {
          continue;
        }

        uniqueNetworks[ssid] = WifiNetwork(
          ssid: ssid,
          signalStrength: accessPoint.level,
          secured: _isSecured(accessPoint),
        );
      }

      _networks = uniqueNetworks.values.toList();

      // Strongest Wi-Fi first.

      _networks.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

      _isScanning = false;

      notifyListeners();
    } catch (e) {
      debugPrint('WifiProvider: Wi-Fi scan error: $e');

      _isScanning = false;

      _errorMessage = 'Unable to scan for Wi-Fi networks.';

      notifyListeners();
    }
  }

  // CHECK WIFI SECURITY

  bool _isSecured(WiFiAccessPoint accessPoint) {
    final capabilities = accessPoint.capabilities.toLowerCase();

    if (capabilities.isEmpty) {
      return true;
    }

    return capabilities.contains('wpa') ||
        capabilities.contains('wpa2') ||
        capabilities.contains('wpa3') ||
        capabilities.contains('wep') ||
        capabilities.contains('psk') ||
        capabilities.contains('sae');
  }

  // SELECT NETWORK

  void selectNetwork(String ssid) {
    _selectedSsid = ssid;

    _errorMessage = null;

    notifyListeners();
  }

  // CONNECT TO WIFI

  Future<void> connectToWifi({
    required String ssid,
    required String password,
  }) async {
    if (!bleService.isConnected) {
      _status = WifiConnectionStatus.failed;

      _errorMessage = 'Connect the ESP32 through BLE first.';

      notifyListeners();

      return;
    }

    // The listener must be ready before
    // sending credentials.

    await initializeWifiListener();

    // Reset state for this connection attempt.

    _selectedSsid = ssid;

    _pendingSsid = ssid;

    _connectedSsid = null;

    _status = WifiConnectionStatus.waiting;

    _errorMessage = null;

    notifyListeners();

    debugPrint('====================================');

    debugPrint('WifiProvider: STARTING WI-FI CONNECTION');

    debugPrint('SSID: $ssid');

    debugPrint('Status: WAITING');

    debugPrint('====================================');

    try {
      await bleService.sendWifiCredentials(ssid: ssid, password: password);

      debugPrint('WifiProvider: Wi-Fi credentials sent to ESP32.');

      if (_status == WifiConnectionStatus.waiting) {
        debugPrint('WifiProvider: Waiting for ESP32 Wi-Fi result...');
      }
    } catch (e) {
      debugPrint('WifiProvider: Wi-Fi credential error: $e');

      _pendingSsid = null;

      _connectedSsid = null;

      _status = WifiConnectionStatus.failed;

      _errorMessage = 'Unable to send Wi-Fi credentials to ESP32.';

      notifyListeners();
    }
  }

  // MANUAL WIFI CONNECTED

  void wifiConnected({String? ssid}) {
    final network = ssid ?? _pendingSsid;

    if (network == null || network.trim().isEmpty) {
      return;
    }

    final newSsid = network.trim();

    if (_status == WifiConnectionStatus.connected &&
        _connectedSsid == newSsid) {
      return;
    }

    _connectedSsid = newSsid;

    _pendingSsid = null;

    _status = WifiConnectionStatus.connected;

    _errorMessage = null;

    notifyListeners();
  }

  // MANUAL WIFI CONNECTION FAILED

  void wifiConnectionFailed() {
    _handleWifiFailed();
  }

  // DISCONNECT WIFI

  void disconnect() {
    _connectedSsid = null;

    _pendingSsid = null;

    _selectedSsid = null;

    _status = WifiConnectionStatus.disconnected;

    _errorMessage = null;

    notifyListeners();
  }

  // CLEAR ERROR

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // RESET

  void reset() {
    _networks = [];

    _isScanning = false;

    _selectedSsid = null;

    _connectedSsid = null;

    _pendingSsid = null;

    _status = WifiConnectionStatus.disconnected;

    _errorMessage = null;

    notifyListeners();
  }

  // DISPOSE

  @override
  void dispose() {
    _wifiStatusSubscription?.cancel();

    _wifiStatusSubscription = null;

    super.dispose();
  }
}
