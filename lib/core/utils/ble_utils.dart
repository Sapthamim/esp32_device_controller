import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleUtils {
  // Get a readable BLE device name.
  static String getDeviceName(BluetoothDevice device) {
    final name = device.platformName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Unknown BLE Device';
  }

  // Get the unique BLE device ID.
  static String getDeviceId(BluetoothDevice device) {
    return device.remoteId.str;
  }

  // Format RSSI signal strength.
  static String formatSignalStrength(int rssi) {
    return '$rssi dBm';
  }

  // Check whether the BLE signal is reasonably strong.
  static bool isGoodSignal(int rssi) {
    return rssi >= -70;
  }

  // Convert RSSI into a simple signal label.
  static String getSignalLabel(int rssi) {
    if (rssi >= -50) {
      return 'Excellent';
    }

    if (rssi >= -60) {
      return 'Good';
    }

    if (rssi >= -70) {
      return 'Fair';
    }

    return 'Weak';
  }
}
