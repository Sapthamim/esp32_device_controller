class WifiNetwork {
  final String ssid;
  final int signalStrength;
  final bool secured;

  const WifiNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.secured,
  });

  WifiNetwork copyWith({String? ssid, int? signalStrength, bool? secured}) {
    return WifiNetwork(
      ssid: ssid ?? this.ssid,
      signalStrength: signalStrength ?? this.signalStrength,
      secured: secured ?? this.secured,
    );
  }
}
