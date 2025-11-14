# BlossomConfigService Interface

**Purpose**: Manages Blossom server configuration, similar to relay configuration management.

## Service Architecture

```dart
final Provider<BlossomConfigService> blossomConfigServiceProvider = Provider<BlossomConfigService>((ref) {
  return BlossomConfigService();
});
```

## Dependencies

None - uses SharedPreferences directly for storage.

## Public Methods

### Get Configurations

```dart
/// Gets all configured Blossom servers
/// 
/// Returns: List of BlossomServerConfig, empty if none configured
Future<List<BlossomServerConfig>> getAllConfigs() async
```

**Implementation**:
- Load from SharedPreferences key `blossom_server_configs`
- Parse JSON array to BlossomServerConfig objects
- Return empty list if key doesn't exist

### Get Default Server

```dart
/// Gets the default Blossom server for file uploads
/// 
/// Returns: Default BlossomServerConfig or null if none configured
/// Throws: ConfigurationException if multiple defaults found
Future<BlossomServerConfig?> getDefaultServer() async
```

**Implementation**:
- Get all configs
- Filter to those with `isDefault == true`
- Validate only one default exists
- Return null if no default configured

### Get Enabled Servers

```dart
/// Gets all enabled Blossom servers
/// 
/// Returns: List of enabled BlossomServerConfig
Future<List<BlossomServerConfig>> getEnabledServers() async
```

**Implementation**:
- Get all configs
- Filter to those with `isEnabled == true`
- Return in priority order (default first)

### Add Server

```dart
/// Adds a new Blossom server configuration
/// 
/// Parameters:
///   - url: Server URL (HTTP/HTTPS)
///   - name: User-friendly name
///   - isDefault: Whether this should be the default
/// 
/// Returns: Created BlossomServerConfig with generated ID
/// Throws: ValidationException, DuplicateServerException
Future<BlossomServerConfig> addServer({
  required String url,
  required String name,
  bool isDefault = false,
}) async
```

**Validation**:
- URL must be valid HTTP or HTTPS
- URL must not already exist
- Name must not be empty
- If isDefault, clear default flag on other servers

**Implementation**:
1. Validate inputs
2. Generate UUID for new config
3. If isDefault, update existing configs to not default
4. Add to list
5. Save to SharedPreferences
6. Return created config

### Update Server

```dart
/// Updates an existing Blossom server configuration
/// 
/// Parameters:
///   - config: Updated BlossomServerConfig
/// 
/// Throws: NotFoundException, ValidationException
Future<void> updateServer(BlossomServerConfig config) async
```

**Validation**:
- Server ID must exist
- URL must be valid
- If isDefault changed, handle default flag

**Implementation**:
1. Validate config
2. Find existing config by ID
3. If isDefault changed, update other configs
4. Replace config in list
5. Save to SharedPreferences

### Delete Server

```dart
/// Deletes a Blossom server configuration
/// 
/// Parameters:
///   - id: Server config ID to delete
/// 
/// Throws: NotFoundException, CannotDeleteDefaultException
Future<void> deleteServer(String id) async
```

**Validation**:
- Cannot delete default server (must set different default first)
- Server ID must exist

**Implementation**:
1. Validate server exists and is not default
2. Remove from list
3. Save to SharedPreferences

### Set Default Server

```dart
/// Sets a server as the default
/// 
/// Parameters:
///   - id: Server config ID to make default
/// 
/// Throws: NotFoundException
Future<void> setDefaultServer(String id) async
```

**Implementation**:
1. Find server by ID
2. Clear default flag on all servers
3. Set default flag on specified server
4. Save to SharedPreferences

### Test Server Connection

```dart
/// Tests connectivity to a Blossom server
/// 
/// Parameters:
///   - url: Server URL to test
/// 
/// Returns: true if reachable, false otherwise
/// Note: Does not throw, returns false on any error
Future<bool> testConnection(String url) async
```

**Implementation**:
1. Try GET request to server root or info endpoint
2. Check for 200 or 404 (both mean server is up)
3. Return true if reachable, false on timeout or error
4. Timeout after 5 seconds

### Initialize Default Servers

```dart
/// Initializes default Blossom servers for new users
/// 
/// Only runs if no servers configured yet
Future<void> initializeDefaults() async
```

**Default Server**:
- Development: `http://localhost:10548` (local Blossom server)
- Name: "Local Blossom Server"
- Enabled and set as default

**Implementation**:
1. Check if any configs exist
2. If none, add localhost:10548 server
3. Mark as default
4. Production servers can be added by users via settings UI

## State Management

Service is stateless. Uses SharedPreferences for persistence. Configurations loaded on-demand and cached in memory by callers if needed.

## Storage Format

```json
{
  "blossom_server_configs": [
    {
      "id": "uuid-1",
      "url": "https://blossom.example.com",
      "name": "Example Blossom",
      "isEnabled": true,
      "lastUsed": "2025-11-14T12:00:00Z",
      "isDefault": true
    },
    {
      "id": "uuid-2",
      "url": "https://files.nostr.net",
      "name": "Nostr Files",
      "isEnabled": true,
      "lastUsed": null,
      "isDefault": false
    }
  ]
}
```

## Testing Strategy

### Unit Tests

- CRUD operations for server configs
- Default server logic (single default enforcement)
- URL validation
- JSON serialization/deserialization
- Edge cases: empty configs, all disabled, etc.

### Integration Tests

- Persistence across app restarts
- Migration from no configs to defaults
- Concurrent access (if needed)

### Golden Tests

- Blossom configuration UI screen
- Server list display
- Add/edit server forms

## UI Components Needed

1. **Blossom Settings Screen** (similar to relay settings)
   - List of configured servers
   - Add server button
   - Edit/delete per server
   - Default indicator
   - Enable/disable toggle

2. **Add/Edit Server Dialog**
   - URL input field
   - Name input field
   - Set as default checkbox
   - Test connection button
   - Save/Cancel buttons

3. **Server Status Indicator**
   - Show last used date
   - Connection test result
   - Default badge

## Error Handling

- **Invalid URL**: "Please enter a valid HTTP or HTTPS URL"
- **Duplicate Server**: "This server is already configured"
- **Cannot Delete Default**: "Set a different default server first"
- **Connection Failed**: "Could not connect to server. Check URL and try again."

## Performance Considerations

- Config list is small (< 10 servers typically), no pagination needed
- Cache loaded configs in memory if called frequently
- Lazy load - don't load on app start unless needed

## Security Considerations

- URLs validated to prevent injection attacks
- HTTPS enforced for production (allow HTTP for local testing)
- No sensitive data in configs (authentication via Nostr keys)

---
**Related Services**: FileStorageService, NdkService

