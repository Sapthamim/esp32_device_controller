import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../services/storage_service.dart';
import '../../states/device_provider.dart';
import '../../states/sensor_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // EXPORT SENSOR DATA

  Future<void> _exportData(BuildContext context) async {
    // Get the service before the first await.
    final storageService = context.read<StorageService>();

    try {
      final readings = await storageService.getAllSensorReadings();

      // Make sure the Settings screen still exists.
      if (!context.mounted) return;

      if (readings.isEmpty) {
        _showErrorSnackBar(context, 'No sensor data available to export.');
        return;
      }

      final csv = StringBuffer();

      // Only these three columns are exported.
      csv.writeln('temperature,humidity,timestamp');

      for (final reading in readings) {
        csv.writeln(
          '${reading.temperature},'
          '${reading.humidity},'
          '${reading.timestamp.toIso8601String()}',
        );
      }

      final fileName = 'sensor_data_${_formatDate(DateTime.now())}.csv';

      const channel = MethodChannel('esp32_controller/downloads');

      await channel.invokeMethod('saveToDownloads', {
        'fileName': fileName,
        'data': Uint8List.fromList(utf8.encode(csv.toString())),
      });

      // Check again after the second await.
      if (!context.mounted) return;

      _showSuccessSnackBar(context, 'Sensor data exported to Downloads.');
    } catch (e) {
      debugPrint('Export error: $e');

      if (!context.mounted) return;

      _showErrorSnackBar(context, 'Unable to export sensor data.');
    }
  }

  // FORMAT DATE

  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // CONNECT BLUETOOTH

  void _connectDevice(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.bleScan);
  }

  // DISCONNECT BLUETOOTH

  Future<void> _disconnectDevice(BuildContext context) async {
    final deviceProvider = context.read<DeviceProvider>();

    final shouldDisconnect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disconnect Device?'),
          content: Text(
            'Are you sure you want to disconnect '
            'from the ${deviceProvider.deviceName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );
    if (shouldDisconnect != true) {
      return;
    }

    if (!context.mounted) return;

    final sensorProvider = context.read<SensorProvider>();

    // STEP 1: STOP SENSOR MONITORING

    await sensorProvider.stopListening();

    if (!context.mounted) return;

    // STEP 2: DISCONNECT BLUETOOTH

    await deviceProvider.disconnect();

    if (!context.mounted) return;

    // STEP 3: CHECK DISCONNECTION RESULT

    if (deviceProvider.status == DeviceConnectionStatus.disconnected) {
      _showSuccessSnackBar(context, 'Bluetooth disconnected.');

      // Give the SnackBar a short moment to appear.
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) return;

      // STEP 4: GO TO BLUETOOTH SCANNING SCREEN

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.bleScan,
        (route) => false,
      );
    } else {
      _showErrorSnackBar(
        context,
        deviceProvider.errorMessage ?? 'Unable to disconnect Bluetooth.',
      );
    }
  }

  // ABOUT DIALOG

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('About ESP32 Controller'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESP32 Controller',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'A Flutter application for controlling '
                'and monitoring an ESP32 device through '
                'Bluetooth Low Energy.',
              ),
              SizedBox(height: 12),
              Text('Version 1.0.0'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // SUCCESS SNACKBAR

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ERROR SNACKBAR

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // BLUETOOTH BUTTON

  Widget _buildBluetoothButton(
    BuildContext context,
    DeviceProvider deviceProvider,
  ) {
    final connected = deviceProvider.isConnected;
    final connecting = deviceProvider.isConnecting;

    String buttonText;
    IconData buttonIcon;

    if (connecting) {
      buttonText = 'Connecting...';
      buttonIcon = Icons.bluetooth_searching;
    } else if (connected) {
      buttonText = 'Disconnect device';
      buttonIcon = Icons.bluetooth_disabled;
    } else {
      buttonText = 'Connect device';
      buttonIcon = Icons.bluetooth;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: connecting
            ? null
            : connected
            ? () {
                _disconnectDevice(context);
              }
            : () {
                _connectDevice(context);
              },
        icon: Icon(buttonIcon),
        label: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // SETTINGS CONTENT
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // DATA
                  const Text(
                    'Export Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Export all sensor readings as CSV'),
                      onTap: () {
                        _exportData(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ABOUT
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('App information'),
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // CONNECT / DISCONNECT BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBluetoothButton(context, deviceProvider),
            ),
          ],
        ),
      ),
    );
  }
}
