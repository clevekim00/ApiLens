# ApiLens Workgroup Guide

ApiLens helps you organize your API requests and workflows efficiently using **Workgroups**. Group your work by project, team, or feature.

## Key Features

### 1. Workgroup Structure
- **No Workgroup (System Default)**: The default catch-all location. Requests not belonging to any group appear here. Cannot be renamed or deleted.
- **Custom Groups**: Create as many groups as you need. Supports organizing distinct projects or modules.

### 2. Creation & Management
- **Create**: Click the **New Folder** icon in the Explorer header.
- **Rename**: Right-click a folder and select **Rename**.
- **Delete**: Right-click and select **Delete**.
  - **Safe Delete**: By default, contents are moved to 'No Workgroup' to prevent data loss.
  - **Permanent Delete**: Uncheck the safe delete option to permanently remove contents.

### 3. Drag & Drop
- **Move Requests**: Drag and drop requests between folders to reorganize them.
- **Reset Group**: Drag a request to 'No Workgroup' or empty space to remove it from a custom group.

### 4. Import / Export (Backup & Share)
- **Export**:
  - Right-click a group -> **Export JSON**.
  - Saves the group along with its Requests and Workflows to a `.apilens-workgroup.json` file.
- **Import**:
  - Click the **Import** icon (upload icon) in the Explorer header.
  - Select a `.apilens-workgroup.json` file.
  - **Conflict Resolution**: Imported data gets generated fresh IDs. Name conflicts are handled by appending `(Imported)`.

### 5. Swagger / OpenAPI Import
- Bulk import API definitions from existing Swagger docs.
- Right-click a group -> **Import Swagger**.
- **From URL**: Fetch directly from a URL (e.g., `https://.../swagger.json`).
- **Paste Content**: Paste JSON content directly.
- Parsed definitions are automatically converted to Requests and added to the group.

## Tips
- **Isolate Environments**: Use separate groups for Dev, Staging, and Prod environments if needed (or combine with Environment variables).
- **Collaboration**: Export your workgroup file and share it with teammates to sync API collections.
