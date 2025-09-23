# Keydex - Secure Text Lockboxes

**The best way to backup sensitive data.**

Keydex is a Flutter mobile application that provides secure, encrypted storage for sensitive text content using NIP-44 encryption with Nostr key pairs. Store passwords, private notes, API keys, and other confidential information with military-grade encryption.

## 🔐 Features

- **End-to-End Encryption**: Uses NIP-44 encryption with Nostr key pairs
- **Biometric Authentication**: Secure access with fingerprint or face recognition
- **Local Storage Only**: All data stays on your device - no cloud dependencies
- **Modern UI**: Beautiful Material Design 3 interface with dark/light themes
- **Cross-Platform**: Built with Flutter for iOS and Android
- **Open Source**: Transparent security you can verify

## 🚀 Quick Start

### Prerequisites

- Flutter 3.5.4 or higher
- Dart 3.5.4 or higher
- Android Studio / Xcode for mobile development
- Device with biometric authentication (recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/keydex.git
   cd keydex
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate mock files (for development)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For Android release
   flutter build apk --release
   
   # For iOS release (requires Xcode)
   flutter build ios --release
   ```

## 📱 Usage

### First Launch Setup

1. **Launch Keydex** - You'll see the authentication screen
2. **Set Up Security** - Tap "Set Up Security" to configure biometric authentication
3. **Create Your First Lockbox** - Tap the "+" button to create an encrypted lockbox
4. **Store Sensitive Data** - Add passwords, notes, or any confidential text

### Creating a Lockbox

1. Tap the floating action button ("+") on the main screen
2. Enter a descriptive name (up to 100 characters)
3. Add your sensitive content (up to 4,000 characters)
4. Tap "Create Encrypted Lockbox"
5. Your data is encrypted using NIP-44 and stored locally

### Accessing Lockboxes

1. Authenticate using biometrics when prompted
2. Tap any lockbox card to view its encrypted content
3. Use the eye icon to show/hide content
4. Tap the copy icon to copy content to clipboard

### Managing Lockboxes

- **Edit**: Tap the edit icon to modify content or name
- **Delete**: Use the menu (⋮) to delete lockboxes permanently
- **Search**: Use the search bar to find specific lockboxes

## 🔧 Configuration

### Authentication Settings

Access via Settings → Security:

- **Biometric Authentication**: Toggle biometric security on/off
- **Encryption Key**: View key status and export backups
- **Key Rotation**: Generate new encryption keys periodically

### App Settings

Access via Settings:

- **Theme**: Choose between light, dark, or system theme
- **Storage Usage**: View app data size
- **Clear All Data**: Reset the app completely

## 🔒 Security

### Encryption Details

- **Algorithm**: NIP-44 (Nostr Improvement Proposal 44)
- **Key Generation**: Cryptographically secure random key pairs
- **Key Storage**: Encrypted and stored in device keychain
- **Authentication**: Biometric (fingerprint/face) or device passcode

### Security Best Practices

1. **Enable Biometric Authentication**: Always use biometric locks when available
2. **Regular Backups**: Export your encryption key backup and store it securely
3. **Key Rotation**: Rotate encryption keys periodically for enhanced security
4. **Device Security**: Ensure your device has a secure lock screen
5. **App Updates**: Keep Keydex updated for latest security improvements

### Data Storage

- **Location**: All data stored locally on device using SharedPreferences
- **Encryption**: All sensitive data encrypted before storage
- **No Cloud**: No data ever transmitted to external servers
- **Privacy**: Complete privacy - only you can access your data

## 🧪 Testing

### Run Unit Tests
```bash
flutter test test/unit/
```

### Run Contract Tests
```bash
flutter test test/contract/
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Performance Tests
```bash
flutter test test/unit/performance_test.dart
```

## 🏗️ Architecture

### Project Structure
```
lib/
├── contracts/          # Service interfaces
├── models/            # Data models
├── services/          # Business logic
├── screens/           # UI screens
├── widgets/           # Reusable components
└── src/
    ├── app.dart       # Main app configuration
    └── settings/      # Settings management

test/
├── contract/          # Contract tests
├── unit/             # Unit tests
└── integration_test/  # Integration tests
```

### Key Components

- **Models**: Immutable data structures (Lockbox, TextContent, EncryptionKey)
- **Services**: Business logic (Auth, Encryption, Storage, Lockbox, Key)
- **Contracts**: Interface definitions ensuring testability
- **Screens**: UI screens with Material Design 3
- **Widgets**: Reusable UI components

### Dependencies

- `local_auth`: Biometric authentication
- `ndk`: Nostr Development Kit for NIP-44 encryption
- `shared_preferences`: Local data persistence
- `uuid`: Unique identifier generation

## 🔍 Error Codes

### Authentication Errors
- `AUTH_NOT_CONFIGURED`: Authentication not set up
- `BIOMETRIC_NOT_AVAILABLE`: Biometric authentication unavailable
- `AUTH_FAILED`: Authentication attempt failed
- `SETUP_CANCELLED`: Authentication setup cancelled

### Encryption Errors
- `NO_KEY_AVAILABLE`: No encryption key found
- `PRIVATE_KEY_MISSING`: Private key required but not available
- `ENCRYPTION_FAILED`: Encryption operation failed
- `DECRYPTION_FAILED`: Decryption operation failed
- `INVALID_KEY_PAIR`: Key pair validation failed

### Storage Errors
- `LOCKBOX_NOT_FOUND`: Requested lockbox doesn't exist
- `DUPLICATE_LOCKBOX_ID`: Lockbox ID already exists
- `STORAGE_FULL`: Device storage insufficient
- `CORRUPTED_DATA`: Stored data appears corrupted

### Validation Errors
- `INVALID_NAME`: Lockbox name validation failed
- `CONTENT_TOO_LONG`: Content exceeds 4,000 character limit
- `INVALID_INPUT`: General input validation failure

## 📋 Roadmap

### Version 1.1
- [ ] Lockbox categories and tags
- [ ] Advanced search and filtering
- [ ] Export/import functionality
- [ ] Backup encryption key QR codes

### Version 1.2
- [ ] File attachment support
- [ ] Multi-user support
- [ ] Secure sharing capabilities
- [ ] Advanced key management

### Version 2.0
- [ ] Desktop application (Windows/macOS/Linux)
- [ ] Browser extension
- [ ] Advanced encryption algorithms
- [ ] Professional features

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes with tests
4. Run the test suite: `flutter test`
5. Submit a pull request

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🛡️ Security Disclosure

If you discover a security vulnerability, please send an email to security@keydex.dev rather than opening a public issue. We take security seriously and will respond promptly.

## 📞 Support

- **Documentation**: Check this README and inline code comments
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join our GitHub Discussions
- **Email**: Contact us at support@keydex.dev

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) for the amazing framework
- [Nostr Community](https://nostr.com) for NIP-44 encryption standard
- [NDK Team](https://github.com/ndk-org/ndk) for the Dart implementation
- All contributors and testers

---

**Remember**: Your security is only as strong as your weakest link. Keep your device secure, use strong authentication, and regularly backup your encryption keys.

*Made with ❤️ by the Keydex Team*