import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hms/app.dart';
import 'package:hms/features/landing/screens/landing_screen.dart';
import 'package:hms/features/authentication/screens/login_screen.dart';
import 'package:hms/features/tenants/screens/add_tenant_screen.dart';
import 'package:hms/state/app_state.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('hms_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>('app_settings');
  });

  testWidgets('Landing Screen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: LandingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HostelGhar'), findsWidgets);
    expect(find.text('Sign in as Warden'), findsOneWidget);
    expect(find.text('Beds & Occupancy Tracking'), findsOneWidget);
    expect(find.text('Offline-First Reliability'), findsOneWidget);
  });

  testWidgets('Login Screen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(appState: AppState()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Manage your property with ease'), findsOneWidget);
    expect(find.text('Email or Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('Main Scaffold and Tab navigation work seamlessly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HostelGharApp(startAtHome: true));
    await tester.pumpAndSettle();

    // 1. Dashboard Tab (Default)
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Overdue Rent'), findsWidgets);

    // 2. Switch to Rooms Tab
    await tester.tap(find.text('Rooms'));
    await tester.pumpAndSettle();
    expect(find.text('Rooms'), findsWidgets);
    expect(find.textContaining('All Rooms'), findsWidgets);

    // 3. Switch to Tenants Tab
    await tester.tap(find.text('Tenants'));
    await tester.pumpAndSettle();
    expect(find.text('Tenants'), findsWidgets);

    // 4. Switch to Billing Tab
    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    expect(find.text('Invoices & Billing'), findsWidgets);

    // 5. Switch to Settings Tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Active Property'), findsOneWidget);
    expect(find.text('Warden Profile'), findsOneWidget);
  });

  testWidgets('Add Tenant Screen renders properly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: AddTenantScreen(
          onTenantAdded: (tenant, {roomId, bedId}) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add New Tenant'), findsOneWidget);
    expect(find.text('Hostel Resident Registration'), findsOneWidget);
    expect(find.textContaining('Resident Profile & KYC'), findsWidgets);
  });

  testWidgets('Complete user flow: 1st Landing Screen -> 2nd Login Screen -> Validation check', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1st screen: Landing page
    await tester.pumpWidget(const HostelGharApp(startAtHome: false));
    await tester.pumpAndSettle();

    expect(find.text('Sign in as Warden'), findsOneWidget);
    expect(find.text('HostelGhar'), findsWidgets);

    // Navigate to 2nd screen: Login page
    await tester.tap(find.text('Sign in as Warden'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Manage your property with ease'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Attempt sign in with empty fields prompts validation snackbar
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your username/email and password.'), findsOneWidget);
  });

  testWidgets('Problem 1 Fix: Authenticated session persists across reload and opens MainScaffold', (WidgetTester tester) async {
    final box = Hive.box<dynamic>('app_settings');
    await tester.runAsync(() async {
      await box.put('auth.accessToken', 'test-access-token');
      await box.put('auth.refreshToken', 'test-refresh-token');
      await box.put('auth.profile', {
        'id': '10',
        'username': 'warden_test',
        'name': 'Test Warden',
        'role': 'warden',
        'email': 'warden@test.com',
      });
    });

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      await tester.runAsync(() async {
        await box.delete('auth.accessToken');
        await box.delete('auth.refreshToken');
        await box.delete('auth.profile');
      });
    });

    // Mount HostelGharApp with default startAtHome (checking persistent auth token in box)
    await tester.pumpWidget(const HostelGharApp());
    await tester.pump(const Duration(seconds: 1));

    // User should be directly on MainScaffold (Dashboard), NOT LandingScreen
    expect(find.text('Sign in as Warden'), findsNothing);
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('Problem 2 Fix: AppState remains valid and undisposed when navigating from LandingScreen to LoginScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    expect(appState.isDisposed, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: LandingScreen(appState: appState),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Sign in as Warden" to push LoginScreen
    await tester.tap(find.text('Sign in as Warden'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(appState.isDisposed, isFalse);

    // AppState refreshRooms must execute cleanly without "used after being disposed"
    await expectLater(appState.refreshRooms(), completes);
    expect(appState.isDisposed, isFalse);
  });

  testWidgets('Disposal safety: Guarded methods on disposed AppState do not throw', (WidgetTester tester) async {
    final appState = AppState();
    appState.dispose();
    expect(appState.isDisposed, isTrue);

    // Calling notifyListeners directly on disposed AppState is safely guarded
    expect(() => appState.notifyListeners(), returnsNormally);

    // Calling refreshRooms on disposed AppState completes without throw
    await expectLater(appState.refreshRooms(), completes);
  });

  // ---------------------------------------------------------------------------
  // Dark Mode: AppState.setThemeMode + Hive persistence
  // Isolated — does NOT use HostelGharApp to avoid backend network timeouts.
  // ---------------------------------------------------------------------------
  test('Dark Mode: AppState.setThemeMode persists to Hive and restores on new AppState', () async {
    final box = Hive.box<dynamic>('app_settings');
    await box.delete('setting.themeMode');

    // Default is light
    final appState = AppState();
    expect(appState.themeMode, equals(ThemeMode.light));

    // Switch to dark — must persist to Hive
    appState.setThemeMode(ThemeMode.dark);
    expect(appState.themeMode, equals(ThemeMode.dark));
    expect(box.get('setting.themeMode'), equals('dark'));

    // Switch to system
    appState.setThemeMode(ThemeMode.system);
    expect(appState.themeMode, equals(ThemeMode.system));
    expect(box.get('setting.themeMode'), equals('system'));

    // Switch back to light
    appState.setThemeMode(ThemeMode.light);
    expect(appState.themeMode, equals(ThemeMode.light));
    expect(box.get('setting.themeMode'), equals('light'));

    // Calling setThemeMode with same value is a no-op (no crash)
    appState.setThemeMode(ThemeMode.light);
    expect(appState.themeMode, equals(ThemeMode.light));

    // A brand-new AppState must restore the persisted dark theme from Hive
    await box.put('setting.themeMode', 'dark');
    final appState2 = AppState();
    expect(appState2.themeMode, equals(ThemeMode.dark));

    // Cleanup
    appState.dispose();
    appState2.dispose();
    await box.delete('setting.themeMode');
  });

  // ---------------------------------------------------------------------------
  // Tenant workflow: payment-method UI must be absent from AddTenantScreen.
  // Uses pump() not pumpAndSettle() to avoid blocking on async timers.
  // Does NOT wrap in extra SingleChildScrollView — AddTenantScreen manages
  // its own scroll internally, double-wrapping causes a semantics stack overflow.
  // ---------------------------------------------------------------------------
  testWidgets('Tenant workflow: AddTenantScreen has Rent & Deposit but no Payment Method UI', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: AddTenantScreen(
          onTenantAdded: (tenant, {roomId, bedId}) {},
        ),
      ),
    );
    // pump a few frames; avoid pumpAndSettle which may block on pending timers
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // _buildFieldLabel uses the raw string as label text — no ₹ or * appended
    expect(find.text('Monthly Base Rent'), findsOneWidget);
    expect(find.text('Security Deposit'), findsOneWidget);

    // Payment-method selectors must NOT be in the Tenant admission workflow
    expect(find.text('First Payment Mode'), findsNothing);
    expect(find.text('eSewa'), findsNothing);
    expect(find.text('Khalti'), findsNothing);
    expect(find.text('Fonepay'), findsNothing);
  });
}

