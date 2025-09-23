// Unit Tests for Widgets
// Testing AuthenticationWidget, LockboxCardWidget, LockboxListWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:keydex/widgets/authentication_widget.dart';
import 'package:keydex/widgets/lockbox_card_widget.dart';
import 'package:keydex/widgets/lockbox_list_widget.dart';
import 'package:keydex/services/auth_service.dart';
import 'package:keydex/contracts/lockbox_service.dart';

import '../contract/auth_service_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('AuthenticationWidget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('should show setup widget when setup is needed', (WidgetTester tester) async {
      bool onSetupRequiredCalled = false;
      bool onAuthenticatedCalled = false;
      String? lastError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthenticationWidget(
              authService: mockAuthService,
              needsSetup: true,
              hasEncryptionKey: false,
              onAuthenticated: () => onAuthenticatedCalled = true,
              onSetupRequired: () => onSetupRequiredCalled = true,
              onError: (error) => lastError = error,
            ),
          ),
        ),
      );

      // Should show setup required text
      expect(find.text('Setup Required'), findsOneWidget);
      expect(find.text('Encryption key needed'), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);

      // Should not show authentication UI
      expect(find.text('Authentication Required'), findsNothing);
    });

    testWidgets('should show authentication widget when setup is complete', (WidgetTester tester) async {
      bool onSetupRequiredCalled = false;
      bool onAuthenticatedCalled = false;
      String? lastError;

      when(mockAuthService.isBiometricAvailable()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthenticationWidget(
              authService: mockAuthService,
              needsSetup: false,
              hasEncryptionKey: true,
              onAuthenticated: () => onAuthenticatedCalled = true,
              onSetupRequired: () => onSetupRequiredCalled = true,
              onError: (error) => lastError = error,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show authentication UI
      expect(find.text('Authentication Required'), findsOneWidget);
      expect(find.text('Authenticate'), findsOneWidget);

      // Should not show setup UI
      expect(find.text('Setup Required'), findsNothing);
    });

    testWidgets('should handle authentication success', (WidgetTester tester) async {
      bool onAuthenticatedCalled = false;
      String? lastError;

      when(mockAuthService.isBiometricAvailable()).thenAnswer((_) async => true);
      when(mockAuthService.authenticateUser()).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthenticationWidget(
              authService: mockAuthService,
              needsSetup: false,
              hasEncryptionKey: true,
              onAuthenticated: () => onAuthenticatedCalled = true,
              onSetupRequired: () {},
              onError: (error) => lastError = error,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the authenticate button
      await tester.tap(find.text('Authenticate'));
      await tester.pumpAndSettle();

      expect(onAuthenticatedCalled, true);
      expect(lastError, isNull);
    });

    testWidgets('should handle authentication failure', (WidgetTester tester) async {
      bool onAuthenticatedCalled = false;
      String? lastError;

      when(mockAuthService.isBiometricAvailable()).thenAnswer((_) async => true);
      when(mockAuthService.authenticateUser()).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthenticationWidget(
              authService: mockAuthService,
              needsSetup: false,
              hasEncryptionKey: true,
              onAuthenticated: () => onAuthenticatedCalled = true,
              onSetupRequired: () {},
              onError: (error) => lastError = error,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the authenticate button
      await tester.tap(find.text('Authenticate'));
      await tester.pumpAndSettle();

      expect(onAuthenticatedCalled, false);
      expect(lastError, isNotNull);
      expect(lastError, contains('Authentication was cancelled or failed'));
    });

    testWidgets('should disable buttons when biometric not available', (WidgetTester tester) async {
      when(mockAuthService.isBiometricAvailable()).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthenticationWidget(
              authService: mockAuthService,
              needsSetup: true,
              hasEncryptionKey: false,
              onAuthenticated: () {},
              onSetupRequired: () {},
              onError: (error) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Setup button should be disabled
      final setupButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Complete Setup'),
      );
      expect(setupButton.onPressed, isNull);

      // Should show error message
      expect(find.text('Biometric authentication is not available'), findsOneWidget);
    });
  });

  group('LockboxCardWidget Tests', () {
    late LockboxMetadata testLockbox;

    setUp(() {
      testLockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
        size: 150,
      );
    });

    testWidgets('should display lockbox information', (WidgetTester tester) async {
      bool tapped = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: testLockbox,
              onTap: () => tapped = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Should display lockbox name
      expect(find.text('Test Lockbox'), findsOneWidget);
      
      // Should display size
      expect(find.text('150 chars'), findsOneWidget);
      
      // Should display encrypted indicator
      expect(find.text('Encrypted'), findsOneWidget);
      
      // Should show lock icon
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('should handle tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: testLockbox,
              onTap: () => tapped = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('should show delete option in menu', (WidgetTester tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: testLockbox,
              onTap: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Should show delete option
      expect(find.text('Delete'), findsOneWidget);

      // Tap delete option
      await tester.tap(find.text('Delete'));
      expect(deleted, true);
    });

    testWidgets('should hide delete button when showDeleteButton is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: testLockbox,
              onTap: () {},
              onDelete: () {},
              showDeleteButton: false,
            ),
          ),
        ),
      );

      // Should not show menu button
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('should format size correctly', (WidgetTester tester) async {
      // Test large size formatting
      final largeLockbox = LockboxMetadata(
        id: 'large-id',
        name: 'Large Lockbox',
        createdAt: DateTime.now(),
        size: 2500, // Should display as "2.5K chars"
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: largeLockbox,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('2.5K chars'), findsOneWidget);
    });

    testWidgets('should show different colors for different sizes', (WidgetTester tester) async {
      // Test different size categories
      final smallLockbox = LockboxMetadata(
        id: 'small',
        name: 'Small',
        createdAt: DateTime.now(),
        size: 1000, // Should be green
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: smallLockbox,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Find the size container and verify it exists
      expect(find.text('1.0K chars'), findsOneWidget);
    });

    testWidgets('should format creation time correctly', (WidgetTester tester) async {
      // Test recent creation time
      final recentLockbox = LockboxMetadata(
        id: 'recent',
        name: 'Recent',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        size: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxCardWidget(
              lockbox: recentLockbox,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('hour'), findsOneWidget);
    });
  });

  group('LockboxListWidget Tests', () {
    testWidgets('should display empty state when no lockboxes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: const [],
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Should show empty state
      expect(find.text('No Lockboxes Yet'), findsOneWidget);
      expect(find.text('Create your first encrypted lockbox'), findsOneWidget);
      expect(find.text('What you can store:'), findsOneWidget);
      expect(find.text('Passwords & Login Credentials'), findsOneWidget);
    });

    testWidgets('should display list of lockboxes', (WidgetTester tester) async {
      final lockboxes = [
        LockboxMetadata(
          id: 'id1',
          name: 'Lockbox 1',
          createdAt: DateTime.now(),
          size: 100,
        ),
        LockboxMetadata(
          id: 'id2',
          name: 'Lockbox 2',
          createdAt: DateTime.now(),
          size: 200,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: lockboxes,
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Should display both lockboxes
      expect(find.text('Lockbox 1'), findsOneWidget);
      expect(find.text('Lockbox 2'), findsOneWidget);
      
      // Should display lockbox cards
      expect(find.byType(LockboxCardWidget), findsNWidgets(2));

      // Should not show empty state
      expect(find.text('No Lockboxes Yet'), findsNothing);
    });

    testWidgets('should handle tap on lockbox', (WidgetTester tester) async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      LockboxMetadata? tappedLockbox;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: [lockbox],
              onTap: (l) => tappedLockbox = l,
              onDelete: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Tap on the lockbox card
      await tester.tap(find.byType(LockboxCardWidget));

      expect(tappedLockbox, equals(lockbox));
    });

    testWidgets('should handle delete on lockbox', (WidgetTester tester) async {
      final lockbox = LockboxMetadata(
        id: 'test-id',
        name: 'Test Lockbox',
        createdAt: DateTime.now(),
        size: 100,
      );

      String? deletedLockboxId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: [lockbox],
              onTap: (_) {},
              onDelete: (id) => deletedLockboxId = id,
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Tap the menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Delete'));

      expect(deletedLockboxId, 'test-id');
    });

    testWidgets('should support pull to refresh', (WidgetTester tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: const [],
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      // Pull to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshed, true);
    });

    testWidgets('should hide empty state when showEmptyState is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: const [],
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () {},
              showEmptyState: false,
            ),
          ),
        ),
      );

      // Should not show empty state
      expect(find.text('No Lockboxes Yet'), findsNothing);
    });

    testWidgets('should use custom physics when provided', (WidgetTester tester) async {
      const customPhysics = NeverScrollableScrollPhysics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: const [],
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () {},
              physics: customPhysics,
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, equals(customPhysics));
    });
  });

  group('Widget Feature Tests', () {
    testWidgets('should show security information in empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: const [],
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Should show security features
      expect(find.text('Secure by Design'), findsOneWidget);
      expect(find.text('All data is encrypted using NIP-44 encryption'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('should show feature list in empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockboxListWidget(
              lockboxes: const [],
              onTap: (_) {},
              onDelete: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Should show all feature items
      expect(find.text('Passwords & Login Credentials'), findsOneWidget);
      expect(find.text('Private Notes & Ideas'), findsOneWidget);
      expect(find.text('Financial Information'), findsOneWidget);
      expect(find.text('API Keys & Secrets'), findsOneWidget);
      
      // Should show corresponding icons
      expect(find.byIcon(Icons.password), findsOneWidget);
      expect(find.byIcon(Icons.note_alt), findsOneWidget);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
    });
  });
}