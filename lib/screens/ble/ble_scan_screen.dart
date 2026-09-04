import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/utils/ble_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../states/ble_provider.dart';
import '../../states/device_provider.dart';
import '../../states/sensor_provider.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  String? _connectingDeviceName;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<BleProvider>().startScan();
    });
  }

  Future<void> _selectDevice(ScanResult result) async {
    if (_isConnecting) return;

    final bleProvider = context.read<BleProvider>();
    final deviceProvider = context.read<DeviceProvider>();
    final sensorProvider = context.read<SensorProvider>();

    final device = result.device;
    final deviceName = BleUtils.getDeviceName(device);
    final rssi = result.rssi;

    setState(() {
      _connectingDeviceName = deviceName;
      _isConnecting = true;
    });

    await bleProvider.stopScan();

    if (!mounted) return;

    // --------------------------------------------------
    // OLD CONNECTING SNACKBAR
    // --------------------------------------------------
    /*
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Connecting to $deviceName...',
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 15),
      ),
    );
    */

    // --------------------------------------------------
    // CONNECT TO ESP32
    // --------------------------------------------------

    await deviceProvider.connect(device, rssi: rssi);

    if (!mounted) return;

    // --------------------------------------------------
    // CONNECTION FAILED
    // --------------------------------------------------

    if (!deviceProvider.isConnected) {
      setState(() {
        _connectingDeviceName = null;
        _isConnecting = false;
      });

      // Hide old connecting SnackBar if it is enabled later.
      // ScaffoldMessenger.of(context).hideCurrentSnackBar();

      SnackbarUtils.showError(
        context,
        deviceProvider.errorMessage ?? 'Unable to connect to device.',
      );

      return;
    }

    // --------------------------------------------------
    // CONNECTION SUCCESSFUL
    // --------------------------------------------------

    // Hide old connecting SnackBar if it is enabled later.
    // ScaffoldMessenger.of(context).hideCurrentSnackBar();

    await sensorProvider.startListening();

    if (!mounted) return;

    setState(() {
      _connectingDeviceName = null;
      _isConnecting = false;
    });

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = context.watch<BleProvider>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --------------------------------------------------
              // BLUETOOTH ICON
              // --------------------------------------------------
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth,
                  size: 65,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // TITLE
              // --------------------------------------------------
              Text(
                bleProvider.isScanning
                    ? 'Scanning for BLE Devices...'
                    : 'Scan for BLE Devices',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // DESCRIPTION
              // --------------------------------------------------
              Text(
                bleProvider.isScanning
                    ? 'Please wait while we search for nearby devices.'
                    : 'Make sure your device is powered on and nearby.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // SCANNING PROGRESS
              // --------------------------------------------------
              if (bleProvider.isScanning) const LinearProgressIndicator(),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // CONNECTING STATUS BOX
              // --------------------------------------------------
              if (_isConnecting && _connectingDeviceName != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connecting to $_connectingDeviceName...',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
              ],

              // --------------------------------------------------
              // AVAILABLE DEVICES
              // --------------------------------------------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Devices (${bleProvider.scanResults.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // DEVICE LIST
              // --------------------------------------------------
              Expanded(
                child: bleProvider.scanResults.isEmpty
                    ? _buildEmptyState(bleProvider.isScanning)
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: bleProvider.scanResults.length,
                        itemBuilder: (context, index) {
                          final result = bleProvider.scanResults[index];

                          return _buildDeviceCard(result);
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // SCAN BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : bleProvider.isScanning
                      ? () {
                          context.read<BleProvider>().stopScan();
                        }
                      : () {
                          context.read<BleProvider>().startScan();
                        },
                  icon: Icon(
                    bleProvider.isScanning
                        ? Icons.stop
                        : Icons.bluetooth_searching,
                  ),
                  label: Text(
                    bleProvider.isScanning ? 'Stop Scan' : 'Start Scan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState(bool isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          Text(
            isScanning ? 'Searching for devices...' : 'No BLE devices found',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (!isScanning)
            Text(
              'Tap "Start Scan" to search again.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // DEVICE CARD
  // --------------------------------------------------

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final deviceName = BleUtils.getDeviceName(device);

    final deviceId = BleUtils.getDeviceId(device);
    final signal = BleUtils.formatSignalStrength(result.rssi);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bluetooth, color: Color(0xFF2563EB)),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: _isConnecting
            ? null
            : () {
                _selectDevice(result);
              },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
