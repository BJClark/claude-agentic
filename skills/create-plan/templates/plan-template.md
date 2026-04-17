# [Feature/Task Name] Implementation Plan

## Overview
[Brief description of what we're implementing and why]

## Current State Analysis
[What exists now, what's missing, key constraints discovered]

## Desired End State
[Specification of desired end state and how to verify it]

### Key Discoveries:
- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## Technical Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [e.g. Storage engine] | [e.g. PostgreSQL JSONB] | [Why this was chosen over alternatives] |

## What We're NOT Doing
[Explicitly list out-of-scope items]

## Implementation Approach
[High-level strategy and reasoning]

## Executable Specifications (Outside-In)

Include this section only if the codebase has a BDD / outside-in harness. Otherwise write "No outside-in harness — n/a" and omit Phase 0.

**Harness**: [e.g. Cucumber / pytest-bdd / RSpec feature]
**Run command**: `[exact CLI]`

| Scenario | Spec file | Expected initial failure mode | Gated phase |
|----------|-----------|-------------------------------|-------------|
| [Happy-path checkout] | `features/checkout.feature:12` | Missing step def for "given cart has items" | Phase 1 |
| [Invalid coupon error] | `features/checkout.feature:40` | Route `/coupons/validate` returns 404 | Phase 2 |

## Phase 0: Failing Specifications

### Overview
Write the executable scenarios that describe the target behavior and confirm they fail for the right reason.

### Changes Required:
- Author `.feature` (or equivalent) files listed in the Executable Specifications table
- Wire minimal step-definition scaffolding needed to reach the failing assertion

### Success Criteria:

#### Automated Verification:
- [ ] New specs run without syntax/environment errors: `[exact CLI]`
- [ ] Each new scenario fails with the documented expected failure mode (not an unrelated error)
- [ ] Pre-existing specs still pass: `[exact CLI for full suite]`

#### Manual Verification:
- [ ] Failure messages clearly describe the missing behavior
- [ ] Scenarios reviewed with product/stakeholder for intent

---

## Phase 1: [Descriptive Name]

### Overview
[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary]

```[language]
// Specific code to add/modify
```

### Success Criteria:

#### Automated Verification:
- [ ] Migration applies cleanly: `make migrate`
- [ ] Unit tests pass: `make test-component`
- [ ] Type checking passes: `make typecheck`
- [ ] Linting passes: `make lint`
- [ ] Integration tests pass: `make test-integration`
- [ ] Gated feature spec(s) now pass: `[exact spec command from Executable Specifications table]`

#### Manual Verification:
- [ ] Feature works as expected in UI
- [ ] Performance acceptable under load
- [ ] Edge case handling verified
- [ ] No regressions in related features

**Implementation Note**: After automated verification passes, pause for manual confirmation before next phase.

---

## Phase 2: [Descriptive Name]
[Similar structure...]

---

## Testing Strategy

### Unit Tests:
- [What to test]
- [Key edge cases]

### Integration Tests:
- [End-to-end scenarios]

### Manual Testing Steps:
1. [Specific verification step]
2. [Another verification step]

## Performance Considerations
[Performance implications or optimizations needed]

## Migration Notes
[How to handle existing data/systems]

## References
- Original ticket: `[path]`
- Related research: `[path]`
- Similar implementation: `[file:line]`
