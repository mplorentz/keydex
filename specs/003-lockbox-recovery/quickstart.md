# Quickstart: Vault Recovery

**Feature**: 003-vault-recovery  
**Date**: 2024-12-19  
**Status**: Complete

## Overview

This quickstart guide demonstrates the complete vault recovery workflow, from setting up relay scanning to successfully recovering a vault.

## Prerequisites

- Horcrux app installed and configured
- At least one vault with distributed backup
- Access to Nostr relays
- Key shares distributed to other stewards

## Step-by-Step Workflow

### 1. Configure Relay Scanning

**Objective**: Set up relay scanning to receive key shares and recovery requests

**Steps**:
1. Open Horcrux app
2. Navigate to vault list screen
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

**Objective**: Receive and accept a key share for a vault

**Steps**:
1. Wait for incoming key share notification
2. Tap notification to view details
3. Review vault information:
   - Vault name
   - Key holder information
   - Share details
4. Tap "Accept Share"
5. Confirm acceptance in dialog
6. Share is added to local storage

**Expected Result**:
- New vault appears in list with "Steward" badge
- Vault shows "Recovery Available" status
- Share is securely stored locally

### 3. Initiate Recovery

**Objective**: Start recovery process for a vault you have a key share for

**Steps**:
1. Navigate to vault detail screen
2. Tap "Initiate Recovery" button
3. Review recovery information:
   - Required stewards
   - Current status
   - Recovery progress
4. Confirm recovery initiation
5. Recovery requests are sent to all stewards

**Expected Result**:
- Recovery request created
- Status shows "Waiting for Responses"
- Key holder list shows "Pending" for all holders
- Nostr events sent to stewards

### 4. Respond to Recovery Request

**Objective**: Approve or deny a recovery request from another steward

**Steps**:
1. Receive recovery request notification
2. Tap notification to view request details
3. Review request information:
   - Initiator information
   - Vault details
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

**Objective**: Track recovery progress and steward responses

**Steps**:
1. Navigate to recovery request detail screen
2. View steward status:
   - "Approved" - steward shared their shard data
   - "Denied" - steward rejected request
   - "Pending" - waiting for response
3. Monitor progress indicator
4. Check if threshold is met for recovery

**Expected Result**:
- Real-time status updates
- Progress indicator shows completion percentage
- Threshold status clearly displayed

### 6. Complete Recovery

**Objective**: Successfully recover vault content when sufficient shares are collected

**Steps**:
1. Wait for sufficient steward approvals
2. System automatically reassembles content from collected shard data
3. Recovery status changes to "Completed"
4. Navigate to vault detail screen
5. View recovered content
6. Content is now available locally

**Expected Result**:
- Vault status shows "Recovered"
- Content is accessible and readable
- Recovery request marked as completed
- Local storage updated with recovered content

## Test Scenarios

### Scenario 1: Successful Recovery
- **Given**: 3 stewards, threshold of 2
- **When**: 2 stewards approve recovery with shard data
- **Then**: Vault content is successfully recovered

### Scenario 2: Partial Recovery
- **Given**: 3 stewards, threshold of 2
- **When**: 1 steward approves, 1 denies
- **Then**: Recovery remains in progress, waiting for more approvals

### Scenario 3: Recovery Denial
- **Given**: Recovery request sent to steward
- **When**: Key holder denies request
- **Then**: Request is marked as denied, no shard data provided

### Scenario 4: Timeout Handling
- **Given**: Recovery request sent to unresponsive steward
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
- **Solution**: Check steward responsiveness, verify threshold settings
- **Prevention**: Maintain contact with stewards

### Error Messages

- **"Relay connection failed"**: Check network and relay URL
- **"Invalid shard data format"**: Shard data may be corrupted, request new share
- **"Insufficient shares for recovery"**: Need more steward approvals
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
