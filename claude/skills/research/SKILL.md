---
name: research
description: 6-agent parallel deep research. Use when the user needs thorough investigation of a codebase question, architecture decision, or implementation approach. Launches explore agents, then 6 research agents with consensus analysis.
---

# 6-Agent Parallel Research

You are conducting deep parallel research on a task. Follow this protocol exactly.

## Input

The user's task/question: $ARGUMENTS

## Phase 1: Initial Exploration

Launch 2 Explore sub-agents in parallel to map the surface area of the task.

- Agent 1: Broad codebase scan — identify all files, patterns, and architecture relevant to the task.
- Agent 2: Focused scan — find specific implementations, configurations, and dependencies directly related to the task.

Wait for both to complete before proceeding.

## Phase 2: Create Research Doc

Derive a short kebab-case slug from the research topic (e.g., "multi-gaid-life-brokerage", "auth-flow-refactor"). Create `_research/6s-{slug}.md` (create `_research/` if it doesn't exist) with:

- **Final end goal**: What the user is trying to accomplish
- **Research requirements**: What we need to find out
- **Initial analysis**: Summary of findings from Phase 1 explore agents
- **Template structure**: Empty sections for full research findings (to be filled in Phase 5)

Use this same filename for all subsequent phases.

## Phase 3: Deep Research (6 Sub-Agents)

Launch 6 sub-agents in parallel (use `general-purpose` subagent type). Each agent receives:

1. The full task context
2. The initial exploration findings from Phase 1
3. A specific research angle (vary prompts based on what the task actually needs — not arbitrary differentiation)

Guidelines:
- Overlap is fine; multiple agents on the same angle strengthens consensus
- Each agent works independently (no shared memory between them)
- Each agent must return findings in this standard format:

```
## Agent [N] Findings
### Research Angle: [description]
### Files Analyzed: [list with paths]
### Key Findings:
- [finding 1]
- [finding 2]
### Code Snippets:
[relevant code with file_path:line_number references]
### Confidence: [0-100%]
### Open Questions: [if any]
```

Wait for all 6 to complete before proceeding.

## Phase 4: Consensus Analysis

Analyze all 6 agent responses for:

- **Points of agreement** (weight these heavily — consensus = high confidence)
- **Conflicts or contradictions** (flag these explicitly)
- **Unique insights** (findings only one agent surfaced)
- **Overall confidence level** (0-100%) based on agreement strength

## Phase 5: Final Output

Update the research doc (`_research/6s-{slug}.md`) with the complete findings:

- **High-level summary** (2-3 paragraphs)
- **Files analyzed** (deduplicated list from all agents)
- **Prioritized recommendations**:
  - P0: Critical / must-do
  - P1: Important / should-do
  - P2: Nice-to-have / consider
- **Code snippets** for suggested fixes or implementations (with file_path:line_number)
- **Confidence score**: [0-100%]
- If confidence < 85%: **Recommended follow-up research angles**
- **Breakdown of each sub-agent's findings** (appendix)

Present a concise summary to the user after updating the research doc.
