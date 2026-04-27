# Template Else Clause Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete template else clause implementation including else-if chains, ensuring full HCL spec compliance.

**Architecture:** Extend existing template parser and evaluator in `template.mbt` to support `%{if cond}...%{else if cond2}...%{else}...%{endif}` syntax. Add comprehensive tests.

**Tech Stack:** MoonBit, existing HCL parser/evaluator infrastructure.

---

## Current Status Analysis

- `template.mbt` already handles `%{else}` directive (line 213)
- `template_test.mbt` has else tests (lines 274-430) - all passing
- Missing: `%{else if cond}` chain support
- Missing: Nested else-if chains

## File Structure

- Modify: `template.mbt` - add else-if parsing and evaluation
- Modify: `template_test.mbt` - add else-if tests
- Modify: `PROGRESS.md` - update status

## Tasks

### Task 1: Verify existing else implementation

**Files:**
- Test: `template_test.mbt`

- [ ] **Step 1: Run existing else tests**

Run: `moon test -F "template else*"`
Expected: All 8 else tests pass

- [ ] **Step 2: Document current behavior**

Verify that `%{if cond}...%{else}...%{endif}` works correctly for:
- true condition → true branch
- false condition → else branch
- nested conditionals
- with interpolation
- inside for loops

### Task 2: Add else-if chain parsing support

**Files:**
- Modify: `template.mbt:203-238` (parse_directive_content function)

- [ ] **Step 1: Extend parse_directive_content to recognize "else if"**

Currently `trimmed == "else"` catches all else directives. Need to check for `has_prefix(trimmed, "else if ")` and parse condition.

```moonbit
} else if has_prefix(trimmed, "else if ") {
    // %{else if cond}
    let cond_str = substring(trimmed, 8, trimmed.length())
    match parse_template_expression(cond_str) {
        Ok(cond) => Ok(ConditionalElseIf(cond))
        Err(e) => Err(e)
    }
} else if trimmed == "else" {
    // %{else}
    Ok(ConditionalElse)
}
```

- [ ] **Step 2: Add ConditionalElseIf variant to TemplatePart enum**

Add new variant to `TemplatePart` enum (line 7-22):

```moonbit
pub(all) enum TemplatePart {
    // ... existing variants ...
    /// Else-if directive %{else if cond}
    ConditionalElseIf(Expression)
    // ... rest ...
}
```

- [ ] **Step 3: Update evaluate function to handle ConditionalElseIf**

Modify `evaluate` function (line 375-494) and helper functions to process else-if chains.

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

### Task 3: Implement else-if chain evaluation

**Files:**
- Modify: `template.mbt` - evaluate function and helpers

- [ ] **Step 1: Update find_conditional_boundary to handle else-if**

Modify `find_conditional_boundary` (line 558-582) to treat `ConditionalElseIf` as boundary (like ConditionalElse).

- [ ] **Step 2: Update evaluate logic for else-if chains**

When condition is false, evaluate else-if conditions sequentially until one is true or fall through to else.

- [ ] **Step 3: Update evaluate_body_range for nested else-if**

Ensure recursive evaluation handles else-if chains correctly.

### Task 4: Add comprehensive else-if tests

**Files:**
- Modify: `template_test.mbt`

- [ ] **Step 1: Add basic else-if test**

```moonbit
test "template else if basic" {
    let input = "%{if a}first%{else if b}second%{else}third%{endif}"
    // Test all combinations: a=true, a=false/b=true, a=false/b=false
}
```

- [ ] **Step 2: Add multiple else-if chain test**

```moonbit
test "template else if chain" {
    let input = "%{if a}1%{else if b}2%{else if c}3%{else}4%{endif}"
    // Test various combinations
}
```

- [ ] **Step 3: Add else-if with interpolation test**

- [ ] **Step 4: Add nested else-if test**

- [ ] **Step 5: Add else-if inside for loop test**

- [ ] **Step 6: Run all tests**

Run: `moon test`
Expected: All tests pass (including new else-if tests)

### Task 5: Update documentation and progress

**Files:**
- Modify: `PROGRESS.md`

- [ ] **Step 1: Update P0 #4 status to completed**

- [ ] **Step 2: Update test count**

- [ ] **Step 3: Update "下一步计划" section**

- [ ] **Step 4: Run final verification**

Run: `moon check && moon test && moon info && moon fmt`
Expected: All pass

## Testing Strategy

1. Unit tests for else-if parsing
2. Integration tests for else-if evaluation
3. Edge cases: nested else-if, multiple chains, with interpolation
4. Regression tests: ensure existing else tests still pass

## Success Criteria

- `%{if cond}...%{else if cond2}...%{else}...%{endif}` syntax works
- All existing tests pass
- New else-if tests pass
- moon check: 0 errors
- moon fmt: passes