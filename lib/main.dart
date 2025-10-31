import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/key_provider.dart';
import 'services/logger.dart';
import 'screens/lockbox_list_screen.dart';
import 'widgets/theme.dart';

void main() {
  runApp(
    // Wrap the entire app with ProviderScope to enable Riverpod
    const ProviderScope(
      child: KeydexApp(),
    ),
  );
}

class KeydexApp extends ConsumerStatefulWidget {
  const KeydexApp({super.key});

  @override
  ConsumerState<KeydexApp> createState() => _KeydexAppState();
}

class _KeydexAppState extends ConsumerState<KeydexApp> {
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize the Nostr key on app launch
      final keyService = ref.read(keyServiceProvider);
      await keyService.initializeKey();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      Log.error('Error initializing app', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to initialize secure storage: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keydex Lockbox',
      theme: keydexTheme,
      debugShowCheckedModeBanner: false,
      home: _isInitializing
          ? const _InitializingScreen()
          : _initError != null
              ? _ErrorScreen(error: _initError!)
              : const LockboxListScreen(),
    );
  }
}

// Loading screen shown during app initialization
class _InitializingScreen extends StatelessWidget {
  const _InitializingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFf47331),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Keydex...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Setting up secure storage',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen shown if initialization fails
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  exit(0);
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
