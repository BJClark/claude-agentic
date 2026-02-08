---
name: ddd-connect
description: "DDD Step 5: Context Mapping — define relationships between bounded contexts"
model: opus
context: fork
allowed-tools: Read, Grep, Glob, Write, Edit, AskUserQuestion
argument-hint: [domain-name]
---

# DDD Step 5: Connect (Context Mapping)

Ultrathink about inter-context relationships and integration patterns. Consider power dynamics between teams, data ownership, translation needs, and the cost of coupling.

Define relationships between bounded contexts using standard context mapping patterns.

**Input**: $ARGUMENTS

## Current Context

- **Branch**: !`git branch --show-current`
- **Last Commit**: !`git log -1 --oneline`

## Prerequisites

- `research/ddd/04-strategy.md` must exist (run `/ddd_strategize` first)
- `research/ddd/03-sub-domains.md` for context boundaries

## Process Steps

### Step 1: Read Prerequisites

1. Read `research/ddd/04-strategy.md` completely
2. Read `research/ddd/03-sub-domains.md` for boundaries and shared events
3. Read `research/ddd/02-event-catalog.md` for full building block details

### Step 2: Present Context Mapping Patterns

Brief user on patterns: Partnership, Customer-Supplier, Conformist, ACL, OHS, Published Language, Shared Kernel, Separate Ways.

### Step 3: Identify Context Pairs

From shared events, identify all context pairs with direction.

### Step 4: Define Each Relationship Interactively

For each context pair, present shared events and direction, then ask:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "What integration pattern fits between [Context A] (upstream) and [Context B] (downstream)?",
    "header": "Pattern",
    "multiSelect": false,
    "options": [
      {
        "label": "Customer-Supplier",
        "description": "Upstream accommodates downstream needs, downstream has influence"
      },
      {
        "label": "Conformist",
        "description": "Downstream conforms to upstream model, no negotiation"
      },
      {
        "label": "ACL (Anti-Corruption Layer)",
        "description": "Downstream translates upstream model to protect its own domain"
      },
      {
        "label": "Partnership",
        "description": "Both contexts evolve together with mutual dependency"
      }
    ]
  }]
</invoke>

If the user selects "Other", present the remaining patterns: OHS, Published Language, Shared Kernel, Separate Ways.

### Step 5: Document Data Flow

For each relationship: what data crosses, in what format, what translation is needed.

### Step 6: Build Context Map Diagram

Create Mermaid diagram showing all contexts and relationships with pattern labels.

After presenting the complete context map diagram:

<invoke name="AskUserQuestion">
  questions: [{
    "question": "Does this context map accurately represent all relationships?",
    "header": "Map Review",
    "multiSelect": false,
    "options": [
      {
        "label": "Map is correct",
        "description": "All relationships and patterns are accurately captured"
      },
      {
        "label": "Missing relationships",
        "description": "There are context interactions not shown on the map"
      },
      {
        "label": "Wrong patterns",
        "description": "Some relationship patterns need to be changed"
      }
    ]
  }]
</invoke>

### Step 7: Write Context Map Artifact

Create `research/ddd/05-context-map.md` with relationship details, integration summary, and ACL specifications.

### Step 8: Prompt Next Step

```
Context map written to `research/ddd/05-context-map.md`.

Summary:
- [N] context relationships mapped
- Patterns used: [list]
- [N] ACLs identified

Next step: Run `/ddd_define` to build Bounded Context Canvases and Aggregate Design Canvases.
```

## Guidelines

1. **User chooses patterns**: Present options with context, let user decide
2. **Direction matters**: Upstream publishes, downstream consumes
3. **ACL protects core domains**: Generic->core almost always needs ACL
4. **OHS for multiple consumers**: 3+ consumers = Open Host Service
5. **Preserve building block IDs**: Continue referencing E1, C1
6. **Practical integration**: Note actual mechanism (events, API, queue)
