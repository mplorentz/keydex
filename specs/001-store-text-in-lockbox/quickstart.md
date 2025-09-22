# Quickstart: Encrypted Text Lockbox

## Overview
This guide demonstrates the complete user workflow for the encrypted text lockbox feature.

## Prerequisites
- Flutter app installed on device
- Biometric authentication available (Touch ID, Face ID, Fingerprint)
- Nostr key pair generated

## User Workflow

### 1. First Time Setup
1. **Launch App**: Open the Keydex app
2. **Setup Authentication**: 
   - App prompts to enable biometric authentication
   - User enables Touch ID/Face ID/Fingerprint
   - Fallback to PIN/password if biometrics unavailable
3. **Generate Keys**: 
   - App automatically generates Nostr key pair
   - Keys stored securely on device
   - No network communication required

### 2. Create Your First Lockbox
1. **Navigate to Lockboxes**: Tap "Lockboxes" in main menu
2. **Create New**: Tap "+" button to create new lockbox
3. **Enter Name**: Type "My First Lockbox" (or any name)
4. **Enter Content**: Type your sensitive text (max 4000 characters)
5. **Save**: Tap "Save" button
6. **Verify**: Lockbox appears in list with your chosen name

### 3. View Lockbox Content
1. **Select Lockbox**: Tap on "My First Lockbox" from the list
2. **Authenticate**: Use biometric authentication or enter password
3. **View Content**: Your decrypted text is displayed
4. **Edit**: Tap "Edit" to modify the content
5. **Save Changes**: Tap "Save" to encrypt and store updated content

### 4. Manage Multiple Lockboxes
1. **Create More**: Repeat steps 2-3 to create additional lockboxes
2. **View List**: See all lockboxes with names and creation dates
3. **Search**: Use search bar to find specific lockboxes
4. **Delete**: Swipe left on any lockbox to delete it permanently

### 5. Error Scenarios
1. **Empty Content**: App allows empty lockboxes (for sharing with peers)
2. **Large Content**: App shows error if content exceeds 4000 characters
3. **Encryption Error**: App shows user-friendly error with support code
4. **Authentication Failed**: App prompts to try again or use password

## Technical Validation

### Encryption Test
1. Create lockbox with text: "This is a secret message"
2. Verify content is encrypted in storage (not plaintext)
3. Decrypt and verify original text is recovered
4. Confirm different lockboxes use different encrypted values

### Authentication Test
1. Create lockbox with sensitive content
2. Close and reopen app
3. Attempt to view lockbox content
4. Verify authentication is required
5. Verify content is accessible after successful authentication

### Cross-Platform Test
1. Test on iOS device (Touch ID/Face ID)
2. Test on Android device (Fingerprint)
3. Test on desktop (password authentication)
4. Verify consistent behavior across platforms

## Success Criteria
- [ ] User can create, view, edit, and delete lockboxes
- [ ] All text content is encrypted before storage
- [ ] Authentication is required for sensitive operations
- [ ] App works consistently across all 5 platforms
- [ ] Error messages are clear and actionable
- [ ] Performance is responsive (<200ms operations)

## Troubleshooting

### Common Issues
1. **"Biometric not available"**: Use password authentication instead
2. **"Content too large"**: Reduce text to under 4000 characters
3. **"Encryption failed"**: Contact support with error code
4. **"Authentication failed"**: Try again or restart app

### Support Information
- Error codes are displayed for support tickets
- All operations are performed locally (no network required)
- Data is encrypted using industry-standard NIP-44
- Keys are stored securely on device only
