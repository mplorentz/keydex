# Quickstart: Lockbox Recovery

**Feature**: 003-lockbox-recovery  
**Date**: 2024-12-19  
**Status**: Complete

## Overview

This quickstart guide demonstrates the complete lockbox recovery workflow, from setting up relay scanning to successfully recovering a lockbox.

## Prerequisites

- Keydex app installed and configured
- At least one lockbox with distributed backup
- Access to Nostr relays
- Key shares distributed to other key holders

## Step-by-Step Workflow

### 1. Configure Relay Scanning

**Objective**: Set up relay scanning to receive key shares and recovery requests

**Steps**:
1. Open Keydex app
2. Navigate to lockbox list screen
3. Tap "Scan for Keys" button
4. Add relay configurations:
   - Tap "Add Relay"
   - Enter relay URL (e.g., `wss://relay.example.com`)
   - Enter friendly name (e.g., "My Trusted Relay")
   - Enable scanning
   - Save configuration
5. Repeat for additional relays
6. Start scanning by tapping "Start Scanning"

**Expected Result**: 
- Relay list shows configured relays
- Scanning status shows "Active"
- App begins monitoring relays for incoming shares

### 2. Receive Key Share

**Objective**: Receive and accept a key share for a lockbox

**Steps**:
1. Wait for incoming key share notification
2. Tap notification to view details
3. Review lockbox information:
   - Lockbox name
   - Key holder information
   - Share details
4. Tap "Accept Share"
5. Confirm acceptance in dialog
6. Share is added to local storage

**Expected Result**:
- New lockbox appears in list with "Key Holder" badge
- Lockbox shows "Recovery Available" status
- Share is securely stored locally

### 3. Initiate Recovery

**Objective**: Start recovery process for a lockbox you have a key share for

**Steps**:
1. Navigate to lockbox detail screen
2. Tap "Initiate Recovery" button
3. Review recovery information:
   - Required key holders
   - Current status
   - Recovery progress
4. Confirm recovery initiation
5. Recovery requests are sent to all key holders

**Expected Result**:
- Recovery request created
- Status shows "Waiting for Responses"
- Key holder list shows "Pending" for all holders
- Nostr events sent to key holders

### 4. Respond to Recovery Request

**Objective**: Approve or deny a recovery request from another key holder

**Steps**:
1. Receive recovery request notification
2. Tap notification to view request details
3. Review request information:
   - Initiator information
   - Lockbox details
   - Request timestamp
4. Choose response:
   - Tap "Approve" to share your shard data
   - Tap "Deny" to reject request
5. Confirm response in dialog
6. Response is sent via Nostr

**Expected Result**:
- Notification disappears from list
- Response status updated in initiator's view
- Shard data sent if approved

### 5. Monitor Recovery Progress

**Objective**: Track recovery progress and key holder responses

**Steps**:
1. Navigate to recovery request detail screen
2. View key holder status:
   - "Approved" - key holder shared their shard data
   - "Denied" - key holder rejected request
   - "Pending" - waiting for response
3. Monitor progress indicator
4. Check if threshold is met for recovery

**Expected Result**:
- Real-time status updates
- Progress indicator shows completion percentage
- Threshold status clearly displayed

### 6. Complete Recovery

**Objective**: Successfully recover lockbox content when sufficient shares are collected

**Steps**:
1. Wait for sufficient key holder approvals
2. System automatically reassembles content from collected shard data
3. Recovery status changes to "Completed"
4. Navigate to lockbox detail screen
5. View recovered content
6. Content is now available locally

**Expected Result**:
- Lockbox status shows "Recovered"
- Content is accessible and readable
- Recovery request marked as completed
- Local storage updated with recovered content

## Test Scenarios

### Scenario 1: Successful Recovery
- **Given**: 3 key holders, threshold of 2
- **When**: 2 key holders approve recovery with shard data
- **Then**: Lockbox content is successfully recovered

### Scenario 2: Partial Recovery
- **Given**: 3 key holders, threshold of 2
- **When**: 1 key holder approves, 1 denies
- **Then**: Recovery remains in progress, waiting for more approvals

### Scenario 3: Recovery Denial
- **Given**: Recovery request sent to key holder
- **When**: Key holder denies request
- **Then**: Request is marked as denied, no shard data provided

### Scenario 4: Timeout Handling
- **Given**: Recovery request sent to unresponsive key holder
- **When**: No response within timeout period
- **Then**: Status shows "Timeout", recovery continues with other holders

## Troubleshooting

### Common Issues

**Issue**: Relay scanning not working
- **Solution**: Check relay URL format, verify network connectivity
- **Prevention**: Test relay connection before adding

**Issue**: Recovery request not received
- **Solution**: Verify relay configuration, check Nostr event delivery
- **Prevention**: Use multiple trusted relays

**Issue**: Shard data not accepted
- **Solution**: Verify shard data format, check storage permissions
- **Prevention**: Ensure sufficient local storage space

**Issue**: Recovery stuck in progress
- **Solution**: Check key holder responsiveness, verify threshold settings
- **Prevention**: Maintain contact with key holders

### Error Messages

- **"Relay connection failed"**: Check network and relay URL
- **"Invalid shard data format"**: Shard data may be corrupted, request new share
- **"Insufficient shares for recovery"**: Need more key holder approvals
- **"Recovery request expired"**: Request timed out, initiate new recovery

## Security Considerations

- All shard data is encrypted before storage
- Recovery requests include expiration timestamps
- Nostr events are end-to-end encrypted
- Local storage uses platform secure storage
- No sensitive data logged or transmitted in plaintext

## Performance Notes

- Relay scanning runs in background
- Recovery requests have 24-hour expiration
- Shard data validation is performed locally
- UI updates are optimized for responsiveness
- Storage operations are asynchronous
