import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urja/features/auth/google_login_screen.dart';
import 'package:urja/features/home/main_two_screen_shell.dart';
import 'package:urja/features/onboarding/citizen_profile_setup_screen.dart';
import 'package:urja/features/onboarding/onboarding_screen.dart';
import 'package:urja/main.dart';

void main() {
  setUp(() {});

  testWidgets('new citizens see three welcome screens before Google sign-in', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump();

    expect(find.text('MAKE EVERYDAY CHOICES COUNT'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final title in ['UNDERSTAND YOUR HOME', 'PLAY. PROGRESS. PROTECT.']) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text(title), findsOneWidget);
      final exception = tester.takeException();
      expect(exception, isNull);
    }

    await tester.tap(find.text('Start your green journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Start your green journey'), findsOneWidget);
  });

  testWidgets('Google sign-in screen stays usable on compact displays', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: GoogleLoginScreen()));
    await tester.pump();

    expect(find.text('Start your green journey'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Explore as Guest · Demo only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mascot interaction is driven by tapping the sparrow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UrjaApp(home: MainTwoScreenShell()));
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Mascot Sanctuary'), findsNothing);
    expect(find.text('Sanctuary'), findsNothing);
    expect(find.text('Tap Cheechee to interact'), findsOneWidget);
    expect(find.text('Feed'), findsNothing);
    expect(find.text('Cheer'), findsNothing);
  });

  testWidgets(
    'Screen 1 Mascot Sanctuary starts at Level 1, shows Dashboard and Weather',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const UrjaApp(home: MainTwoScreenShell()));
      await tester.pump();

      // Verify Screen 1 Game HUD starts at Level 1
      expect(find.text('Lv 1 Sparrow'), findsOneWidget);
      expect(find.text('🪙 250'), findsOneWidget);
      expect(find.text('Sparrow Vitality'), findsOneWidget);

      // Keep household and impact controls off the mascot scene.
      expect(find.text('Daily missions'), findsOneWidget);
      expect(find.text('CO2e Ledger'), findsNothing);
      expect(find.text('Meter Plot'), findsNothing);
      expect(find.text('Water'), findsNothing);
      expect(find.text('Devices'), findsNothing);
      expect(find.text('Commute'), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Interact with the companion directly instead of selecting expression buttons.
      expect(find.text('Tap Cheechee to interact'), findsOneWidget);
      expect(find.text('Feed'), findsNothing);
      expect(find.text('Cheer'), findsNothing);
      expect(
        find.textContaining('Scroll Down to 3D Garden Island'),
        findsOneWidget,
      );

      await tester.tap(find.text('Daily missions'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Daily Mission LiFE Quests'), findsOneWidget);
      Navigator.of(
        tester.element(find.text('Daily Mission LiFE Quests')),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('MENU'));
      await tester.pumpAndSettle();
      expect(find.text('Explore Urja'), findsOneWidget);
      Navigator.of(tester.element(find.text('Explore Urja'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Player profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Player Profile'), findsOneWidget);
      Navigator.of(tester.element(find.text('Player Profile'))).pop();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Sanctuary opens the backend-backed citizen dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UrjaApp(home: MainTwoScreenShell()));
    await tester.pump();

    await tester.tap(find.byTooltip('Citizen dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your green day'), findsOneWidget);
    expect(find.text('YOUR DASHBOARD'), findsOneWidget);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Add reading'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Your progress'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('My devices'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My devices'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Slide Left to Activity Feed, Slide Right to Wardrobe, and Scroll Down to Garden Island',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const UrjaApp(home: MainTwoScreenShell()));
      await tester.pump();

      // 1. Navigate to the live activity feed from the notification control.
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('MISSION LiFE NOTIFICATIONS'), findsOneWidget);

      // Return to Sanctuary
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Lv 1 Sparrow'), findsOneWidget);

      // 2. Navigate to Wardrobe Studio (Slide Right)
      await tester.dragFrom(const Offset(270, 600), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Urja Wardrobe Studio'), findsOneWidget);
      expect(find.text('Tap to Preview • Confirm to Buy'), findsOneWidget);
      expect(find.text('Hats'), findsOneWidget);
      expect(find.text('Face'), findsOneWidget);
      expect(find.text('Outfits'), findsOneWidget);

      // Return to Sanctuary
      await tester.dragFrom(const Offset(270, 600), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Lv 1 Sparrow'), findsOneWidget);

      // 3. Navigate vertically to 3D Garden Island
      await tester.tap(find.textContaining('Scroll Down to 3D Garden Island'));
      await tester.pumpAndSettle();

      // Verify Screen 2 3D Garden Island Elements
      expect(find.text('Floating Island 🏝️'), findsOneWidget);
      expect(find.text('Pinch to Zoom • Snap to Grid'), findsOneWidget);
      expect(find.text('Flora 🌷'), findsOneWidget);

      // Return to Mascot Sanctuary
      await tester.tap(find.text('Mascot'));
      await tester.pumpAndSettle();
      expect(find.text('Lv 1 Sparrow'), findsOneWidget);
    },
  );

  testWidgets(
    'CitizenProfileSetupScreen steps through Gujarat location, water, electricity, and sparrow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: CitizenProfileSetupScreen()),
      );
      await tester.pumpAndSettle();

      // Step 1: Location & House
      expect(find.text('YOUR GREEN HOME'), findsOneWidget);
      expect(find.text('Gujarat Home & District'), findsOneWidget);
      expect(find.text('Ahmedabad'), findsOneWidget);
      expect(find.text('Navrangpura'), findsOneWidget);

      // Tap Next Step -> Step 2: Owned Vehicles
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('Owned Household Vehicles'), findsOneWidget);
      expect(find.textContaining('Add Vehicle Owned'), findsOneWidget);

      // Tap Next Step -> Step 3: Water Supply & Storage
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('Water Supply & Storage'), findsOneWidget);
      expect(find.text('Water Storage Configuration'), findsOneWidget);

      // Tap Next Step -> Step 4: Electricity & Normalized Devices
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('Electricity & High-Drain Appliances'), findsOneWidget);
      expect(find.textContaining('RO Water Purifier'), findsOneWidget);

      // Tap Next Step -> Step 5: Cooking Gas
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('Kitchen Cooking Energy'), findsOneWidget);

      // Tap Next Step -> Step 6: Companion Sparrow
      await tester.tap(find.text('Next Step →'));
      await tester.pumpAndSettle();

      expect(find.text('Adopt Your Sparrow Companion'), findsOneWidget);
      expect(find.text('Complete & Enter Sanctuary 🌿'), findsOneWidget);
    },
  );
}
