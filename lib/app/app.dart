import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../states/ble_provider.dart';
import '../states/device_provider.dart';
import '../states/sensor_provider.dart';
import '../states/wifi_provider.dart';
import 'routes.dart';

class ESP32ControllerApp extends StatelessWidget {
  const ESP32ControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // BLE SERVICE
        Provider<BleService>(
          create: (_) => BleService(),
          dispose: (_, service) {
            service.disposeService();
          },
        ),

        // STORAGE SERVICE
        Provider<StorageService>(create: (_) => StorageService()),

        // BLE PROVIDER
        ChangeNotifierProvider<BleProvider>(
          create: (context) {
            return BleProvider(bleService: context.read<BleService>());
          },
        ),

        // ESP32 DEVICE PROVIDER
        ChangeNotifierProvider<DeviceProvider>(
          create: (context) {
            return DeviceProvider(bleService: context.read<BleService>());
          },
        ),

        // SENSOR PROVIDER
        ChangeNotifierProvider<SensorProvider>(
          create: (context) {
            return SensorProvider(
              bleService: context.read<BleService>(),
              storageService: context.read<StorageService>(),
            );
          },
        ),

        // WI-FI PROVIDER
        ChangeNotifierProvider<WifiProvider>(
          create: (context) {
            return WifiProvider(bleService: context.read<BleService>());
          },
        ),
      ],

      // MATERIAL APP
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ESP32 Controller',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
