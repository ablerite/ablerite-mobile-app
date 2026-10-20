import 'package:ableritemobile/ui/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> advancePage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('user controls the complete animated onboarding sequence', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(onComplete: () => completed = true, onSkip: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('Grow every part of your life'), findsOneWidget);

    await tester.tap(find.text('Discover Ablerite'));
    await advancePage(tester);
    expect(
      find.text('Train your mind.\nShape your direction.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await advancePage(tester);
    expect(find.text('Meet Diana Life Assistant'), findsOneWidget);
    expect(find.byIcon(Icons.face_3), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await advancePage(tester);
    expect(find.text('What do you want to solve?'), findsOneWidget);

    await tester.tap(find.text('Health'));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.text('Continue'));
    await advancePage(tester);
    expect(find.text('Start with free guidance'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await advancePage(tester);
    expect(find.text('Picture what you want'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await advancePage(tester);
    expect(find.text('Meditate on your desires'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await advancePage(tester);
    expect(find.text('Turn insight into action'), findsOneWidget);

    await tester.tap(find.text('Create Your Account'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(completed, isTrue);
  });

  testWidgets('skip bypasses onboarding and opens the login path', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var completed = false;
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          onComplete: () => completed = true,
          onSkip: () => skipped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(skipped, isTrue);
    expect(completed, isFalse);
    expect(
      await SharedPreferences.getInstance().then(
        (prefs) => prefs.getBool(OnboardingPage.storageKey),
      ),
      isTrue,
    );
  });

  testWidgets('initial offer is followed by the logo animation once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var offerCount = 0;
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: InitialOfferPage(
          userId: 'new-account-user',
          showOffer: (context, userId) async {
            offerCount += 1;
          },
          onComplete: () => completed = true,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(offerCount, 1);
    expect(find.text('You’re ready to manifest.'), findsOneWidget);
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 2300));
    expect(completed, isTrue);
    expect(await InitialOfferPage.isComplete('new-account-user'), isTrue);
  });

  test(
    'legacy onboarding completion does not suppress the initial offer',
    () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete_existing-user': true,
      });

      expect(await InitialOfferPage.isComplete('existing-user'), isFalse);
    },
  );

  testWidgets('interrupted onboarding resumes from the saved page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      OnboardingPage.progressStorageKey: 5,
      OnboardingPage.painPointStorageKey: 'Wealth',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(onComplete: () {}, onSkip: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('Picture what you want'), findsOneWidget);
  });

  for (final entry in <String, Size>{
    'iPad portrait': const Size(1024, 1366),
    'iPad landscape': const Size(1366, 1024),
  }.entries) {
    testWidgets('${entry.key} onboarding keeps artwork and copy in bounds', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = entry.value;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(onComplete: () {}, onSkip: () {}),
        ),
      );
      await tester.pump();
      await advancePage(tester);
      expect(tester.takeException(), isNull);

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      final titles = <String>[
        'Grow every part of your life',
        'Train your mind.\nShape your direction.',
        'Meet Diana Life Assistant',
        'What do you want to solve?',
        'Start with free guidance',
        'Picture what you want',
        'Meditate on your desires',
        'Turn insight into action',
      ];

      for (var index = 0; index < titles.length; index += 1) {
        controller.jumpToPage(index);
        await advancePage(tester);
        expect(find.text(titles[index]), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
