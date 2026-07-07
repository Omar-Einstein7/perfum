# Feature Specification: Units of Measure

**Feature Branch**: `003-units-of-measure`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "phase 2 — Units of Measure module: CRUD management for measurement units used across the system (kg, liter, piece, box, etc.)"

## User Scenarios & Testing

### User Story 1 — List and View Units (Priority: P1)

As a user with edit-masters permission, I want to see a paginated, searchable list of all units of measure so that I can quickly find and manage them.

**Why this priority**: Listing is the entry point for every other unit operation. Without it, users cannot find, edit, or delete units.

**Independent Test**: Navigate to the Units page → see a table/list showing unit name, abbreviation, type, and status. The list loads within 3 seconds. Typing in a search box filters the list in real time.

**Acceptance Scenarios**:

1. **Given** I am on the Units page, **When** the page loads, **Then** I see a paginated list of active units sorted by name, showing name, abbreviation, type, and status.
2. **Given** I am on the Units page, **When** I type in the search box, **Then** the list filters to show only units whose name or abbreviation matches my query.
3. **Given** there are more than 20 units, **When** the page loads, **Then** only the first 20 are shown with pagination controls to see more.
4. **Given** there are no units in the system, **When** the page loads, **Then** I see an empty-state message with a button to create the first unit.

---

### User Story 2 — Create a Unit (Priority: P1)

As a user with edit-masters permission, I want to create a new unit of measure so that it becomes available for use in materials and other inventory records.

**Why this priority**: Creating units is the primary write operation. Materials and other entities depend on units existing.

**Independent Test**: Navigate to the Units page → tap "Add Unit" → fill in name, abbreviation, and type → submit → see the new unit appear in the list.

**Acceptance Scenarios**:

1. **Given** I am on the create-unit form, **When** I enter a name, abbreviation, and select a type and tap Save, **Then** the unit is saved and I am taken back to the list where the new unit appears.
2. **Given** I am on the create-unit form, **When** I enter a name that already exists, **Then** I see a clear error message and am not redirected.
3. **Given** I am on the create-unit form, **When** I leave required fields (name, abbreviation) empty and tap Save, **Then** I see validation errors and the form is not submitted.

---

### User Story 3 — Edit a Unit (Priority: P2)

As a user with edit-masters permission, I want to update an existing unit's details so that I can correct mistakes or change how the unit is represented.

**Why this priority**: Editing is important for data maintenance but listing and creation cover the primary workflow.

**Independent Test**: Navigate to the Units page → tap a unit → edit its name → save → see updated name in the list.

**Acceptance Scenarios**:

1. **Given** I am on the edit-unit form, **When** I change any field and tap Save, **Then** the changes are persisted and I return to the list showing the updated data.
2. **Given** I am on the edit-unit form, **When** I change the name to one already used by another unit, **Then** I see a duplicate-name error and the form is not saved.
3. **Given** I am on the edit-unit form, **When** I tap Cancel, **Then** no changes are saved and I return to the list.

---

### User Story 4 — Delete a Unit (Priority: P3)

As a user with edit-masters permission, I want to deactivate a unit that is no longer needed so that the list stays clean and relevant.

**Why this priority**: Deactivation is less frequent and can be done manually by admins. The system should prevent deactivation of units that are in use by materials.

**Independent Test**: Navigate to the Units page → tap deactivate on an unused unit → confirm → see the unit disappear from the active list.

**Acceptance Scenarios**:

1. **Given** I am viewing a unit, **When** I tap Deactivate and confirm, **Then** the unit is marked inactive (if not referenced by any material) and hidden from the default active list.
2. **Given** I am viewing a unit that is referenced by one or more materials, **When** I tap Deactivate, **Then** I see a message that the unit cannot be deactivated because it is in use.
3. **Given** I tap Deactivate on a unit, **When** the confirmation dialog appears and I tap Cancel, **Then** the unit is not deactivated.

---

### Edge Cases

- What happens when the network is unreachable during a create/edit/deactivate operation? A clear error message should appear, and the app should not lose the user's unsaved form data.
- What happens when two users try to edit the same unit simultaneously? The last save wins (no optimistic locking for v1).
- What happens when a user attempts to create a unit with an abbreviation that already exists? Should show a duplicate error, same as duplicate name.
- What happens when the backend returns a server error (5xx) during any operation? A friendly error message should appear; the user should be able to retry.

## Clarifications

### Session 2026-07-08

- Q: Soft-delete vs hard-delete → A: Soft-delete with active/inactive status toggle
- Q: Unit type — fixed enum or extensible → A: Fixed enum (weight, volume, count, length, area, time, other)

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow users to view a paginated, searchable list of all units of measure.
- **FR-002**: System MUST support searching units by name and abbreviation.
- **FR-003**: System MUST allow users to create a new unit with name, abbreviation, type, and optional description.
- **FR-004**: System MUST validate that unit name and abbreviation are non-empty and unique.
- **FR-005**: System MUST allow users to update any field of an existing unit.
- **FR-006**: System MUST allow users to deactivate a unit that is not referenced by any material (soft-delete, sets active=false).
- **FR-007**: System MUST prevent deactivation of a unit that is in use by one or more materials, showing a clear explanation.
- **FR-008**: System MUST show a loading indicator during all CRUD operations.
- **FR-009**: System MUST display clear, user-friendly error messages for all failure scenarios — not technical error codes.
- **FR-010**: System MUST redirect users without edit-masters permission away from the Units pages to the dashboard.

### Key Entities

- **Unit of Measure**: A measurement standard used across the system. Each unit has a unique name (e.g., "Kilogram"), an abbreviation (e.g., "kg"), a type (weight, volume, count, length, area, time, or other), and an optional description. Units are referenced by Materials to specify how a material is quantified.
- **Unit Type**: A fixed-enum classification of units into measurement categories (weight, volume, count, length, area, time, other). Determines which units can be converted between each other.
- **Material**: An item or product in inventory that references a unit of measure (e.g., "Rice — 50kg bag" references the "Kilogram" unit). When a unit is referenced by a material, it cannot be deleted.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A user can complete the full create-unit workflow (navigate → fill form → submit → see result) in under 30 seconds.
- **SC-002**: The unit list page loads and displays results within 3 seconds on a typical internet connection.
- **SC-003**: Search results update within 1 second of the user finishing typing.
- **SC-004**: A user can navigate from the unit list to viewing a specific unit's details and back within 5 seconds total.
- **SC-005**: Error messages are displayed within 2 seconds of a failed operation.

## Assumptions

- The backend supports CRUD endpoints for units: `GET /units` (paginated, searchable), `POST /units`, `PUT /units/:id`, `DELETE /units/:id`.
- The backend includes a check preventing deletion of units referenced by materials (returns 409 Conflict with explanation).
- Unit names and abbreviations are unique per tenant.
- The user must have `canEditMasters` permission to access Units features.
- The existing permission guard from the auth module will protect Units routes automatically.
- Pre-seeded units (kg, liter, piece, box, etc.) may exist on the backend for initial testing.
