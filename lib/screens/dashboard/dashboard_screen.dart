import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/device_provider.dart';
import '../../states/sensor_provider.dart';
import '../../states/wifi_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final sensorProvider = context.watch<SensorProvider>();
    final wifiProvider = context.watch<WifiProvider>();

    final sensorData = sensorProvider.sensorData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // BODY
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              const Text(
                'ESP32 Controller',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              // Text(
              //   deviceProvider.deviceId.isEmpty
              //       ? 'No device connected'
              //       : deviceProvider.deviceId,
              //   style: const TextStyle(
              //     color: Colors.grey,
              //     fontSize: 14,
              //   ),
              // ),
              const SizedBox(height: 15),

              // ESP32 CONNECTION
              _buildDeviceConnectionCard(context, deviceProvider),

              const SizedBox(height: 14),

              // WI-FI STATUS
              _buildWifiCard(wifiProvider),

              const SizedBox(height: 25),

              // SENSOR DATA TITLE
              const Text(
                'Sensor Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              // TEMPERATURE
              _buildTemperatureCard(
                sensorData.temperature,
                sensorProvider.isListening,
              ),

              const SizedBox(height: 14),

              // HUMIDITY
              _buildHumidityCard(
                sensorData.humidity,
                sensorProvider.isListening,
              ),

              // SENSOR ERROR
              // ======================================================
              if (sensorProvider.errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorCard(sensorProvider.errorMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DEVICE CONNECTION CARD
  // ============================================================

  Widget _buildDeviceConnectionCard(
    BuildContext context,
    DeviceProvider deviceProvider,
  ) {
    final connected = deviceProvider.isConnected;
    final connecting = deviceProvider.isConnecting;

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
          // --------------------------------------------------------
          // BLUETOOTH ICON
          // --------------------------------------------------------
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

          // DEVICE INFORMATION
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
                  deviceProvider.connectedDeviceName,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // CONNECTION STATUS ICON
          Icon(
            connected
                ? Icons.check_circle
                : connecting
                ? Icons.sync
                : Icons.cancel,
            color: connected
                ? Colors.green
                : connecting
                ? Colors.orange
                : Colors.grey,
          ),
        ],
      ),
    );
  }

  // WI-FI CARD

  Widget _buildWifiCard(WifiProvider wifiProvider) {
    final connected = wifiProvider.status == WifiConnectionStatus.connected;

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
          // WI-FI ICON
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

          // WI-FI INFORMATION
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
                  connected && wifiProvider.connectedSsid != null
                      ? wifiProvider.connectedSsid!
                      : 'Device Wi-Fi connection',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // WI-FI STATUS
          Icon(
            connected ? Icons.check_circle : Icons.cancel,
            color: connected ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  // TEMPERATURE CARD

  Widget _buildTemperatureCard(double temperature, bool isLive) {
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
              // TEMPERATURE ICON
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.thermostat,
                  color: Colors.orange,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  'Temperature',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              if (isLive) _buildLiveLabel(),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            '${temperature.toStringAsFixed(1)} °C',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // HUMIDITY CARD

  Widget _buildHumidityCard(double humidity, bool isLive) {
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
              // HUMIDITY ICON
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Color(0xFF2563EB),
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  'Humidity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              if (isLive) _buildLiveLabel(),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            '${humidity.toStringAsFixed(1)} %',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // LIVE LABEL

  Widget _buildLiveLabel() {
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

  // ERROR CARD

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),

          const SizedBox(width: 10),

          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}
