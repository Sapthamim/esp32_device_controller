import 'package:flutter/material.dart';

// DEVICE CONNECTION CARD

class DeviceConnectionCard extends StatelessWidget {
  final bool connected;
  final bool connecting;
  final String deviceName;

  const DeviceConnectionCard({
    super.key,
    required this.connected,
    required this.connecting,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFEFFAF2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: connected ? const Color(0xFFB7E4C7) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFFDDF7E5)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: connected
                  ? Colors.green.shade700
                  : const Color(0xFF155EEF),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? 'Device Connected'
                      : connecting
                      ? 'Connecting...'
                      : 'Device Disconnected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  deviceName,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WI-FI STATUS CARD

class WifiStatusCard extends StatelessWidget {
  final bool connected;
  final String? connectedSsid;

  const WifiStatusCard({
    super.key,
    required this.connected,
    required this.connectedSsid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFEFFAF2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: connected ? const Color(0xFFB7E4C7) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFFDDF7E5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              connected ? Icons.wifi : Icons.wifi_off,
              color: connected ? Colors.green.shade700 : Colors.grey.shade600,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wi-Fi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  connected && connectedSsid != null
                      ? connectedSsid!
                      : 'Device Wi-Fi connection',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SENSOR CARD

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isLive;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 29),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (isLive) const LiveLabel(),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            value,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// LIVE LABEL

class LiveLabel extends StatelessWidget {
  const LiveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }
}
