import 'package:ableritemobile/ui/widgets/spotlight_walkthrough.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('visible financial targets stay fixed throughout walkthrough', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = ScrollController();
    addTearDown(controller.dispose);
    final targetKeys = List<GlobalKey>.generate(4, (_) => GlobalKey());
    const titles = <String>[
      'Net Worth',
      'Monthly Income',
      'Monthly Expenses',
      'Cash Surplus',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 80),
                for (var index = 0; index < targetKeys.length; index++) ...[
                  SizedBox(
                    key: targetKeys[index],
                    width: 340,
                    height: 80,
                    child: Text(titles[index]),
                  ),
                  if (index != targetKeys.length - 1) const SizedBox(height: 6),
                ],
                const SizedBox(height: 700),
              ],
            ),
          ),
        ),
      ),
    );

    SpotlightWalkthrough.show(
      tester.element(find.byType(Scaffold)),
      steps: [
        for (var index = 0; index < targetKeys.length; index++)
          SpotlightStep(
            targetKey: targetKeys[index],
            title: titles[index],
            body: 'Financial overview walkthrough target.',
          ),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(controller.offset, 0);
    for (var index = 1; index < targetKeys.length; index++) {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(titles[index]), findsWidgets);
      expect(controller.offset, 0);
    }
  });

  testWidgets('off-screen walkthrough targets still scroll into view', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = ScrollController();
    addTearDown(controller.dispose);
    final firstKey = GlobalKey();
    final offscreenKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                SizedBox(key: firstKey, width: 340, height: 80),
                const SizedBox(height: 700),
                SizedBox(key: offscreenKey, width: 340, height: 80),
                const SizedBox(height: 300),
              ],
            ),
          ),
        ),
      ),
    );

    SpotlightWalkthrough.show(
      tester.element(find.byType(Scaffold)),
      steps: [
        SpotlightStep(targetKey: firstKey, title: 'First', body: 'First step'),
        SpotlightStep(
          targetKey: offscreenKey,
          title: 'Off-screen',
          body: 'Second step',
        ),
      ],
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    final targetRect = tester.getRect(find.byKey(offscreenKey));
    expect(targetRect.top, greaterThanOrEqualTo(0));
    expect(targetRect.bottom, lessThanOrEqualTo(600));
  });
}
