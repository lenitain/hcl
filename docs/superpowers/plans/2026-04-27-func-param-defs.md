# Function Parameter Definition System (#13) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace raw closures with formal `FuncDef` structs that carry parameter type specs, variadic support, and automatic arity/type validation for all 45 built-in functions.

**Architecture:** Add `ParamType` enum + `FuncDef` struct + `FuncDefBuilder` to `funcs.mbt`. Each built-in function gets a formal definition with typed params. `FuncDef::call()` validates arity and types before invoking the function body. `eval.mbt` is updated to call through `FuncDef`.

**Tech Stack:** MoonBit, existing HCLValue/HCLError types

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `funcs.mbt` | Modify | Add ParamType, FuncDef, FuncDefBuilder types + update builtin_functions() |
| `funcs_test.mbt` | Modify | Add tests for FuncDef validation system |
| `eval.mbt` | Modify | Update ExprFuncCall handler to use FuncDef::call() |

## Design

### ParamType enum
```
enum ParamType {
  Any              // accepts all types
  Bool             // HCLValue::Bool
  Number           // HCLValue::Number
  String           // HCLValue::String
  Array(ParamType) // Array with element type hint
  Object(ParamType)// Object with value type hint
  Nullable(ParamType) // null or inner type
  OneOf(Array[ParamType]) // union type
}
```

### FuncDef struct
```
struct FuncDef {
  name       : String
  params     : Array[ParamType]       // positional params
  variadic   : ParamType?             // variadic tail (optional)
  func       : (Array[HCLValue]) -> HCLResult[HCLValue]
}
```

### FuncDefBuilder
Builder pattern: `.param(ParamType)`, `.variadic(ParamType)`, `.build(name, func)`

### FuncDef::call(args)
1. Check arity: `args.length() < params.length()` → error
2. Check arity: `!variadic.is_some() && args.length() > params.length()` → error
3. Type-check each positional arg against its ParamType
4. Type-check each variadic arg against variadic ParamType
5. Call `func(args)`

### Integration
- `builtin_functions()` changes return type to `Map[String, FuncDef]`
- `eval.mbt` calls `func_def.call(evaluated_args)` instead of `func(evaluated_args)`
- Individual functions drop manual `check_args`/`check_min_args` calls

---

## Tasks

### Task 1: Add ParamType enum and is_satisfied_by

**Files:**
- Modify: `funcs.mbt` (add before `builtin_functions()`)

- [ ] **Step 1: Add ParamType enum**

```moonbit
///|
/// Parameter type hint for function argument validation
pub enum ParamType {
  /// Accepts any type
  Any
  /// Boolean value
  ParamBool
  /// Numeric value
  ParamNumber
  /// String value
  ParamString
  /// Array with element type hint
  ParamArray(ParamType)
  /// Object with value type hint
  ParamObject(ParamType)
  /// Nullable version of inner type
  Nullable(ParamType)
  /// Union of multiple types
  OneOf(Array[ParamType])
} derive(Debug, Eq)
```

- [ ] **Step 2: Add is_satisfied_by method**

```moonbit
///|
/// Check if a value satisfies this parameter type
pub fn ParamType::is_satisfied_by(self : ParamType, value : HCLValue) -> Bool {
  match self {
    Any => true
    ParamBool => value.is_bool()
    ParamNumber => value.is_number()
    ParamString => value.is_string()
    ParamArray(elem) =>
      match value {
        Array(arr, _) => arr.all(fn(v) { elem.is_satisfied_by(v) })
        _ => false
      }
    ParamObject(val_type) =>
      match value {
        Object(o, _) => {
          for _, v in o {
            if not(val_type.is_satisfied_by(v)) {
              return false
            }
          }
          true
        }
        _ => false
      }
    Nullable(inner) =>
      match value {
        Null(_) => true
        _ => inner.is_satisfied_by(value)
      }
    OneOf(types) => types.any(fn(t) { t.is_satisfied_by(value) })
  }
}
```

- [ ] **Step 3: Add display name for error messages**

```moonbit
///|
/// Get display name for ParamType (for error messages)
pub fn ParamType::display_name(self : ParamType) -> String {
  match self {
    Any => "any"
    ParamBool => "bool"
    ParamNumber => "number"
    ParamString => "string"
    ParamArray(elem) => "array(" + elem.display_name() + ")"
    ParamObject(val_type) => "object(" + val_type.display_name() + ")"
    Nullable(inner) => inner.display_name() + "?"
    OneOf(_) => "oneof"
  }
}
```

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

- [ ] **Step 5: Commit**

```bash
git add funcs.mbt
git commit -m "feat(funcs): add ParamType enum with type checking"
```

---

### Task 2: Add FuncDef struct and FuncDefBuilder

**Files:**
- Modify: `funcs.mbt` (add after ParamType)

- [ ] **Step 1: Add FuncDef struct**

```moonbit
///|
/// Function definition with parameter specifications
pub struct FuncDef {
  name     : String
  params   : Array[ParamType]
  variadic : ParamType?
  func     : (Array[HCLValue]) -> HCLResult[HCLValue]
}
```

- [ ] **Step 2: Add FuncDef::call() with validation**

```moonbit
///|
/// Call function with argument validation
pub fn FuncDef::call(self : FuncDef, args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let params_len = self.params.length()
  let args_len = args.length()

  // Too few args
  if args_len < params_len {
    return Err(
      HCLError::invalid_value(
        self.name + "() expects at least " + params_len.to_string() +
        " argument(s), got " + args_len.to_string(),
      ),
    )
  }

  // Too many args without variadic
  if not(self.variadic.is_some()) && args_len > params_len {
    return Err(
      HCLError::invalid_value(
        self.name + "() expects at most " + params_len.to_string() +
        " argument(s), got " + args_len.to_string(),
      ),
    )
  }

  // Type-check positional args
  for i in 0..<params_len {
    if not(self.params[i].is_satisfied_by(args[i])) {
      return Err(
        HCLError::type_error(
          self.name + "() argument " + (i + 1).to_string() +
          " expects " + self.params[i].display_name() +
          ", got " + args[i].type_name(),
        ),
      )
    }
  }

  // Type-check variadic args
  match self.variadic {
    Some(var_type) =>
      for i in params_len..<args_len {
        if not(var_type.is_satisfied_by(args[i])) {
          return Err(
            HCLError::type_error(
              self.name + "() variadic argument " + (i + 1).to_string() +
              " expects " + var_type.display_name() +
              ", got " + args[i].type_name(),
            ),
          )
        }
      }
    None => ()
  }

  self.func(args)
}
```

- [ ] **Step 3: Add FuncDefBuilder**

```moonbit
///|
/// Builder for FuncDef
pub struct FuncDefBuilder {
  params   : Array[ParamType]
  variadic : ParamType?
} derive(Debug, Eq)

///|
/// Create new FuncDefBuilder
pub fn FuncDefBuilder::new() -> FuncDefBuilder {
  { params: [], variadic: None }
}

///|
/// Add a positional parameter
pub fn FuncDefBuilder::param(
  self : FuncDefBuilder,
  ptype : ParamType,
) -> FuncDefBuilder {
  self.params.push(ptype)
  self
}

///|
/// Set variadic parameter type
pub fn FuncDefBuilder::variadic(
  self : FuncDefBuilder,
  vtype : ParamType,
) -> FuncDefBuilder {
  self.variadic = Some(vtype)
  self
}

///|
/// Build FuncDef with name and function body
pub fn FuncDefBuilder::build(
  self : FuncDefBuilder,
  name : String,
  func : (Array[HCLValue]) -> HCLResult[HCLValue],
) -> FuncDef {
  { name, params: self.params, variadic: self.variadic, func }
}
```

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

- [ ] **Step 5: Commit**

```bash
git add funcs.mbt
git commit -m "feat(funcs): add FuncDef struct with validation and builder"
```

---

### Task 3: Update builtin_functions() to return Map[String, FuncDef]

**Files:**
- Modify: `funcs.mbt` (update `builtin_functions()` signature and body)
- Modify: `eval.mbt` (update ExprFuncCall handler)

- [ ] **Step 1: Update builtin_functions() return type and registrations**

Change return type from `Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]]` to `Map[String, FuncDef]`.

Update all registrations to use FuncDefBuilder pattern. Example for numeric functions:

```moonbit
pub fn builtin_functions() -> Map[String, FuncDef] {
  let funcs = {}

  // Numeric functions
  funcs["abs"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("abs", fn_abs)
  funcs["ceil"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("ceil", fn_ceil)
  funcs["floor"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("floor", fn_floor)
  funcs["log"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .param(ParamNumber)
    .build("log", fn_log)
  funcs["max"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .variadic(ParamNumber)
    .build("max", fn_max)
  funcs["min"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .variadic(ParamNumber)
    .build("min", fn_min)
  funcs["parseint"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamNumber)
    .build("parseint", fn_parseint)
  funcs["pow"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .param(ParamNumber)
    .build("pow", fn_pow)
  funcs["signum"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("signum", fn_signum)

  // Collection functions
  funcs["length"] = FuncDefBuilder::new()
    .param(OneOf([ParamArray(Any), ParamObject(Any), ParamString]))
    .build("length", fn_length)
  funcs["keys"] = FuncDefBuilder::new()
    .param(ParamObject(Any))
    .build("keys", fn_keys)
  funcs["values"] = FuncDefBuilder::new()
    .param(ParamObject(Any))
    .build("values", fn_values)
  funcs["contains"] = FuncDefBuilder::new()
    .param(ParamArray(Any))
    .param(Any)
    .build("contains", fn_contains)
  funcs["flatten"] = FuncDefBuilder::new()
    .param(ParamArray(Any))
    .build("flatten", fn_flatten)
  funcs["merge"] = FuncDefBuilder::new()
    .variadic(ParamObject(Any))
    .build("merge", fn_merge)
  funcs["reverse"] = FuncDefBuilder::new()
    .param(OneOf([ParamArray(Any), ParamString]))
    .build("reverse", fn_reverse)
  funcs["distinct"] = FuncDefBuilder::new()
    .param(ParamArray(Any))
    .build("distinct", fn_distinct)
  funcs["sort"] = FuncDefBuilder::new()
    .param(ParamArray(Any))
    .build("sort", fn_sort)
  funcs["slice"] = FuncDefBuilder::new()
    .param(ParamArray(Any))
    .param(ParamNumber)
    .param(ParamNumber)
    .build("slice", fn_slice)
  funcs["element"] = FuncDefBuilder::new()
    .param(ParamArray(Any))
    .param(ParamNumber)
    .build("element", fn_element)

  // String functions
  funcs["chomp"] = FuncDefBuilder::new()
    .param(ParamString)
    .build("chomp", fn_chomp)
  funcs["indent"] = FuncDefBuilder::new()
    .param(ParamNumber)
    .param(ParamString)
    .build("indent", fn_indent)
  funcs["join"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamArray(ParamString))
    .build("join", fn_join)
  funcs["lower"] = FuncDefBuilder::new()
    .param(ParamString)
    .build("lower", fn_lower)
  funcs["upper"] = FuncDefBuilder::new()
    .param(ParamString)
    .build("upper", fn_upper)
  funcs["replace"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamString)
    .param(ParamString)
    .build("replace", fn_replace)
  funcs["split"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamString)
    .build("split", fn_split)
  funcs["strrev"] = FuncDefBuilder::new()
    .param(ParamString)
    .build("strrev", fn_strrev)
  funcs["substr"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamNumber)
    .param(ParamNumber)
    .build("substr", fn_substr)
  funcs["trim"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamString)
    .build("trim", fn_trim)
  funcs["trimprefix"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamString)
    .build("trimprefix", fn_trimprefix)
  funcs["trimsuffix"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamString)
    .build("trimsuffix", fn_trimsuffix)
  funcs["trimspace"] = FuncDefBuilder::new()
    .param(ParamString)
    .build("trimspace", fn_trimspace)
  funcs["format"] = FuncDefBuilder::new()
    .param(ParamString)
    .variadic(Any)
    .build("format", fn_format)
  funcs["formatlist"] = FuncDefBuilder::new()
    .param(ParamString)
    .param(ParamArray(Any))
    .build("formatlist", fn_formatlist)

  // Type conversion functions
  funcs["tobool"] = FuncDefBuilder::new()
    .param(OneOf([ParamBool, ParamString, ParamNumber]))
    .build("tobool", fn_tobool)
  funcs["tonumber"] = FuncDefBuilder::new()
    .param(OneOf([ParamNumber, ParamString, ParamBool]))
    .build("tonumber", fn_tonumber)
  funcs["tolist"] = FuncDefBuilder::new()
    .param(Any)
    .build("tolist", fn_tolist)
  funcs["tomap"] = FuncDefBuilder::new()
    .param(ParamObject(Any))
    .build("tomap", fn_tomap)
  funcs["toset"] = FuncDefBuilder::new()
    .param(Any)
    .build("toset", fn_toset)
  funcs["tostring"] = FuncDefBuilder::new()
    .param(Any)
    .build("tostring", fn_tostring)

  funcs
}
```

- [ ] **Step 2: Remove check_args/check_min_args calls from individual functions**

Remove `guard check_args(...)` and `guard check_min_args(...)` from all 45 functions since FuncDef::call() now handles validation.

- [ ] **Step 3: Update eval.mbt ExprFuncCall handler**

In `eval.mbt`, change the function call handling from:
```moonbit
match functions.get(fc.name) {
  Some(func) => func(evaluated_args)
  None => Err(HCLError::undefined_function(fc.name))
}
```
To:
```moonbit
match functions.get(fc.name) {
  Some(func_def) => func_def.call(evaluated_args)
  None => Err(HCLError::undefined_function(fc.name))
}
```

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

- [ ] **Step 5: Run moon test**

Run: `moon test`
Expected: All 682 tests pass (no behavior change, just framework validation)

- [ ] **Step 6: Commit**

```bash
git add funcs.mbt eval.mbt
git commit -m "feat(funcs): integrate FuncDef with builtin_functions and eval"
```

---

### Task 4: Add FuncDef tests

**Files:**
- Modify: `funcs_test.mbt` (add new test block)

- [ ] **Step 1: Add ParamType validation tests**

```moonbit
///| =========================================================================
/// FuncDef Parameter Validation Tests

///| =========================================================================

///|
test "ParamType Any accepts all types" {
  let any = ParamType::Any
  assert_true(any.is_satisfied_by(Bool(true, Decor::empty())))
  assert_true(any.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_true(any.is_satisfied_by(String("hi", Decor::empty())))
  assert_true(any.is_satisfied_by(Null(Decor::empty())))
  assert_true(any.is_satisfied_by(Array([], Decor::empty())))
}

///|
test "ParamType Bool rejects non-bool" {
  let pt = ParamType::ParamBool
  assert_true(pt.is_satisfied_by(Bool(true, Decor::empty())))
  assert_false(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_false(pt.is_satisfied_by(String("true", Decor::empty())))
}

///|
test "ParamType Number rejects non-number" {
  let pt = ParamType::ParamNumber
  assert_true(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_false(pt.is_satisfied_by(Bool(true, Decor::empty())))
  assert_false(pt.is_satisfied_by(String("1", Decor::empty())))
}

///|
test "ParamType String rejects non-string" {
  let pt = ParamType::ParamString
  assert_true(pt.is_satisfied_by(String("hi", Decor::empty())))
  assert_false(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
}

///|
test "ParamType Array checks elements" {
  let pt = ParamType::ParamArray(ParamString)
  assert_true(
    pt.is_satisfied_by(
      Array([String("a", Decor::empty()), String("b", Decor::empty())], Decor::empty()),
    ),
  )
  assert_false(
    pt.is_satisfied_by(
      Array([String("a", Decor::empty()), Number(Number::from_int(1), Decor::empty())], Decor::empty()),
    ),
  )
  assert_false(pt.is_satisfied_by(String("not array", Decor::empty())))
}

///|
test "ParamType Nullable accepts null" {
  let pt = ParamType::Nullable(ParamString)
  assert_true(pt.is_satisfied_by(Null(Decor::empty())))
  assert_true(pt.is_satisfied_by(String("hi", Decor::empty())))
  assert_false(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
}

///|
test "ParamType OneOf accepts any matching" {
  let pt = ParamType::OneOf([ParamString, ParamNumber])
  assert_true(pt.is_satisfied_by(String("hi", Decor::empty())))
  assert_true(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_false(pt.is_satisfied_by(Bool(true, Decor::empty())))
}

///|
test "ParamType display_name" {
  assert_true(ParamType::Any.display_name() == "any")
  assert_true(ParamType::ParamBool.display_name() == "bool")
  assert_true(ParamType::ParamNumber.display_name() == "number")
  assert_true(ParamType::ParamString.display_name() == "string")
  assert_true(ParamType::ParamArray(ParamString).display_name() == "array(string)")
  assert_true(ParamType::Nullable(ParamNumber).display_name() == "number?")
}
```

- [ ] **Step 2: Add FuncDef validation tests**

```moonbit
///|
test "FuncDef call validates too few args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .param(ParamNumber)
    .build("add", fn_add_stub)
  match fd.call([Number(Number::from_int(1), Decor::empty())]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef call validates too many args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("abs", fn_abs)
  match fd.call([
    Number(Number::from_int(1), Decor::empty()),
    Number(Number::from_int(2), Decor::empty()),
  ]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef call validates type mismatch" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("abs", fn_abs)
  match fd.call([String("not a number", Decor::empty())]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef call succeeds with valid args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("abs", fn_abs)
  match fd.call([Number(Number::from_int(-5), Decor::empty())]) {
    Ok(v) => assert_true(v == Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "FuncDef variadic accepts extra args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .variadic(ParamNumber)
    .build("max", fn_max)
  match fd.call([
    Number(Number::from_int(1), Decor::empty()),
    Number(Number::from_int(3), Decor::empty()),
    Number(Number::from_int(2), Decor::empty()),
  ]) {
    Ok(v) => assert_true(v == Number(Number::from_int(3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "FuncDef variadic rejects wrong type in extra args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .variadic(ParamNumber)
    .build("max", fn_max)
  match fd.call([
    Number(Number::from_int(1), Decor::empty()),
    String("not number", Decor::empty()),
  ]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef builder factory" {
  let fd = FuncDef::builder()
    .param(ParamString)
    .build("lower", fn_lower)
  assert_true(fd.name == "lower")
  assert_true(fd.params.length() == 1)
}
```

- [ ] **Step 3: Add helper stub for test**

```moonbit
///|
fn fn_add_stub(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  Ok(Number(Number::from_int(0), Decor::empty()))
}
```

- [ ] **Step 4: Add FuncDef::builder() factory method**

In `funcs.mbt`, add:
```moonbit
///|
/// Create a FuncDefBuilder
pub fn FuncDef::builder() -> FuncDefBuilder {
  FuncDefBuilder::new()
}
```

- [ ] **Step 5: Run moon test**

Run: `moon test`
Expected: All tests pass (682 existing + ~12 new)

- [ ] **Step 6: Commit**

```bash
git add funcs.mbt funcs_test.mbt
git commit -m "test(funcs): add FuncDef parameter validation tests"
```

---

### Task 5: Run moon info and final verification

**Files:**
- Modify: generated `.mbti` via `moon info`

- [ ] **Step 1: Run moon info**

Run: `moon info`
Expected: No errors, `.mbti` updated with new public types

- [ ] **Step 2: Run moon fmt**

Run: `moon fmt`
Expected: No changes needed

- [ ] **Step 3: Run full test suite**

Run: `moon test`
Expected: All tests pass

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

- [ ] **Step 5: Update PROGRESS.md**

Update task #13 status to ✅, add details about FuncDef system.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: update PROGRESS.md for func param defs (#13)"
```
