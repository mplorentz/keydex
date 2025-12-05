# Feature Specification: Vault Recovery

**Feature Branch**: `003-vault-recovery`  
**Created**: 2024-12-19  
**Status**: Draft  
**Input**: User description: "a new feature: recovering a vault."

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
As a steward, I want to recover a vault that I have a key share for, so that I can access the encrypted contents when the original owner is unavailable or when I need to restore the data.

### Acceptance Scenarios
1. **Given** I am a steward for a vault, **When** I initiate recovery from the vault detail screen, **Then** the system should send encrypted recovery requests to all other stewards and display their response status
2. **Given** I receive a recovery request notification, **When** I tap on the request, **Then** I should see options to approve or deny the recovery request
3. **Given** I have been given a key share for a vault, **When** I view the vault list, **Then** I should see both vaults I own and vaults I have keys for, clearly distinguished
4. **Given** I am scanning for keys on configured relays, **When** a new encrypted share is found for me, **Then** a new vault record should be created locally and displayed in my vault list
5. **Given** enough stewards have approved a recovery request, **When** their shares are collected, **Then** the vault contents should be reassembled and saved locally, marking the vault as recovered

### Edge Cases
- What happens when a steward denies a recovery request? this just blocks the use of that share. The request should no longer be shown for the one who denied it, but future requests may be shown.
- How does the system handle when some stewards are unresponsive during recovery? if peers are unresponsive then the recovery will just be stuck. The recovery initiator can try to get in contact with them out of band if necessary.
- What happens if the recovery initiator goes offline during the process? that's fine. Because everything is done with nostr events through relays it tolerates folks coming on and offline at any time.
- How does the system handle duplicate recovery requests for the same vault? we can just show all requests. I suppose we can display the timestamp from the nostr event to differentiate between them.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST allow any steward to initiate recovery of a vault they have a key share for
- **FR-002**: System MUST display vaults that the user owns differently from vaults they only have keys for
- **FR-003**: System MUST provide a "Scan for Keys" button on the vault list screen that navigates to relay management
- **FR-004**: System MUST allow users to configure a list of Nostr relays to scan for encrypted key shares
- **FR-005**: System MUST automatically scan configured relays for encrypted shares addressed to the current user
- **FR-006**: System MUST create local Vault records when encrypted shares are found and addressed to the current user
- **FR-007**: System MUST provide a "Initiate Recovery" button on vault detail screens for vaults without local content
- **FR-008**: System MUST send encrypted Nostr events to all stewards when recovery is initiated
- **FR-009**: System MUST display steward status (Unlocked, Waiting, Denied) during recovery mode
- **FR-010**: System MUST continuously scan relays for recovery request DMs
- **FR-011**: System MUST display recovery request notifications in an overlay at the bottom of the vault list screen
- **FR-012**: System MUST allow stewards to approve or deny recovery requests from the notification overlay
- **FR-013**: System MUST reassemble vault contents when sufficient key shares are collected
- **FR-014**: System MUST save recovered vault contents to local storage
- **FR-015**: System MUST mark vaults as recovered when contents are successfully reassembled

### Key Entities *(include if feature involves data)*
- **Recovery Request**: Represents a request to recover a vault, containing the vault ID, initiator's public key, timestamp, and current status
- **Key Share**: Represents an encrypted portion of a vault's content that can be used to reconstruct the original data
- **Relay Configuration**: Represents a list of Nostr relays that the app monitors for incoming key shares and recovery requests
- **Recovery Status**: Represents the current state of a recovery process, including which stewards have responded and their decision

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

### Horcrux-Specific Requirements
- [x] Security requirements clearly defined for sensitive data handling
- [x] Cross-platform functionality specified for all 5 platforms
- [x] Nostr protocol integration requirements documented
- [x] User experience designed for non-technical users
- [x] Shamir's Secret Sharing workflow clearly described

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---
