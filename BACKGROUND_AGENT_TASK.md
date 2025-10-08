# 🤖 Background Agent Task: Complete Riverpod Migration

## Objective
Migrate all remaining Flutter screens from StatefulWidget with manual state management to Riverpod architecture.

## Reference Implementation
✅ **SUCCESS EXAMPLE:** `lib/screens/lockbox_list_screen.dart`
- Study this file to understand the pattern
- It went from StatefulWidget (432 lines) → ConsumerWidget (413 lines, cleaner)
- Uses `ref.watch()`, `AsyncValue.when()`, extracted widgets

✅ **EXISTING PROVIDERS:**
- `lib/providers/lockbox_provider.dart` - StreamProvider + Repository pattern
- `lib/providers/key_provider.dart` - FutureProvider pattern

## Your Task: Migrate 9 Screens

### Order of Execution (Easiest → Hardest):

1. **lib/screens/edit_lockbox_screen.dart**
   - Create: No new provider needed (uses lockbox_provider)
   - Pattern: Simple form screen

2. **lib/screens/lockbox_detail_screen.dart**
   - Create: No new provider needed (uses lockbox_provider)
   - Pattern: Detail view with actions

3. **lib/screens/relay_management_screen.dart**
   - Create: `lib/providers/relay_provider.dart`
   - Pattern: List with CRUD operations

4. **lib/screens/backup_config_screen.dart**
   - Create: `lib/providers/backup_provider.dart`
   - Pattern: Configuration screen with async operations

5. **lib/screens/create_lockbox_with_backup_screen.dart**
   - Uses: lockbox_provider, backup_provider
   - Pattern: Multi-step form

6. **lib/screens/recovery_notification_overlay.dart**
   - Create: `lib/providers/recovery_provider.dart`
   - Pattern: Notification overlay with stream

7. **lib/screens/recovery_request_screen.dart**
   - Uses: recovery_provider
   - Pattern: Complex form with async validation

8. **lib/screens/recovery_request_detail_screen.dart**
   - Uses: recovery_provider, backup_provider
   - Pattern: Complex state machine with real-time updates

9. **lib/screens/recovery_status_screen.dart**
   - Uses: recovery_provider
   - Pattern: Real-time status monitoring

## Required Pattern for Each Screen

### 1. Analyze Current Screen
Read the screen file and identify:
```
What data does it fetch? → Create/use FutureProvider or StreamProvider
What state does it manage? → Move to provider
What services does it call? → Wrap in Repository
Any subscriptions? → Convert to StreamProvider
```

### 2. Create Provider (if needed)
```dart
// lib/providers/[service]_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// For streams (real-time data)
final dataStreamProvider = StreamProvider<List<Item>>((ref) async* {
  final initial = await Service.getInitial();
  yield initial;
  await for (final data in Service.stream) {
    yield data;
  }
});

// For one-time async (fetch once)
final dataProvider = FutureProvider<Data>((ref) async {
  return await Service.getData();
});

// For operations (mutations)
final repositoryProvider = Provider<Repository>((ref) {
  return Repository(ref);
});

class Repository {
  final Ref _ref;
  Repository(this._ref);
  
  Future<void> updateData(Data data) async {
    await Service.update(data);
    _ref.invalidate(dataProvider); // Refresh!
  }
}
```

### 3. Convert Screen
```dart
// BEFORE:
class MyScreen extends StatefulWidget { ... }
class _MyScreenState extends State<MyScreen> {
  bool _isLoading = true;
  Data? _data;
  
  @override
  void initState() {
    _loadData();
  }
  // ... setState(), dispose(), etc.
}

// AFTER:
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);
    
    return dataAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
      data: (data) => SuccessView(data),
    );
  }
}
```

### 4. Handle User Actions
```dart
// In buttons/forms:
ElevatedButton(
  onPressed: () async {
    await ref.read(repositoryProvider).doAction();
    // Provider auto-refreshes if using ref.invalidate()
  },
)
```

## Quality Checklist (For Each Screen)

Before moving to next screen:
- [ ] No StatefulWidget (unless needed for TextEditingController)
- [ ] No manual setState() for data
- [ ] No manual StreamSubscription
- [ ] Uses ref.watch() for reactive data
- [ ] Uses ref.read() for actions
- [ ] Uses AsyncValue.when() for async data
- [ ] Extracted large widgets into separate classes
- [ ] Hot reload works ✅
- [ ] Screen functions correctly ✅
- [ ] No linter errors ✅

## Commit After Each Screen
```bash
git add lib/screens/[screen].dart lib/providers/[provider].dart
git commit -m "feat: migrate [screen_name] to Riverpod"
```

## Important Services to Know

These static service classes need to be wrapped in providers:
- `LockboxService` → lockbox_provider ✅
- `KeyService` → key_provider ✅
- `RecoveryService` → recovery_provider (create)
- `BackupService` → backup_provider (create)
- `RelayScanService` → relay_provider (create)
- `LockboxShareService` → Can use lockbox/backup providers
- `ShardDistributionService` → Can use backup_provider

## Key Rules

1. **Never use static service calls in widgets** → Always through providers
2. **Always use AsyncValue.when()** for FutureProvider/StreamProvider
3. **ref.watch() in build()** → subscribes and rebuilds
4. **ref.read() in callbacks** → one-time read without subscribing
5. **ref.invalidate() after mutations** → refreshes cached data
6. **Extract complex widgets** → Keep files readable
7. **Follow lockbox_list_screen.dart pattern** → It's your north star

## Getting Started

1. Read `.cursor/riverpod_migration_prompt.md` for detailed guidance
2. Check `.cursor/migration_checklist.md` and tick off as you complete
3. Start with `edit_lockbox_screen.dart` (simplest)
4. Test thoroughly after each migration
5. Commit atomically

## Success Criteria

When done:
- [ ] All 9 screens migrated
- [ ] All new providers created and tested
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes  
- [ ] App runs smoothly on macos
- [ ] All user flows tested
- [ ] Migration checklist complete

## Need Help?

If stuck:
- Reference `lib/screens/lockbox_list_screen.dart`
- Check existing providers for patterns
- Ask the user for clarification on complex state

---

**Start here:** `lib/screens/edit_lockbox_screen.dart`

Good luck! 🚀

