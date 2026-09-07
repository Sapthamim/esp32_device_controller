import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/constants/app_constants.dart';

class BleService {
  BluetoothDevice? _connectedDevice;

  BluetoothCharacteristic? _sensorCharacteristic;

  BluetoothCharacteristic? _wifiCharacteristic;

  // SCAN RESULTS

  Stream<List<ScanResult>> get scanResults {
    return FlutterBluePlus.onScanResults;
  }

  Stream<bool> get isScanning {
    return FlutterBluePlus.isScanning;
  }

  // BLUETOOTH SUPPORT

  Future<bool> isBluetoothSupported() async {
    return FlutterBluePlus.isSupported;
  }

  // START BLE SCAN

  Future<void> startScan() async {
    await stopScan();

    await FlutterBluePlus.startScan(timeout: AppConstants.bleScanDuration);
  }

  // STOP BLE SCAN

  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  // CONNECTED DEVICE

  BluetoothDevice? get connectedDevice {
    return _connectedDevice;
  }

  bool get isConnected {
    return _connectedDevice != null;
  }

  // CONNECT TO ESP32

  Future<void> connect(BluetoothDevice device) async {
    debugPrint('====================================');
    debugPrint('Connecting to ESP32...');
    debugPrint('Device: ${device.remoteId}');
    debugPrint('====================================');

    // If another device is connected,
    // disconnect it first.
    if (_connectedDevice != null &&
        _connectedDevice!.remoteId != device.remoteId) {
      await disconnect();
    }

    _connectedDevice = device;

    try {
      // CONNECT TO ESP32

      if (!device.isConnected) {
        await device.connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 15),
          autoConnect: false,
        );
      }

      debugPrint('BLE connection established.');

      // DISCOVER SERVICES

      await _discoverServices(device);

      await enableSensorNotifications();

      debugPrint('ESP32 BLE setup completed.');
    } catch (e) {
      debugPrint('ESP32 BLE connection error: $e');

      await _clearConnection();

      rethrow;
    }
  }

  // DISCOVER ESP32 SERVICES

  Future<void> _discoverServices(BluetoothDevice device) async {
    debugPrint('Discovering BLE services...');

    List<BluetoothService> services;

    try {
      services = await device.discoverServices();
    } catch (e) {
      debugPrint('First service discovery failed: $e');

      // Small retry delay.
      await Future.delayed(const Duration(milliseconds: 500));

      services = await device.discoverServices();
    }

    _sensorCharacteristic = null;
    _wifiCharacteristic = null;

    final expectedServiceUuid = AppConstants.esp32ServiceUuid.toLowerCase();

    final expectedSensorUuid = AppConstants.sensorCharacteristicUuid
        .toLowerCase();

    final expectedWifiUuid = AppConstants.wifiCharacteristicUuid.toLowerCase();

    debugPrint(
      'Expected SERVICE UUID: '
      '$expectedServiceUuid',
    );

    debugPrint(
      'Expected DATA UUID: '
      '$expectedSensorUuid',
    );

    debugPrint(
      'Expected WIFI UUID: '
      '$expectedWifiUuid',
    );

    // SEARCH SERVICES

    for (final service in services) {
      final serviceUuid = service.uuid.toString().toLowerCase();

      debugPrint('FOUND SERVICE: $serviceUuid');

      if (serviceUuid != expectedServiceUuid) {
        continue;
      }

      debugPrint('ESP32 SERVICE FOUND.');

      // SEARCH CHARACTERISTICS

      for (final characteristic in service.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();

        debugPrint(
          'FOUND CHARACTERISTIC: $uuid\n'
          '  read: '
          '${characteristic.properties.read}\n'
          '  write: '
          '${characteristic.properties.write}\n'
          '  writeWithoutResponse: '
          '${characteristic.properties.writeWithoutResponse}\n'
          '  notify: '
          '${characteristic.properties.notify}\n'
          '  indicate: '
          '${characteristic.properties.indicate}',
        );

        // DATA UUID

        if (uuid == expectedSensorUuid) {
          _sensorCharacteristic = characteristic;

          debugPrint('>>> DATA_UUID FOUND');
        }

        // WIFI UUID

        if (uuid == expectedWifiUuid) {
          _wifiCharacteristic = characteristic;

          debugPrint('>>> WIFI_UUID FOUND');
        }
      }
    }

    debugPrint(
      'DATA CHARACTERISTIC FOUND: '
      '${_sensorCharacteristic != null}',
    );

    debugPrint(
      'WIFI CHARACTERISTIC FOUND: '
      '${_wifiCharacteristic != null}',
    );

    // DATA CHARACTERISTIC REQUIRED

    if (_sensorCharacteristic == null) {
      throw Exception(
        'ESP32 DATA characteristic not found.\n'
        'Expected: $expectedSensorUuid',
      );
    }

    // WIFI CHARACTERISTIC REQUIRED

    if (_wifiCharacteristic == null) {
      throw Exception(
        'ESP32 WIFI characteristic not found.\n'
        'Expected: $expectedWifiUuid',
      );
    }

    // WIFI CHARACTERISTIC MUST SUPPORT WRITE

    if (!_wifiCharacteristic!.properties.write &&
        !_wifiCharacteristic!.properties.writeWithoutResponse) {
      throw Exception(
        'ESP32 WIFI characteristic '
        'does not support writing.',
      );
    }

    debugPrint('All required ESP32 characteristics found.');
  }

  // DISCONNECT

  Future<void> disconnect() async {
    debugPrint('====================================');
    debugPrint('BLE: Disconnecting ESP32...');
    debugPrint('====================================');

    final device = _connectedDevice;

    try {
      await disableSensorNotifications().timeout(const Duration(seconds: 2));

      debugPrint('BLE: DATA notifications disabled.');
    } catch (e) {
      debugPrint('BLE: Unable to disable DATA notifications: $e');
    }

    await _clearConnection();

    if (device != null) {
      try {
        await device.disconnect().timeout(const Duration(seconds: 3));

        debugPrint('BLE: ESP32 disconnected successfully.');
      } catch (e) {
        debugPrint(
          'BLE: Device disconnect timed out '
          'or failed: $e',
        );

        // We still consider the app-side connection
        // cleared because _clearConnection() already
        // ran above.
      }
    } else {
      debugPrint('BLE: No device to disconnect.');
    }

    debugPrint('BLE: Disconnect process completed.');
  }

  // CLEAR CONNECTION

  Future<void> _clearConnection() async {
    _connectedDevice = null;

    _sensorCharacteristic = null;

    _wifiCharacteristic = null;
  }

  // SENSOR / DATA CHARACTERISTIC

  BluetoothCharacteristic? get sensorCharacteristic {
    return _sensorCharacteristic;
  }

  bool get hasSensorCharacteristic {
    return _sensorCharacteristic != null;
  }

  bool get sensorSupportsNotify {
    final characteristic = _sensorCharacteristic;

    if (characteristic == null) {
      return false;
    }

    return characteristic.properties.notify ||
        characteristic.properties.indicate;
  }

  bool get sensorSupportsRead {
    final characteristic = _sensorCharacteristic;

    if (characteristic == null) {
      return false;
    }

    return characteristic.properties.read;
  }

  // SENSOR / DATA NOTIFICATION STREAM

  Stream<List<int>>? get sensorNotifications {
    final characteristic = _sensorCharacteristic;

    if (characteristic == null) {
      return null;
    }

    return characteristic.onValueReceived;
  }

  Stream<String>? get dataStream {
    final stream = sensorNotifications;

    if (stream == null) {
      return null;
    }

    return stream.map((data) => utf8.decode(data, allowMalformed: true));
  }

  // WIFI STATUS STREAM

  // Wi-Fi status also comes through DATA_UUID.

  Stream<String>? get wifiStatusStream {
    return dataStream;
  }

  // ENABLE SENSOR / DATA NOTIFICATIONS

  Future<void> enableSensorNotifications() async {
    final characteristic = _sensorCharacteristic;

    if (characteristic == null) {
      throw Exception('DATA characteristic not found.');
    }

    debugPrint('Enabling DATA_UUID notifications...');

    debugPrint(
      'notify='
      '${characteristic.properties.notify}',
    );

    debugPrint(
      'indicate='
      '${characteristic.properties.indicate}',
    );

    debugPrint(
      'read='
      '${characteristic.properties.read}',
    );

    // NOTIFY / INDICATE

    if (characteristic.properties.notify ||
        characteristic.properties.indicate) {
      try {
        await characteristic.setNotifyValue(true);

        debugPrint('DATA_UUID notifications enabled.');

        return;
      } catch (e) {
        debugPrint('Notification enable failed: $e');

        // Continue to READ fallback if available.
      }
    }

    // READ FALLBACK

    if (characteristic.properties.read) {
      debugPrint('DATA_UUID will use READ mode.');

      return;
    }

    throw Exception(
      'DATA characteristic does not support '
      'Read, Notify, or Indicate.',
    );
  }

  // DISABLE SENSOR / DATA NOTIFICATIONS

  Future<void> disableSensorNotifications() async {
    final characteristic = _sensorCharacteristic;

    if (characteristic == null) {
      return;
    }

    if (!characteristic.properties.notify &&
        !characteristic.properties.indicate) {
      return;
    }

    try {
      if (characteristic.isNotifying) {
        await characteristic.setNotifyValue(false);

        debugPrint('DATA_UUID notifications disabled.');
      }
    } catch (e) {
      debugPrint('Unable to disable notifications: $e');

      // Do not rethrow.
      //
      // Disconnect should continue even if
      // notification disabling fails.
    }
  }

  // READ SENSOR DATA

  Future<List<int>> readSensorData() async {
    final characteristic = _sensorCharacteristic;

    if (characteristic == null) {
      throw Exception('DATA characteristic not found.');
    }

    if (!characteristic.properties.read) {
      throw Exception(
        'DATA characteristic does not '
        'support reading.',
      );
    }

    final data = await characteristic.read();

    debugPrint(
      'DATA READ: '
      '${utf8.decode(data, allowMalformed: true)}',
    );

    return data;
  }

  // WIFI CHARACTERISTIC

  BluetoothCharacteristic? get wifiCharacteristic {
    return _wifiCharacteristic;
  }

  bool get hasWifiCharacteristic {
    return _wifiCharacteristic != null;
  }

  bool get wifiSupportsWrite {
    final characteristic = _wifiCharacteristic;

    if (characteristic == null) {
      return false;
    }

    return characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
  }

  // SEND WIFI CREDENTIALS

  //
  // ESP32 expects:
  //
  // SSID|PASSWORD
  //
  // Example:
  //
  // IOT|MyPassword123
  //
  // NOT JSON.

  Future<void> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    final characteristic = _wifiCharacteristic;

    if (characteristic == null) {
      throw Exception('Wi-Fi characteristic not found.');
    }

    final canWrite =
        characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;

    if (!canWrite) {
      throw Exception(
        'Wi-Fi characteristic does not '
        'support writing.',
      );
    }

    if (ssid.trim().isEmpty) {
      throw Exception('Wi-Fi SSID cannot be empty.');
    }

    // IMPORTANT

    // ESP32 firmware expects:

    // SSID|PASSWORD

    final credentials = '$ssid|$password';

    debugPrint('------------------------------------');

    debugPrint('Sending Wi-Fi credentials to ESP32');

    debugPrint('SSID: $ssid');

    // Never print the real password.
    debugPrint('Password: ********');

    debugPrint('Payload: $ssid|********');

    debugPrint(
      'Payload length: '
      '${utf8.encode(credentials).length}',
    );

    debugPrint('------------------------------------');

    try {
      // WRITE WITH RESPONSE

      //
      // ESP32 WIFI_UUID supports PROPERTY_WRITE.

      if (characteristic.properties.write) {
        try {
          await characteristic.write(
            utf8.encode(credentials),
            withoutResponse: false,
          );

          debugPrint(
            'Wi-Fi credentials written '
            'successfully.',
          );

          return;
        } catch (e) {
          final error = e.toString();

          debugPrint(
            'BLE write with response failed: '
            '$error',
          );

          // IMPORTANT

          // ESP32 performs WiFi.begin() directly
          // inside onWrite().

          // Android can therefore sometimes wait for
          // the GATT write response while ESP32 is
          // busy connecting to Wi-Fi.

          // If this is a timeout, do NOT immediately
          // report Wi-Fi failure.

          // The real result will arrive through
          // DATA_UUID.

          if (_isBleTimeout(error)) {
            debugPrint(
              'BLE write timed out while ESP32 '
              'may still be processing the request.',
            );

            debugPrint(
              'Waiting for ESP32 Wi-Fi result '
              'through DATA_UUID.',
            );

            return;
          }

          // FALLBACK:
          // WRITE WITHOUT RESPONSE

          if (characteristic.properties.writeWithoutResponse) {
            try {
              await characteristic.write(
                utf8.encode(credentials),
                withoutResponse: true,
              );

              debugPrint(
                'Wi-Fi credentials sent using '
                'writeWithoutResponse.',
              );

              return;
            } catch (fallbackError) {
              debugPrint(
                'Fallback Wi-Fi write failed: '
                '$fallbackError',
              );

              rethrow;
            }
          }

          rethrow;
        }
      }

      // WRITE WITHOUT RESPONSE

      if (characteristic.properties.writeWithoutResponse) {
        await characteristic.write(
          utf8.encode(credentials),
          withoutResponse: true,
        );

        debugPrint(
          'Wi-Fi credentials sent using '
          'writeWithoutResponse.',
        );

        return;
      }

      throw Exception('Wi-Fi characteristic cannot be written.');
    } catch (e) {
      debugPrint('Wi-Fi credential WRITE failed: $e');

      rethrow;
    }
  }

  // CHECK BLE TIMEOUT

  bool _isBleTimeout(String error) {
    final value = error.toLowerCase();

    return value.contains('timed out') ||
        value.contains('timeout') ||
        value.contains('timed out after');
  }

  Future<void> enableWifiNotifications() async {
    debugPrint('Wi-Fi status uses DATA_UUID.');

    await enableSensorNotifications();
  }

  // DISABLE WIFI STATUS

  Future<void> disableWifiNotifications() async {}

  BluetoothCharacteristic? get controlCharacteristic {
    return null;
  }

  Future<void> sendCommand(String command) async {
    debugPrint(
      'Control command ignored because the '
      'current ESP32 firmware does not have '
      'a control characteristic: $command',
    );
  }

  // DISPOSE

  Future<void> disposeService() async {
    await disconnect();
  }
}
