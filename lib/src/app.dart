import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../screens/lockbox_list_screen.dart';
import '../screens/lockbox_detail_screen.dart';
import '../screens/create_lockbox_screen.dart';
import '../screens/edit_lockbox_screen.dart';
import '../screens/authentication_screen.dart';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import '../services/lockbox_service.dart';
import '../services/storage_service.dart';
import '../services/key_service.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

/// The main Keydex application widget that configures routing and services
class KeydexApp extends StatelessWidget {
  const KeydexApp({
    super.key,
    required this.settingsController,
    required this.lockboxService,
    required this.authService,
    required this.encryptionService,
    required this.keyService,
    required this.storageService,
  });

  final SettingsController settingsController;
  final LockboxService lockboxService;
  final AuthService authService;
  final EncryptionService encryptionService;
  final KeyService keyService;
  final StorageService storageService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'keydex_app',
          
          // Localization
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          
          // App title
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          
          // Theme configuration
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.light,
            ),
            cardTheme: const CardTheme(
              elevation: 2,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.dark,
            ),
            cardTheme: const CardTheme(
              elevation: 2,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          themeMode: settingsController.themeMode,
          
          // Initial route
          initialRoute: AuthenticationScreen.routeName,
          
          // Route generation
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case AuthenticationScreen.routeName:
                    return AuthenticationScreen(
                      authService: authService,
                      keyService: keyService,
                    );
                  case LockboxListScreen.routeName:
                    return LockboxListScreen(
                      lockboxService: lockboxService,
                      authService: authService,
                    );
                  case LockboxDetailScreen.routeName:
                    final args = routeSettings.arguments as Map<String, dynamic>?;
                    final lockboxId = args?['lockboxId'] as String?;
                    if (lockboxId == null) {
                      return const _ErrorScreen('Lockbox ID required');
                    }
                    return LockboxDetailScreen(
                      lockboxId: lockboxId,
                      lockboxService: lockboxService,
                    );
                  case CreateLockboxScreen.routeName:
                    return CreateLockboxScreen(
                      lockboxService: lockboxService,
                    );
                  case EditLockboxScreen.routeName:
                    final args = routeSettings.arguments as Map<String, dynamic>?;
                    final lockboxId = args?['lockboxId'] as String?;
                    final currentName = args?['currentName'] as String?;
                    final currentContent = args?['currentContent'] as String?;
                    if (lockboxId == null) {
                      return const _ErrorScreen('Lockbox data required');
                    }
                    return EditLockboxScreen(
                      lockboxId: lockboxId,
                      currentName: currentName ?? '',
                      currentContent: currentContent ?? '',
                      lockboxService: lockboxService,
                    );
                  case SettingsView.routeName:
                    return SettingsView(
                      controller: settingsController,
                      authService: authService,
                      keyService: keyService,
                      storageService: storageService,
                    );
                  default:
                    return const _ErrorScreen('Route not found');
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Simple error screen for route issues
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AuthenticationScreen.routeName,
                (route) => false,
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
