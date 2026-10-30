import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urja/main.dart';

void main() {
  setUp(() {});

  testWidgets('Screen 1 Mascot Sanctuary starts at Level 1, shows Dashboard and Weather', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const UrjaApp());
    await tester.pump();

    // Verify Screen 1 Game HUD starts at Level 1
    expect(find.text('Lv 1'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
    expect(find.text('Sparrow Vitality'), findsOneWidget);

    // Verify Floating Ledger & Meter Plot Buttons
    expect(find.text('CO2e Ledger'), findsOneWidget);
    expect(find.text('Meter Plot'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // Verify Action Dock
    expect(find.text('Pet'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.text('Eco Tip'), findsOneWidget);

    // Open Dashboard Modal
    await tester.tap(find.text('CO2e Ledger'));
    await tester.pumpAndSettle();

    expect(find.text('Carbon & Energy Impact'), findsOneWidget);
    expect(find.text('CO2e PREVENTED'), findsOneWidget);
    expect(find.text('Unplug Wall Charger'), findsOneWidget);

    // Log an action: Unplug Wall Charger (+15 coins, +0.25kg CO2e)
    await tester.tap(find.text('+15 🪙').first);
    await tester.pump();

    // Close modal by tapping backdrop
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Coins increased to 265
    expect(find.text('265'), findsOneWidget);
  });

  testWidgets('Slide Left to Activity Feed, Slide Right to Wardrobe, and Scroll Down to Garden Island', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const UrjaApp());
    await tester.pump();

    // 1. Navigate to Activity Feed & Notifications (Slide Left)
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.text('Eco-Feed & Alerts'), findsOneWidget);
    expect(find.text('NOTIFICATION CENTER'), findsOneWidget);
    expect(find.text('GUJARAT MISSION LiFE COMMUNITY'), findsOneWidget);

    // Return to Sanctuary
    await tester.tap(find.text('Sanctuary'));
    await tester.pumpAndSettle();
    expect(find.text('Lv 1'), findsOneWidget);

    // 2. Navigate to Wardrobe Studio (Slide Right)
    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();

    expect(find.text('Urja Wardrobe Studio'), findsOneWidget);
    expect(find.text('Tap to Preview • Confirm to Buy'), findsOneWidget);
    expect(find.text('Hats'), findsOneWidget);
    expect(find.text('Face'), findsOneWidget);
    expect(find.text('Outfits'), findsOneWidget);

    // Return to Sanctuary
    await tester.tap(find.text('Sanctuary'));
    await tester.pumpAndSettle();
    expect(find.text('Lv 1'), findsOneWidget);

    // 3. Navigate vertically to 3D Garden Island
    await tester.tap(find.textContaining('Scroll Down to 3D Garden Island'));
    await tester.pumpAndSettle();

    // Verify Screen 2 3D Garden Island Elements
    expect(find.text('Floating Island 🏝️'), findsOneWidget);
    expect(find.text('🔨 Build Mode'), findsOneWidget);

    // Tap Build Mode
    await tester.tap(find.text('🔨 Build Mode'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Done Building'), findsOneWidget);

    // Return to Mascot Sanctuary
    await tester.tap(find.text('Mascot'));
    await tester.pumpAndSettle();
    expect(find.text('Lv 1'), findsOneWidget);
  });
}
