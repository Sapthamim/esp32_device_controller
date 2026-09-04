import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/ble_service.dart';

class BleProvider extends ChangeNotifier {
  final BleService bleService;

  BleProvider({required this.bleService}) {
    _listenToBleService();
  }
  // STATE

  bool _isScanning = false;

  List<ScanResult> _scanResults = [];

  String? _errorMessage;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  StreamSubscription<bool>? _scanningSubscription;
  // GETTERS

  bool get isScanning => _isScanning;

  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  String? get errorMessage => _errorMessage;
  // LISTEN TO BLE SERVICE

  void _listenToBleService() {
    _scanSubscription = bleService.scanResults.listen(
      _handleScanResults,
      onError: (error) {
        debugPrint('BLE PROVIDER: Scan stream error: $error');

        _isScanning = false;

        _errorMessage = 'Unable to scan for BLE devices.';

        notifyListeners();
      },
    );

    _scanningSubscription = bleService.isScanning.listen((scanning) {
      debugPrint('BLE PROVIDER: isScanning = $scanning');

      _isScanning = scanning;

      notifyListeners();
    });
  }
  // HANDLE SCAN RESULTS

  void _handleScanResults(List<ScanResult> results) {
    debugPrint('BLE PROVIDER: Received ${results.length} scan results.');

    final Map<String, ScanResult> devices = {};

    for (final result in results) {
      final device = result.device;

      final name = device.platformName.trim();

      final id = device.remoteId.str;

      debugPrint(
        'BLE PROVIDER: Found device '
        'name="$name", id="$id", RSSI=${result.rssi}',
      );

      // Ignore devices that have no name.
      if (name.isEmpty) {
        continue;
      }

      devices[id] = result;
    }

    _scanResults = devices.values.toList();

    notifyListeners();
  }

  // START BLE SCAN
  Future<void> startScan() async {
    try {
      debugPrint('====================================');

      debugPrint('BLE PROVIDER: START SCAN');

      debugPrint('====================================');

      _errorMessage = null;

      _scanResults = [];

      notifyListeners();
      // CHECK BLUETOOTH SUPPORT
      debugPrint('BLE PROVIDER: Checking Bluetooth support...');

      final supported = await bleService.isBluetoothSupported();

      debugPrint('BLE PROVIDER: Bluetooth supported = $supported');

      if (!supported) {
        _isScanning = false;

        _errorMessage = 'Bluetooth Low Energy is not supported.';

        notifyListeners();

        return;
      }
      // CHECK BLUETOOTH STATE

      debugPrint('BLE PROVIDER: Checking Bluetooth state...');

      final adapterState = await FlutterBluePlus.adapterState.first;

      debugPrint('BLE PROVIDER: Bluetooth state = $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        _isScanning = false;

        _errorMessage = 'Please turn on Bluetooth and try again.';

        notifyListeners();

        return;
      }
      // START SCAN

      debugPrint('BLE PROVIDER: Calling BleService.startScan()...');

      await bleService.startScan();

      debugPrint('BLE PROVIDER: BleService.startScan() completed.');
    } catch (e) {
      debugPrint('====================================');

      debugPrint('BLE PROVIDER: START SCAN ERROR');

      debugPrint('$e');

      debugPrint('====================================');

      _isScanning = false;

      _errorMessage = 'Unable to start BLE scan: $e';

      notifyListeners();
    }
  }

  // STOP BLE SCAN
  Future<void> stopScan() async {
    try {
      debugPrint('BLE PROVIDER: STOP SCAN');

      await bleService.stopScan();

      _isScanning = false;

      notifyListeners();
    } catch (e) {
      debugPrint('BLE PROVIDER: Stop scan error: $e');

      _isScanning = false;

      _errorMessage = 'Unable to stop BLE scan.';

      notifyListeners();
    }
  }

  // CLEAR RESULTS
  void clearResults() {
    _scanResults = [];

    _errorMessage = null;

    notifyListeners();
  }
  // CLEAR ERROR

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // DISPOSE

  @override
  void dispose() {
    _scanSubscription?.cancel();

    _scanningSubscription?.cancel();

    super.dispose();
  }
}
