# Unknown Values Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `Unknown` value variant to HCLValue for Terraform plan-stage compatibility (unknown value propagation).

**Architecture:** Add `Unknown(Decor)` to `HCLValue` and `ExprUnknown` to `Expression`. Operations on Unknown propagate Unknown (not error). No parser support — Unknown comes from programmatic construction (Terraform plan). Serialization outputs `"unknown"`.

**Tech Stack:** MoonBit, HCL library

---

## Files to Modify

| File | Change |
|------|--------|
| `value.mbt` | Add `Unknown(Decor)` variant; update `get_decor`, `set_decor`, `is_unknown`, `to_json_string`, factory constructor |
| `expr.mbt` | Add `ExprUnknown` variant; update `expr_to_string`, `expr_to_hcl_value`, `hcl_value_to_expression`, factory fn |
| `eval.mbt` | Unknown propagation: `eval_binary`, `eval_unary`, `eval_conditional`, `eval_expr`, `simplify_value` |
| `ser.mbt` | Add Unknown case in `format_hcl_value`, `format_value_content`, `Formatter::format_hcl_value_impl` |
| `de.mbt` | Update `value_to_type_name` |
| `json.mbt` | Add Unknown case in `value_to_json`, `value_to_json_pretty` |
| `template.mbt` | Update `value_to_string` |
| `trait.mbt` | Update `type_name_of` |
| `visit.mbt` | Update `visit_value_default` |
| `visit_mut.mbt` | Update `visit_value_mut_default` |
| `schema.mbt` | Handle Unknown in `validate_at` (pass through `Any`, reject others) |
| `funcs.mbt` | Add Unknown propagation helper; update `tostring` to handle Unknown |

## New Test File

| File | Content |
|------|---------|
| `unknown_test.mbt` | Tests for Unknown value: construction, type check, serialization, eval propagation, JSON, schema |

---

### Task 1: Add Unknown variant to HCLValue

**Files:**
- Modify: `value.mbt`
- Test: `unknown_test.mbt`

- [ ] **Step 1: Write the failing test**

Create `unknown_test.mbt`:
```moonbit
///|
test "HCLValue unknown construction and type check" {
  let u = HCLValue::unknown()
  assert_true(u.is_unknown())
  assert_false(u.is_null())
  assert_false(u.is_bool())
  assert_eq(u.get_decor().get_prefix(), None)
}

test "HCLValue unknown with decor" {
  let decor = { prefix: Some("# comment\n"), suffix: None }
  let u = Unknown(decor)
  assert_true(u.is_unknown())
  assert_eq(u.get_decor().get_prefix(), Some("# comment\n"))
}

test "HCLValue unknown set_decor" {
  let u = HCLValue::unknown()
  let decor = { prefix: Some("# c"), suffix: None }
  let u2 = u.set_decor(decor)
  assert_true(u2.is_unknown())
  assert_eq(u2.get_decor().get_prefix(), Some("# c"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test -F "HCLValue unknown *"`
Expected: FAIL (Unknown variant / is_unknown not found)

- [ ] **Step: Implement Unknown variant in value.mbt**

Add `Unknown(Decor)` to enum, add `is_unknown`, `unknown()` factory, update `get_decor`, `set_decor`, `to_json_string`.

- [ ] **Step: Run test to verify it passes**

Run: `moon test -F "HCLValue unknown *"`
Expected: PASS

- [ ] **Step: Commit**

```bash
git add value.mbt unknown_test.mbt
git commit -m "feat: add Unknown variant to HCLValue"
```

---

### Task 2: Add ExprUnknown to Expression + bridge functions

**Files:**
- Modify: `expr.mbt`
- Modify: `unknown_test.mbt`

- [ ] **Step: Write failing tests**

```moonbit
test "Expression unknown" {
  let e = ExprUnknown
  assert_eq(expr_to_string(e), "unknown")
}

test "expr_to_hcl_value unknown" {
  let v = expr_to_hcl_value(ExprUnknown)
  assert_true(v.is_unknown())
}

test "hcl_value_to_expression unknown" {
  let e = hcl_value_to_expression(HCLValue::unknown())
  assert_true(e == ExprUnknown)
}
```

- [ ] **Step: Implement**

Add `ExprUnknown` variant to `Expression`. Update `expr_to_string`, `expr_to_hcl_value`, `hcl_value_to_expression`. Add `expr_unknown()` factory.

- [ ] **Step: Run tests**

Run: `moon test -F "Expression unknown" && moon test -F "expr_to_hcl_value unknown" && moon test -F "hcl_value_to_expression unknown"`
Expected: PASS

- [ ] **Step: Commit**

```bash
git add expr.mbt unknown_test.mbt
git commit -m "feat: add ExprUnknown expression variant and bridge functions"
```

---

### Task 3: Serialization support (ser.mbt, json.mbt, de.mbt)

**Files:**
- Modify: `ser.mbt`
- Modify: `json.mbt`
- Modify: `de.mbt`
- Modify: `unknown_test.mbt`

- [ ] **Step: Write failing tests**

```moonbit
test "serialize unknown value" {
  assert_eq(to_hcl_value(HCLValue::unknown()), "unknown")
}

test "json unknown value" {
  assert_eq(value_to_json(HCLValue::unknown()), "null")
}

test "value_to_type_name unknown" {
  // internal test via deserialization path
}
```

- [ ] **Step: Implement**

- `ser.mbt`: Add `Unknown(_)` case outputting `"unknown"` in `format_hcl_value`, `format_value_content`, `Formatter::format_hcl_value_impl`
- `json.mbt`: Add `Unknown(_)` case outputting `"null"` in `value_to_json`, `value_to_json_pretty`
- `de.mbt`: Add `Unknown(_) => "unknown"` in `value_to_type_name`

- [ ] **Step: Run tests**

Run: `moon test -F "serialize unknown" && moon test -F "json unknown"`
Expected: PASS

- [ ] **Step: Commit**

```bash
git add ser.mbt json.mbt de.mbt unknown_test.mbt
git commit -m "feat: serialization support for Unknown values"
```

---

### Task 4: Eval propagation — Unknown returns Unknown

**Files:**
- Modify: `eval.mbt`
- Modify: `unknown_test.mbt`

- [ ] **Step: Write failing tests**

```moonbit
test "eval binary with unknown propagates" {
  let result = eval_binary(HCLValue::unknown(), Plus, HCLValue::int(1))
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => assert_true(false)
  }
}

test "eval unary with unknown propagates" {
  let result = eval_unary(Minus, HCLValue::unknown())
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => assert_true(false)
  }
}

test "eval conditional with unknown condition" {
  // Unknown condition should return unknown
  let cond = ExprUnknown
  let result = eval_conditional(cond, ExprBool(true), ExprBool(false))
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => assert_true(false)
  }
}

test "eval_expr unknown returns unknown" {
  let result = eval_expr(ExprUnknown, {}, builtin_functions())
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => assert_true(false)
  }
}
```

- [ ] **Step: Implement**

Add `fn is_unknown_value(v : HCLValue) -> Bool` helper. In `eval_binary`, check if either operand is Unknown → return Ok(unknown). In `eval_unary`, check operand → return Ok(unknown). In `eval_conditional`, if condition evaluates to Unknown → return Ok(unknown). In `eval_expr`, add `ExprUnknown => Ok(HCLValue::unknown())`.

- [ ] **Step: Run tests**

Run: `moon test -F "eval binary with unknown" && moon test -F "eval unary with unknown" && moon test -F "eval conditional with unknown" && moon test -F "eval_expr unknown"`
Expected: PASS

- [ ] **Step: Run full test suite**

Run: `moon test`
Expected: All existing tests still pass

- [ ] **Step: Commit**

```bash
git add eval.mbt unknown_test.mbt
git commit -m "feat: unknown value propagation in expression evaluation"
```

---

### Task 5: Template, Visit, Trait, Schema, Funcs support

**Files:**
- Modify: `template.mbt`
- Modify: `visit.mbt`
- Modify: `visit_mut.mbt`
- Modify: `trait.mbt`
- Modify: `schema.mbt`
- Modify: `funcs.mbt`
- Modify: `unknown_test.mbt`

- [ ] **Step: Write failing tests**

```moonbit
test "template value_to_string unknown" {
  // value_to_string on unknown should produce "unknown"
}

test "visit unknown value" {
  // visit_value should handle Unknown variant
}

test "schema rejects unknown for non-Any" {
  // validate_at with BoolSchema on Unknown should fail
}

test "schema accepts unknown for Any" {
  // validate_at with Any on Unknown should pass
}

test "tostring from unknown" {
  let f = builtin_functions().get("tostring")
  match f {
    Some(func) => {
      match func([HCLValue::unknown()]) {
        Ok(v) => assert_true(v == HCLValue::String("unknown", Decor::empty()))
        Err(_) => assert_true(false)
      }
    }
    None => assert_true(false)
  }
}
```

- [ ] **Step: Implement**

- `template.mbt`: Add `Unknown(_) => "unknown"` in `value_to_string`
- `visit.mbt`: Add `Unknown(_) => ()` in `visit_value_default`
- `visit_mut.mbt`: Add `Unknown(_) => ()` in `visit_value_mut_default`
- `trait.mbt`: Add `Unknown(_) => "unknown"` in `type_name_of`
- `schema.mbt`: In `validate_at`, for non-Any schema, check `is_unknown()` → return error; for `Any`, pass through
- `funcs.mbt`: Update `tostring` function to handle Unknown → return `"unknown"`

- [ ] **Step: Run full test suite**

Run: `moon check && moon test && moon info && moon fmt`
Expected: All tests pass, 0 type errors

- [ ] **Step: Commit**

```bash
git add template.mbt visit.mbt visit_mut.mbt trait.mbt schema.mbt funcs.mbt unknown_test.mbt
git commit -m "feat: complete Unknown value support across all modules"
```

---

### Task 6: Final verification and cleanup

- [ ] **Step: Run full verification**

```bash
moon check && moon test && moon info && moon fmt
```

Expected: 0 errors, all tests pass (including new Unknown tests)

- [ ] **Step: Verify warning count**

Run: `moon check 2>&1 | grep -c "warning"`
Expected: ~25 warnings (same as before, no new warnings)

- [ ] **Step: Update PROGRESS.md**

Mark Unknown (#1) as ✅ 完成. Update test count. Update iteration status.

- [ ] **Step: Final commit**

```bash
git add PROGRESS.md
git commit -m "docs: mark Unknown values as complete in PROGRESS.md"
```
