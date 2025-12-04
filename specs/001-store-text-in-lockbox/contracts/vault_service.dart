// VaultService Contract
// This file defines the interface for vault operations

abstract class VaultService {
  /// Creates a new encrypted vault
  /// Returns the created vault ID on success
  Future<String> createVault({required String name, required String content});

  /// Retrieves all user vaults (metadata only)
  /// Returns list of vault metadata without decrypted content
  Future<List<VaultMetadata>> getAllVaults();

  /// Retrieves and decrypts a specific vault
  /// Requires authentication before decryption
  Future<VaultContent> getVaultContent(String vaultId);

  /// Updates an existing vault's content
  /// Re-encrypts the new content
  Future<void> updateVault({required String vaultId, required String content});

  /// Updates an existing vault's name
  Future<void> updateVaultName({required String vaultId, required String name});

  /// Permanently deletes a vault
  Future<void> deleteVault(String vaultId);

  /// Authenticates user before sensitive operations
  Future<bool> authenticateUser();
}

/// Vault metadata record - immutable data container
typedef VaultMetadata = ({String id, String name, DateTime createdAt, int size});

/// Vault content record - immutable data container
typedef VaultContent = ({String id, String name, String content, DateTime createdAt});

class VaultException implements Exception {
  final String message;
  final String? errorCode;

  VaultException(this.message, {this.errorCode});
}
