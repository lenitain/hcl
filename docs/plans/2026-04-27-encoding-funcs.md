# EncodingFuncs Implementation Plan (Iteration 5)

> **Goal:** Add 6 encoding/decoding built-in functions: jsondecode, jsonencode, base64decode, base64encode, csvdecode, urlencode

**Architecture:** Extend `funcs.mbt` with new functions following existing FuncDef pattern. Use MoonBit `@json` and `@encoding/base64` stdlib packages.

**Tech Stack:** MoonBit, `@json`, `@encoding/base64`

---

## Files to Modify

| File | Change |
|------|--------|
| `moon.pkg` | Add `@json` and `@encoding/base64` imports |
| `funcs.mbt` | Add 6 function implementations + register in `builtin_functions()` |
| `funcs_test.mbt` | Add ~18 tests (3 per function) |

## Tasks

### Task 1: Add imports to moon.pkg
- [ ] Add `"moonbitlang/core/json" @json` and `"moonbitlang/core/encoding/base64" @encoding/base64` to `moon.pkg` import block

### Task 2: Implement jsondecode/jsonencode
- [ ] `jsondecode(str)` — `@json.parse()` → convert `Json` → `HCLValue`
- [ ] `jsonencode(val)` — convert `HCLValue` → `Json` → `Json::stringify()`

### Task 3: Implement base64decode/base64encode
- [ ] `base64decode(str)` — `@encoding/base64.decode()` Bytes → String
- [ ] `base64encode(str)` — String → Bytes → `@encoding/base64.encode()`

### Task 4: Implement csvdecode
- [ ] Manual CSV parser: split lines, split fields by comma, first row = headers, return `Array[HCLValue]` of objects

### Task 5: Implement urlencode
- [ ] Percent-encoding: iterate chars, encode unreserved chars (RFC 3986)

### Task 6: Register all 6 functions in builtin_functions()
- [ ] Add FuncDef registrations with proper ParamType specs

### Task 7: Write tests
- [ ] jsondecode: valid JSON → HCLValue, nested, error case
- [ ] jsonencode: HCLValue → JSON string, nested, error case
- [ ] base64: encode/decode round-trip, empty, error
- [ ] csvdecode: basic, quoted fields, error
- [ ] urlencode: basic, special chars, empty

### Task 8: Verify
- [ ] `moon check && moon test && moon info && moon fmt`

## Verification
```bash
moon check && moon test && moon info && moon fmt
```
Expected: 0 errors, ~870+ tests passing
