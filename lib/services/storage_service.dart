import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sensor_data.dart';

class StorageService {
  static const String _databaseName = 'esp32_controller.db';
  static const int _databaseVersion = 1;

  static const String _sensorTable = 'sensor_readings';

  Database? _database;
  // DATABASE
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_sensorTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            temperature REAL NOT NULL,
            humidity REAL NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // SAVE SENSOR READING
  Future<void> saveSensorReading(SensorData reading) async {
    final db = await database;

    await db.insert(_sensorTable, {
      'temperature': reading.temperature,
      'humidity': reading.humidity,
      'timestamp': reading.timestamp.toIso8601String(),
    });
  }

  // GET ALL SENSOR READINGS
  Future<List<SensorData>> getAllSensorReadings() async {
    final db = await database;

    final rows = await db.query(_sensorTable, orderBy: 'id ASC');

    return rows.map((row) {
      return SensorData(
        temperature: (row['temperature'] as num).toDouble(),
        humidity: (row['humidity'] as num).toDouble(),
        pressure: 0.0,
        timestamp: DateTime.parse(row['timestamp'] as String),
      );
    }).toList();
  }

  // DELETE ALL SENSOR DATA
  Future<void> clearSensorReadings() async {
    final db = await database;

    await db.delete(_sensorTable);
  }

  // CLOSE DATABASE
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
