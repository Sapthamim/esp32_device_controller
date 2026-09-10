import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../app/routes.dart';
import '../../states/device_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../wifi/wifi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  DeviceProvider? _deviceProvider;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WifiScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedTab();
  }

  Future<void> _loadSavedTab() async {
    final savedIndex = await ESP32ControllerApp.getLastHomeTabIndex();
    if (!mounted) return;
    setState(() {
      _selectedIndex = savedIndex.clamp(0, _screens.length - 1);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.read<DeviceProvider>();

    if (!identical(_deviceProvider, provider)) {
      // Remove listener from the previous provider if there was one.
      _deviceProvider?.removeListener(_handleDeviceStatusChanged);

      // Store the provider reference.
      _deviceProvider = provider;

      // Listen for Bluetooth connection changes.
      _deviceProvider!.addListener(_handleDeviceStatusChanged);
    }
  }

  void _handleDeviceStatusChanged() {
    if (!mounted) return;

    final deviceProvider = _deviceProvider;

    if (deviceProvider == null) return;

    if (deviceProvider.unexpectedDisconnect) {
      // Clear the flag so the SnackBar is shown only once.
      deviceProvider.clearUnexpectedDisconnect();

      _showBluetoothLostSnackBar();
    }
  }

  void _showBluetoothLostSnackBar() {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    // Remove any existing SnackBar first.
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Bluetooth connection lost.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'CONNECT AGAIN',
          textColor: Colors.white,
          onPressed: () {
            AppRoutes.clearAndNavigateToBleScan(context);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Do NOT use context.read() here.
    // The widget is already being deactivated.
    _deviceProvider?.removeListener(_handleDeviceStatusChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
            ESP32ControllerApp.saveLastHomeTabIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.wifi_outlined),
              selectedIcon: Icon(Icons.wifi),
              label: 'Wi-Fi',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
