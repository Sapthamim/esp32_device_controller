import 'package:flutter/material.dart';

import '../screens/ble/ble_scan_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/wifi/wifi_screen.dart';

class AppRoutes {
  // ROUTE NAMES
  static const String splash = '/';

  static const String welcome = '/welcome';

  static const String bleScan = '/ble-scan';

  static const String home = '/home';

  static const String dashboard = '/dashboard';

  static const String wifi = '/wifi';

  static const String settings = '/settings';

  // ROUTE GENERATOR: which screen to create based on the route name.
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    // Checks which screen was requested.
    switch (routeSettings.name) {
      // Splash Screen
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // Welcome Screen
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      // BLE Scan Screen
      case bleScan:
        return MaterialPageRoute(builder: (_) => const BleScanScreen());

      // Home Screen
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      // Dashboard Screen
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      // Wi-Fi Screen
      case wifi:
        return MaterialPageRoute(builder: (_) => const WifiScreen());

      // Settings Screen
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      // Unknown route
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Page not found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
    }
  }
}
