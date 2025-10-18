<!-- 653cdac0-a3c3-448d-95bb-28eb0f8365bf 70727333-f414-4563-8331-8b9369ba6788 -->
# Create project_structure.txt with current and proposed structures

## Goal

Produce a concise tree of the current repository and a recommended, cleaner structure (Uber/Bolt-style modularity) in a single file named `project_structure.txt` at repo root.

## Steps

1. Capture the current tree (top-level, then `backend/` and `swiftride/` significant subtrees) and format it as a readable tree in the file under a "Current Structure" section.
2. Draft a "Proposed Structure" focusing on:

- Frontend (`swiftride/`) reorganized by features: `features/{home,rides,account,auth}` with subfolders `data`, `domain`, `presentation`.
- Shared `core/` (constants, styles, services, routing, widgets/common, utils).
- Assets grouped logically.
- Backend (`backend/`) kept but with clearer app boundaries and `api/` module for REST.

3. Write both sections into `project_structure.txt` with clear headings and indentation for easy reading.
4. (Optional) If desired, include a short rationale paragraph and migration notes for how to move current files into the proposed layout.

## Affected files

- Create: `project_structure.txt`

## Todos

- create-structure-file: Create `project_structure.txt` with both structures
- include-migration-notes: Add brief mapping hints from current to proposed

### To-dos

- [ ] Create project_structure.txt with both structures
- [ ] Add brief mapping hints from current to proposed