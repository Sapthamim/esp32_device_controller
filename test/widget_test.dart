import 'package:flutter_test/flutter_test.dart';

import 'package:esp32_device_controller/app/app.dart';

void main() {
  testWidgets('ESP32 Controller app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ESP32ControllerApp());

    expect(find.text('ESP32'), findsOneWidget);
  });
}
