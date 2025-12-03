# Quickstart: Invitation Links for Stewards

**Feature**: 004-invitation-links  
**Date**: 2025-01-27

## Overview

This document provides step-by-step instructions for testing the invitation links feature end-to-end. It validates that all user stories from the feature specification are working correctly.

## Prerequisites

- Horcrux app installed on at least 2 devices (or simulators)
- At least one vault created with backup configuration
- Access to Nostr relays (for event publishing/receiving)
- Domain horcrux.app configured with Universal Links/App Links (or local testing setup)

## Test Scenario 1: Generate and Share Invitation Link

**User Story**: As a vault owner, I want to generate an invitation link to invite someone as a steward.

### Steps

1. **Open Backup Configuration**
   - Navigate to a vault detail screen
   - Tap "Backup Settings" button
   - Verify backup configuration screen opens

2. **Generate Invitation Link**
   - Select "Invite by Link" option
   - Enter invitee name: "Alice"
   - Tap "Generate Invitation Link"
   - Verify invitation link is displayed
   - Verify "Copy Link" button is available

3. **Copy and Share Link**
   - Tap "Copy Link" button
   - Verify link is copied to clipboard
   - Verify link format: `https://horcrux.app/invite/{inviteCode}?owner={pubkey}&relays={urls}`
   - Share link via text/email (or note it for testing)

### Expected Results

- ✅ Invitation link generated successfully
- ✅ Link contains valid invite code (43 characters, Base64URL)
- ✅ Link contains owner pubkey (hex format)
- ✅ Link contains relay URLs (1-3 URLs)
- ✅ Invitation appears in pending invitations list
- ✅ Invitation status shows as "invited"

## Test Scenario 2: Accept Invitation (Existing User)

**User Story**: As an existing Horcrux user, I want to accept an invitation link to become a steward.

### Steps

1. **Open Invitation Link**
   - From device 2 (or simulator), tap the invitation link
   - Verify app opens (if installed) or prompts to install
   - Verify invitation acceptance screen displays

2. **Review Invitation Details**
   - Verify vault owner information displays
   - Verify invitation details are shown
   - Verify "Accept Invitation" button is available

3. **Accept Invitation**
   - Tap "Accept Invitation" button
   - Confirm acceptance in dialog
   - Verify status message: "Invitation accepted. Waiting for key distribution."

4. **Verify RSVP Event**
   - Check vault owner's device
   - Verify invitation status updated to "redeemed"
   - Verify steward added to backup config
   - Verify steward status shows as "awaiting key"

### Expected Results

- ✅ App opens from invitation link
- ✅ Invitation acceptance screen displays correctly
- ✅ RSVP event published to Nostr relays
- ✅ Vault owner receives RSVP event
- ✅ Invitation marked as redeemed
- ✅ Key holder added to backup config
- ✅ Status updated to "awaiting key"

## Test Scenario 3: Accept Invitation (New User)

**User Story**: As a new user without Horcrux installed, I want to accept an invitation link and set up my account.

### Steps

1. **Open Invitation Link**
   - From device without Horcrux installed, tap invitation link
   - Verify app store/app installation prompt appears
   - Install Horcrux app

2. **Complete Account Setup**
   - Open Horcrux app
   - Verify invitation acceptance flow initiates
   - Complete account setup (create Nostr key pair)
   - Verify invitation details are preserved

3. **Accept Invitation**
   - Review invitation details
   - Tap "Accept Invitation"
   - Verify account setup completes
   - Verify RSVP event is sent

### Expected Results

- ✅ App installation prompt appears
- ✅ Invitation acceptance flow initiates after install
- ✅ Account setup completes successfully
- ✅ RSVP event published after account creation
- ✅ Key holder added to backup config

## Test Scenario 4: Generate and Distribute Keys

**User Story**: As a vault owner, I want to generate and distribute keys after receiving RSVPs from all invited stewards.

### Steps

1. **Check Steward Status**
   - Navigate to vault detail screen
   - Verify steward list shows all invited stewards
   - Verify all stewards have status "awaiting key"

2. **Generate and Distribute Keys**
   - Verify "Generate and Distribute Keys" button appears
   - Tap button
   - Verify key generation progress indicator
   - Wait for distribution to complete

3. **Verify Key Distribution**
   - Verify success message appears
   - Verify shard events published to Nostr relays
   - Check steward devices for shard receipt

### Expected Results

- ✅ Button appears when all stewards have accepted
- ✅ Keys generated successfully
- ✅ Shard events published to relays
- ✅ Key holders receive their shards
- ✅ Shard confirmation events sent automatically

## Test Scenario 5: Steward Confirms Shard Receipt

**User Story**: As a steward, I want to automatically confirm receipt of my shard.

### Steps

1. **Receive Shard**
   - Open Horcrux app on steward device
   - Verify shard is received and processed
   - Verify shard is stored securely

2. **Verify Confirmation Event**
   - Check vault owner's device
   - Verify steward status updated to "holding key"
   - Verify confirmation timestamp updated

### Expected Results

- ✅ Shard received and decrypted successfully
- ✅ Shard stored securely
- ✅ Confirmation event published automatically
- ✅ Vault owner receives confirmation
- ✅ Status updated to "holding key"

## Test Scenario 6: Deny Invitation

**User Story**: As an invitee, I want to deny an invitation if I don't want to be a steward.

### Steps

1. **Open Invitation Link**
   - Tap invitation link
   - Verify invitation acceptance screen displays

2. **Deny Invitation**
   - Tap "Deny" or "Decline" button
   - Optionally enter reason for denial
   - Confirm denial

3. **Verify Denial Event**
   - Check vault owner's device
   - Verify invitation status updated to "denied"
   - Verify invitation code invalidated

### Expected Results

- ✅ Denial event published to Nostr relays
- ✅ Vault owner receives denial event
- ✅ Invitation marked as denied
- ✅ Invitation code invalidated

## Test Scenario 7: Invalid Invitation Code Handling

**User Story**: Handle gracefully when someone tries to redeem an already-used invitation code.

### Steps

1. **Redeem Invitation (First Time)**
   - Accept invitation successfully (from Test Scenario 2)
   - Verify invitation is redeemed

2. **Attempt Second Redemption**
   - Try to redeem same invitation code again
   - Verify error message displays
   - Verify invalid event sent to second attempt

3. **Verify Error Handling**
   - Check vault owner's device
   - Verify invalid event received
   - Verify error logged appropriately

### Expected Results

- ✅ Second redemption attempt fails gracefully
- ✅ Error message displays to user
- ✅ Invalid event sent to vault owner
- ✅ Error logged appropriately

## Test Scenario 8: Duplicate Invitation Handling

**User Story**: Handle gracefully when someone tries to redeem an invitation for a vault they're already a steward for.

### Steps

1. **Accept Invitation**
   - Accept invitation successfully
   - Verify steward status updated

2. **Attempt Duplicate Invitation**
   - Try to redeem another invitation for same vault
   - Verify local message displays
   - Verify message: "You are already a member of this vault"

### Expected Results

- ✅ Duplicate invitation handled gracefully
- ✅ Local message displays
- ✅ No errors thrown
- ✅ User experience remains smooth

## Test Scenario 9: Manual Steward Entry Still Works

**User Story**: As a vault owner, I want to still be able to add stewards by entering their public keys directly.

### Steps

1. **Open Backup Configuration**
   - Navigate to backup config screen
   - Verify "Add by Public Key" option available

2. **Add Steward Manually**
   - Select "Add by Public Key" option
   - Enter Nostr public key (npub format)
   - Verify steward added to list
   - Verify functionality works as before

### Expected Results

- ✅ Manual entry option still available
- ✅ Public key validation works
- ✅ Key holder added successfully
- ✅ Existing functionality preserved

## Test Scenario 10: Steward Status Display

**User Story**: As a vault owner, I want to see the status of each steward in the vault detail screen.

### Steps

1. **View Steward List**
   - Navigate to vault detail screen
   - Verify steward list section displays
   - Verify status indicators show for each steward

2. **Verify Status Display**
   - Check "invited" status for pending invitations
   - Check "awaiting key" status for accepted invitations
   - Check "holding key" status for confirmed stewards
   - Check "error" status for failed operations

### Expected Results

- ✅ Status indicators display correctly
- ✅ Status text is clear and understandable
- ✅ Visual indicators (colors/icons) match status
- ✅ Status updates reflect current state

## Edge Cases to Test

### Network Interruption
- Test invitation acceptance with network interruption
- Verify retry mechanism works
- Verify user feedback about pending operations

### Invalid Link Format
- Test with malformed URLs
- Test with missing parameters
- Verify error messages are clear

### Configuration Changes
- Test invitation redemption after backup config changes
- Verify invitations still work if invitee still in config
- Verify removal notification if invitee removed

### Relay Failures
- Test with unavailable relays
- Verify failover mechanisms work
- Verify error handling for relay failures

## Acceptance Criteria Validation

After completing all test scenarios, verify:

- ✅ All functional requirements (FR-001 through FR-029) are met
- ✅ All acceptance scenarios from spec are validated
- ✅ Edge cases are handled appropriately
- ✅ Error messages are clear and actionable
- ✅ UI is intuitive for non-technical users
- ✅ Cross-platform consistency maintained
- ✅ Security requirements met (encryption, secure storage)

## Notes

- Deep linking requires proper domain configuration (horcrux.app)
- Universal Links on iOS require apple-app-site-association file
- App Links on Android require assetlinks.json file
- For local testing, may need to modify deep link handling to accept local URLs
- Nostr relay connectivity required for event publishing/receiving
- Test with multiple devices/simulators for realistic scenarios

