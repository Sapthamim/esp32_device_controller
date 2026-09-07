import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wifi_network.dart';
import '../../states/device_provider.dart';
import '../../states/wifi_provider.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  late WifiProvider _wifiProvider;

  bool _listenerAdded = false;
  bool _waitingForWifiResult = false;

  final TextEditingController _passwordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_listenerAdded) {
      _wifiProvider = context.read<WifiProvider>();

      _wifiProvider.addListener(_handleWifiStatusChanged);

      _listenerAdded = true;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      // Wi-Fi scan does NOT start automatically.
      // User must press SCAN.
    });
  }

  @override
  void dispose() {
    if (_listenerAdded) {
      _wifiProvider.removeListener(_handleWifiStatusChanged);
    }

    _passwordController.dispose();

    super.dispose();
  }

  // WIFI STATUS CHANGED

  void _handleWifiStatusChanged() {
    if (!mounted) {
      return;
    }

    if (!_waitingForWifiResult) {
      return;
    }

    final currentStatus = _wifiProvider.status;

    // WIFI CONNECTED

    if (currentStatus == WifiConnectionStatus.connected) {
      _waitingForWifiResult = false;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      _showSuccessSnackBar('Wi-Fi connected successfully.');

      return;
    }

    // WIFI FAILED

    if (currentStatus == WifiConnectionStatus.failed) {
      _waitingForWifiResult = false;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      _showErrorSnackBar(
        _wifiProvider.errorMessage ?? 'Wi-Fi connection failed.',
      );
    }
  }

  // SUCCESS SNACKBAR

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ERROR SNACKBAR

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

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

  // SELECT WIFI NETWORK

  Future<void> _connectToWifi(WifiNetwork network) async {
    final deviceProvider = context.read<DeviceProvider>();

    if (!deviceProvider.isConnected) {
      _showErrorSnackBar('Connect the ESP32 through BLE first.');

      return;
    }

    _passwordController.clear();

    await _showPasswordDialog(network);
  }

  // PASSWORD DIALOG

  Future<void> _showPasswordDialog(WifiNetwork network) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Connect to ${network.ssid}'),

              content: TextField(
                controller: _passwordController,
                obscureText: obscurePassword,
                autofocus: true,

                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password',
                  hintText: 'Enter password',
                  border: const OutlineInputBorder(),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),

                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(_passwordController.text);
                  },
                  child: const Text('Connect'),
                ),
              ],
            );
          },
        );
      },
    );

    if (password == null) {
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('Please enter the Wi-Fi password.');

      return;
    }

    await _startWifiConnection(network.ssid, password);
  }

  // START WIFI CONNECTION

  Future<void> _startWifiConnection(String ssid, String password) async {
    final wifiProvider = context.read<WifiProvider>();

    _waitingForWifiResult = true;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    await wifiProvider.connectToWifi(ssid: ssid, password: password);

    if (!mounted) {
      return;
    }

    // WAITING FOR ESP32

    if (wifiProvider.status == WifiConnectionStatus.waiting) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Credentials sent. Waiting for ESP32...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          duration: const Duration(seconds: 15),
        ),
      );

      return;
    }

    // QUICK SUCCESS

    if (wifiProvider.status == WifiConnectionStatus.connected) {
      _waitingForWifiResult = false;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      _showSuccessSnackBar('Wi-Fi connected successfully.');

      return;
    }

    // FAILED

    if (wifiProvider.status == WifiConnectionStatus.failed) {
      _waitingForWifiResult = false;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      _showErrorSnackBar(
        wifiProvider.errorMessage ?? 'Wi-Fi connection failed.',
      );
    }
  }

  // SCAN WIFI NETWORKS

  Future<void> _scanNetworks() async {
    await context.read<WifiProvider>().scanNetworks();
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wi-Fi Networks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          TextButton.icon(
            onPressed: _scanNetworks,

            icon: const Icon(Icons.wifi_find),

            label: const Text(
              'SCAN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

      body: Consumer<WifiProvider>(
        builder: (context, wifiProvider, child) {
          // SCANNING

          if (wifiProvider.isScanning) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR

          if (wifiProvider.errorMessage != null &&
              wifiProvider.networks.isEmpty) {
            return _buildErrorView(wifiProvider.errorMessage!);
          }

          // EMPTY

          if (wifiProvider.networks.isEmpty) {
            return _buildEmptyView();
          }

          // NETWORK LIST

          return ListView(
            padding: const EdgeInsets.all(16),

            children: [
              // CONNECTED CARD
              if (wifiProvider.isConnected)
                _buildConnectedCard(wifiProvider.connectedSsid ?? ''),

              // CONNECTING CARD
              if (wifiProvider.isConnecting)
                _buildConnectingCard(wifiProvider.selectedSsid ?? ''),

              const SizedBox(height: 16),

              const Text(
                'Available Wi-Fi Networks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...wifiProvider.networks.map((network) {
                return _buildWifiNetworkCard(network, wifiProvider);
              }),
            ],
          );
        },
      ),
    );
  }

  // WIFI NETWORK CARD

  Widget _buildWifiNetworkCard(WifiNetwork network, WifiProvider wifiProvider) {
    final isSelected = wifiProvider.selectedSsid == network.ssid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 1,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // LEFT WIFI ICON — KEPT
        leading: Icon(network.secured ? Icons.wifi_lock : Icons.wifi, size: 30),

        title: Text(
          network.ssid,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        // Signal strength text removed
        // as it was already removed in your code.

        // RIGHT ICON
        //
        // Arrow is removed.
        // Only connected Wi-Fi shows green check.
        onTap: () {
          if (wifiProvider.isConnecting) {
            return;
          }

          _connectToWifi(network);
        },

        selected: isSelected,
      ),
    );
  }

  // CONNECTED CARD

  Widget _buildConnectedCard(String ssid) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.green.withValues(alpha: 0.30)),
      ),

      child: Row(
        children: [
          const Icon(Icons.wifi, color: Colors.green, size: 30),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Wi-Fi Connected',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(ssid),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // CONNECTING CARD

  Widget _buildConnectingCard(String ssid) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.blue.withValues(alpha: 0.30)),
      ),

      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,

            child: CircularProgressIndicator(strokeWidth: 2),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Connecting to Wi-Fi',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(ssid.isEmpty ? 'Please wait...' : ssid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ERROR VIEW

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.red),

            const SizedBox(height: 16),

            const Text(
              'Unable to load Wi-Fi networks',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _scanNetworks,

              icon: const Icon(Icons.refresh),

              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY VIEW

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.wifi_find, size: 60),

            const SizedBox(height: 16),

            const Text(
              'No Wi-Fi networks found.',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            const Text(
              'Press SCAN to find available Wi-Fi networks.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
