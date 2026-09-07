import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/device_provider.dart';
import '../../states/sensor_provider.dart';
import '../../states/wifi_provider.dart';
import '../../widgets/dashboard_widgets.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

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

              const SizedBox(height: 21),

              // BLUETOOTH / ESP32
              DeviceConnectionCard(
                connected: deviceProvider.isConnected,
                connecting: deviceProvider.isConnecting,
                deviceName: deviceProvider.connectedDeviceName,
              ),

              const SizedBox(height: 14),

              // WI-FI
              WifiStatusCard(
                connected:
                    wifiProvider.status == WifiConnectionStatus.connected,
                connectedSsid: wifiProvider.connectedSsid,
              ),

              const SizedBox(height: 25),

              // SENSOR DATA TITLE
              const Text(
                'Sensor Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              // TEMPERATURE
              SensorCard(
                title: 'Temperature',
                value: '${sensorData.temperature.toStringAsFixed(1)} °C',
                icon: Icons.thermostat,
                iconColor: Colors.orange,
                iconBackgroundColor: const Color(0xFFFFF4E5),
                isLive: sensorProvider.isListening,
              ),

              const SizedBox(height: 14),

              // HUMIDITY
              SensorCard(
                title: 'Humidity',
                value: '${sensorData.humidity.toStringAsFixed(1)} %',
                icon: Icons.water_drop,
                iconColor: const Color(0xFF2563EB),
                iconBackgroundColor: const Color(0xFFEFF6FF),
                isLive: sensorProvider.isListening,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
