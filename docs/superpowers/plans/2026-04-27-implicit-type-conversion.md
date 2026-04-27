# Implicit Type Conversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement implicit type conversion between string↔number and string↔bool types in HCL expression evaluation, following the HCL specification.

**Architecture:** Add conversion functions and modify existing evaluation functions to automatically convert types when needed. The approach will be to add helper functions for type conversion, then modify the binary/comparison operations to use these conversions.

**Tech Stack:** MoonBit, HCL parser/evaluator

---

## HCL Specification Reference

From the HCL spec (lines 502-526):
- **string↔number**: Bidirectional conversion. Number→string is safe, string→number is unsafe.
- **string↔bool**: Bidirectional conversion. Bool→string is safe, string→bool is unsafe.
- **bool values**: true, false, "1", "0" (alternative representations)
- **number to string**: Integer part + optional fractional part (no exponent)
- **string to number**: Reverse of above mapping (no exponent allowed)

## File Structure

- Modify: `eval.mbt` - Add conversion functions and modify evaluation logic
- Create: `eval_wbtest.mbt` - Whitebox tests for type conversion
- Modify: `template.mbt` - Update `value_to_string` for consistency

## Tasks

### Task 1: Add Type Conversion Helper Functions

**Files:**
- Modify: `eval.mbt:1-50` (add new functions after existing helpers)

- [ ] **Step 1: Add string_to_bool conversion function**

```moonbit
///|
/// Convert string to bool value
fn string_to_bool(s : String) -> HCLResult[HCLValue] {
  match s {
    "true" | "1" => Ok(Bool(true, Decor::empty()))
    "false" | "0" => Ok(Bool(false, Decor::empty()))
    _ => Err(HCLError::type_error("Cannot convert string \"" + s + "\" to bool"))
  }
}

///|
/// Convert string to number value
fn string_to_number(s : String) -> HCLResult[HCLValue] {
  let trimmed = s.trim().to_string()
  if trimmed.length() == 0 {
    return Err(HCLError::type_error("Cannot convert empty string to number"))
  }
  
  // Check if it's a valid number format
  let mut has_digit = false
  let mut has_dot = false
  let mut i = 0
  let mut negative = false
  
  if trimmed.code_unit_at(0) == '-'.to_int().to_uint16() {
    negative = true
    i = 1
  } else if trimmed.code_unit_at(0) == '+'.to_int().to_uint16() {
    i = 1
  }
  
  while i < trimmed.length() {
    let c = trimmed.code_unit_at(i)
    if c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16() {
      has_digit = true
    } else if c == '.'.to_int().to_uint16() {
      if has_dot {
        return Err(HCLError::type_error("Invalid number format: " + s))
      }
      has_dot = true
    } else {
      return Err(HCLError::type_error("Invalid number format: " + s))
    }
    i += 1
  }
  
  if !has_digit {
    return Err(HCLError::type_error("Invalid number format: " + s))
  }
  
  // Parse the number
  if has_dot {
    // Parse as float
    match trimmed.parse_double() {
      Some(f) => Ok(Number(Number::from_finite_f64(if negative { -f } else { f }), Decor::empty()))
      None => Err(HCLError::type_error("Invalid number format: " + s))
    }
  } else {
    // Parse as integer
    match trimmed.parse_int() {
      Some(n) => Ok(Number(Number::from_int(if negative { -n } else { n }), Decor::empty()))
      None => Err(HCLError::type_error("Invalid number format: " + s))
    }
  }
}

///|
/// Convert number to string value
fn number_to_string(n : Number) -> String {
  n.to_string()
}

///|
/// Convert bool to string value
fn bool_to_string(b : Bool) -> String {
  if b { "true" } else { "false" }
}

///|
/// Try to convert value to target type for implicit conversion
fn try_convert(value : HCLValue, target_type : String) -> HCLResult[HCLValue] {
  match (value, target_type) {
    // Already correct type
    (String(_, _), "string") => Ok(value)
    (Number(_, _), "number") => Ok(value)
    (Bool(_, _), "bool") => Ok(value)
    (Null(_), _) => Ok(value) // Null converts to any type
    
    // String to other types
    (String(s, _), "number") => string_to_number(s)
    (String(s, _), "bool") => string_to_bool(s)
    
    // Other types to string
    (Number(n, _), "string") => Ok(String(number_to_string(n), Decor::empty()))
    (Bool(b, _), "string") => Ok(String(bool_to_string(b), Decor::empty()))
    
    // No conversion available
    _ => Err(HCLError::type_error("Cannot convert " + value.type_name() + " to " + target_type))
  }
}
```

- [ ] **Step 2: Add type_name helper to HCLValue**

In `value.mbt`, add a method to get type name:

```moonbit
///|
/// Get type name as string
pub fn HCLValue::type_name(self : HCLValue) -> String {
  match self {
    Null(_) => "null"
    Bool(_, _) => "bool"
    Number(_, _) => "number"
    String(_, _) => "string"
    Array(_, _) => "array"
    Object(_, _) => "object"
    Unknown(_) => "unknown"
  }
}
```

- [ ] **Step 3: Run tests to verify no regressions**

Run: `moon test`
Expected: All existing tests pass

### Task 2: Modify Binary Operations for Implicit Conversion

**Files:**
- Modify: `eval.mbt:57-180` (modify eval_add, eval_sub, etc.)

- [ ] **Step 1: Modify eval_add for implicit conversion**

```moonbit
///|
/// Evaluate addition
fn eval_add(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Number(a + b, Decor::empty()))
    (String(a, _), String(b, _)) => Ok(String(a + b, Decor::empty()))
    // Implicit conversion: string + number
    (String(a, _), Number(b, _)) => Ok(String(a + number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) => Ok(String(number_to_string(a) + b, Decor::empty()))
    // Implicit conversion: string + bool
    (String(a, _), Bool(b, _)) => Ok(String(a + bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) => Ok(String(bool_to_string(a) + b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for addition"))
  }
}
```

- [ ] **Step 2: Modify comparison operations for implicit conversion**

```moonbit
///|
/// Evaluate equality with implicit conversion
fn eval_eq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  // Try direct comparison first
  if left == right {
    return Ok(Bool(true, Decor::empty()))
  }
  
  // Try implicit conversion for comparison
  match (left, right) {
    // String vs Number: convert number to string
    (String(s, _), Number(n, _)) => Ok(Bool(s == number_to_string(n), Decor::empty()))
    (Number(n, _), String(s, _)) => Ok(Bool(number_to_string(n) == s, Decor::empty()))
    // String vs Bool: convert bool to string
    (String(s, _), Bool(b, _)) => Ok(Bool(s == bool_to_string(b), Decor::empty()))
    (Bool(b, _), String(s, _)) => Ok(Bool(bool_to_string(b) == s, Decor::empty()))
    _ => Ok(Bool(false, Decor::empty()))
  }
}

///|
/// Evaluate inequality with implicit conversion
fn eval_neq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match eval_eq(left, right) {
    Ok(Bool(b, _)) => Ok(Bool(!b, Decor::empty()))
    other => other
  }
}

///|
/// Evaluate less than with implicit conversion
fn eval_lt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a < b, Decor::empty()))
    // String comparison for mixed types
    (String(a, _), Number(b, _)) => Ok(Bool(a < number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) => Ok(Bool(number_to_string(a) < b, Decor::empty()))
    (String(a, _), Bool(b, _)) => Ok(Bool(a < bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) => Ok(Bool(bool_to_string(a) < b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for less than"))
  }
}

///|
/// Evaluate greater than with implicit conversion
fn eval_gt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a > b, Decor::empty()))
    // String comparison for mixed types
    (String(a, _), Number(b, _)) => Ok(Bool(a > number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) => Ok(Bool(number_to_string(a) > b, Decor::empty()))
    (String(a, _), Bool(b, _)) => Ok(Bool(a > bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) => Ok(Bool(bool_to_string(a) > b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for greater than"))
  }
}

///|
/// Evaluate less than or equal with implicit conversion
fn eval_lte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a <= b, Decor::empty()))
    // String comparison for mixed types
    (String(a, _), Number(b, _)) => Ok(Bool(a <= number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) => Ok(Bool(number_to_string(a) <= b, Decor::empty()))
    (String(a, _), Bool(b, _)) => Ok(Bool(a <= bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) => Ok(Bool(bool_to_string(a) <= b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for less than or equal"))
  }
}

///|
/// Evaluate greater than or equal with implicit conversion
fn eval_gte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a >= b, Decor::empty()))
    // String comparison for mixed types
    (String(a, _), Number(b, _)) => Ok(Bool(a >= number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) => Ok(Bool(number_to_string(a) >= b, Decor::empty()))
    (String(a, _), Bool(b, _)) => Ok(Bool(a >= bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) => Ok(Bool(bool_to_string(a) >= b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for greater than or equal"))
  }
}
```

- [ ] **Step 3: Run tests to verify no regressions**

Run: `moon test`
Expected: All existing tests pass

### Task 3: Add Tests for Implicit Type Conversion

**Files:**
- Create: `eval_wbtest.mbt` (or modify existing test file)

- [ ] **Step 1: Create test file for implicit type conversion**

```moonbit
///|
/// Tests for implicit type conversion in HCL evaluation

test "string to number conversion" {
  // Valid integer
  let result = string_to_number("123")
  assert_true(result.is_ok())
  
  // Valid float
  let result = string_to_number("123.45")
  assert_true(result.is_ok())
  
  // Invalid string
  let result = string_to_number("abc")
  assert_true(result.is_err())
}

test "string to bool conversion" {
  // Valid true values
  assert_true(string_to_bool("true").is_ok())
  assert_true(string_to_bool("1").is_ok())
  
  // Valid false values
  assert_true(string_to_bool("false").is_ok())
  assert_true(string_to_bool("0").is_ok())
  
  // Invalid string
  let result = string_to_bool("yes")
  assert_true(result.is_err())
}

test "implicit conversion in addition" {
  // string + number
  let left = String("value: ", Decor::empty())
  let right = Number(Number::from_int(42), Decor::empty())
  let result = eval_add(left, right)
  assert_true(result.is_ok())
  match result {
    Ok(String(s, _)) => assert_eq(s, "value: 42")
    _ => assert_true(false)
  }
}

test "implicit conversion in equality" {
  // string == number
  let left = String("42", Decor::empty())
  let right = Number(Number::from_int(42), Decor::empty())
  let result = eval_eq(left, right)
  assert_true(result.is_ok())
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => assert_true(false)
  }
}

test "implicit conversion in comparison" {
  // string < number
  let left = String("10", Decor::empty())
  let right = Number(Number::from_int(20), Decor::empty())
  let result = eval_lt(left, right)
  assert_true(result.is_ok())
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => assert_true(false)
  }
}
```

- [ ] **Step 2: Run the new tests**

Run: `moon test -F "implicit"`
Expected: All new tests pass

### Task 4: Update Template System for Consistency

**Files:**
- Modify: `template.mbt:835-845` (update value_to_string)

- [ ] **Step 1: Update value_to_string to use consistent conversion**

```moonbit
///|
/// Convert HCLValue to string
fn value_to_string(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(b, _) => bool_to_string(b)
    Number(n, _) => number_to_string(n)
    String(s, _) => s
    Array(_, _) => "[array]"
    Object(_, _) => "[object]"
    Unknown(_) => "(unknown)"
  }
}
```

- [ ] **Step 2: Run all tests**

Run: `moon test`
Expected: All tests pass

### Task 5: Final Verification and Cleanup

- [ ] **Step 1: Run full test suite**

Run: `moon test`
Expected: All tests pass, including new implicit conversion tests

- [ ] **Step 2: Run moon check for type checking**

Run: `moon check`
Expected: No type errors

- [ ] **Step 3: Run moon fmt for formatting**

Run: `moon fmt`
Expected: Code formatted correctly

- [ ] **Step 4: Run moon info to regenerate interface**

Run: `moon info`
Expected: Interface updated

- [ ] **Step 5: Commit changes**

```bash
git add eval.mbt value.mbt template.mbt eval_wbtest.mbt
git commit -m "feat: implement implicit type conversion for string↔number and string↔bool

- Add string_to_number and string_to_bool conversion functions
- Modify binary operations to support implicit conversion
- Update comparison operations for mixed types
- Add comprehensive tests for type conversion
- Follow HCL specification for conversion rules

Closes #2"
```

---

## Success Criteria

1. ✅ String can be implicitly converted to number in arithmetic operations
2. ✅ String can be implicitly converted to bool in logical operations
3. ✅ Number can be implicitly converted to string in concatenation
4. ✅ Bool can be implicitly converted to string in concatenation
5. ✅ Mixed type comparisons work correctly
6. ✅ All existing tests continue to pass
7. ✅ New tests cover all conversion scenarios
8. ✅ Code follows MoonBit style guidelines

## Reference

- HCL Specification: https://github.com/hashicorp/hcl/blob/main/spec.md (lines 502-526)
- Current implementation: `eval.mbt`
- Test patterns: `template_test.mbt`, `spec_test.mbt`
