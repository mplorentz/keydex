# Riverpod Migration Checklist

## Phase 1: Core Providers (Create First)
- [x] lockbox_provider.dart
- [x] key_provider.dart
- [ ] recovery_provider.dart
- [ ] backup_provider.dart
- [ ] relay_provider.dart

## Phase 2: Simple Screens (Migrate First)
These are simpler and good for validating the pattern:

- [ ] edit_lockbox_screen.dart
  - Uses: lockbox_provider
  - Complexity: Low (simple form)
  
- [ ] lockbox_detail_screen.dart
  - Uses: lockbox_provider
  - Complexity: Low (display + edit)

## Phase 3: Medium Complexity Screens

- [ ] create_lockbox_with_backup_screen.dart
  - Uses: lockbox_provider, backup_provider
  - Complexity: Medium (multi-step form)

- [ ] backup_config_screen.dart
  - Uses: backup_provider, relay_provider
  - Complexity: Medium (config form)

- [ ] relay_management_screen.dart
  - Uses: relay_provider
  - Complexity: Medium (list + actions)

## Phase 4: Complex Screens

- [ ] recovery_request_screen.dart
  - Uses: recovery_provider, relay_provider
  - Complexity: High (multi-step flow)

- [ ] recovery_request_detail_screen.dart
  - Uses: recovery_provider, backup_provider
  - Complexity: High (complex state machine)

- [ ] recovery_status_screen.dart
  - Uses: recovery_provider
  - Complexity: High (real-time updates)

- [ ] recovery_notification_overlay.dart
  - Uses: recovery_provider
  - Complexity: Medium (overlay with notifications)

## Testing Checklist
After each migration:
- [ ] Hot reload works
- [ ] Screen displays correctly
- [ ] All interactions work
- [ ] No console errors
- [ ] No memory leaks
- [ ] Linter passes

## Final Validation
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Test complete user flows:
  - [ ] Create lockbox → backup → view
  - [ ] Request recovery → contribute shard → complete
  - [ ] Manage relays
  - [ ] Edit/delete lockboxes
- [ ] Check for any remaining StatefulWidget with manual state
- [ ] Review all TODO comments in code

## Known Issues / Notes
(Add any issues or decisions made during migration)

---
Last updated: 2025-10-08

