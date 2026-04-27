# ParseErrorRecovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade parser from single-error to multi-error accumulation mode, so users see all errors at once.

**Architecture:** Add `MultipleErrors` variant to `HCLError`, introduce `parse_with_recovery` that collects errors while continuing to parse. Keep `parse()` backward-compatible.

**Tech Stack:** MoonBit

---

## File Map

| File | Change |
|------|--------|
| `error.mbt` | Add `MultipleErrors(Array[HCLError])` variant + factory method |
| `parser.mbt` | Add `parse_body_with_recovery`, `parse_with_recovery`; modify error recovery logic |
| `recovery_test.mbt` | New test file for multi-error scenarios |

---

### Task 1: Add MultipleErrors to HCLError

**Files:**
- Modify: `error.mbt`

- [ ] **Step 1: Add MultipleErrors variant**

```moonbit
pub(all) enum HCLError {
  // ... existing variants ...
  MultipleErrors(Array[HCLError])
} derive(Debug, Eq)
```

- [ ] **Step 2: Add factory method**

```moonbit
pub fn HCLError::multi(errors : Array[HCLError]) -> HCLError {
  MultipleErrors(errors)
}
```

- [ ] **Step 3: Add message handler**

Add to `HCLError::message` match:
```moonbit
MultipleErrors(errors) =>
  errors.map(fn(e) { e.message() }).join("\n")
```

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

---

### Task 2: Implement parse_body_with_recovery

**Files:**
- Modify: `parser.mbt`

- [ ] **Step 1: Add skip_to_next_item helper**

```moonbit
fn Parser::skip_to_next_item(self : Parser) -> HCLResult[Parser] {
  let mut parser = self
  loop {
    match parser.current {
      Newline | EOF => break
      _ =>
        match parser.advance() {
          Ok(p) => parser = p
          Err(e) => return Err(e)
        }
    }
  }
  // Skip the newline too
  match parser.current {
    Newline =>
      match parser.advance() {
        Ok(p) => Ok(p)
        Err(e) => Err(e)
      }
    _ => Ok(parser)
  }
}
```

- [ ] **Step 2: Add parse_body_with_recovery**

```moonbit
pub fn Parser::parse_body_with_recovery(self : Parser) -> (HCLResult[Body], Array[HCLError]) {
  match self.skip_newlines() {
    Ok(start_parser) => {
      let (start_line, start_col, start_offset) = start_parser.current_location()
      let items = []
      let errors : Array[HCLError] = []
      let mut parser = start_parser

      while !parser.check(EOF) {
        match parser.current {
          Ident(_) =>
            if parser.check(Equals) || parser.peek == Equals {
              match parser.parse_attr() {
                Ok((attr, new_parser)) => {
                  items.push(Attribute(attr))
                  parser = new_parser
                }
                Err(e) => {
                  errors.push(e)
                  match parser.skip_to_next_item() {
                    Ok(p) => parser = p
                    Err(e2) => {
                      errors.push(e2)
                      break
                    }
                  }
                }
              }
            } else {
              match parser.parse_block() {
                Ok((block, new_parser)) => {
                  items.push(Block(block))
                  parser = new_parser
                }
                Err(e) => {
                  errors.push(e)
                  match parser.skip_to_next_item() {
                    Ok(p) => parser = p
                    Err(e2) => {
                      errors.push(e2)
                      break
                    }
                  }
                }
              }
            }
          Newline =>
            match parser.advance() {
              Ok(p) => parser = p
              Err(e) => {
                errors.push(e)
                break
              }
            }
          EOF => break
          _ => {
            let (line, col, offset) = parser.lexer.location()
            errors.push(
              HCLError::parse_error_with_context(
                "Unexpected token: " + token_to_string(parser.current),
                line, col, offset,
                parser.lexer.get_line(line),
              ),
            )
            match parser.skip_to_next_item() {
              Ok(p) => parser = p
              Err(e2) => {
                errors.push(e2)
                break
              }
            }
          }
        }
        match parser.skip_newlines() {
          Ok(p) => parser = p
          Err(e) => {
            errors.push(e)
            break
          }
        }
      }

      if errors.length() == 0 {
        let (end_line, end_col, end_offset) = parser.current_location()
        let span = Span::new(start_line, start_col, start_offset, end_line, end_col, end_offset)
        (Ok(Body::from_items(items).set_span(span)), errors)
      } else if items.length() > 0 {
        let (end_line, end_col, end_offset) = parser.current_location()
        let span = Span::new(start_line, start_col, start_offset, end_line, end_col, end_offset)
        (Ok(Body::from_items(items).set_span(span)), errors)
      } else {
        (Err(errors[0]), errors)
      }
    }
    Err(e) => (Err(e), [e])
  }
}
```

- [ ] **Step 3: Add parse_with_recovery public API**

```moonbit
pub fn parse_with_recovery(input : String) -> (HCLResult[Body], Array[HCLError]) {
  match Lexer::validate_input(input) {
    Ok(_) =>
      match Parser::new(input) {
        Ok(parser) => parser.parse_body_with_recovery()
        Err(e) => (Err(e), [e])
      }
    Err(e) => (Err(e), [e])
  }
}
```

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

---

### Task 3: Write tests

**Files:**
- Create: `recovery_test.mbt`

- [ ] **Step 1: Write multi-error tests**

```moonbit
///|
/// Parse Error Recovery Tests

test "recovery: multiple syntax errors" {
  let input = "a = 1\nb = \nc = 3\n"
  let (result, errors) = parse_with_recovery(input)
  // b = has no value, should produce error
  assert_eq(errors.length() > 0, true)
  // But a=1 and c=3 should still parse
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 2) // a and c
    }
    Err(_) => fail("expected partial body")
  }
}

test "recovery: unexpected token mid-file" {
  let input = "a = 1\n???\nb = 2\n"
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length() > 0, true)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 2) // a and b
    }
    Err(_) => fail("expected partial body")
  }
}

test "recovery: block with bad body" {
  let input = "resource \"x\" \"y\" {\n  bad\nc = 1\n}\n"
  let (result, errors) = parse_with_recovery(input)
  // Should have at least one error from inside block
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length() > 0, true)
    }
    Err(_) => fail("expected partial body")
  }
}

test "recovery: clean input produces no errors" {
  let input = "a = 1\nb = 2\n"
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length(), 0)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 2)
    }
    Err(_) => fail("expected success")
  }
}

test "recovery: empty input" {
  let input = ""
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length(), 0)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 0)
    }
    Err(_) => fail("expected success")
  }
}

test "recovery: only newlines" {
  let input = "\n\n\n"
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length(), 0)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 0)
    }
    Err(_) => fail("expected success")
  }
}

test "recovery: error on first line" {
  let input = "= bad\na = 1\n"
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length() > 0, true)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1) // a = 1
    }
    Err(_) => fail("expected partial body with a=1")
  }
}

test "recovery: error on last line" {
  let input = "a = 1\nb = "
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length() > 0, true)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1) // a = 1
    }
    Err(_) => fail("expected partial body with a=1")
  }
}

test "recovery: consecutive errors" {
  let input = "a = \nb = \nc = 3\n"
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length() >= 2, true)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1) // c = 3
    }
    Err(_) => fail("expected partial body with c=3")
  }
}

test "recovery: multiple errors joined in multi-error" {
  let errors = [
    HCLError::parse_error("err1", 1, 1, 0),
    HCLError::parse_error("err2", 2, 1, 5),
  ]
  let multi = HCLError::multi(errors)
  let msg = multi.message()
  assert_eq(msg.contains("err1"), true)
  assert_eq(msg.contains("err2"), true)
}
```

- [ ] **Step 2: Run tests**

Run: `moon test`
Expected: All tests pass including new recovery tests

- [ ] **Step 3: Run full verification**

Run: `moon check && moon test && moon info && moon fmt`
Expected: 0 errors, all tests pass

---

### Task 4: Update PROGRESS.md

- [ ] **Step 1: Update PROGRESS.md with completion status**

Update the iteration 1 row and test counts.
