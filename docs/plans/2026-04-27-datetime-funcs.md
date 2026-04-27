# DateTimeFuncs Implementation Plan

> **For agentic workers:** Use subagent-driven-development to implement task-by-task.

**Goal:** Implement HCL date/time functions: `formatdate`, `timeadd`, `timecmp`.

**Architecture:** Use `@time` package (moonbitlang/x/time) for date parsing/manipulation. RFC3339 timestamps parsed to `PlainDateTime`, manipulated, then serialized back. Custom `formatdate` implementation for Go-style reference date formatting.

**Tech Stack:** MoonBit, `@time` (PlainDateTime, Duration, Period), `@encoding/utf8`

---

## Scope

| Function | Signature | Status |
|----------|-----------|--------|
| `formatdate(format, timestamp)` | `(string, string) -> string` | Implement |
| `timeadd(timestamp, duration)` | `(string, string) -> string` | Implement |
| `timecmp(t1, t2)` | `(string, string) -> number` | Implement |
| `timestamp()` | `() -> string` | Skip — MoonBit has no public system clock API |

## File Structure

| File | Change |
|------|--------|
| `funcs.mbt` | Add 3 function implementations + 3 FuncDef registrations |
| `funcs_test.mbt` | Add 12+ tests |
| `moon.pkg` | Add `"moonbitlang/x/time" @time` import |

## Task 1: Add @time dependency

- [ ] **Step 1:** Add `"moonbitlang/x/time" @time` to `moon.pkg`
- [ ] **Step 2:** Run `moon check` to verify dependency resolves

## Task 2: Implement RFC3339 parsing helper

- [ ] **Step 1:** Write `parse_rfc3339(s: String) -> HCLResult[PlainDateTime]` helper in `funcs.mbt`
  - Parse `2006-01-02T15:04:05Z` and `2006-01-02T15:04:05+07:00` / `-07:00` formats
  - Strip timezone suffix, parse datetime part with `PlainDateTime::from_string`
  - Return parsed datetime (ignore offset for now — treat as UTC)
- [ ] **Step 2:** Write `format_rfc3339(dt: PlainDateTime) -> String` helper
  - Format as `YYYY-MM-DDThh:mm:ssZ` (always UTC)

## Task 3: Implement `formatdate`

- [ ] **Step 1:** Write failing tests in `funcs_test.mbt`:
  - `formatdate("YYYY-MM-DD", "2006-01-02T15:04:05Z")` → `"2006-01-02"`
  - `formatdate("hh:mm:ss", "2006-01-02T15:04:05Z")` → `"15:04:05"`
  - `formatdate("DD/MM/YYYY", "2006-01-02T15:04:05Z")` → `"02/01/2006"`
  - Error: non-string args
- [ ] **Step 2:** Implement `fn_formatdate`:
  - Parse timestamp with `parse_rfc3339`
  - Tokenize format string for Go reference date tokens:
    - `YYYY` → 4-digit year, `YY` → 2-digit year
    - `MM` → 2-digit month, `M` → 1-digit month (zero-padded)
    - `DD` → 2-digit day, `D` → 1-digit day
    - `hh` → 2-digit hour (24h), `h` → 1-digit hour
    - `mm` → 2-digit minute, `m` → 1-digit minute
    - `ss` → 2-digit second, `s` → 1-digit second
    - `Z` → timezone suffix (emit `Z` for UTC)
    - Literal text in single/double quotes
  - Replace tokens with datetime components
- [ ] **Step 3:** Register in `builtin_functions()`: `FuncDef::builder().param(ParamString).param(ParamString).build("formatdate", fn_formatdate)`
- [ ] **Step 4:** Run tests, verify pass

## Task 4: Implement `timeadd`

- [ ] **Step 1:** Write failing tests:
  - `timeadd("2006-01-02T15:04:05Z", "1h")` → `"2006-01-02T16:04:05Z"`
  - `timeadd("2006-01-02T15:04:05Z", "1h30m")` → `"2006-01-02T16:34:05Z"`
  - `timeadd("2006-01-02T15:04:05Z", "24h")` → `"2006-01-03T15:04:05Z"`
  - `timeadd("2006-01-02T15:04:05Z", "-1h")` → `"2006-01-02T14:04:05Z"`
  - Error: invalid timestamp
- [ ] **Step 2:** Implement `fn_timeadd`:
  - Parse timestamp with `parse_rfc3339`
  - Parse duration: convert HCL duration string (e.g. `1h30m`, `5s`) to ISO 8601 `PT1H30M` format
  - Create `Duration::from_string(iso_duration)`
  - Call `PlainDateTime::add_duration(duration)`
  - Format result with `format_rfc3339`
- [ ] **Step 3:** Register: `FuncDef::builder().param(ParamString).param(ParamString).build("timeadd", fn_timeadd)`
- [ ] **Step 4:** Run tests

## Task 5: Implement `timecmp`

- [ ] **Step 1:** Write failing tests:
  - `timecmp("2006-01-02T15:04:05Z", "2006-01-02T15:04:05Z")` → `0`
  - `timecmp("2006-01-02T15:04:05Z", "2006-01-02T16:04:05Z")` → `-1`
  - `timecmp("2006-01-02T16:04:05Z", "2006-01-02T15:04:05Z")` → `1`
  - Error: non-string args
- [ ] **Step 2:** Implement `fn_timecmp`:
  - Parse both timestamps with `parse_rfc3339`
  - Convert to unix seconds via `PlainDateTime::to_unix_second`
  - Compare: return Int(-1), Int(0), or Int(1)
- [ ] **Step 3:** Register: `FuncDef::builder().param(ParamString).param(ParamString).build("timecmp", fn_timecmp)`
- [ ] **Step 4:** Run tests

## Task 6: Verify & update PROGRESS.md

- [ ] **Step 1:** Run `moon check && moon test && moon info && moon fmt`
- [ ] **Step 2:** Confirm all tests pass, note count
- [ ] **Step 3:** Update PROGRESS.md with iteration 7 results
- [ ] **Step 4:** Commit

## HCL Duration Format Reference

HCL uses simplified duration strings (not full ISO 8601):
- `1h` = 1 hour
- `5m` = 5 minutes  
- `30s` = 30 seconds
- `1h30m` = 1 hour 30 minutes
- `-5h` = negative 5 hours
- Combinations: `1h30m5s`

Conversion to ISO 8601: prepend `PT`, uppercase units → `PT1H30M5S`

## HCL formatdate Token Reference

Based on Go reference time: `Mon Jan 2 15:04:05 MST 2006`

| Token | Meaning | Example |
|-------|---------|---------|
| `YYYY` | 4-digit year | 2006 |
| `YY` | 2-digit year | 06 |
| `MM` | Month (01-12) | 01 |
| `DD` | Day (01-31) | 02 |
| `hh` | Hour (00-23) | 15 |
| `mm` | Minute (00-59) | 04 |
| `ss` | Second (00-59) | 05 |
| `Z` | UTC suffix | Z |
| Text in quotes | Literal | any |
