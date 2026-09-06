// Tests for the Settings screen's SUPPORT section: the rate card and the
// feedback row, plus the shared "the handoff didn't happen" snackbar.
//
// The tiles resolve FeedbackService from get_it only inside onTap, so
// rendering them needs no DI setup. runSupportAction is exercised directly
// with a stub, which is the part worth pinning: a launch that returns false
// must tell the user rather than look like a dead tap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:credit_cards/features/cards/presentation/pages/profile_screen/components/support_tiles.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('rate card shows its copy and five stars', (tester) async {
    await tester.pumpWidget(_wrap(const RateAppTile()));

    expect(find.text('Rate this app'), findsOneWidget);
    expect(
      find.text('Tap to rate Card Vault on the Play Store'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
  });

  testWidgets('feedback row shows its copy', (tester) async {
    await tester.pumpWidget(_wrap(const SendFeedbackTile()));

    expect(find.text('Send feedback'), findsOneWidget);
    expect(find.text('Report a problem or suggest a feature'), findsOneWidget);
  });

  testWidgets('a failed handoff surfaces a snackbar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => runSupportAction(
              context,
              () async => false,
              'Could not open the Play Store',
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the Play Store'), findsOneWidget);
  });

  testWidgets('a successful handoff stays silent', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => runSupportAction(
              context,
              () async => true,
              'Could not open the Play Store',
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });
}
