class SensorData {
  final double temperature;
  final double humidity;
  final double pressure;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.timestamp,
  });

  factory SensorData.empty() {
    return SensorData(
      temperature: 0,
      humidity: 0,
      pressure: 0,
      timestamp: DateTime.now(),
    );
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? pressure,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
