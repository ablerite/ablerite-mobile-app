import 'package:ableritemobile/ui/pro_status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('free users see neutral account options and account deletion', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProStatusPage()));

    expect(find.text('Account Options'), findsOneWidget);
    expect(find.text('Free Account'), findsOneWidget);
    expect(find.text('View Pro Plans'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Ablerite Pro'), findsNothing);

    await tester.ensureVisible(find.text('Delete Account'));
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account?'), findsOneWidget);
    expect(
      find.textContaining('permanently deletes your Ablerite account'),
      findsOneWidget,
    );
  });

  testWidgets(
    'deletion waits for the keyboard and dialogs before auth teardown',
    (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(393, 852);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: _DeletionHarness()));

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Signed out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _DeletionHarness extends StatefulWidget {
  const _DeletionHarness();

  @override
  State<_DeletionHarness> createState() => _DeletionHarnessState();
}

class _DeletionHarnessState extends State<_DeletionHarness> {
  bool _signedIn = true;

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const Scaffold(body: Center(child: Text('Signed out')));
    }
    return ProStatusPage(
      deleteAccount: () async {
        setState(() => _signedIn = false);
      },
    );
  }
}
