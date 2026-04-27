# Splat + Strip Markers + Unicode Ident Implementation Plan

> **For agentic workers:** Use subagent-driven-development to implement task-by-task.

**Goal:** Implement 3 P1 features: Splat operator (`.*`/`[*]`), Template strip markers (`${~ expr ~}`), and Unicode identifiers (XID_Start/XID_Continue).

**Architecture:** 
- Splat: Add `Splat` variant to `TraversalOperator`, update parser/eval/visit/serialization
- Strip markers: Extend `TemplatePart` with strip-aware variants, strip whitespace during evaluation
- Unicode: Replace ASCII-only checks with Unicode XID_Start/XID_Continue validation

**Branch:** `lenitain/feat/splat-strip-unicode`

---

## Files to Modify

| File | Changes |
|------|---------|
| `expr.mbt` | Add `Splat` to `TraversalOperator`, update `expr_to_string` |
| `parser.mbt` | Parse `.*` and `[*]` in `parse_property_access` |
| `eval.mbt` | Evaluate `Splat` operator (map over array elements) |
| `visit.mbt` | Handle `Splat` in `visit_traversal_operator_default` |
| `visit_mut.mbt` | Handle `Splat` in `visit_traversal_operator_mut_default` |
| `template.mbt` | Add strip-aware `InterpolationStrip`/`ConditionalStartStrip` etc., update `evaluate` |
| `ident.mbt` | Add Unicode XID_Start/XID_Continue validation |
| `lexer.mbt` | Support Unicode identifier chars in token reading |
| `expr_wbtest.mbt` | Add splat tests |
| `template_test.mbt` | Add strip marker tests |
| New: `splat_test.mbt` | Splat operator integration tests |

---

### Task 1: Splat - Add `Splat` variant to `TraversalOperator`

**Files:** `expr.mbt:104-109`

- [ ] Add `Splat` variant to `TraversalOperator` enum
- [ ] Add `splat()` method to `TraversalBuilder`
- [ ] Update `expr_to_string` to output `.*` for `Splat`
- [ ] Update `visit.mbt` and `visit_mut.mbt` for `Splat` case
- [ ] Run `moon check`

### Task 2: Splat - Parser support for `.*` and `[*]`

**Files:** `parser.mbt:735-790`

- [ ] In `parse_property_access`, after `.`, check if next token is `Star` → emit `Splat`
- [ ] In `parse_property_access`, after `[`, check if next token is `Star` → consume `]` → emit `Splat`
- [ ] Write parser tests
- [ ] Run `moon check && moon test`

### Task 3: Splat - Evaluation

**Files:** `eval.mbt:399-470`

- [ ] In `eval_expr` traversal loop, handle `Splat` operator:
  - If current value is array, map over elements applying remaining operators
  - If current value is object, map over values applying remaining operators
  - Otherwise return type error
- [ ] Write eval tests
- [ ] Run `moon check && moon test`

### Task 4: Strip markers - Template parsing

**Files:** `template.mbt`

- [ ] Add `InterpolationStrip(Expression)` variant to `TemplatePart`
- [ ] In `Template::from_string`, detect `${~` and `~}` patterns
- [ ] Store strip info in template parts
- [ ] In `evaluate`, strip adjacent whitespace for strip-marked parts
- [ ] Write tests
- [ ] Run `moon check && moon test`

### Task 5: Unicode identifiers

**Files:** `ident.mbt`, `lexer.mbt`

- [ ] Implement `is_xid_start(ch : Char) -> Bool` (Unicode property check)
- [ ] Implement `is_xid_continue(ch : Char) -> Bool`
- [ ] Update `is_id_start` and `is_id_continue` to include Unicode chars
- [ ] Update lexer to read Unicode identifier characters
- [ ] Write tests with Unicode identifiers
- [ ] Run `moon check && moon test`

### Task 6: Final verification

- [ ] `moon check` — 0 errors
- [ ] `moon test` — all tests pass
- [ ] `moon fmt` — passes
- [ ] `moon info` — passes
- [ ] Update PROGRESS.md
