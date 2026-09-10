import 'package:esp32_device_controller/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ESP32')),
        ),
      ),
    );

    expect(find.text('ESP32'), findsOneWidget);
  });

  testWidgets('reconnect flow clears previous routes before opening scan screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.welcome:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Welcome')),
                ),
              );
            case AppRoutes.bleScan:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Scan for BLE Devices')),
                ),
              );
            case AppRoutes.home:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Home')),
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Unknown')),
                ),
              );
          }
        },
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.welcome);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppRoutes.clearAndNavigateToBleScan(context);
                });
              },
              child: const Text('Start reconnect'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Start reconnect'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsNothing);
    expect(find.text('Scan for BLE Devices'), findsOneWidget);
  });
}
