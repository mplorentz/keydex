# Feature Specification: Invitation Links for Key Holders

**Feature Branch**: `004-invitation-links`  
**Created**: 2025-01-27  
**Status**: Draft  
**Input**: User description: "a new feature: invitation links. This should allow lockbox owners to invite others to be a key holder for their lockbox by sending them a link. The links should be Universal Links on ios, and the appropriate similar feature on other platforms. I have purchased the domain keydex.app for this purpose. Consumers of the link may or may not already be keydex users. In either case tapping the linnk should giuide the user to becoming a key holder for the lockbox they were invited to. The backup config screen should give the user a place to generate these invitation links and copy them. We should generate a unique link for each person invited, so before generating the link we shoul dhave the user enter a name of who they are sending the link to. I think the link will need to contain a special invite code which can then be sent back to teh lockbox owner in an encyrpted event to authenticate the key holder once they have set up an account. That event should contain the public key of the key holder. Then once the locbkox owner has received the public keys of all the invited share holders they can generate the shards and distribute them. We should still keep the functionality for them to enter npubs directly. The invite link should also contain the URL of the relays to use for communication, and the public key of the lockbox owner."

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a lockbox owner, I want to invite friends and family to become key holders by sending them a simple invitation link, so that I don't need to manually exchange Nostr public keys and can make the process more accessible to people who may not already be Keydex users. When someone taps the invitation link, they should be guided through the process of becoming a key holder for my lockbox, whether they already have Keydex installed or need to set it up first.

### Acceptance Scenarios
1. **Given** a lockbox owner is configuring backup settings, **When** they want to invite someone as a key holder, **Then** they can enter the invitee's name and generate a unique invitation link
2. **Given** a lockbox owner has generated an invitation link, **When** they share it with an invitee via any communication method (text, email, etc.), **Then** the invitee can tap the link to open Keydex
3. **Given** an invitee taps an invitation link, **When** they don't have Keydex installed, **Then** they are guided to install Keydex and set up an account
4. **Given** an invitee taps an invitation link, **When** they already have Keydex installed, **Then** they are guided to accept the invitation and become a key holder
5. **Given** an invitee accepts an invitation by completing account setup, **When** they confirm acceptance, **Then** their public key is sent to the lockbox owner via encrypted event
6. **Given** a lockbox owner has received public keys from all invited key holders, **When** they open the lockbox detail screen, **Then** they should see a button to generate and distribute keys
7. **Given** a lockbox owner has received public keys from all invited key holders, **When** they click a button to distribute keys from the lockbox detail screen, **Then** they can generate keys and distribute them to all key holders
8. **Given** a key holder opens Keydex and receives their shard, **When** they successfully process and store it, **Then** they automatically send a confirmation event back to the lockbox owner
9. **Given** a lockbox owner views their lockbox details, **When** they check the key holder list, **Then** they can see the status of each key holder (invited, awaiting key, holding key, or error)
10. **Given** a lockbox owner is configuring backup, **When** they prefer to add key holders directly, **Then** they can still enter Nostr public keys (npubs) manually as an alternative to invitation links

### Edge Cases
- What happens when an invitation link is tapped multiple times or by multiple people? Invitation links can only be redeemed once. If a second person tries to redeem it, the lockbox owner should send them an event detailing that the code was invalid. The lockbox owner should keep a table of invitation codes and mark when they have been used. The system should log an error message that the link has already been redeemed.
- How does the system handle when an invitee taps a link but decides not to accept the invitation? In that case, the system should send an event back to the lockbox owner letting them know the invitation was denied. The lockbox owner should invalidate the invitation code.
- What occurs when a lockbox owner generates an invitation link but then modifies the backup configuration before the invitee accepts? The invitation should still work given that the backup configuration still includes the invitee. But if the invitee has been removed from the backup configuration, the system should send them a Nostr event letting them know they have been removed from the lockbox.
- How does the system handle when an invitee accepts an invitation but the lockbox owner hasn't yet generated shards? The invitee will be in "awaiting key" status until shards are distributed. The lockbox detail screen should show a button to generate and distribute keys when all invited key holders have accepted.
- What happens when a key holder receives their shard but fails to process it? They should go into an error status, and the lockbox owner should see an error status. The key holder should publish an event for the lockbox owner to let them know an error has occurred.
- How does the system handle network interruptions during invitation acceptance or shard confirmation? The system should retry sending events and provide user feedback about pending operations.
- What occurs when an invitation link is shared with someone who is already a key holder for that lockbox? The system should handle it gracefully. If they redeem an invitation to a lockbox they are already a part of, the system should show a message locally that they are already a member of that lockbox.
- How does the system handle invitation links that are invalid or malformed? The app should display an error message and guide the user appropriately.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST allow lockbox owners to generate invitation links from the backup configuration screen
- **FR-002**: System MUST require lockbox owners to enter an invitee's name before generating an invitation link
- **FR-003**: System MUST generate a unique invitation link for each invitee that contains: invite code, relay URLs, and lockbox owner's public key
- **FR-004**: System MUST support invitation links as Universal Links on iOS
- **FR-005**: System MUST support invitation links as the appropriate deep link mechanism on Android, macOS, Windows, and Web platforms
- **FR-006**: System MUST use the domain keydex.app for invitation links
- **FR-007**: System MUST allow invitation links to be copied and shared via any communication method
- **FR-008**: System MUST guide users who tap invitation links through the process of becoming a key holder, whether they are existing Keydex users or new users
- **FR-009**: System MUST guide new users through Keydex account setup when they tap an invitation link
- **FR-010**: System MUST allow invitees to accept invitations by sending an encrypted RSVP event containing their public key and the invite code
- **FR-011**: System MUST allow lockbox owners to receive RSVP events from invited key holders
- **FR-012**: System MUST allow lockbox owners to generate and distribute shards after receiving public keys from all invited key holders
- **FR-013**: System MUST allow key holders to send shard confirmation events after successfully processing and storing their shard
- **FR-014**: System MUST allow lockbox owners to receive shard confirmation events from key holders
- **FR-015**: System MUST display key holder status in the lockbox detail screen, showing: invited, awaiting key, holding key, or error
- **FR-016**: System MUST maintain the existing functionality for lockbox owners to enter Nostr public keys (npubs) directly as an alternative to invitation links
- **FR-017**: System MUST track invitation status for each key holder separately
- **FR-018**: System MUST provide visual feedback to lockbox owners about the status of each invited key holder
- **FR-019**: System MUST allow invitation links to be redeemed only once per invite code
- **FR-020**: System MUST maintain a table of invitation codes and mark them as used when redeemed
- **FR-021**: System MUST send an event to invitees who attempt to redeem an already-used invitation code, informing them the code is invalid
- **FR-022**: System MUST log error messages when an invitation link is redeemed more than once
- **FR-023**: System MUST allow invitees to deny invitations and send a denial event to the lockbox owner
- **FR-024**: System MUST invalidate invitation codes when invitees deny invitations
- **FR-025**: System MUST validate that an invitee is still in the backup configuration when they accept an invitation
- **FR-026**: System MUST send a Nostr event to invitees who have been removed from the backup configuration, informing them they have been removed
- **FR-027**: System MUST display a button on the lockbox detail screen to generate and distribute keys when all invited key holders have accepted their invitations
- **FR-028**: System MUST allow key holders to send error events to lockbox owners when they fail to process their shard
- **FR-029**: System MUST handle gracefully when someone attempts to redeem an invitation link for a lockbox they are already a key holder for, showing a local message that they are already a member

## User Interface Flow *(mandatory)*

### Backup Configuration Screen - Invitation Link Generation
The backup configuration screen should include a new section for generating invitation links:

1. **Invitation Section Header**: "Invite Key Holders" or similar
2. **Invitation Method Selection**: Toggle or buttons to choose between "Invite by Link" and "Add by Public Key"
3. **Invite by Link Flow**:
   - Input field: "Enter invitee's name" (required before generating link)
   - Button: "Generate Invitation Link"
   - After generation: Display the invitation link with a "Copy Link" button
   - Option to generate another link for a different invitee
   - List of pending invitations showing invitee name and status
4. **Add by Public Key Flow**: (existing functionality maintained)
   - Input field for Nostr public keys (npubs)
   - List of added key holders

### Invitation Link Handling
When a user taps an invitation link:

1. **Link Detection**: App opens and recognizes the invitation link format
2. **Account Check**: 
   - If user has account: Navigate to invitation acceptance screen
   - If user doesn't have account: Navigate to account setup flow, then invitation acceptance
3. **Invitation Acceptance Screen**:
   - Display lockbox owner's information
   - Display invitation details
   - Button: "Accept Invitation" or "Become Key Holder"
   - Confirmation dialog explaining what being a key holder means
4. **Post-Acceptance**: 
   - Show status: "Invitation accepted. Waiting for key distribution."
   - Send RSVP event automatically

### Lockbox Detail Screen - Key Holder Status
The key holder list section should display status for each key holder:

1. **Key Holder Item Display**:
   - Name or public key identifier
   - Status indicator (badge or icon) showing: invited, awaiting key, holding key, or error
   - Status text explanation
2. **Status Definitions**:
   - **Invited**: Invitation link sent but not yet accepted
   - **Awaiting Key**: Invitation accepted, public key received, but shard not yet distributed
   - **Holding Key**: Shard distributed and confirmation received
   - **Error**: Failed to process invitation, shard distribution, or confirmation
3. **Generate and Distribute Keys Button**:
   - Displayed when all invited key holders have accepted their invitations
   - Allows lockbox owner to trigger key generation and distribution
   - Only visible to lockbox owners

## Key Entities *(include if feature involves data)*
- **Invitation Link**: A unique URL containing an invite code, relay URLs, and lockbox owner's public key, used to invite someone to become a key holder
- **Invite Code**: A unique identifier embedded in an invitation link that authenticates the invitation and links it to a specific lockbox and invitee, can only be redeemed once
- **Invitation Code Table**: A data structure maintained by the lockbox owner tracking invitation codes and their redemption status (used/unused)
- **RSVP Event**: An encrypted Nostr event sent by an invitee to accept an invitation, containing their public key and the invite code
- **Invitation Denial Event**: An encrypted Nostr event sent by an invitee who declines an invitation, informing the lockbox owner and invalidating the invitation code
- **Shard Confirmation Event**: An encrypted Nostr event sent by a key holder after successfully processing and storing their shard, confirming receipt to the lockbox owner
- **Shard Error Event**: An encrypted Nostr event sent by a key holder when they fail to process their shard, informing the lockbox owner of the error
- **Invitation Status**: The current state of an invitation for a key holder (invited, awaiting key, holding key, or error)

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain (answered items removed, remaining items are implementation details)
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Keydex-Specific Requirements
- [x] Security requirements clearly defined for sensitive data handling (encrypted events)
- [x] Cross-platform functionality specified for all 5 platforms (iOS Universal Links, appropriate similar features on other platforms)
- [x] Nostr protocol integration requirements documented (encrypted events for RSVP and confirmation)
- [x] User experience designed for non-technical users (guided flows, clear status indicators)
- [x] Invitation workflow clearly described (link generation → acceptance → key distribution → confirmation)
- [x] Integration with existing backup configuration flow specified
- [x] Domain ownership specified (keydex.app)

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] UI flow specified
- [x] Review checklist passed

---

## Implementation Notes
The following items are implementation details that will be determined during development:

1. **Invite Code Security**: Format, length, and generation algorithm for invite codes to ensure uniqueness and prevent unauthorized access
2. **Link Format**: Exact URL format for invitation links (human-readable vs encoded)
3. **Relay URL Handling**: Maximum number of relay URLs to include in links, handling of relay URL changes
4. **Error Recovery Actions**: Specific UI actions available to lockbox owners when key holders are in error status (retry distribution, revoke invitation, etc.)

