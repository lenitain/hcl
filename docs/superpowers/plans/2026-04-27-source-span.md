# Source Span (#10) Implementation Plan

> **For agentic workers:** Use subagent-driven-development to implement task-by-task.

**Goal:** Add source position (byte offset + line/column) tracking to AST nodes so every parsed element knows its origin in the source string.

**Architecture:**
- New `Span` struct with `start_line`, `start_col`, `start_offset`, `end_line`, `end_col`, `end_offset`
- New `Spanned[T]` wrapper (value + optional span), used for `Spanned[Expression]` in `Attr`
- `Body`, `Block` get optional `span` fields directly
- Parser captures start/end positions using `lexer.location()` around each parse operation
- Lexer adds `last_end` tracking for accurate end positions

**Branch:** `lenitain/feat/source-span`

---

## Files to Modify

| File | Changes |
|------|---------|
| New: `span.mbt` | `Span` struct, `Spanned[T]` wrapper |
| `body.mbt` | `Attr.value` → `Spanned[Expression]`, `Body.span`, `Block.span` |
| `parser.mbt` | Capture spans during parsing |
| `eval.mbt` | Unwrap `Spanned[Expression]` |
| `ser.mbt` | Unwrap `Spanned[Expression]` |
| `visit.mbt` | Handle `Spanned[Expression]` |
| `visit_mut.mbt` | Handle `Spanned[Expression]` |
| `decorated_expr.mbt` | Update for `Spanned[Expression]` |
| `json.mbt` | Unwrap `Spanned[Expression]` |
| `de.mbt` | Update deserialization |
| `schema.mbt` | Unwrap `Spanned[Expression]` |
| `analysis.mbt` | Unwrap `Spanned[Expression]` |
| Various test files | Update pattern matches |

---

### Task 1: Add `Span` and `Spanned[T]` types

**Files:** New `span.mbt`

- [ ] Create `span.mbt` with:
  - `Span` struct (6 fields: start_line, start_col, start_offset, end_line, end_col, end_offset)
  - `Span::new()`, `Span::empty()`, `Span::merge()` methods
  - `Spanned[T]` struct (value + span?)
  - `Spanned::new()`, `Spanned::bare()` constructors
  - `Spanned::unwrap()` to get inner value
- [ ] Run `moon check`

### Task 2: Update `Attr` to use `Spanned[Expression]`

**Files:** `body.mbt`

- [ ] Change `Attr.value` from `Expression` to `Spanned[Expression]`
- [ ] Update `Attr::new()`, `Attr::with_decor()` constructors
- [ ] Add `Attr::expr()` accessor that unwraps Spanned
- [ ] Update all pattern matches on `Attr` in `body.mbt`
- [ ] Run `moon check`

### Task 3: Add `span` to `Body` and `Block`

**Files:** `body.mbt`

- [ ] Add `span : Span?` field to `Body` struct
- [ ] Add `span : Span?` field to `Block` struct
- [ ] Update constructors (default to `None`)
- [ ] Add `set_span` methods
- [ ] Run `moon check`

### Task 4: Update parser to capture spans

**Files:** `parser.mbt`

- [ ] Add helper `with_span(parser, fn) -> (result, Span)` that captures start/end positions
- [ ] In `parse_attr`: capture span, wrap value in `Spanned`
- [ ] In `parse_block`: capture span, set on Block
- [ ] In `parse_body`: capture span, set on Body
- [ ] In expression parsing: capture span, wrap in `Spanned[Expression]`
- [ ] Run `moon check && moon test`

### Task 5: Update eval.mbt

**Files:** `eval.mbt`

- [ ] All places accessing `attr.value` → `attr.value.unwrap()` or `attr.expr()`
- [ ] Update `eval_expr` if it receives `Spanned[Expression]`
- [ ] Run `moon check && moon test`

### Task 6: Update ser.mbt, json.mbt, de.mbt

**Files:** `ser.mbt`, `json.mbt`, `de.mbt`

- [ ] Serialization: unwrap Spanned when accessing expression
- [ ] JSON conversion: unwrap Spanned
- [ ] Deserialization: wrap in Spanned::bare()
- [ ] Run `moon check && moon test`

### Task 7: Update visit.mbt, visit_mut.mbt, decorated_expr.mbt

**Files:** `visit.mbt`, `visit_mut.mbt`, `decorated_expr.mbt`

- [ ] Visit: add `visit_spanned_expr` method, update `visit_attr` to unwrap
- [ ] VisitMut: same
- [ ] decorated_expr.mbt: update for Spanned[Expression]
- [ ] Run `moon check && moon test`

### Task 8: Update remaining files and tests

**Files:** `schema.mbt`, `analysis.mbt`, `template.mbt`, all test files

- [ ] Update all `attr.value` accesses across codebase
- [ ] Update test pattern matches
- [ ] Add span-specific tests (verify line/col tracking)
- [ ] Run `moon check && moon test && moon fmt && moon info`

### Task 9: Final verification

- [ ] `moon check` — 0 errors
- [ ] `moon test` — all tests pass
- [ ] `moon fmt` — passes
- [ ] `moon info` — passes
- [ ] Update PROGRESS.md
