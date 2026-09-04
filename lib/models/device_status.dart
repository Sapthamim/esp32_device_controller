enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class DeviceStatus {
  //This stores the current connection state.
  final DeviceConnectionStatus connectionStatus;
  final String message;

  const DeviceStatus({required this.connectionStatus, this.message = ''});
  //This is a convenient way to check whether the ESP32 is connected
  bool get isConnected => connectionStatus == DeviceConnectionStatus.connected;

  bool get isConnecting =>
      connectionStatus == DeviceConnectionStatus.connecting;
  //This checks whether there is a connection error.
  bool get hasError => connectionStatus == DeviceConnectionStatus.error;
  //creates a new DeviceStatus object based on the existing one, while allowing you to change only the values you want.
  DeviceStatus copyWith({
    DeviceConnectionStatus? connectionStatus,
    String? message,
  }) {
    return DeviceStatus(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      message: message ?? this.message,
    );
  }
}
//copyWith() creates a new copy of the current DeviceStatus and lets you change only the fields you need, 
////while keeping the other fields unchanged.