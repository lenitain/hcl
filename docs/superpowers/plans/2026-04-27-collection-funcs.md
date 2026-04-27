# CollectionFuncs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 12 collection/conditional functions for HCL MoonBit library (iteration 3)

**Architecture:** Add function implementations to `funcs.mbt` following existing patterns, register in `builtin_functions()`, add tests to `funcs_test.mbt`

**Tech Stack:** MoonBit, HCL library

---

## Functions to Implement

| # | Function | Signature | Description |
|---|----------|-----------|-------------|
| 1 | `concat` | `variadic array(array) -> array` | Concatenate multiple arrays |
| 2 | `coalesce` | `variadic any -> any` | Return first non-null value |
| 3 | `range` | `(number) -> array` or `(number, number) -> array` | Generate number sequence |
| 4 | `chunklist` | `(array, number) -> array(array)` | Split array into chunks |
| 5 | `lookup` | `(object, string, any?) -> any` | Safe map key access |
| 6 | `zipmap` | `(array(string), array) -> object` | Merge two arrays into map |
| 7 | `transpose` | `(object) -> object` | Transpose map keys/values |
| 8 | `matchkeys` | `(array, array, array) -> array` | Match key patterns |
| 9 | `sum` | `(array(number)) -> number` | Sum numeric array |
| 10 | `alltrue` | `(array(bool)) -> bool` | All values true |
| 11 | `anytrue` | `(array(bool)) -> bool` | Any value true |
| 12 | `one` | `(array(any)) -> any` | Ensure single element |

---

## Task 1: concat, coalesce, range (Simple functions)

**Files:**
- Modify: `/home/pilot/.projects/hcl/funcs.mbt`
- Modify: `/home/pilot/.projects/hcl/funcs_test.mbt`

- [ ] **Step 1: Implement fn_concat**

```moonbit
///|
/// concat(list1, list2, ...) - Concatenate multiple arrays
fn fn_concat(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let result = []
  for arg in args {
    match arg {
      Array(arr, _) => {
        for item in arr {
          result.push(item)
        }
      }
      _ => return Err(HCLError::type_error("concat() requires arrays"))
    }
  }
  Ok(Array(result, Decor::empty()))
}
```

- [ ] **Step 2: Implement fn_coalesce**

```moonbit
///|
/// coalesce(val1, val2, ...) - Return first non-null value
fn fn_coalesce(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  for arg in args {
    match arg {
      Null(_) => continue
      _ => return Ok(arg)
    }
  }
  Ok(Null(Decor::empty()))
}
```

- [ ] **Step 3: Implement fn_range**

```moonbit
///|
/// range(max) or range(start, limit) - Generate number sequence
fn fn_range(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let (start, limit) = match args.length() {
    1 =>
      match args[0] {
        Number(n, _) => (0, n.to_int())
        _ => return Err(HCLError::type_error("range() requires numbers"))
      }
    2 =>
      match (args[0], args[1]) {
        (Number(n1, _), Number(n2, _)) => (n1.to_int(), n2.to_int())
        _ => return Err(HCLError::type_error("range() requires numbers"))
      }
    _ => return Err(HCLError::invalid_value("range() requires 1 or 2 arguments"))
  }
  let result = []
  let mut i = start
  while i < limit {
    result.push(Number(Number::from_int(i), Decor::empty()))
    i = i + 1
  }
  Ok(Array(result, Decor::empty()))
}
```

- [ ] **Step 4: Register functions in builtin_functions()**

Add after existing collection functions:
```moonbit
  funcs["concat"] = FuncDef::builder()
    .variadic(ParamArray(Any))
    .build("concat", fn_concat)
  funcs["coalesce"] = FuncDef::builder()
    .variadic(Any)
    .build("coalesce", fn_coalesce)
  funcs["range"] = FuncDef::builder()
    .variadic(ParamNumber)
    .build("range", fn_range)
```

- [ ] **Step 5: Add tests**

```moonbit
///|
test "concat basic" {
  let funcs = builtin_functions()
  let f = funcs["concat"]
  let arr1 = HCLValue::Array([num(1), num(2)], Decor::empty())
  let arr2 = HCLValue::Array([num(3), num(4)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 4)
      assert_true(arr[0] == num(1))
      assert_true(arr[3] == num(4))
    }
    _ => panic()
  }
}

///|
test "coalesce first non-null" {
  let funcs = builtin_functions()
  let f = funcs["coalesce"]
  match f.call([null(), num(42), str("hello")]) {
    Ok(v) => assert_true(v == num(42))
    _ => panic()
  }
}

///|
test "range single arg" {
  let funcs = builtin_functions()
  let f = funcs["range"]
  match f.call([num(3)]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 3)
      assert_true(arr[0] == num(0))
      assert_true(arr[2] == num(2))
    }
    _ => panic()
  }
}
```

- [ ] **Step 6: Run tests**

Run: `moon test -F "concat" -F "coalesce" -F "range"`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add funcs.mbt funcs_test.mbt
git commit -m "feat: add concat, coalesce, range functions"
```

---

## Task 2: chunklist, lookup, zipmap (Medium complexity)

**Files:**
- Modify: `/home/pilot/.projects/hcl/funcs.mbt`
- Modify: `/home/pilot/.projects/hcl/funcs_test.mbt`

- [ ] **Step 1: Implement fn_chunklist**

```moonbit
///|
/// chunklist(list, size) - Split array into chunks
fn fn_chunklist(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (Array(arr, _), Number(n, _)) => {
      let size = n.to_int()
      if size <= 0 {
        return Err(HCLError::invalid_value("chunklist() size must be positive"))
      }
      let result = []
      let mut chunk = []
      for item in arr {
        chunk.push(item)
        if chunk.length() == size {
          result.push(Array(chunk, Decor::empty()))
          chunk = []
        }
      }
      if chunk.length() > 0 {
        result.push(Array(chunk, Decor::empty()))
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("chunklist() requires (array, number)"))
  }
}
```

- [ ] **Step 2: Implement fn_lookup**

```moonbit
///|
/// lookup(map, key, default?) - Safe map key access
fn fn_lookup(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (Object(o, _), String(key, _)) => {
      for k, v in o {
        if k == key {
          return Ok(v)
        }
      }
      if args.length() == 3 {
        return Ok(args[2])
      }
      Err(HCLError::invalid_value("lookup() key not found: " + key))
    }
    _ => Err(HCLError::type_error("lookup() requires (object, string)"))
  }
}
```

- [ ] **Step 3: Implement fn_zipmap**

```moonbit
///|
/// zipmap(keys, values) - Merge two arrays into map
fn fn_zipmap(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (Array(keys_arr, _), Array(values_arr, _)) => {
      let map : Map[String, HCLValue] = {}
      let len = min(keys_arr.length(), values_arr.length())
      let mut i = 0
      while i < len {
        match keys_arr[i] {
          String(key, _) => {
            map[key] = values_arr[i]
          }
          _ => return Err(HCLError::type_error("zipmap() keys must be strings"))
        }
        i = i + 1
      }
      Ok(Object(map, Decor::empty()))
    }
    _ => Err(HCLError::type_error("zipmap() requires (array, array)"))
  }
}
```

- [ ] **Step 4: Register functions**

```moonbit
  funcs["chunklist"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamNumber)
    .build("chunklist", fn_chunklist)
  funcs["lookup"] = FuncDef::builder()
    .param(ParamObject(Any))
    .param(ParamString)
    .variadic(Any)
    .build("lookup", fn_lookup)
  funcs["zipmap"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("zipmap", fn_zipmap)
```

- [ ] **Step 5: Add tests**

```moonbit
///|
test "chunklist basic" {
  let funcs = builtin_functions()
  let f = funcs["chunklist"]
  let arr = HCLValue::Array([num(1), num(2), num(3), num(4), num(5)], Decor::empty())
  match f.call([arr, num(2)]) {
    Ok(HCLValue::Array(chunks, _)) => {
      assert_eq(chunks.length(), 3)
    }
    _ => panic()
  }
}

///|
test "lookup found" {
  let funcs = builtin_functions()
  let f = funcs["lookup"]
  let obj = HCLValue::Object({"a": num(1), "b": num(2)}, Decor::empty())
  match f.call([obj, str("b")]) {
    Ok(v) => assert_true(v == num(2))
    _ => panic()
  }
}

///|
test "zipmap basic" {
  let funcs = builtin_functions()
  let f = funcs["zipmap"]
  let keys = HCLValue::Array([str("a"), str("b")], Decor::empty())
  let values = HCLValue::Array([num(1), num(2)], Decor::empty())
  match f.call([keys, values]) {
    Ok(HCLValue::Object(m, _)) => {
      assert_true(m["a"] == num(1))
      assert_true(m["b"] == num(2))
    }
    _ => panic()
  }
}
```

- [ ] **Step 6: Run tests**

Run: `moon test -F "chunklist" -F "lookup" -F "zipmap"`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add funcs.mbt funcs_test.mbt
git commit -m "feat: add chunklist, lookup, zipmap functions"
```

---

## Task 3: transpose, matchkeys (Map operations)

**Files:**
- Modify: `/home/pilot/.projects/hcl/funcs.mbt`
- Modify: `/home/pilot/.projects/hcl/funcs_test.mbt`

- [ ] **Step 1: Implement fn_transpose**

```moonbit
///|
/// transpose(map) - Transpose map keys/values
fn fn_transpose(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Object(o, _) => {
      let result : Map[String, HCLValue] = {}
      for k, v in o {
        match v {
          Array(arr, _) => {
            for item in arr {
              match item {
                String(s, _) => {
                  if result.contains_key(s) {
                    match result[s] {
                      Array(existing, _) => {
                        existing.push(String(k, Decor::empty()))
                        result[s] = Array(existing, Decor::empty())
                      }
                      _ => return Err(HCLError::invalid_value("transpose() internal error"))
                    }
                  } else {
                    result[s] = Array([String(k, Decor::empty())], Decor::empty())
                  }
                }
                _ => return Err(HCLError::type_error("transpose() values must be arrays of strings"))
              }
            }
          }
          _ => return Err(HCLError::type_error("transpose() values must be arrays"))
        }
      }
      Ok(Object(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("transpose() requires an object"))
  }
}
```

- [ ] **Step 2: Implement fn_matchkeys**

```moonbit
///|
/// matchkeys(search, keys, values) - Match key patterns
fn fn_matchkeys(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1], args[2]) {
    (Array(search_arr, _), Array(keys_arr, _), Array(values_arr, _)) => {
      let result = []
      for search_item in search_arr {
        let mut i = 0
        while i < keys_arr.length() && i < values_arr.length() {
          if keys_arr[i] == search_item {
            result.push(values_arr[i])
            break
          }
          i = i + 1
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("matchkeys() requires (array, array, array)"))
  }
}
```

- [ ] **Step 3: Register functions**

```moonbit
  funcs["transpose"] = FuncDef::builder()
    .param(ParamObject(Any))
    .build("transpose", fn_transpose)
  funcs["matchkeys"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("matchkeys", fn_matchkeys)
```

- [ ] **Step 4: Add tests**

```moonbit
///|
test "transpose basic" {
  let funcs = builtin_functions()
  let f = funcs["transpose"]
  let obj = HCLValue::Object({
    "a": HCLValue::Array([str("x"), str("y")], Decor::empty()),
    "b": HCLValue::Array([str("y"), str("z")], Decor::empty())
  }, Decor::empty())
  match f.call([obj]) {
    Ok(HCLValue::Object(m, _)) => {
      assert_true(m.contains_key("x"))
      assert_true(m.contains_key("y"))
      assert_true(m.contains_key("z"))
    }
    _ => panic()
  }
}

///|
test "matchkeys basic" {
  let funcs = builtin_functions()
  let f = funcs["matchkeys"]
  let search = HCLValue::Array([str("a"), str("c")], Decor::empty())
  let keys = HCLValue::Array([str("a"), str("b"), str("c")], Decor::empty())
  let values = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  match f.call([search, keys, values]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      assert_true(arr[0] == num(1))
      assert_true(arr[1] == num(3))
    }
    _ => panic()
  }
}
```

- [ ] **Step 5: Run tests**

Run: `moon test -F "transpose" -F "matchkeys"`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add funcs.mbt funcs_test.mbt
git commit -m "feat: add transpose, matchkeys functions"
```

---

## Task 4: sum, alltrue, anytrue, one (Aggregation functions)

**Files:**
- Modify: `/home/pilot/.projects/hcl/funcs.mbt`
- Modify: `/home/pilot/.projects/hcl/funcs_test.mbt`

- [ ] **Step 1: Implement fn_sum**

```moonbit
///|
/// sum(list) - Sum numeric array
fn fn_sum(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      let mut total = 0.0
      for item in arr {
        match item {
          Number(n, _) => total = total + n.as_float()
          _ => return Err(HCLError::type_error("sum() requires numeric array"))
        }
      }
      Ok(Number(Number::from_finite_f64(total), Decor::empty()))
    }
    _ => Err(HCLError::type_error("sum() requires an array"))
  }
}
```

- [ ] **Step 2: Implement fn_alltrue**

```moonbit
///|
/// alltrue(list) - All values true
fn fn_alltrue(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      for item in arr {
        match item {
          Bool(false, _) => return Ok(Bool(false, Decor::empty()))
          Bool(true, _) => continue
          _ => return Err(HCLError::type_error("alltrue() requires bool array"))
        }
      }
      Ok(Bool(true, Decor::empty()))
    }
    _ => Err(HCLError::type_error("alltrue() requires an array"))
  }
}
```

- [ ] **Step 3: Implement fn_anytrue**

```moonbit
///|
/// anytrue(list) - Any value true
fn fn_anytrue(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      for item in arr {
        match item {
          Bool(true, _) => return Ok(Bool(true, Decor::empty()))
          Bool(false, _) => continue
          _ => return Err(HCLError::type_error("anytrue() requires bool array"))
        }
      }
      Ok(Bool(false, Decor::empty()))
    }
    _ => Err(HCLError::type_error("anytrue() requires an array"))
  }
}
```

- [ ] **Step 4: Implement fn_one**

```moonbit
///|
/// one(list) - Ensure single element and return it
fn fn_one(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      if arr.length() == 1 {
        Ok(arr[0])
      } else if arr.length() == 0 {
        Err(HCLError::invalid_value("one() requires exactly one element, got 0"))
      } else {
        Err(
          HCLError::invalid_value(
            "one() requires exactly one element, got " + arr.length().to_string(),
          ),
        )
      }
    }
    _ => Err(HCLError::type_error("one() requires an array"))
  }
}
```

- [ ] **Step 5: Register functions**

```moonbit
  funcs["sum"] = FuncDef::builder()
    .param(ParamArray(ParamNumber))
    .build("sum", fn_sum)
  funcs["alltrue"] = FuncDef::builder()
    .param(ParamArray(ParamBool))
    .build("alltrue", fn_alltrue)
  funcs["anytrue"] = FuncDef::builder()
    .param(ParamArray(ParamBool))
    .build("anytrue", fn_anytrue)
  funcs["one"] = FuncDef::builder()
    .param(ParamArray(Any))
    .build("one", fn_one)
```

- [ ] **Step 6: Add tests**

```moonbit
///|
test "sum basic" {
  let funcs = builtin_functions()
  let f = funcs["sum"]
  let arr = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == num(6))
    _ => panic()
  }
}

///|
test "alltrue all true" {
  let funcs = builtin_functions()
  let f = funcs["alltrue"]
  let arr = HCLValue::Array([bool_true(), bool_true()], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_true())
    _ => panic()
  }
}

///|
test "anytrue mixed" {
  let funcs = builtin_functions()
  let f = funcs["anytrue"]
  let arr = HCLValue::Array([bool_false(), bool_true()], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_true())
    _ => panic()
  }
}

///|
test "one single element" {
  let funcs = builtin_functions()
  let f = funcs["one"]
  let arr = HCLValue::Array([num(42)], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == num(42))
    _ => panic()
  }
}
```

- [ ] **Step 7: Run tests**

Run: `moon test -F "sum" -F "alltrue" -F "anytrue" -F "one"`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add funcs.mbt funcs_test.mbt
git commit -m "feat: add sum, alltrue, anytrue, one functions"
```

---

## Task 5: Integration and final verification

**Files:**
- Modify: `/home/pilot/.projects/hcl/PROGRESS.md`

- [ ] **Step 1: Run all tests**

Run: `moon test`
Expected: All tests pass (should be ~840+ tests)

- [ ] **Step 2: Run moon check**

Run: `moon check`
Expected: 0 errors

- [ ] **Step 3: Run moon info**

Run: `moon info`
Expected: `.mbti` interface updated

- [ ] **Step 4: Run moon fmt**

Run: `moon fmt`
Expected: All files formatted

- [ ] **Step 5: Update PROGRESS.md**

Update the following sections:
1. Change "当前状态" to "集合/条件函数补齐 — 迭代 3 完成 ✅"
2. Update "当前分支" to `lenitain/feat/collection-funcs`
3. Add new section documenting implemented functions
4. Update test count
5. Update roadmap to mark iteration 3 as complete

- [ ] **Step 6: Commit progress**

```bash
git add PROGRESS.md
git commit -m "docs: update progress for iteration 3 (collection funcs)"
```

---

## Summary

| Task | Functions | Tests |
|------|-----------|-------|
| 1 | concat, coalesce, range | 3 |
| 2 | chunklist, lookup, zipmap | 3 |
| 3 | transpose, matchkeys | 2 |
| 4 | sum, alltrue, anytrue, one | 4 |
| 5 | Integration | - |
| **Total** | **12 functions** | **12+ tests** |

Expected final test count: ~813+ (801 current + 12 new)
