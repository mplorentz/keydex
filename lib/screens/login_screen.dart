import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import '../utils/validators.dart';
import '../widgets/row_button.dart';
import 'account_created_screen.dart';

/// Screen for importing an existing Nostr key
/// Supports nsec, hex private key, and bunker URL (bunker not yet implemented)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Validate the key input and return error message if invalid
  String? _validateKeyInput(String input) {
    if (input.isEmpty) return 'Please enter a key';

    if (isValidNsec(input)) return null; // Valid nsec
    if (isValidHexPrivkey(input)) return null; // Valid hex
    if (isValidBunkerUrl(input)) return 'Bunker URLs not yet supported';

    return 'Invalid key format. Enter nsec or hex private key.';
  }

  /// Auto-detect format and import the key
  Future<void> _importKey() async {
    final input = _controller.text.trim();
    final validationError = _validateKeyInput(input);

    if (validationError != null) {
      setState(() {
        _errorText = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final loginService = ref.read(loginServiceProvider);

      // Auto-detect format and import
      String? nsecKey;
      if (isValidNsec(input)) {
        // Import nsec directly
        final keyPair = await loginService.importNsecKey(input);
        nsecKey = keyPair.privateKeyBech32;
      } else if (isValidHexPrivkey(input)) {
        // Import hex private key
        final keyPair = await loginService.importHexPrivateKey(input);
        nsecKey = keyPair.privateKeyBech32;
      } else if (isValidBunkerUrl(input)) {
        // Bunker not yet supported
        setState(() {
          _errorText = 'Bunker URLs not yet supported';
          _isLoading = false;
        });
        return;
      } else {
        setState(() {
          _errorText = 'Invalid key format';
          _isLoading = false;
        });
        return;
      }

      // Navigate to AccountCreatedScreen
      if (mounted && nsecKey != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccountCreatedScreen(
              nsec: nsecKey!,
              isImported: true,
            ),
          ),
        );
      } else if (nsecKey == null) {
        setState(() {
          _errorText = 'Error: Failed to generate key';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Error importing key: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login with Nostr Key'),
      ),
      body: SafeArea(
        bottom: false, // Let RowButton handle bottom safe area
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions
                      Text(
                        'Enter your Nostr key',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can use any of these formats:',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• nsec (bech32): nsec1abc...\n'
                        '• Hex private key: 64 hex characters\n'
                        '• Bunker URL: bunker://... (coming soon)',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // Key input field
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter nsec, hex private key, or bunker URL',
                          errorText: _errorText,
                          prefixIcon: const Icon(Icons.key),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          // Clear error when user types
                          if (_errorText != null) {
                            setState(() {
                              _errorText = null;
                            });
                          }
                        },
                        onSubmitted: (_) => _importKey(),
                      ),
                      const SizedBox(height: 24),

                      // Security warning
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Never share your private key. Only enter it in trusted applications.',
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Continue button
            RowButton(
              onPressed: _isLoading ? null : _importKey,
              icon: _isLoading ? Icons.hourglass_empty : Icons.arrow_forward,
              text: _isLoading ? 'Importing...' : 'Continue',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}
