# Background Task: Migrate All Screens to Riverpod Architecture

## Context
We have successfully migrated `lockbox_list_screen.dart` to use Riverpod architecture. Now we need to apply the same pattern to all remaining screens in the application.

**Current Branch:** `riverpod-migration-all-screens`  
**Parent Branch:** `riverpod`

## What Was Done (Reference Implementation)

### Files Already Migrated:
1. ✅ `lib/screens/lockbox_list_screen.dart` - **USE THIS AS THE PATTERN**
2. ✅ `lib/providers/lockbox_provider.dart` - Created
3. ✅ `lib/providers/key_provider.dart` - Created
4. ✅ `lib/main.dart` - Wrapped with ProviderScope
5. ✅ `pubspec.yaml` - Added flutter_riverpod: ^2.6.1

## Screens That Need Migration

1. `lib/screens/backup_config_screen.dart`
2. `lib/screens/create_lockbox_with_backup_screen.dart`
3. `lib/screens/edit_lockbox_screen.dart`
4. `lib/screens/lockbox_detail_screen.dart`
5. `lib/screens/recovery_notification_overlay.dart`
6. `lib/screens/recovery_request_detail_screen.dart`
7. `lib/screens/recovery_request_screen.dart`
8. `lib/screens/recovery_status_screen.dart`
9. `lib/screens/relay_management_screen.dart`

## Migration Pattern to Follow

### Step 1: Analyze Each Screen
For each screen, identify:
- What state does it manage? (StatefulWidget state variables)
- What data does it load? (Future/Stream data sources)
- What services does it call? (Static service method calls)
- Are there any listeners/subscriptions? (StreamSubscriptions, etc.)

### Step 2: Create Providers (if needed)
Create new provider files in `lib/providers/` following these patterns:

**For async one-time data loading:**
```dart
final someDataProvider = FutureProvider<DataType>((ref) async {
  return await SomeService.getData();
});
```

**For streaming data:**
```dart
final someStreamProvider = StreamProvider<DataType>((ref) async* {
  // Yield initial data if needed
  final initial = await SomeService.getInitialData();
  yield initial;
  
  // Then stream updates
  await for (final data in SomeService.dataStream) {
    yield data;
  }
});
```

**For repository/operations:**
```dart
final someRepositoryProvider = Provider<SomeRepository>((ref) {
  return SomeRepository(ref);
});

class SomeRepository {
  final Ref _ref;
  SomeRepository(this._ref);
  
  Future<void> doSomething() async {
    await SomeService.doSomething();
    _ref.invalidate(someDataProvider); // Refresh after mutation
  }
}
```

### Step 3: Convert Screen Widget

**Before (StatefulWidget):**
```dart
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoading = true;
  String? _data;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final data = await SomeService.getData();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading ? Loading() : Text(_data!);
  }
}
```

**After (ConsumerWidget):**
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(someDataProvider);
    
    return dataAsync.when(
      loading: () => Loading(),
      error: (err, stack) => ErrorWidget(err),
      data: (data) => Text(data),
    );
  }
}
```

### Step 4: Handle Mutations
For actions that modify data:

```dart
// In screen
ElevatedButton(
  onPressed: () async {
    await ref.read(someRepositoryProvider).updateData(newValue);
    // Provider auto-refreshes if using invalidate()
  },
  child: Text('Update'),
)
```

### Step 5: Extract Complex Widgets
Follow the pattern from `lockbox_list_screen.dart`:
- Extract card/list item widgets as private `_WidgetName` classes
- Use `ConsumerWidget` for widgets that need providers
- Use `StatelessWidget` for pure presentational widgets

## Key Riverpod Concepts

### ref.watch() vs ref.read() vs ref.listen()
- `ref.watch()` - Rebuilds when provider changes (use in build methods)
- `ref.read()` - One-time read without listening (use in callbacks/methods)
- `ref.listen()` - Listen without rebuilding (use for side effects like navigation/snackbars)

### AsyncValue.when()
Always use this pattern for FutureProvider and StreamProvider:
```dart
asyncValue.when(
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorDisplay(error),
  data: (data) => SuccessWidget(data),
)
```

### Invalidating Providers
After mutations, refresh data:
```dart
ref.invalidate(someProvider); // Resets and refetches
ref.refresh(someProvider);    // Forces immediate refetch
```

## Testing Strategy

After migrating each screen:
1. Hot reload the app
2. Navigate to the screen
3. Verify all data loads correctly
4. Test all user interactions (buttons, forms, etc.)
5. Test error states if possible
6. Verify no memory leaks (no manual subscription management needed)

## Additional Providers Likely Needed

Based on the services in the codebase, you'll likely need:

1. **Recovery Provider** (`lib/providers/recovery_provider.dart`)
   - RecoveryRequest stream/list
   - RecoveryNotification stream/list
   - Recovery operations (request, contribute shard, etc.)

2. **Backup Provider** (`lib/providers/backup_provider.dart`)
   - KeyHolder stream/list
   - ShardEvent stream/list
   - Backup operations

3. **Relay Provider** (`lib/providers/relay_provider.dart`)
   - Relay list
   - Scan operations
   - Connection status

## Code Quality Guidelines

1. **No manual setState()** - Use providers instead
2. **No manual stream subscriptions** - Use StreamProvider
3. **No static service calls in widgets** - Use providers
4. **Extract widgets** - Keep files under 500 lines
5. **Use AsyncValue.when()** - Don't manually check loading/error states
6. **Proper error handling** - Always handle error case in .when()
7. **Type safety** - Leverage Riverpod's compile-time safety

## Repository Pattern

Follow this structure for consistency:
```
lib/
  providers/
    lockbox_provider.dart     ✅ Done
    key_provider.dart         ✅ Done
    recovery_provider.dart    ← Create
    backup_provider.dart      ← Create
    relay_provider.dart       ← Create
  screens/
    lockbox_list_screen.dart  ✅ Migrated
    [other screens...]        ← Migrate each
```

## Success Criteria

For each migrated screen:
- [ ] No StatefulWidget (unless absolutely necessary for form controllers, etc.)
- [ ] No manual setState() calls for data loading
- [ ] No manual stream subscription management
- [ ] All data access through providers
- [ ] Proper loading/error/data states with AsyncValue.when()
- [ ] Code compiles without errors
- [ ] App runs and screen functions correctly
- [ ] No linter warnings

## Commit Strategy

Make atomic commits for each screen:
```
git add lib/screens/backup_config_screen.dart lib/providers/backup_provider.dart
git commit -m "feat: migrate backup_config_screen to Riverpod"
```

## Final Deliverable

When all screens are migrated:
1. Run full app and test all flows
2. Run linter: `flutter analyze`
3. Run tests: `flutter test`
4. Create a summary of what was changed
5. Ready for PR review

## Questions/Clarifications Needed

If you encounter:
- Complex state that doesn't fit the pattern → Ask for guidance
- Performance issues with providers → Consider using select() or family modifiers
- Circular dependencies → Restructure provider dependencies

## Reference Files

Look at these for examples:
- `lib/screens/lockbox_list_screen.dart` - Main reference
- `lib/providers/lockbox_provider.dart` - StreamProvider pattern
- `lib/providers/key_provider.dart` - FutureProvider pattern

Good luck! This is a large refactoring but will make the codebase much cleaner and more maintainable.

