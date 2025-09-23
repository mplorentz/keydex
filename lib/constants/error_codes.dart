// Error Code Documentation
// Centralized error codes and messages for the Keydex application

/// Authentication error codes
class AuthErrorCodes {
  static const String notConfigured = 'AUTH_NOT_CONFIGURED';
  static const String biometricNotAvailable = 'BIOMETRIC_NOT_AVAILABLE';
  static const String authFailed = 'AUTH_FAILED';
  static const String setupCancelled = 'SETUP_CANCELLED';
  static const String setupFailed = 'SETUP_FAILED';
  static const String disableFailed = 'DISABLE_FAILED';
  static const String enableFailed = 'ENABLE_FAILED';
}

/// Encryption error codes
class EncryptionErrorCodes {
  static const String noKeyAvailable = 'NO_KEY_AVAILABLE';
  static const String privateKeyMissing = 'PRIVATE_KEY_MISSING';
  static const String encryptionFailed = 'ENCRYPTION_FAILED';
  static const String decryptionFailed = 'DECRYPTION_FAILED';
  static const String keyGenerationFailed = 'KEY_GENERATION_FAILED';
  static const String invalidKeyPair = 'INVALID_KEY_PAIR';
  static const String keyRetrievalFailed = 'KEY_RETRIEVAL_FAILED';
  static const String keyStorageFailed = 'KEY_STORAGE_FAILED';
  static const String keyClearFailed = 'KEY_CLEAR_FAILED';
  static const String corruptedKeyData = 'CORRUPTED_KEY_DATA';
  static const String privateKeyRequired = 'PRIVATE_KEY_REQUIRED';
}

/// Storage error codes
class StorageErrorCodes {
  static const String lockboxRetrievalFailed = 'LOCKBOX_RETRIEVAL_FAILED';
  static const String lockboxSaveFailed = 'LOCKBOX_SAVE_FAILED';
  static const String lockboxNotFound = 'LOCKBOX_NOT_FOUND';
  static const String lockboxAddFailed = 'LOCKBOX_ADD_FAILED';
  static const String lockboxUpdateFailed = 'LOCKBOX_UPDATE_FAILED';
  static const String lockboxDeleteFailed = 'LOCKBOX_DELETE_FAILED';
  static const String duplicateLockboxId = 'DUPLICATE_LOCKBOX_ID';
  static const String contentRetrievalFailed = 'CONTENT_RETRIEVAL_FAILED';
  static const String contentSaveFailed = 'CONTENT_SAVE_FAILED';
  static const String contentDeleteFailed = 'CONTENT_DELETE_FAILED';
  static const String preferencesRetrievalFailed = 'PREFERENCES_RETRIEVAL_FAILED';
  static const String preferencesSaveFailed = 'PREFERENCES_SAVE_FAILED';
  static const String preferenceSetFailed = 'PREFERENCE_SET_FAILED';
  static const String clearDataFailed = 'CLEAR_DATA_FAILED';
}

/// Lockbox error codes
class LockboxErrorCodes {
  static const String noEncryptionKey = 'NO_ENCRYPTION_KEY';
  static const String authenticationRequired = 'AUTHENTICATION_REQUIRED';
  static const String createFailed = 'CREATE_FAILED';
  static const String retrievalFailed = 'RETRIEVAL_FAILED';
  static const String contentRetrievalFailed = 'CONTENT_RETRIEVAL_FAILED';
  static const String updateFailed = 'UPDATE_FAILED';
  static const String nameUpdateFailed = 'NAME_UPDATE_FAILED';
  static const String deleteFailed = 'DELETE_FAILED';
  static const String authenticationFailed = 'AUTHENTICATION_FAILED';
  static const String searchFailed = 'SEARCH_FAILED';
  static const String lockboxNotFound = 'LOCKBOX_NOT_FOUND';
  static const String contentNotFound = 'CONTENT_NOT_FOUND';
  static const String invalidName = 'INVALID_NAME';
  static const String nameTooLong = 'NAME_TOO_LONG';
  static const String contentTooLong = 'CONTENT_TOO_LONG';
}

/// Key service error codes
class KeyServiceErrorCodes {
  static const String keyGenerationFailed = 'KEY_GENERATION_FAILED';
  static const String nostrKeyGenerationFailed = 'NOSTR_KEY_GENERATION_FAILED';
  static const String keyRetrievalFailed = 'KEY_RETRIEVAL_FAILED';
  static const String nostrKeyRetrievalFailed = 'NOSTR_KEY_RETRIEVAL_FAILED';
  static const String invalidKey = 'INVALID_KEY';
  static const String invalidNostrKeyPair = 'INVALID_NOSTR_KEY_PAIR';
  static const String keySetFailed = 'KEY_SET_FAILED';
  static const String nostrKeySetFailed = 'NOSTR_KEY_SET_FAILED';
  static const String noKeyToExport = 'NO_KEY_TO_EXPORT';
  static const String publicKeyOnly = 'PUBLIC_KEY_ONLY';
  static const String keyExportFailed = 'KEY_EXPORT_FAILED';
  static const String invalidBackupFormat = 'INVALID_BACKUP_FORMAT';
  static const String invalidImportedKey = 'INVALID_IMPORTED_KEY';
  static const String keyImportFailed = 'KEY_IMPORT_FAILED';
  static const String keyRestoreFailed = 'KEY_RESTORE_FAILED';
  static const String keyRotationFailed = 'KEY_ROTATION_FAILED';
}

/// Validation error codes
class ValidationErrorCodes {
  static const String invalidInput = 'INVALID_INPUT';
  static const String fieldRequired = 'FIELD_REQUIRED';
  static const String fieldTooLong = 'FIELD_TOO_LONG';
  static const String fieldTooShort = 'FIELD_TOO_SHORT';
  static const String invalidFormat = 'INVALID_FORMAT';
  static const String contentTooLong = 'CONTENT_TOO_LONG';
  static const String nameTooLong = 'NAME_TOO_LONG';
  static const String emptyContent = 'EMPTY_CONTENT';
  static const String emptyName = 'EMPTY_NAME';
}

/// Error message mappings
class ErrorMessages {
  /// Authentication error messages
  static const Map<String, String> auth = {
    AuthErrorCodes.notConfigured: 
      'Authentication not configured. Please set up authentication first.',
    AuthErrorCodes.biometricNotAvailable: 
      'Biometric authentication is not available on this device.',
    AuthErrorCodes.authFailed: 
      'Authentication failed. Please try again.',
    AuthErrorCodes.setupCancelled: 
      'Authentication setup was cancelled.',
    AuthErrorCodes.setupFailed: 
      'Failed to setup authentication.',
    AuthErrorCodes.disableFailed: 
      'Failed to disable authentication.',
    AuthErrorCodes.enableFailed: 
      'Failed to enable authentication.',
  };

  /// Encryption error messages
  static const Map<String, String> encryption = {
    EncryptionErrorCodes.noKeyAvailable: 
      'No encryption key available. Please generate or set a key pair.',
    EncryptionErrorCodes.privateKeyMissing: 
      'Private key not available for this operation.',
    EncryptionErrorCodes.encryptionFailed: 
      'Failed to encrypt content. Please check your encryption key.',
    EncryptionErrorCodes.decryptionFailed: 
      'Failed to decrypt content. Data may be corrupted or key invalid.',
    EncryptionErrorCodes.keyGenerationFailed: 
      'Failed to generate encryption key pair.',
    EncryptionErrorCodes.invalidKeyPair: 
      'Invalid key pair provided.',
    EncryptionErrorCodes.keyRetrievalFailed: 
      'Failed to retrieve encryption key.',
    EncryptionErrorCodes.keyStorageFailed: 
      'Failed to store encryption key.',
    EncryptionErrorCodes.corruptedKeyData: 
      'Stored key data appears to be corrupted.',
    EncryptionErrorCodes.privateKeyRequired: 
      'This operation requires a private key.',
  };

  /// Storage error messages
  static const Map<String, String> storage = {
    StorageErrorCodes.lockboxRetrievalFailed: 
      'Failed to retrieve lockboxes from storage.',
    StorageErrorCodes.lockboxSaveFailed: 
      'Failed to save lockbox to storage.',
    StorageErrorCodes.lockboxNotFound: 
      'The requested lockbox was not found.',
    StorageErrorCodes.duplicateLockboxId: 
      'A lockbox with this ID already exists.',
    StorageErrorCodes.contentRetrievalFailed: 
      'Failed to retrieve encrypted content.',
    StorageErrorCodes.contentSaveFailed: 
      'Failed to save encrypted content.',
    StorageErrorCodes.preferencesRetrievalFailed: 
      'Failed to retrieve user preferences.',
    StorageErrorCodes.preferencesSaveFailed: 
      'Failed to save user preferences.',
    StorageErrorCodes.clearDataFailed: 
      'Failed to clear application data.',
  };

  /// Lockbox error messages
  static const Map<String, String> lockbox = {
    LockboxErrorCodes.noEncryptionKey: 
      'No encryption key available. Please set up encryption first.',
    LockboxErrorCodes.authenticationRequired: 
      'Authentication required to access lockbox content.',
    LockboxErrorCodes.createFailed: 
      'Failed to create lockbox.',
    LockboxErrorCodes.retrievalFailed: 
      'Failed to retrieve lockboxes.',
    LockboxErrorCodes.contentRetrievalFailed: 
      'Failed to retrieve lockbox content.',
    LockboxErrorCodes.updateFailed: 
      'Failed to update lockbox.',
    LockboxErrorCodes.nameUpdateFailed: 
      'Failed to update lockbox name.',
    LockboxErrorCodes.deleteFailed: 
      'Failed to delete lockbox.',
    LockboxErrorCodes.authenticationFailed: 
      'Authentication failed when accessing lockbox.',
    LockboxErrorCodes.lockboxNotFound: 
      'The requested lockbox was not found.',
    LockboxErrorCodes.contentNotFound: 
      'Encrypted content for this lockbox was not found.',
    LockboxErrorCodes.invalidName: 
      'Invalid lockbox name. Please use a valid name.',
    LockboxErrorCodes.nameTooLong: 
      'Lockbox name is too long. Maximum 100 characters allowed.',
    LockboxErrorCodes.contentTooLong: 
      'Content is too long. Maximum 4,000 characters allowed.',
  };

  /// Key service error messages
  static const Map<String, String> keyService = {
    KeyServiceErrorCodes.keyGenerationFailed: 
      'Failed to generate new encryption key.',
    KeyServiceErrorCodes.keyRetrievalFailed: 
      'Failed to retrieve current encryption key.',
    KeyServiceErrorCodes.invalidKey: 
      'Invalid encryption key provided.',
    KeyServiceErrorCodes.keySetFailed: 
      'Failed to set encryption key.',
    KeyServiceErrorCodes.noKeyToExport: 
      'No encryption key available to export.',
    KeyServiceErrorCodes.publicKeyOnly: 
      'Cannot export public-only key.',
    KeyServiceErrorCodes.keyExportFailed: 
      'Failed to export encryption key backup.',
    KeyServiceErrorCodes.invalidBackupFormat: 
      'Invalid key backup format.',
    KeyServiceErrorCodes.invalidImportedKey: 
      'The imported key is not valid.',
    KeyServiceErrorCodes.keyImportFailed: 
      'Failed to import encryption key.',
    KeyServiceErrorCodes.keyRestoreFailed: 
      'Failed to restore key from backup.',
    KeyServiceErrorCodes.keyRotationFailed: 
      'Failed to rotate encryption key.',
  };

  /// Validation error messages
  static const Map<String, String> validation = {
    ValidationErrorCodes.fieldRequired: 
      'This field is required.',
    ValidationErrorCodes.fieldTooLong: 
      'This field is too long.',
    ValidationErrorCodes.fieldTooShort: 
      'This field is too short.',
    ValidationErrorCodes.invalidFormat: 
      'Invalid format for this field.',
    ValidationErrorCodes.contentTooLong: 
      'Content exceeds the maximum length of 4,000 characters.',
    ValidationErrorCodes.nameTooLong: 
      'Name exceeds the maximum length of 100 characters.',
    ValidationErrorCodes.emptyContent: 
      'Content cannot be empty.',
    ValidationErrorCodes.emptyName: 
      'Name cannot be empty.',
  };

  /// Get user-friendly error message for error code
  static String getErrorMessage(String errorCode, {String? fallback}) {
    // Check all error message maps
    String? message = auth[errorCode] ??
        encryption[errorCode] ??
        storage[errorCode] ??
        lockbox[errorCode] ??
        keyService[errorCode] ??
        validation[errorCode];

    return message ?? fallback ?? 'An unexpected error occurred.';
  }

  /// Check if an error code is a user-actionable error
  static bool isUserActionable(String errorCode) {
    const userActionableErrors = {
      AuthErrorCodes.notConfigured,
      AuthErrorCodes.biometricNotAvailable,
      AuthErrorCodes.setupCancelled,
      LockboxErrorCodes.noEncryptionKey,
      LockboxErrorCodes.authenticationRequired,
      LockboxErrorCodes.invalidName,
      LockboxErrorCodes.nameTooLong,
      LockboxErrorCodes.contentTooLong,
      ValidationErrorCodes.contentTooLong,
      ValidationErrorCodes.nameTooLong,
      ValidationErrorCodes.emptyContent,
      ValidationErrorCodes.emptyName,
    };

    return userActionableErrors.contains(errorCode);
  }

  /// Get suggested action for an error code
  static String? getSuggestedAction(String errorCode) {
    const actionSuggestions = {
      AuthErrorCodes.notConfigured: 
        'Go to Settings and set up biometric authentication.',
      AuthErrorCodes.biometricNotAvailable: 
        'Enable biometric authentication in your device settings.',
      LockboxErrorCodes.noEncryptionKey: 
        'Set up encryption by going through the initial setup process.',
      LockboxErrorCodes.authenticationRequired: 
        'Authenticate using your biometric or device passcode.',
      LockboxErrorCodes.nameTooLong: 
        'Reduce the lockbox name to 100 characters or fewer.',
      LockboxErrorCodes.contentTooLong: 
        'Reduce the content to 4,000 characters or fewer.',
      ValidationErrorCodes.contentTooLong: 
        'Try splitting your content into multiple lockboxes.',
    };

    return actionSuggestions[errorCode];
  }
}

/// Error severity levels
enum ErrorSeverity {
  info,    // Informational messages
  warning, // Warnings that don't prevent operation
  error,   // Errors that prevent operation
  critical // Critical errors that may affect security
}

/// Error categorization helper
class ErrorCategories {
  /// Get the severity level for an error code
  static ErrorSeverity getSeverity(String errorCode) {
    // Critical security errors
    const critical = {
      EncryptionErrorCodes.corruptedKeyData,
      StorageErrorCodes.clearDataFailed,
      LockboxErrorCodes.authenticationFailed,
    };

    // Standard errors that prevent operation
    const errors = {
      AuthErrorCodes.authFailed,
      EncryptionErrorCodes.encryptionFailed,
      EncryptionErrorCodes.decryptionFailed,
      StorageErrorCodes.lockboxSaveFailed,
      LockboxErrorCodes.createFailed,
      LockboxErrorCodes.updateFailed,
      LockboxErrorCodes.deleteFailed,
    };

    // Warnings that don't prevent operation
    const warnings = {
      AuthErrorCodes.setupCancelled,
      LockboxErrorCodes.lockboxNotFound,
      ValidationErrorCodes.fieldTooLong,
    };

    if (critical.contains(errorCode)) return ErrorSeverity.critical;
    if (errors.contains(errorCode)) return ErrorSeverity.error;
    if (warnings.contains(errorCode)) return ErrorSeverity.warning;
    return ErrorSeverity.info;
  }

  /// Check if an error should trigger security measures
  static bool requiresSecurityAction(String errorCode) {
    const securityErrors = {
      EncryptionErrorCodes.corruptedKeyData,
      EncryptionErrorCodes.keyRetrievalFailed,
      LockboxErrorCodes.authenticationFailed,
      AuthErrorCodes.authFailed,
    };

    return securityErrors.contains(errorCode);
  }
}