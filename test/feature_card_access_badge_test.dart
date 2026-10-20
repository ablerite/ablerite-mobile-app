import 'package:ableritemobile/ui/widgets/feature_card.dart';
import 'package:ableritemobile/ui/widgets/access_tier_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCard({
    required AccessTier tier,
    required ValueNotifier<bool> proStatus,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FeatureCard(
          title: 'Test app',
          subtitle: 'Test subtitle',
          icon: Icons.apps,
          color: Colors.green,
          accessTier: tier,
          proStatusListenable: proStatus,
          onTap: () {},
        ),
      ),
    );
  }

  testWidgets('shows the access tier on an app card for a free account', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCard(tier: AccessTier.free, proStatus: ValueNotifier<bool>(false)),
    );

    expect(find.text('Free'), findsOneWidget);
    final iconCenter = tester.getCenter(find.byIcon(Icons.apps));
    final badgeCenter = tester.getCenter(find.text('Free'));
    expect(badgeCenter.dx, greaterThan(iconCenter.dx));
    expect(badgeCenter.dy, lessThan(iconCenter.dy));
  });

  testWidgets('removes the access tier when the account becomes Pro', (
    tester,
  ) async {
    final proStatus = ValueNotifier<bool>(false);
    await tester.pumpWidget(
      buildCard(tier: AccessTier.pro, proStatus: proStatus),
    );
    expect(find.text('Pro'), findsOneWidget);

    proStatus.value = true;
    await tester.pump();

    expect(find.text('Pro'), findsNothing);
  });

  testWidgets('uses a distinct gold colour for Pro access', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AccessTierBadge(tier: AccessTier.free),
              AccessTierBadge(tier: AccessTier.pro),
            ],
          ),
        ),
      ),
    );

    final freeText = tester.widget<Text>(find.text('Free'));
    final proText = tester.widget<Text>(find.text('Pro'));
    expect(proText.style?.color, isNot(freeText.style?.color));
    expect(proText.style?.color, const Color(0xFF8B6508));
  });
}
