import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/utils/ble_utils.dart';
import '../../states/device_provider.dart';

class DeviceInfoScreen extends StatelessWidget {
  final BluetoothDevice device;

  const DeviceInfoScreen({super.key, required this.device});

  Future<void> _connect(BuildContext context) async {
    final deviceProvider = context.read<DeviceProvider>();

    await deviceProvider.connect(device);

    if (!context.mounted) return;

    if (deviceProvider.isConnected) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deviceProvider.errorMessage ?? 'Unable to connect to ESP32.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    final deviceName = BleUtils.getDeviceName(device);
    final deviceId = BleUtils.getDeviceId(device);

    final isThisDeviceConnected =
        deviceProvider.isConnected &&
        deviceProvider.device?.remoteId == device.remoteId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text(
          'Device Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            // Device icon
            Center(
              child: Container(
                width: 120,
                height: 120,

                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.developer_board,
                  size: 70,
                  color: Color(0xFF155EEF),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Device name
            const Text(
              'Device Name',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 6),

            Text(
              deviceName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            // Device ID
            const Text(
              'Device ID',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),

              child: Text(deviceId, style: const TextStyle(fontSize: 14)),
            ),

            const SizedBox(height: 25),

            // Connection status
            const Text(
              'Connection Status',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: isThisDeviceConnected
                        ? Colors.green
                        : deviceProvider.isConnecting
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ),

                const SizedBox(width: 10),

                Text(
                  isThisDeviceConnected
                      ? 'Connected'
                      : deviceProvider.isConnecting
                      ? 'Connecting...'
                      : 'Disconnected',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,

                    color: isThisDeviceConnected
                        ? Colors.green
                        : deviceProvider.isConnecting
                        ? Colors.orange
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Connect button
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: deviceProvider.isConnecting || isThisDeviceConnected
                    ? null
                    : () => _connect(context),

                icon: Icon(
                  isThisDeviceConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                ),

                label: Text(
                  isThisDeviceConnected
                      ? 'Connected'
                      : deviceProvider.isConnecting
                      ? 'Connecting...'
                      : 'Connect to ESP32',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Disconnect button
            if (isThisDeviceConnected)
              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<DeviceProvider>().disconnect();
                  },

                  icon: const Icon(Icons.bluetooth_disabled),

                  label: const Text('Disconnect'),
                ),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
