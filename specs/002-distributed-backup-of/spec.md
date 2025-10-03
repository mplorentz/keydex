# Feature Specification: Distributed Backup of Lockboxes

**Feature Branch**: `002-distributed-backup-of`  
**Created**: 2024-12-19  
**Status**: Draft  
**Input**: User description: "distributed backup of lockboxes"

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
As a Keydex user, I want my lockboxes to be backed up to the devices of my chosen friends and family so that I can recover my encrypted secrets even if my primary device is lost, stolen, or damaged, ensuring my sensitive data remains accessible and secure through trusted key holders. Each peer will hold one key to the lockbox, and the lockbox will require some number of keys to open. I may generate and share more keys than necessary in case some are not available at the time of recovery.

### Acceptance Scenarios
1. **Given** a user has created a lockbox with sensitive data, **When** they configure backup settings during lockbox creation, **Then** they can specify how many key holders are needed and add friends/family by their Nostr public keys
2. **Given** a user has configured backup with 3 keys needed to open a lockbox and 5 users invited as key holders **When** they complete the backup setup, **Then** the lockbox is split into 5 keys and each key is encrypted and sent to the respective key holder's device
3. **Given** a user's primary device is lost or damaged, **When** they access Keydex from a new device, **Then** they can initiate recovery by contacting their key holders
4. **Given** a user has configured backup with friends and family, **When** they modify a lockbox, **Then** the updated lockbox is re-split and new keys are sent to all key holders
5. **Given** a user has set up backup **When** they invite or remove key holders **Then** the lockbox keys are re-generated and new keys are sent to all key holders

### Edge Cases
- What happens when not enough key holders are available for recovery (e.g., only 2 out of 3 required)? Then the data is not recoverable. We will eventually have a status screen to communicate this to the user.
- How does the system handle when a key holder's device is lost or their Nostr key is compromised? We will eventually have regular checkins to detect these cases and regenerate keys.
- What occurs when a user tries to add a key holder with an invalid Nostr public key? We'll show an error message that the Nostr key is not valid.
- How does the system handle network interruptions during key distribution? The app will retry the distribution periodically. We will also have a status screen for each lockbox which tracks which peers have their latest key and can prompt the user to get in touch with peers who are not responsive.
- What happens when a user wants to change their key holder configuration after initial setup? That should be possible. We just regenerate and redistribute keys.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST provide a backup configuration screen during lockbox creation flow
- **FR-002**: Users MUST be able to specify the number of keys needed to unlock a lockbox (threshold)
- **FR-003**: Users MUST be able to specify the total number of key holders for a lockbox
- **FR-004**: Users MUST be able to add key holders by inputting their Nostr public keys (npubs)
- **FR-005**: System MUST validate that Nostr public keys are in correct format before adding key holders
- **FR-006**: System MUST split lockbox data into keys using Shamir's Secret Sharing algorithm
- **FR-007**: System MUST encrypt each key for its respective key holder using NIP-44 encryption
- **FR-008**: System MUST wrap encrypted keys in NIP-59 gift wrap events (kind 1059) for distribution
- **FR-009**: System MUST publish gift wrap events to Nostr relays for key holder access
- **FR-010**: System MUST work across all supported platforms (iOS, Android, macOS, Windows, Web)
- **FR-011**: System MUST integrate with existing Nostr protocol infrastructure for key distribution

## User Interface Flow *(mandatory)*

### Backup Configuration Screen
The backup configuration screen should be presented as part of the lockbox creation flow, after the user has added initial content to their lockbox. The screen should include:

1. **Screen Title**: "Share Keys"
2. **Introductory Text**: "A Keydex lockbox requires many keys to open. Choose how many and share them with trusted parties."
3. **Configuration Inputs**:
   - "Number of keys needed to open box:" with numerical input (default: 3)
   - "Total number of keys to create:" with numerical input (default: 4)
4. **Configuration Summary**: Dynamic text explaining the current settings (e.g., "In this configuration you will share keys with 4 friends, and if 3 of them agree they can open your lockbox.")
5. **Key Holder Management**:
   - Input field for adding Nostr public keys (npubs)
   - List of added key holders with ability to remove
6. **Instructions**: "Once you have added all keyholders, tap 'Continue'"
7. **Continue Button**: Proceed to next step in lockbox creation

### Key Entities *(include if feature involves data)*
- **Key Holder**: A trusted friend or family member identified by their Nostr public key (npub) who holds one key for a lockbox
- **Lockbox Key**: A portion of the lockbox data created using Shamir's Secret Sharing, encrypted for a specific key holder
- **Gift Wrap Event**: A Nostr event (kind 1059) containing an encrypted key, published to relays for key holder access
- **Backup Configuration**: Settings defining how many key holders are needed (threshold) and total number of key holders for a lockbox

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Keydex-Specific Requirements
- [x] Security requirements clearly defined for sensitive data handling
- [x] Cross-platform functionality specified for all 5 platforms
- [x] Nostr protocol integration requirements documented (NIP-44, NIP-59)
- [x] User experience designed for non-technical users (no mention of Shamir's Secret Sharing)
- [x] Key distribution workflow clearly described using lockbox/key terminology
- [x] Integration with existing lockbox creation flow specified

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
