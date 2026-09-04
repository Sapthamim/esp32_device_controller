class Esp32Device {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;

  const Esp32Device({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
  });

  Esp32Device copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnected,
  }) {
    return Esp32Device(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
