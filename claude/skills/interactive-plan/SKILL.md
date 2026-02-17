---
name: interactive-plan
description: Generate an interactive HTML architecture plan with Mermaid diagrams, phase tracking, decision cards, and a feedback panel for review.
---

# Interactive Architecture Plan Generator

Creates a self-contained HTML file that serves as a living architecture document with visual diagrams, phase tracking, and inline review capabilities.

## Invocation

```
/interactive-plan                          # Generate plan, serve locally (default)
/interactive-plan --gcs                    # Generate plan, upload to default GCS bucket
/interactive-plan --gcs my-other-bucket    # Generate plan, upload to specific bucket
```

The user may also request GCS upload conversationally (e.g., "upload it to GCS", "put it in cloud storage"). Treat that the same as `--gcs`.

## Configuration

- **Default GCS bucket:** `<YOUR_GCS_BUCKET>`
  - Override per-invocation with `--gcs <bucket-name>`
  - To change the default, edit this value in the skill file
- **GCS requires:** `gcloud` CLI installed and authenticated (`gcloud auth login`)

## Process

### 1. Explore Codebase Context

Before generating the plan, gather:
- Project structure and key files
- Existing architecture patterns
- Dependencies and integrations
- Current pain points or migration context from `_research/` and CLAUDE.md

### 2. Generate Self-Contained HTML

Create a single `.html` file (no external dependencies except CDN) containing:

#### Mermaid Diagrams
- Load Mermaid.js from CDN (`https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js`)
- Include relevant diagram types based on the plan:
  - `flowchart` for request/data flows
  - `sequenceDiagram` for service interactions
  - `C4Context` / `C4Container` for system architecture
  - `gantt` for timeline/phasing
- Each diagram should be editable (wrapped in `<pre class="mermaid">`)

#### Phase Table
- Rows for each implementation phase
- Columns: Phase, Description, Status, Dependencies, Estimated Effort
- Status badges: `Not Started` (gray), `In Progress` (blue), `Done` (green), `Blocked` (red)
- Clickable rows that expand to show sub-tasks

#### Architecture Decision Cards
- One card per key decision (ADR-style)
- Fields: Title, Status (Proposed/Accepted/Deprecated), Context, Decision, Consequences
- Collapsible detail sections

#### Code Reference Table
- File paths with line references relevant to each phase
- Links formatted as `file_path:line_number` for easy navigation
- Grouped by phase/component

#### Feedback Panel
- Select any text on the page and right-click to add a comment
- Comments stored in `localStorage` and highlighted inline
- "Export Feedback" button that downloads all comments as JSON with:
  - Selected text
  - Comment text
  - Section/phase reference
  - Timestamp
- "Import Feedback" to reload previous review sessions
- Comment counter badge in the header

### 3. Styling Requirements

- Clean, professional appearance — no "AI slop" aesthetics
- Dark/light mode toggle (respect `prefers-color-scheme`)
- Responsive layout that works on desktop and tablet
- Print-friendly styles (`@media print` hides interactive elements)
- Sticky navigation header with jump links to each section

### 4. Delivery

**Default: Local file**
- Write the HTML file to the project root (or a specified path)
- Print the full file path so the user can open it

**Optional: GCS upload** (when `--gcs` is passed or user requests it)
1. Verify `gcloud` is installed: `which gcloud`
   - If missing, tell the user to install it:
     - macOS: `brew install google-cloud-sdk`
     - WSL/Linux: `curl https://sdk.cloud.google.com | bash` or `sudo apt install google-cloud-cli`
2. Verify authentication: `gcloud auth print-access-token > /dev/null 2>&1`
   - If not authenticated, prompt user to run `gcloud auth login`
3. Determine bucket:
   - Use explicit bucket from args if provided
   - Otherwise use the default: `<YOUR_GCS_BUCKET>`
4. Generate a filename: `plan-<project-name>-<YYYY-MM-DD>.html`
5. Upload: `gcloud storage cp <file> gs://<bucket>/<filename>`
6. Make publicly readable (if bucket allows): `gcloud storage objects update gs://<bucket>/<filename> --add-acl-grant=entity=allUsers,role=READER`
   - If this fails (e.g., uniform bucket-level access), skip silently — the file is still uploaded
7. Print the public URL: `https://storage.googleapis.com/<bucket>/<filename>`

Always keep the local file regardless of whether GCS upload is requested.

## Output

A single self-contained HTML file. No build step, no framework, no node_modules. Just open in a browser.
