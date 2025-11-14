# Feature Specification: File Storage in Lockboxes

**Feature Branch**: `005-file-support`  
**Created**: 2025-11-14  
**Status**: Draft  
**Input**: User description: "a new feature called file-support. This feature will allow vault owners to add files to their vault via a native file picker instead of mere text content, and it will allow stewards to recover the files during the recovery process. This feature will replace the current `content` field in the vault/lockbox - we no longer need to allow the user to edit vault contents directly within the keydex app. The expectation is that they will create documents elsewhere (preferably pdf, or txt) and then add them into a vault in keydex. When the vault contents are changed we should encrypt them using a symmetric key and upload the encrypted blob to a blossom server. The blossom server should be configurable the same way that the Nostr relay is. We should also delete any out of date blobs after we have received confirmation from all stewards (if any) that they have the new one. After the encrypted blob is uploaded to blossom we can include the blossom address in the shard data that is sent to stewards. And stewards, upon receiving the shard data, should also download the encrypted blossom blob. We need to update our UI like the lockbox detail screen to show the status of the vault contents just like we show the status of the key/shard. During recovery the initiating steward will reassemble the symmetric key and then decrypt the vault contents and will be able to save the files to their device using a native interface. Don't worry about backwards compatibility with the old lockbox format, we have no existing users."

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
As a lockbox owner, I want to store complete files (PDFs, text documents, etc.) in my lockbox instead of typing content directly in the app, so that I can protect important documents created elsewhere. The files should be encrypted and backed up to my key holders, and in a recovery scenario, my key holders should be able to retrieve and save these files to their devices.

### Acceptance Scenarios
1. **Given** a user creates a new lockbox, **When** they want to add content, **Then** they are presented with a file picker to select a file from their device rather than a text editor
2. **Given** a user has selected a file for their lockbox, **When** the file is added, **Then** the file is encrypted and uploaded to a configured storage server, and the encrypted file location is included in the keys distributed to key holders
3. **Given** a user has added a file to their lockbox, **When** they configure key holders, **Then** the keys distributed to key holders include information about where to retrieve the encrypted file
4. **Given** a key holder receives a key with file information, **When** they receive the key, **Then** the system automatically retrieves the encrypted file from the storage server
5. **Given** a user wants to change the file in their lockbox, **When** they select a new file, **Then** the old encrypted file is marked for deletion, the new file is encrypted and uploaded, and updated keys are sent to all key holders
6. **Given** all key holders have confirmed receipt of the new file location, **When** the system verifies all confirmations, **Then** the old encrypted file is permanently deleted from the storage server
7. **Given** a lockbox owner views their lockbox details, **When** they check the status screen, **Then** they can see which key holders have successfully retrieved the encrypted file
8. **Given** enough key holders initiate recovery, **When** they reconstruct the lockbox key, **Then** they can decrypt the file and save it to their device using a native save dialog
9. **Given** a user needs to configure their storage server, **When** they access settings, **Then** they can configure the storage server address similar to how they configure Nostr relays

### Edge Cases
- What happens when a user selects a very large file (e.g., 100MB+)? - the total vault size should not exceed 1GB
- What happens when the storage server is unavailable during file upload? The system should display an error to the user and allow them to retry the upload when the server is available again
- What happens if a key holder cannot retrieve the encrypted file from the storage server? The system should display an error status for that key holder in the lockbox detail screen, indicating the file retrieval failed
- What happens when file upload succeeds but key distribution fails? The encrypted file remains on the storage server, and the system should retry key distribution. The file should not be deleted until successfully distributed
- What happens during recovery if the encrypted file is no longer available on the storage server? The recovery should fail with a clear error message that the file cannot be retrieved. 
- What happens if a user tries to select multiple files at once? They should be allowed.
- What happens when network interruption occurs during file upload? The system should display appropriate error messaging and allow the user to retry the operation
- What happens when a user deletes a lockbox that has files on the storage server? The encrypted files should be deleted from the storage server as part of the lockbox deletion process

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST provide a native file picker interface for users to select files to store in lockboxes
- **FR-002**: System MUST encrypt selected files before uploading to storage server
- **FR-003**: System MUST upload encrypted files to a configurable storage server
- **FR-004**: System MUST provide a configuration interface for users to set their storage server address
- **FR-005**: System MUST include the storage location of encrypted files in the keys distributed to key holders
- **FR-006**: System MUST automatically retrieve encrypted files from storage when key holders receive their keys
- **FR-007**: System MUST track which key holders have successfully retrieved encrypted files
- **FR-008**: System MUST display file retrieval status for each key holder in the lockbox detail screen
- **FR-009**: System MUST mark old encrypted files for deletion when lockbox content is updated with a new file
- **FR-010**: System MUST delete old encrypted files from storage only after all key holders confirm receipt of new file location
- **FR-011**: System MUST allow key holders to decrypt and save recovered files to their devices using a native save dialog
- **FR-012**: System MUST remove the ability to directly edit text content within the app
- **FR-013**: System MUST handle file upload errors gracefully and provide clear error messages to users
- **FR-014**: System MUST handle file retrieval errors and display appropriate status to key holders
- **FR-015**: System MUST delete encrypted files from storage server when a lockbox is deleted
- **FR-016**: System MUST work across all supported platforms (iOS, Android, macOS, Windows, Web) with native file picker interfaces
- **FR-017**: System MUST validate that storage server is reachable before attempting file operations

### Key Entities *(include if feature involves data)*
- **Lockbox File**: A file (PDF, text document, etc.) selected by the user to store in a lockbox, which gets encrypted before storage
- **Encrypted File Blob**: The encrypted version of the lockbox file, stored on a remote storage server
- **Storage Server Configuration**: User-configurable setting specifying the address of the storage server for encrypted files
- **File Location Reference**: Information included in distributed keys that tells key holders where to retrieve the encrypted file
- **File Status**: Tracking information showing which key holders have successfully retrieved the encrypted file
- **File Retrieval Confirmation**: Acknowledgment from key holders that they have successfully downloaded the encrypted file

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Keydex-Specific Requirements
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
- [x] Review checklist passed (with clarifications needed)

---

