import 'package:flutter/material.dart';
import 'screens/lockbox_list_screen.dart';
import 'screens/authentication_screen.dart';
import 'contracts/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const KeydexApp());
}

class KeydexApp extends StatelessWidget {
  const KeydexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keydex',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // TODO: Replace with actual AuthService implementation
    // For now, assume authentication is needed
    setState(() {
      _isLoading = false;
      _isAuthenticated = false;
    });
  }

  void _onAuthenticated() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated
        ? const LockboxListScreen()
        : AuthenticationScreen(onAuthenticated: _onAuthenticated);
  }
}
