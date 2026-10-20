import 'package:ableritemobile/ui/train_page.dart';
import 'package:ableritemobile/ui/widgets/ambient_focus_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _useSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

void main() {
  for (final entry in <String, Size>{
    'portrait': const Size(1024, 1366),
    'landscape': const Size(1366, 1024),
  }.entries) {
    testWidgets('Brain Training has no iPad ${entry.key} overflow', (
      tester,
    ) async {
      await _useSize(tester, entry.value);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: TrainPage()));
      await tester.pump();

      expect(find.text('Pelmanism'), findsOneWidget);
      expect(find.text('Play Memory Match'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Focus app drawer expands on iPad ${entry.key}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _useSize(tester, entry.value);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showFocusShortcutDrawer(context),
                  child: const Text('Open apps'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open apps'));
      await tester.pumpAndSettle();

      expect(find.text('Apps'), findsOneWidget);
      final appsTextCenter = tester.getCenter(find.text('Apps'));
      expect(appsTextCenter.dx, lessThan(entry.value.width * 0.4));
      expect(tester.takeException(), isNull);
    });
  }
}
