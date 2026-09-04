import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/sensor_data.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

class SensorProvider extends ChangeNotifier {
  final BleService bleService;
  final StorageService storageService;

  SensorProvider({required this.bleService, required this.storageService}) {
    _loadSensorHistory();
  }

  SensorData _sensorData = SensorData.empty();

  final List<SensorData> _sensorHistory = [];

  StreamSubscription<String>? _sensorSubscription;

  Timer? _sensorReadTimer;

  bool _isListening = false;

  String? _errorMessage;

  // GETTERS

  SensorData get sensorData => _sensorData;

  List<SensorData> get sensorHistory => List.unmodifiable(_sensorHistory);

  bool get isListening => _isListening;

  String? get errorMessage => _errorMessage;

  // LOAD SAVED SENSOR HISTORY FROM SQLITE

  Future<void> _loadSensorHistory() async {
    try {
      final savedReadings = await storageService.getAllSensorReadings();

      _sensorHistory
        ..clear()
        ..addAll(savedReadings);

      if (savedReadings.isNotEmpty) {
        _sensorData = savedReadings.last;
      }

      debugPrint(
        'SensorProvider: Loaded '
        '${savedReadings.length} saved sensor readings.',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('SensorProvider: Unable to load sensor history: $e');
    }
  }

  // START SENSOR MONITORING

  Future<void> startListening() async {
    try {
      _errorMessage = null;

      // Cancel any existing subscription.
      await _sensorSubscription?.cancel();
      _sensorSubscription = null;

      // Cancel any existing read timer.
      _sensorReadTimer?.cancel();
      _sensorReadTimer = null;

      // Check BLE connection.
      if (!bleService.isConnected) {
        throw Exception('ESP32 is not connected.');
      }

      final supportsNotify = bleService.sensorSupportsNotify;

      final supportsRead = bleService.sensorSupportsRead;

      // NOTIFICATION MODE

      if (supportsNotify) {
        final sensorStream = bleService.dataStream;

        // dataStream is nullable, so check it first.
        if (sensorStream == null) {
          throw Exception('Sensor data stream is not available.');
        }

        _sensorSubscription = sensorStream.listen(
          _handleSensorData,
          onError: (error) {
            debugPrint('Sensor stream error: $error');

            _isListening = false;

            _errorMessage = 'Unable to receive sensor data.';

            notifyListeners();
          },
        );

        _isListening = true;

        debugPrint(
          'SensorProvider: Sensor notification '
          'listener started.',
        );

        notifyListeners();

        return;
      }

      // READ MODE

      if (supportsRead) {
        _isListening = true;

        notifyListeners();

        // Read immediately once.
        await _readSensorData();

        // Continue reading every 2 seconds.
        _sensorReadTimer = Timer.periodic(const Duration(seconds: 2), (
          _,
        ) async {
          await _readSensorData();
        });

        debugPrint('SensorProvider: Sensor read monitoring started.');

        return;
      }

      // NO SUPPORTED MODE

      throw Exception(
        'Sensor characteristic does not support '
        'Notify, Indicate, or Read.',
      );
    } catch (e) {
      debugPrint('Unable to start sensor monitoring: $e');

      _isListening = false;

      _errorMessage = 'Unable to start sensor monitoring.';

      notifyListeners();
    }
  }

  // READ SENSOR DATA

  Future<void> _readSensorData() async {
    if (!bleService.isConnected) {
      return;
    }

    try {
      final data = await bleService.readSensorData();

      if (data.isEmpty) {
        return;
      }

      final receivedData = utf8.decode(data, allowMalformed: true).trim();

      if (receivedData.isEmpty) {
        return;
      }

      _handleSensorData(receivedData);
    } catch (e) {
      debugPrint('Sensor read error: $e');
    }
  }

  // HANDLE DATA RECEIVED FROM ESP32

  Future<void> _handleSensorData(String receivedData) async {
    try {
      final data = receivedData.trim();

      if (data.isEmpty) {
        return;
      }

      debugPrint('SensorProvider received: $data');

      // Convert JSON string into Dart object.
      final dynamic decodedData = jsonDecode(data);

      // Make sure the JSON is an object.
      if (decodedData is! Map<String, dynamic>) {
        return;
      }

      // We only process packets containing
      // temperature or humidity.
      if (!decodedData.containsKey('temperature') &&
          !decodedData.containsKey('humidity')) {
        return;
      }

      // TEMPERATURE

      final temperature =
          (decodedData['temperature'] as num?)?.toDouble() ?? 0.0;

      // HUMIDITY

      final humidity = (decodedData['humidity'] as num?)?.toDouble() ?? 0.0;

      // PHONE TIMESTAMP

      final timestamp = DateTime.now();

      // CREATE SENSOR READING

      final reading = SensorData(
        temperature: temperature,
        humidity: humidity,

        // Pressure is not provided by the ESP32
        // and is not stored in SQLite/CSV.
        pressure: 0.0,

        timestamp: timestamp,
      );

      // UPDATE CURRENT SENSOR DATA

      _sensorData = reading;

      // Add the reading to the in-memory history.
      _sensorHistory.add(reading);

      // SAVE TO SQLITE

      await storageService.saveSensorReading(reading);

      debugPrint(
        'SensorProvider: Sensor reading '
        'saved to SQLite.',
      );

      // Tell the UI that new sensor data is available.
      notifyListeners();
    } catch (e) {
      debugPrint('Invalid ESP32 sensor packet: $e');
    }
  }

  // STOP SENSOR MONITORING

  Future<void> stopListening() async {
    // Stop periodic reads.
    _sensorReadTimer?.cancel();
    _sensorReadTimer = null;

    // Stop notification listener.
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;

    _isListening = false;

    debugPrint('SensorProvider: Sensor monitoring stopped.');

    notifyListeners();
  }

  // CLEAR SENSOR HISTORY

  Future<void> clearHistory() async {
    try {
      // Delete all readings from SQLite.
      await storageService.clearSensorReadings();

      // Delete readings from memory.
      _sensorHistory.clear();

      // Reset current sensor data.
      _sensorData = SensorData.empty();

      debugPrint('SensorProvider: Sensor history cleared.');

      notifyListeners();
    } catch (e) {
      debugPrint('SensorProvider: Unable to clear history: $e');
    }
  }

  // CLEAR ERROR

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // RESET

  void reset() {
    _sensorData = SensorData.empty();

    // Stop periodic reading.
    _sensorReadTimer?.cancel();
    _sensorReadTimer = null;

    // Stop notification subscription.
    _sensorSubscription?.cancel();
    _sensorSubscription = null;

    _isListening = false;

    _errorMessage = null;

    notifyListeners();
  }

  // DISPOSE

  @override
  void dispose() {
    _sensorReadTimer?.cancel();

    _sensorSubscription?.cancel();

    super.dispose();
  }
}
