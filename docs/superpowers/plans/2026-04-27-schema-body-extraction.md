# Schema Body Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement schema-driven body extraction that can parse HCL Body into structured data based on a schema definition, similar to hcl-rs's hcldec functionality.

**Architecture:** Extend existing schema system with BodySchema types that can extract attributes and blocks from Body, returning structured ExtractedBody with validation.

**Tech Stack:** MoonBit, existing HCL parser and schema system

---

## Context

Current schema system (`schema.mbt`) only validates `HCLValue` (after body→value conversion). Need to add direct Body extraction that:
1. Preserves block structure (type_name + labels + nested body)
2. Validates attribute types and required fields
3. Validates block occurrence (required/optional, max items)
4. Returns structured result for easy access

## Design Decisions

### Option A: Extend existing TypeSchema
- Add `BodySchema` variant to `TypeSchema`
- Problem: TypeSchema is for HCLValue, not Body

### Option B: New BodySchema type (chosen)
- Separate `BodySchema` type for body structure
- `extract_body(body, schema) -> Result[ExtractedBody, errors]`
- Clean separation of concerns

### Option C: Go-style hcldec spec
- Complex spec types (AttrSpec, BlockSpec, etc.)
- Over-engineered for MoonBit context

**Chosen: Option B** - Simple, focused, follows existing patterns.

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `schema.mbt` | Modify | Add BodySchema types and extract functions |
| `schema_test.mbt` | Modify | Add extraction tests |
| `de.mbt` | Modify | Add `from_hcl_with_body_schema` API |
| `body.mbt` | No change | Use existing Body API |

## Types to Add

```moonbit
// Schema for HCL Body structure
pub struct BodySchema {
  attrs : Map[String, AttrSchema]      // Expected attributes
  blocks : Map[String, BlockSchema]    // Expected block types
  extra_attrs : Bool                   // Allow undeclared attributes
  extra_blocks : Bool                  // Allow undeclared blocks
}

// Schema for an attribute
pub struct AttrSchema {
  required : Bool
  type_schema : TypeSchema
}

// Schema for a block type
pub struct BlockSchema {
  required : Bool                      // At least one required?
  max_items : Int?                     // Max occurrences (None = unlimited)
  labels : Array[LabelSchema]          // Label validation
  body : BodySchema                    // Nested body schema
}

// Schema for block labels
pub struct LabelSchema {
  required : Bool
}

// Extraction result
pub struct ExtractedBody {
  attrs : Map[String, HCLValue]
  blocks : Map[String, Array[ExtractedBlock]]
}

pub struct ExtractedBlock {
  labels : Array[String]
  body : ExtractedBody
}
```

## Tasks

### Task 1: Add BodySchema types to schema.mbt

**Files:**
- Modify: `schema.mbt`

- [ ] **Step 1: Add BodySchema struct**

```moonbit
pub struct BodySchema {
  attrs : Map[String, AttrSchema]
  blocks : Map[String, BlockSchema]
  extra_attrs : Bool
  extra_blocks : Bool
} derive(Debug, Eq)
```

- [ ] **Step 2: Add AttrSchema struct**

```moonbit
pub struct AttrSchema {
  required : Bool
  type_schema : TypeSchema
} derive(Debug, Eq)
```

- [ ] **Step 3: Add BlockSchema struct**

```moonbit
pub struct BlockSchema {
  required : Bool
  max_items : Int?
  labels : Array[LabelSchema]
  body : BodySchema
} derive(Debug, Eq)
```

- [ ] **Step 4: Add LabelSchema struct**

```moonbit
pub struct LabelSchema {
  required : Bool
} derive(Debug, Eq)
```

- [ ] **Step 5: Add constructor functions**

```moonbit
pub fn BodySchema::new() -> BodySchema
pub fn BodySchema::with_attrs(self, attrs) -> BodySchema
pub fn BodySchema::with_blocks(self, blocks) -> BodySchema
pub fn AttrSchema::required(type_schema) -> AttrSchema
pub fn AttrSchema::optional(type_schema) -> AttrSchema
pub fn BlockSchema::new(body) -> BlockSchema
pub fn BlockSchema::mark_required(self) -> BlockSchema
pub fn BlockSchema::with_max_items(self, max) -> BlockSchema
pub fn LabelSchema::required() -> LabelSchema
pub fn LabelSchema::optional() -> LabelSchema
```

- [ ] **Step 6: Run moon check**

Run: `moon check`
Expected: 0 errors

### Task 2: Add ExtractedBody types

**Files:**
- Modify: `schema.mbt`

- [ ] **Step 1: Add ExtractedBody struct**

```moonbit
pub struct ExtractedBody {
  attrs : Map[String, HCLValue]
  blocks : Map[String, Array[ExtractedBlock]]
} derive(Debug, Eq)
```

- [ ] **Step 2: Add ExtractedBlock struct**

```moonbit
pub struct ExtractedBlock {
  labels : Array[String]
  body : ExtractedBody
} derive(Debug, Eq)
```

- [ ] **Step 3: Add accessor methods**

```moonbit
pub fn ExtractedBody::get_attr(self, key) -> HCLValue?
pub fn ExtractedBody::get_blocks(self, type_name) -> Array[ExtractedBlock]
pub fn ExtractedBody::get_block(self, type_name) -> ExtractedBlock?
pub fn ExtractedBlock::get_label(self, index) -> String?
```

- [ ] **Step 4: Run moon check**

Run: `moon check`
Expected: 0 errors

### Task 3: Implement extract_body function

**Files:**
- Modify: `schema.mbt`

- [ ] **Step 1: Write failing test**

Add to `schema_test.mbt`:
```moonbit
test "extract_body with simple attrs" {
  let body = parse("name = \"test\"\ncount = 42").unwrap()
  let schema = BodySchema::new()
    .with_attrs({
      "name": AttrSchema::required(TypeSchema::string()),
      "count": AttrSchema::required(TypeSchema::int()),
    })
  let result = extract_body(body, schema)
  // Should succeed
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test -F "extract_body with simple attrs"`
Expected: FAIL (function not found)

- [ ] **Step 3: Implement extract_body**

```moonbit
pub fn extract_body(body : Body, schema : BodySchema) -> Result[ExtractedBody, Array[HCLError]] {
  let errors = []
  let attrs = {}
  let blocks = {}
  
  // Extract attributes
  for item in body.get_items() {
    match item {
      Attribute(attr) => {
        let key = attr.get_key()
        match schema.attrs[key] {
          Some(attr_schema) => {
            let value = expr_to_hcl_value(attr.get_value())
            let validation_errors = validate(value, attr_schema.type_schema)
            errors.push_all(validation_errors)
            attrs[key] = value
          }
          None => {
            if not(schema.extra_attrs) {
              errors.push(HCLError::validation_error("$." + key, "unexpected attribute"))
            }
            attrs[key] = expr_to_hcl_value(attr.get_value())
          }
        }
      }
      Block(block) => {
        // Handle blocks
      }
    }
  }
  
  // Check required attributes
  for key, attr_schema in schema.attrs {
    if attr_schema.required and attrs[key] is None {
      errors.push(HCLError::validation_error("$." + key, "required attribute missing"))
    }
  }
  
  if errors.is_empty() {
    Ok({ attrs, blocks })
  } else {
    Err(errors)
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test -F "extract_body with simple attrs"`
Expected: PASS

- [ ] **Step 5: Run moon check**

Run: `moon check`
Expected: 0 errors

### Task 4: Implement block extraction

**Files:**
- Modify: `schema.mbt`

- [ ] **Step 1: Write failing test**

```moonbit
test "extract_body with blocks" {
  let body = parse("server \"web\" {\n  port = 8080\n}\nserver \"api\" {\n  port = 3000\n}").unwrap()
  let schema = BodySchema::new()
    .with_blocks({
      "server": BlockSchema::new(
        BodySchema::new().with_attrs({
          "port": AttrSchema::required(TypeSchema::int()),
        })
      ).with_max_items(2)
    })
  let result = extract_body(body, schema)
  // Should extract two server blocks
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test -F "extract_body with blocks"`
Expected: FAIL

- [ ] **Step 3: Implement block extraction in extract_body**

Extend extract_body to handle Block items:
- Match block type_name against schema.blocks
- Validate labels
- Recursively extract nested body
- Check max_items constraint

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test -F "extract_body with blocks"`
Expected: PASS

- [ ] **Step 5: Run moon check**

Run: `moon check`
Expected: 0 errors

### Task 5: Add from_hcl_with_body_schema API

**Files:**
- Modify: `de.mbt`

- [ ] **Step 1: Write failing test**

```moonbit
test "from_hcl_with_body_schema" {
  let input = "name = \"test\"\nserver {\n  port = 8080\n}"
  let schema = BodySchema::new()
    .with_attrs({ "name": AttrSchema::required(TypeSchema::string()) })
    .with_blocks({ "server": BlockSchema::new(...) })
  let result = from_hcl_with_body_schema(input, schema)
  // Should succeed
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test -F "from_hcl_with_body_schema"`
Expected: FAIL (function not found)

- [ ] **Step 3: Implement from_hcl_with_body_schema**

```moonbit
pub fn from_hcl_with_body_schema(
  input : String,
  schema : BodySchema,
) -> Result[ExtractedBody, Array[HCLError]] {
  match parse(input) {
    Ok(body) => extract_body(body, schema)
    Err(e) => Err([e])
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test -F "from_hcl_with_body_schema"`
Expected: PASS

- [ ] **Step 5: Run moon check**

Run: `moon check`
Expected: 0 errors

### Task 6: Comprehensive tests

**Files:**
- Modify: `schema_test.mbt`

- [ ] **Step 1: Add test for required attribute missing**

```moonbit
test "extract_body missing required attr" {
  // Should return error
}
```

- [ ] **Step 2: Add test for unexpected attribute**

```moonbit
test "extract_body extra_attrs false" {
  // Should reject extra attrs
}
```

- [ ] **Step 3: Add test for nested blocks**

```moonbit
test "extract_body nested blocks" {
  // server { location { path = "/" } }
}
```

- [ ] **Step 4: Add test for max_items constraint**

```moonbit
test "extract_body block max_items exceeded" {
  // Should return error
}
```

- [ ] **Step 5: Add test for optional attributes**

```moonbit
test "extract_body optional attr" {
  // Missing optional attr should be ok
}
```

- [ ] **Step 6: Run all schema tests**

Run: `moon test -F "schema"`
Expected: All tests pass

### Task 7: Run full test suite and update PROGRESS.md

- [ ] **Step 1: Run moon check**

Run: `moon check`
Expected: 0 errors

- [ ] **Step 2: Run moon test**

Run: `moon test`
Expected: All tests pass (including new extraction tests)

- [ ] **Step 3: Run moon fmt**

Run: `moon fmt`
Expected: No changes

- [ ] **Step 4: Run moon info**

Run: `moon info`
Expected: No errors

- [ ] **Step 5: Update PROGRESS.md**

Update status, test count, feature completion.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: implement schema body extraction (#9)"
```

---

## Success Criteria

1. `BodySchema`, `AttrSchema`, `BlockSchema`, `LabelSchema` types defined
2. `ExtractedBody`, `ExtractedBlock` types with accessors
3. `extract_body(body, schema)` function working
4. `from_hcl_with_body_schema(input, schema)` API
5. All tests passing (existing + new)
6. PROGRESS.md updated