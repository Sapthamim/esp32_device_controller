class AppConstants {
  static const String appName = 'ESP32 Controller';

  static const Duration bleScanDuration = Duration(seconds: 5);

  static const String defaultDeviceName = 'ESP32_CONTROLLER';

  // ESP32 BLE Service
  static const String esp32ServiceUuid = '12345678-1234-1234-1234-123456789000';

  // ESP32 Sensor / Data characteristic
  static const String sensorCharacteristicUuid =
      '12345678-1234-1234-1234-123456789001';

  // ESP32 Wi-Fi characteristic
  static const String wifiCharacteristicUuid =
      '12345678-1234-1234-1234-123456789002';
}
