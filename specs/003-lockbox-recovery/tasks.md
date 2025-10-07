# Tasks: Lockbox Recovery

**Feature**: 003-lockbox-recovery  
**Date**: 2024-12-19  
**Status**: In Progress

## Task Execution Rules

- **[P]** = Can run in parallel with other [P] tasks in the same phase
- **Sequential** = Must complete before next task in phase
- **UI-First** = Create stubs for manual verification, then implement functionality

## Phase 0: Setup (Prerequisites)
- [X] 0.1 - Verify existing models (Lockbox, ShardData) are compatible with recovery feature
- [X] 0.2 - Review existing services (BackupService, LockboxService) for reusable patterns

## Phase 1: Data Models [P]
- [X] 1.1 - Create RecoveryRequestStatus enum (pending, sent, in_progress, completed, failed, cancelled)
- [X] 1.2 - Create RecoveryResponseStatus enum (pending, approved, denied, timeout)
- [X] 1.3 - Create RecoveryRequest model with validation rules
- [X] 1.4 - Create RecoveryResponse model with validation rules
- [X] 1.5 - Create RelayConfiguration model with validation rules
- [X] 1.6 - Create RecoveryStatus model with validation rules
- [X] 1.7 - Extend ShardData model with recovery metadata (id, lockboxId, recipientPubkey, isReceived, receivedAt, nostrEventId)

## Phase 2: UI Stubs (Outside-In Development)
- [X] 2.1 - Create relay_management_screen.dart stub with relay list and add relay UI
- [X] 2.2 - Create recovery_notification_overlay.dart stub with notification display
- [X] 2.3 - Update lockbox_detail_screen.dart with "Initiate Recovery" button stub
- [X] 2.4 - Update lockbox_list_screen.dart with "Scan for Keys" button and key holder badge display
- [X] 2.5 - Create recovery_status_screen.dart stub with key holder status display
- [X] 2.6 - Create recovery_request_detail_screen.dart stub with approve/deny actions

## Phase 3: Service Implementations

### Phase 3.1: Recovery Service Core
- [X] 3.1.1 - Implement RecoveryService.initiateRecovery() - create recovery request
- [X] 3.1.2 - Implement RecoveryService.getRecoveryRequests() - fetch all requests
- [X] 3.1.3 - Implement RecoveryService.getRecoveryStatus() - get request status
- [X] 3.1.4 - Implement RecoveryService.respondToRecoveryRequest() - approve/deny
- [X] 3.1.5 - Implement RecoveryService.cancelRecoveryRequest() - cancel request
- [X] 3.1.6 - Implement RecoveryService.canRecoverLockbox() - check recovery availability
- [X] 3.1.7 - Implement RecoveryService.getKeyHolderResponses() - fetch responses

### Phase 3.2: Relay Scan Service
- [X] 3.2.1 - Implement RelayScanService.getRelayConfigurations() - fetch relay configs
- [X] 3.2.2 - Implement RelayScanService.addRelayConfiguration() - add new relay
- [X] 3.2.3 - Implement RelayScanService.updateRelayConfiguration() - update relay
- [X] 3.2.4 - Implement RelayScanService.removeRelayConfiguration() - remove relay
- [X] 3.2.5 - Implement RelayScanService.startRelayScanning() - start background scan
- [X] 3.2.6 - Implement RelayScanService.stopRelayScanning() - stop scan
- [X] 3.2.7 - Implement RelayScanService.isScanningActive() - check scan status
- [X] 3.2.8 - Implement RelayScanService.getScanningStatus() - get scan statistics

### Phase 3.3: Lockbox Share Service
- [X] 3.3.1 - Implement LockboxShareService.getLockboxShares() - fetch shares for lockbox
- [X] 3.3.2 - Implement LockboxShareService.getLockboxShare() - fetch specific share
- [X] 3.3.3 - Implement LockboxShareService.markShareAsReceived() - mark share received
- [X] 3.3.4 - Implement LockboxShareService.reassembleLockboxContent() - reconstruct content
- [X] 3.3.5 - Implement LockboxShareService.hasSufficientShares() - check threshold
- [X] 3.3.6 - Implement LockboxShareService.getCollectedShardData() - get collected shards

### Phase 3.4: Recovery Notification Service
- [X] 3.4.1 - Implement RecoveryNotificationService.getPendingNotifications() - fetch pending
- [X] 3.4.2 - Implement RecoveryNotificationService.markNotificationAsViewed() - mark viewed
- [X] 3.4.3 - Implement RecoveryNotificationService.getNotificationCount() - count notifications
- [X] 3.4.4 - Implement RecoveryNotificationService.clearAllNotifications() - clear all
- [X] 3.4.5 - Implement RecoveryNotificationService.recoveryRequestStream - stream requests
- [X] 3.4.6 - Implement RecoveryNotificationService.notificationStream - stream notifications

## Phase 4: UI Integration (Wire up stubs)
- [X] 4.1 - Connect relay_management_screen to RelayScanService
- [X] 4.2 - Connect recovery_notification_overlay to RecoveryNotificationService
- [X] 4.3 - Connect lockbox_detail_screen "Initiate Recovery" to RecoveryService
- [X] 4.4 - Connect lockbox_list_screen "Scan for Keys" to relay management
- [X] 4.5 - Connect recovery_status_screen to RecoveryService status updates
- [X] 4.6 - Connect recovery_request_detail_screen to RecoveryService respond actions

## Phase 5: Integration Tests
- [ ] 5.1 - Test complete recovery workflow (quickstart scenario 1)
- [ ] 5.2 - Test partial recovery scenario (quickstart scenario 2)
- [ ] 5.3 - Test recovery denial scenario (quickstart scenario 3)
- [ ] 5.4 - Test timeout handling scenario (quickstart scenario 4)
- [ ] 5.5 - Test relay configuration and scanning
- [ ] 5.6 - Test key holder status tracking

## Phase 6: Edge Cases and Polish
- [ ] 6.1 - Handle unresponsive key holders gracefully
- [ ] 6.2 - Handle duplicate recovery requests display
- [ ] 6.3 - Handle recovery initiator going offline
- [ ] 6.4 - Add error handling for invalid shard data
- [ ] 6.5 - Add loading states to all UI components
- [ ] 6.6 - Add proper error messages for all failure scenarios

## Task Count
- Total tasks: 53
- Parallel-capable: 7 (Phase 1)
- Sequential: 46

## Execution Progress
- Phase 0: 2/2 complete ✅
- Phase 1: 7/7 complete ✅
- Phase 2: 6/6 complete ✅
- Phase 3: 27/27 complete ✅
  - 3.1: 7/7 complete ✅
  - 3.2: 8/8 complete ✅
  - 3.3: 6/6 complete ✅
  - 3.4: 6/6 complete ✅
- Phase 4: 6/6 complete ✅
- Phase 5: 0/6 complete
- Phase 6: 0/6 complete
