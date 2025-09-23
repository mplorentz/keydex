import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'services/auth_service.dart';
import 'services/encryption_service.dart';
import 'services/lockbox_service.dart';
import 'services/storage_service.dart';
import 'services/key_service.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up service dependencies
  final storageService = StorageService();
  final encryptionService = EncryptionServiceImpl();
  final authService = AuthServiceImpl();
  final keyService = KeyService(encryptionService);
  final lockboxService = LockboxServiceImpl(
    storageService,
    encryptionService,
    authService,
  );

  // Set up the SettingsController
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController and services
  runApp(KeydexApp(
    settingsController: settingsController,
    lockboxService: lockboxService,
    authService: authService,
    encryptionService: encryptionService,
    keyService: keyService,
    storageService: storageService,
  ));
}
