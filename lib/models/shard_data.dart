import 'lockbox.dart';

/// Represents the decrypted shard data contained within a ShardEvent
///
/// This model contains the actual Shamir share data that is encrypted
/// and stored in the ShardEvent for distribution to key holders.
typedef ShardData = ({
  String shard,
  int threshold,
  int shardIndex,
  int totalShards,
  String primeMod,
  String creatorPubkey,
  int createdAt,
});

/// Create a new ShardData with validation
ShardData createShardData({
  required String shard,
  required int threshold,
  required int shardIndex,
  required int totalShards,
  required String primeMod,
  required String creatorPubkey,
}) {
  if (shard.isEmpty) {
    throw ArgumentError('Shard cannot be empty');
  }
  if (threshold < LockboxBackupConstraints.minThreshold || threshold > totalShards) {
    throw ArgumentError(
        'Threshold must be >= ${LockboxBackupConstraints.minThreshold} and <= totalShards');
  }
  if (shardIndex < 0 || shardIndex >= totalShards) {
    throw ArgumentError('ShardIndex must be >= 0 and < totalShards');
  }
  if (primeMod.isEmpty) {
    throw ArgumentError('PrimeMod cannot be empty');
  }
  if (creatorPubkey.isEmpty) {
    throw ArgumentError('CreatorPubkey cannot be empty');
  }

  return (
    shard: shard,
    threshold: threshold,
    shardIndex: shardIndex,
    totalShards: totalShards,
    primeMod: primeMod,
    creatorPubkey: creatorPubkey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp
  );
}

/// Create a copy of this ShardData with updated fields
ShardData copyShardData(
  ShardData shardData, {
  String? shard,
  int? threshold,
  int? shardIndex,
  int? totalShards,
  String? primeMod,
  String? creatorPubkey,
  int? createdAt,
}) {
  return (
    shard: shard ?? shardData.shard,
    threshold: threshold ?? shardData.threshold,
    shardIndex: shardIndex ?? shardData.shardIndex,
    totalShards: totalShards ?? shardData.totalShards,
    primeMod: primeMod ?? shardData.primeMod,
    creatorPubkey: creatorPubkey ?? shardData.creatorPubkey,
    createdAt: createdAt ?? shardData.createdAt,
  );
}

/// Extension methods for ShardData
extension ShardDataExtension on ShardData {
  /// Check if this shard data is valid
  bool get isValid {
    try {
      if (shard.isEmpty) return false;
      if (threshold < LockboxBackupConstraints.minThreshold || threshold > totalShards)
        return false;
      if (shardIndex < 0 || shardIndex >= totalShards) return false;
      if (primeMod.isEmpty) return false;
      if (creatorPubkey.isEmpty) return false;
      if (createdAt <= 0) return false;

      // Validate base64 encoding
      if (!_isValidBase64(shard)) return false;
      if (!_isValidBase64(primeMod)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the age of this shard data in seconds
  int get ageInSeconds {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - createdAt;
  }

  /// Get the age of this shard data in hours
  double get ageInHours {
    return ageInSeconds / 3600.0;
  }

  /// Check if this shard data is recent (less than 24 hours old)
  bool get isRecent {
    return ageInHours < 24.0;
  }
}

/// Convert to JSON for storage
Map<String, dynamic> shardDataToJson(ShardData shardData) {
  return {
    'share': shardData.shard,
    'threshold': shardData.threshold,
    'share_index': shardData.shardIndex,
    'total_shares': shardData.totalShards,
    'prime_mod': shardData.primeMod,
    'creator_pubkey': shardData.creatorPubkey,
    'createdAt': shardData.createdAt,
  };
}

/// Create from JSON
ShardData shardDataFromJson(Map<String, dynamic> json) {
  return (
    shard: json['shard'] as String,
    threshold: json['threshold'] as int,
    shardIndex: json['shardIndex'] as int,
    totalShards: json['totalShards'] as int,
    primeMod: json['primeMod'] as String,
    creatorPubkey: json['creatorPubkey'] as String,
    createdAt: json['createdAt'] as int,
  );
}

/// String representation of ShardData
String shardDataToString(ShardData shardData) {
  return 'ShardData(shardIndex: ${shardData.shardIndex}/${shardData.totalShards}, '
      'threshold: ${shardData.threshold}, creator: ${shardData.creatorPubkey.substring(0, 8)}...)';
}

/// Validate base64 encoding
bool _isValidBase64(String str) {
  if (str.isEmpty) return false;

  try {
    // Check if string contains only valid base64 characters
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    if (!base64Regex.hasMatch(str)) return false;

    // Try to decode to verify it's valid base64
    // Note: This is a basic check - actual decoding would require base64 library
    return str.length % 4 == 0 || str.endsWith('=') || str.endsWith('==');
  } catch (e) {
    return false;
  }
}
