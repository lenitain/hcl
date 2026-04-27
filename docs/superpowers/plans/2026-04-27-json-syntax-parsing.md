# JSON 语法解析 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement HCL JSON syntax parsing — read `terraform.tfvars.json` and other JSON-based HCL files into the same `Body`/`Attr`/`Block`/`Expression` AST as the native parser.

**Architecture:** New `json_parse.mbt` file with a hand-written JSON tokenizer + recursive descent parser. Two-phase approach: (1) parse JSON text → `JsonValue` intermediate type, (2) map `JsonValue` → `Body` following HCL JSON spec rules. Also fix `body_to_json()` to produce spec-compliant output.

**Tech Stack:** MoonBit, existing HCL types (`Body`, `Attr`, `Block`, `Expression`, `HCLValue`, `Number`)

---

## HCL JSON Spec Rules (from hashicorp/hcl spec.md)

1. Top-level JSON object → `Body`
2. String/number/bool/null value → `Attr` with literal `Expression`
3. JSON object value → `Block` (type = key, body = recurse into object)
4. JSON array-of-objects value → multiple `Block`s of same type
5. JSON array (non-object elements) → `Attr` with `ExprArray`
6. Labels: `{"block_type": {"label1": {"label2": {body}}}}` → Block with labels `["label1", "label2"]`

## Files Structure

| File | Action | Purpose |
|------|--------|---------|
| `json_parse.mbt` | **Create** | JSON tokenizer + parser + JSON→Body mapping |
| `json_parse_test.mbt` | **Create** | Tests for JSON parsing |
| `json.mbt` | **Modify** | Fix `body_to_json()` to be spec-compliant (nested labels, array for repeated blocks) |
| `json_test.mbt` | **Modify** | Update existing tests to match new output format |

---

## Task 1: Create JSON tokenizer and parser → JsonValue

**Files:**
- Create: `json_parse.mbt`
- Create: `json_parse_test.mbt`

### Step 1.1: Define JsonValue type and tokenizer

```moonbit
// json_parse.mbt

/// Intermediate JSON value type (internal use)
enum JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(String)  // keep as string for precision
  JsonString(String)
  JsonArray(Array[JsonValue])
  JsonObject(Array[(String, JsonValue)])  // ordered
}

/// JSON tokenizer token
enum JsonToken {
  TkLBrace      // {
  TkRBrace      // }
  TkLBracket    // [
  TkRBracket    // ]
  TkColon       // :
  TkComma       // ,
  TkString(String)
  TkNumber(String)
  TkTrue
  TkFalse
  TkNull
}

struct JsonLexer {
  input : String
  pos : Int
  len : Int
}

fn JsonLexer::new(input : String) -> JsonLexer {
  { input, pos: 0, len: input.length() }
}

fn JsonLexer::peek(self : JsonLexer) -> Char? {
  if self.pos >= self.len { None } else { Some(self.input[self.pos]) }
}

fn JsonLexer::advance(self : JsonLexer) -> (Char, JsonLexer) {
  (self.input[self.pos], { ..self, pos: self.pos + 1 })
}

fn JsonLexer::skip_whitespace(self : JsonLexer) -> JsonLexer {
  let mut lexer = self
  while lexer.pos < lexer.len {
    match lexer.input[lexer.pos] {
      ' ' | '\n' | '\r' | '\t' => lexer = { ..lexer, pos: lexer.pos + 1 }
      _ => break
    }
  }
  lexer
}
```

### Step 1.2: Implement string/number tokenization

```moonbit
fn JsonLexer::read_string(self : JsonLexer) -> HCLResult[(String, JsonLexer)] {
  let mut lexer = { ..self, pos: self.pos + 1 } // skip opening "
  let mut result = ""
  while lexer.pos < lexer.len {
    let c = lexer.input[lexer.pos]
    match c {
      '"' => return Ok((result, { ..lexer, pos: lexer.pos + 1 }))
      '\\' => {
        lexer = { ..lexer, pos: lexer.pos + 1 }
        if lexer.pos >= lexer.len {
          return Err(HCLError::invalid_value("unterminated string escape"))
        }
        let esc = lexer.input[lexer.pos]
        result = result + match esc {
          '"' => "\""
          '\\' => "\\"
          '/' => "/"
          'n' => "\n"
          'r' => "\r"
          't' => "\t"
          'b' => "\b"
          'f' => "\f"
          'u' => {
            // Read 4 hex digits
            if lexer.pos + 4 >= lexer.len {
              return Err(HCLError::invalid_value("incomplete unicode escape"))
            }
            let hex = lexer.input.substring(lexer.pos + 1, lexer.pos + 5)
            lexer = { ..lexer, pos: lexer.pos + 4 }
            // Convert hex to char
            let code = hex_to_int(hex)
            String::from_utf16([code.to_uint16()])
          }
          _ => return Err(HCLError::invalid_value("invalid escape: \\" + esc.to_string()))
        }
        lexer = { ..lexer, pos: lexer.pos + 1 }
      }
      _ => {
        result = result + c.to_string()
        lexer = { ..lexer, pos: lexer.pos + 1 }
      }
    }
  }
  Err(HCLError::invalid_value("unterminated string"))
}

fn JsonLexer::read_number(self : JsonLexer) -> HCLResult[(String, JsonLexer)] {
  let start = self.pos
  let mut lexer = self
  // Optional minus
  if lexer.pos < lexer.len && lexer.input[lexer.pos] == '-' {
    lexer = { ..lexer, pos: lexer.pos + 1 }
  }
  // Integer part
  while lexer.pos < lexer.len && lexer.input[lexer.pos] >= '0' && lexer.input[lexer.pos] <= '9' {
    lexer = { ..lexer, pos: lexer.pos + 1 }
  }
  // Fractional part
  if lexer.pos < lexer.len && lexer.input[lexer.pos] == '.' {
    lexer = { ..lexer, pos: lexer.pos + 1 }
    while lexer.pos < lexer.len && lexer.input[lexer.pos] >= '0' && lexer.input[lexer.pos] <= '9' {
      lexer = { ..lexer, pos: lexer.pos + 1 }
    }
  }
  // Exponent part
  if lexer.pos < lexer.len && (lexer.input[lexer.pos] == 'e' || lexer.input[lexer.pos] == 'E') {
    lexer = { ..lexer, pos: lexer.pos + 1 }
    if lexer.pos < lexer.len && (lexer.input[lexer.pos] == '+' || lexer.input[lexer.pos] == '-') {
      lexer = { ..lexer, pos: lexer.pos + 1 }
    }
    while lexer.pos < lexer.len && lexer.input[lexer.pos] >= '0' && lexer.input[lexer.pos] <= '9' {
      lexer = { ..lexer, pos: lexer.pos + 1 }
    }
  }
  if lexer.pos == start {
    return Err(HCLError::invalid_value("expected number"))
  }
  Ok((lexer.input.substring(start, lexer.pos), lexer))
}
```

### Step 1.3: Implement token stream

```moonbit
fn JsonLexer::next_token(self : JsonLexer) -> HCLResult[(JsonToken, JsonLexer)] {
  let lexer = self.skip_whitespace()
  if lexer.pos >= lexer.len {
    return Err(HCLError::invalid_value("unexpected end of JSON input"))
  }
  let c = lexer.input[lexer.pos]
  match c {
    '{' => Ok((TkLBrace, { ..lexer, pos: lexer.pos + 1 }))
    '}' => Ok((TkRBrace, { ..lexer, pos: lexer.pos + 1 }))
    '[' => Ok((TkLBracket, { ..lexer, pos: lexer.pos + 1 }))
    ']' => Ok((TkRBracket, { ..lexer, pos: lexer.pos + 1 }))
    ':' => Ok((TkColon, { ..lexer, pos: lexer.pos + 1 }))
    ',' => Ok((TkComma, { ..lexer, pos: lexer.pos + 1 }))
    '"' => {
      match lexer.read_string() {
        Ok((s, l)) => Ok((TkString(s), l))
        Err(e) => Err(e)
      }
    }
    't' => {
      if lexer.pos + 3 < lexer.len && lexer.input.substring(lexer.pos, lexer.pos + 4) == "true" {
        Ok((TkTrue, { ..lexer, pos: lexer.pos + 4 }))
      } else {
        Err(HCLError::invalid_value("unexpected token"))
      }
    }
    'f' => {
      if lexer.pos + 4 < lexer.len && lexer.input.substring(lexer.pos, lexer.pos + 5) == "false" {
        Ok((TkFalse, { ..lexer, pos: lexer.pos + 5 }))
      } else {
        Err(HCLError::invalid_value("unexpected token"))
      }
    }
    'n' => {
      if lexer.pos + 3 < lexer.len && lexer.input.substring(lexer.pos, lexer.pos + 4) == "null" {
        Ok((TkNull, { ..lexer, pos: lexer.pos + 4 }))
      } else {
        Err(HCLError::invalid_value("unexpected token"))
      }
    }
    '-' | '0'...'9' => {
      match lexer.read_number() {
        Ok((n, l)) => Ok((TkNumber(n), l))
        Err(e) => Err(e)
      }
    }
    _ => Err(HCLError::invalid_value("unexpected character: " + c.to_string()))
  }
}
```

### Step 1.4: Recursive descent parser → JsonValue

```moonbit
struct JsonParser {
  lexer : JsonLexer
  current : JsonToken?
}

fn JsonParser::new(input : String) -> JsonParser {
  { lexer: JsonLexer::new(input), current: None }
}

fn JsonParser::advance(self : JsonParser) -> HCLResult[(JsonToken, JsonParser)] {
  match self.current {
    Some(tok) => Ok((tok, { ..self, current: None }))
    None => self.lexer.next_token().fn((tok, lex) => Ok((tok, { lexer: lex, current: None })))
  }
}

fn JsonParser::peek(self : JsonParser) -> HCLResult[(JsonToken, JsonParser)] {
  match self.current {
    Some(tok) => Ok((tok, self))
    None => self.lexer.next_token().fn((tok, lex) => Ok((tok, { lexer: lex, current: Some(tok) })))
  }
}

fn JsonParser::parse_value(self : JsonParser) -> HCLResult[(JsonValue, JsonParser)] {
  match self.advance() {
    Ok((tok, parser)) => match tok {
      TkNull => Ok((JsonNull, parser))
      TkTrue => Ok((JsonBool(true), parser))
      TkFalse => Ok((JsonBool(false), parser))
      TkNumber(n) => Ok((JsonNumber(n), parser))
      TkString(s) => Ok((JsonString(s), parser))
      TkLBracket => parser.parse_array()
      TkLBrace => parser.parse_object()
      _ => Err(HCLError::invalid_value("unexpected token in value"))
    }
    Err(e) => Err(e)
  }
}

fn JsonParser::parse_array(self : JsonParser) -> HCLResult[(JsonValue, JsonParser)] {
  let mut items = []
  let mut parser = self
  // Check for empty array
  match parser.peek() {
    Ok((TkRBracket, p)) => {
      let (_, p2) = p.advance()! // consume ]
      return Ok((JsonArray(items), p2))
    }
    _ => ()
  }
  loop {
    let (val, p) = parser.parse_value()!
    items.push(val)
    parser = p
    match parser.advance()! {
      (TkComma, p2) => parser = p2
      (TkRBracket, p2) => return Ok((JsonArray(items), p2))
      _ => return Err(HCLError::invalid_value("expected ',' or ']' in array"))
    }
  }
}

fn JsonParser::parse_object(self : JsonParser) -> HCLResult[(JsonValue, JsonParser)] {
  let mut pairs = []
  let mut parser = self
  // Check for empty object
  match parser.peek() {
    Ok((TkRBrace, p)) => {
      let (_, p2) = p.advance()! // consume }
      return Ok((JsonObject(pairs), p2))
    }
    _ => ()
  }
  loop {
    let (key_tok, p) = parser.advance()!
    let key = match key_tok {
      TkString(s) => s
      _ => return Err(HCLError::invalid_value("expected string key in object"))
    }
    let (_, p2) = p.advance()! // consume :
    let (val, p3) = p2.parse_value()!
    pairs.push((key, val))
    parser = p3
    match parser.advance()! {
      (TkComma, p4) => parser = p4
      (TkRBrace, p4) => return Ok((JsonObject(pairs), p4))
      _ => return Err(HCLError::invalid_value("expected ',' or '}' in object"))
    }
  }
}

/// Parse JSON string into JsonValue
pub fn parse_json(input : String) -> HCLResult[JsonValue] {
  let parser = JsonParser::new(input)
  let (value, _) = parser.parse_value()!
  Ok(value)
}
```

### Step 1.5: Test JSON tokenizer and parser

- [ ] **Write test:** Basic JSON values

```moonbit
// json_parse_test.mbt
test "json parse null" {
  let result = parse_json("null")
  match result {
    Ok(JsonNull) => ()
    _ => panic()
  }
}

test "json parse bool" {
  let result = parse_json("true")
  match result {
    Ok(JsonBool(true)) => ()
    _ => panic()
  }
}

test "json parse number" {
  let result = parse_json("42")
  match result {
    Ok(JsonNumber("42")) => ()
    _ => panic()
  }
}

test "json parse string" {
  let result = parse_json("\"hello\"")
  match result {
    Ok(JsonString("hello")) => ()
    _ => panic()
  }
}

test "json parse array" {
  let result = parse_json("[1, 2, 3]")
  match result {
    Ok(JsonArray(arr)) => assert_eq(arr.length(), 3)
    _ => panic()
  }
}

test "json parse object" {
  let result = parse_json("{\"key\": \"value\"}")
  match result {
    Ok(JsonObject(pairs)) => assert_eq(pairs.length(), 1)
    _ => panic()
  }
}
```

- [ ] **Run:** `moon test -F "json parse"`
- [ ] **Expected:** All pass

---

## Task 2: Implement JsonValue → Body mapping

**Files:**
- Modify: `json_parse.mbt`

### Step 2.1: JSON value → Expression mapping

```moonbit
/// Convert JsonValue to Expression (for attribute values)
fn json_to_expression(jv : JsonValue) -> Expression {
  match jv {
    JsonNull => ExprNull
    JsonBool(b) => ExprBool(b)
    JsonNumber(s) => json_number_to_expression(s)
    JsonString(s) => ExprString(s)
    JsonArray(items) => ExprArray(items.map(json_to_expression))
    JsonObject(pairs) => {
      let obj : ExprObject = []
      for k, v in pairs {
        obj.push((ObjectKey::Identifier(k), json_to_expression(v)))
      }
      ExprObject(obj)
    }
  }
}

/// Parse JSON number string to appropriate Expression
fn json_number_to_expression(s : String) -> Expression {
  if s.contains(".") || s.contains("e") || s.contains("E") {
    match Double::from_string(s) {
      Some(f) => ExprFloat(f)
      None => ExprFloat(0.0)
    }
  } else {
    match Int::from_string(s) {
      Some(i) => ExprInt(i)
      None => ExprInt(0)
    }
  }
}
```

### Step 2.2: Top-level JSON object → Body mapping

```moonbit
/// Convert top-level JsonValue to Body
/// HCL JSON spec: top-level must be a JSON object
fn json_to_body_impl(jv : JsonValue) -> HCLResult[Body] {
  match jv {
    JsonObject(pairs) => {
      let items : Array[BodyItem] = []
      for key, value in pairs {
        match value {
          // Object value → Block (recurse into body)
          JsonObject(_) => {
            let block = json_object_to_block(key, value)?
            items.push(Block(block))
          }
          // Array value → check if array of objects (multiple blocks)
          JsonArray(arr) => {
            if is_block_array(arr) {
              // Each element is a block body
              for elem in arr {
                let block = json_object_to_block(key, elem)?
                items.push(Block(block))
              }
            } else {
              // Regular array attribute
              items.push(Attribute(Attr::new(key, json_to_expression(value))))
            }
          }
          // Primitive → Attribute
          _ => {
            items.push(Attribute(Attr::new(key, json_to_expression(value))))
          }
        }
      }
      Ok(Body::from_items(items))
    }
    _ => Err(HCLError::invalid_value("HCL JSON: top-level must be a JSON object"))
  }
}

/// Check if all array elements are objects (block array)
fn is_block_array(arr : Array[JsonValue]) -> Bool {
  if arr.is_empty() {
    return false
  }
  for elem in arr {
    match elem {
      JsonObject(_) => ()
      _ => return false
    }
  }
  true
}

/// Convert a JSON object value to a Block, handling label nesting
/// {"label1": {"label2": {body}}} → Block(type, ["label1", "label2"], body)
fn json_object_to_block(type_name : String, jv : JsonValue) -> HCLResult[Block] {
  match jv {
    JsonObject(pairs) => {
      // Check if this is a label-nesting pattern:
      // If the object has exactly one key whose value is also an object,
      // treat that key as a label and recurse.
      if pairs.length() == 1 {
        let (key, value) = pairs[0]
        match value {
          JsonObject(_) => {
            // This is a label: key is the label, value is the rest
            let (labels, body) = extract_labels(value)?
            let all_labels = [key] + labels
            Ok(Block::new(type_name, all_labels, body))
          }
          _ => {
            // Single-key object but value is not object → it's the body with one attr
            let body_items : Array[BodyItem] = []
            body_items.push(Attribute(Attr::new(key, json_to_expression(value))))
            Ok(Block::simple(type_name, Body::from_items(body_items)))
          }
        }
      } else {
        // Multiple keys → this is the body itself
        let body = json_to_body_impl(jv)?
        Ok(Block::simple(type_name, body))
      }
    }
    _ => Err(HCLError::invalid_value("block value must be a JSON object"))
  }
}

/// Recursively extract labels from nested single-key objects
fn extract_labels(jv : JsonValue) -> HCLResult[(Array[String], Body)] {
  match jv {
    JsonObject(pairs) => {
      if pairs.length() == 1 {
        let (key, value) = pairs[0]
        match value {
          JsonObject(_) => {
            // Could be another label or could be body
            let (more_labels, body) = extract_labels(value)?
            let labels = [key] + more_labels
            Ok((labels, body))
          }
          _ => {
            // Value is not object → this is the body with one attr
            let body_items : Array[BodyItem] = []
            body_items.push(Attribute(Attr::new(key, json_to_expression(value))))
            Ok(([], Body::from_items(body_items)))
          }
        }
      } else {
        // Multiple keys → this is the body
        let body = json_to_body_impl(jv)?
        Ok(([], body))
      }
    }
    _ => Err(HCLError::invalid_value("expected object for block body"))
  }
}
```

### Step 2.3: Public API functions

```moonbit
/// Parse JSON string to HCL Body
pub fn json_to_body(input : String) -> HCLResult[Body] {
  let jv = parse_json(input)?
  json_to_body_impl(jv)
}

/// Convert JSON string to HCL native string
pub fn json_to_hcl_string(input : String) -> HCLResult[String] {
  let body = json_to_body(input)?
  Ok(format_body(body))
}
```

### Step 2.4: Test JsonValue → Body mapping

- [ ] **Write test:** JSON to Body conversion

```moonbit
test "json_to_body simple attribute" {
  let result = json_to_body("{\"name\": \"John\"}")
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
    }
    Err(_) => panic()
  }
}

test "json_to_body block" {
  let result = json_to_body("{\"server\": {\"host\": \"localhost\"}}")
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "server")
          assert_eq(block.get_labels().length(), 0)
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

test "json_to_body block with label" {
  let result = json_to_body("{\"resource\": {\"aws_instance\": {\"web\": {\"ami\": \"abc\"}}}}")
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "resource")
          assert_eq(block.get_labels(), ["aws_instance", "web"])
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

test "json_to_body multiple blocks same type" {
  let result = json_to_body("{\"resource\": [{\"aws_instance\": {\"web\": {\"ami\": \"abc\"}}}, {\"aws_instance\": {\"db\": {\"ami\": \"def\"}}}]}")
  match result {
    Ok(body) => {
      let blocks = body.find_blocks("resource")
      assert_eq(blocks.length(), 2)
    }
    Err(_) => panic()
  }
}
```

- [ ] **Run:** `moon test -F "json_to_body"`
- [ ] **Expected:** All pass

---

## Task 3: Fix body_to_json() to be spec-compliant

**Files:**
- Modify: `json.mbt` (lines 45-65 for compact, lines 100-120 for pretty)
- Modify: `json_test.mbt` (update expected outputs)

The current `body_to_json()` flattens labels into key names (`type_label1_label2`), which is **not** HCL JSON spec-compliant. Fix to use nested objects for labels.

### Step 3.1: Fix block serialization

Change block serialization from:
```moonbit
// OLD: block_key = type_name + "_" + labels.join("_")
// result = escape_json_string(block_key) + ":" + body_to_json(block.get_body())
```

To:
```moonbit
// NEW: nest labels as objects
// For block "resource" with labels ["aws_instance", "web"]:
// "resource": {"aws_instance": {"web": {body}}}
```

### Step 3.2: Handle repeated block types

Group blocks by type name. If multiple blocks share the same type, serialize as array:
```json
{"resource": [{...}, {...}]}
```

### Step 3.3: Update tests

Update `json_test.mbt` to verify spec-compliant output format.

---

## Task 4: Integration tests

**Files:**
- Create: `json_parse_test.mbt`

### Step 4.1: Round-trip tests

```moonbit
test "json round-trip: simple attributes" {
  let json = "{\"name\": \"John\", \"age\": 30}"
  let body = json_to_body(json)!
  let hcl = format_body(body)
  // Re-parse HCL to verify
  let body2 = parse(hcl)!
  let name = body2.find_attr("name")
  assert_true(name is Some(_))
}

test "json to hcl: terraform.tfvars.json style" {
  let json = "{\"variable\": {\"region\": {\"default\": \"us-east-1\"}}}"
  let body = json_to_body(json)!
  let items = body.get_items()
  assert_eq(items.length(), 1)
  match items[0] {
    Block(block) => {
      assert_eq(block.get_type_name(), "variable")
      assert_eq(block.get_labels(), ["region"])
    }
    _ => panic()
  }
}
```

### Step 4.2: Error handling tests

```moonbit
test "json parse error: invalid JSON" {
  let result = json_to_body("{invalid}")
  assert_true(result is Err(_))
}

test "json parse error: not an object" {
  let result = json_to_body("\"just a string\"")
  assert_true(result is Err(_))
}
```

---

## Task 5: Final verification

- [ ] Run `moon check` — 0 errors
- [ ] Run `moon fmt` — passes
- [ ] Run `moon test` — all tests pass (existing 601 + new tests)
- [ ] Run `moon info` — regenerate `.mbti`
- [ ] Verify `json_to_body` works with real-world `terraform.tfvars.json` format
- [ ] Update `PROGRESS.md`
