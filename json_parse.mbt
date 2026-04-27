///|
/// JSON to HCL Body parser - implements HCL JSON equivalent syntax
/// Parses JSON input and produces HCL Body/Attr/Block structures

///|
/// JSON value intermediate type
pub(all) enum JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(String)
  JsonString(String)
  JsonArray(Array[JsonValue])
  JsonObject(Array[(String, JsonValue)])
} derive(Debug, Eq)

///|
/// JSON token types
priv enum JsonToken {
  JBrace
  JRBrace
  JLBracket
  JRBracket
  JColon
  JComma
  JStringLit(String)
  JNumberLit(String)
  JTrueLit
  JFalseLit
  JNullLit
  JEOF
}

///|
/// JSON lexer state
priv struct JsonLexer {
  input : String
  pos : Int
  len : Int
}

///|
/// Create a new JSON lexer
fn JsonLexer::new(input : String) -> JsonLexer {
  { input, pos: 0, len: input.length() }
}

///|
/// Check if lexer has more input
fn JsonLexer::has_more(self : JsonLexer) -> Bool {
  self.pos < self.len
}

///|
/// Get current character code
fn JsonLexer::current(self : JsonLexer) -> UInt16 {
  self.input[self.pos]
}

///|
/// Advance position
fn JsonLexer::advance(self : JsonLexer) -> JsonLexer {
  { ..self, pos: self.pos + 1 }
}

///|
/// Skip whitespace
fn JsonLexer::skip_whitespace(self : JsonLexer) -> JsonLexer {
  let mut pos = self.pos
  while pos < self.len {
    let c = self.input[pos]
    if c == ' '.to_int().to_uint16() ||
      c == '\n'.to_int().to_uint16() ||
      c == '\r'.to_int().to_uint16() ||
      c == '\t'.to_int().to_uint16() {
      pos = pos + 1
    } else {
      break
    }
  }
  { ..self, pos, }
}

///|
/// Parse a JSON string literal
fn JsonLexer::parse_string(
  self : JsonLexer,
) -> Result[(String, JsonLexer), String] {
  let mut pos = self.pos + 1
  let mut result = ""
  let len = self.len

  while pos < len {
    let c = self.input[pos]
    if c == '"'.to_int().to_uint16() {
      return Ok((result, { ..self, pos: pos + 1 }))
    } else if c == '\\'.to_int().to_uint16() {
      pos = pos + 1
      if pos >= len {
        return Err("unexpected end of string escape")
      }
      let esc = self.input[pos]
      if esc == '"'.to_int().to_uint16() {
        result = result + "\""
      } else if esc == '\\'.to_int().to_uint16() {
        result = result + "\\"
      } else if esc == '/'.to_int().to_uint16() {
        result = result + "/"
      } else if esc == 'n'.to_int().to_uint16() {
        result = result + "\n"
      } else if esc == 'r'.to_int().to_uint16() {
        result = result + "\r"
      } else if esc == 't'.to_int().to_uint16() {
        result = result + "\t"
      } else if esc == 'b'.to_int().to_uint16() {
        result = result + "\b"
      } else if esc == 'f'.to_int().to_uint16() {
        result = result + "\f"
      } else if esc == 'u'.to_int().to_uint16() {
        if pos + 4 >= len {
          return Err("incomplete unicode escape")
        }
        let hex = self.input[pos + 1:pos + 5].to_string()
        match parse_hex(hex) {
          Some(code) => {
            result = result +
              code.to_uint16().to_int().unsafe_to_char().to_string()
            pos = pos + 4
          }
          None => return Err("invalid unicode escape: " + hex)
        }
      } else {
        return Err("invalid escape character")
      }
      pos = pos + 1
    } else {
      result = result + c.to_int().unsafe_to_char().to_string()
      pos = pos + 1
    }
  }

  Err("unterminated string")
}

///|
/// Parse a JSON number literal
fn JsonLexer::parse_number(self : JsonLexer) -> (String, JsonLexer) {
  let mut pos = self.pos
  let mut result = ""
  let len = self.len

  if pos < len && self.input[pos] == '-'.to_int().to_uint16() {
    result = result + "-"
    pos = pos + 1
  }

  while pos < len {
    let c = self.input[pos]
    if c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16() {
      result = result + c.to_int().unsafe_to_char().to_string()
      pos = pos + 1
    } else {
      break
    }
  }

  if pos < len && self.input[pos] == '.'.to_int().to_uint16() {
    result = result + "."
    pos = pos + 1
    while pos < len {
      let c = self.input[pos]
      if c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16() {
        result = result + c.to_int().unsafe_to_char().to_string()
        pos = pos + 1
      } else {
        break
      }
    }
  }

  if pos < len {
    let c = self.input[pos]
    if c == 'e'.to_int().to_uint16() || c == 'E'.to_int().to_uint16() {
      result = result + c.to_int().unsafe_to_char().to_string()
      pos = pos + 1
      if pos < len {
        let c2 = self.input[pos]
        if c2 == '+'.to_int().to_uint16() || c2 == '-'.to_int().to_uint16() {
          result = result + c2.to_int().unsafe_to_char().to_string()
          pos = pos + 1
        }
      }
      while pos < len {
        let c3 = self.input[pos]
        if c3 >= '0'.to_int().to_uint16() && c3 <= '9'.to_int().to_uint16() {
          result = result + c3.to_int().unsafe_to_char().to_string()
          pos = pos + 1
        } else {
          break
        }
      }
    }
  }

  (result, { ..self, pos, })
}

///|
/// Get next token from lexer
fn JsonLexer::next_token(
  self : JsonLexer,
) -> Result[(JsonToken, JsonLexer), String] {
  let lexer = self.skip_whitespace()
  if !lexer.has_more() {
    return Ok((JEOF, lexer))
  }

  let c = lexer.current()
  if c == '{'.to_int().to_uint16() {
    Ok((JBrace, lexer.advance()))
  } else if c == '}'.to_int().to_uint16() {
    Ok((JRBrace, lexer.advance()))
  } else if c == '['.to_int().to_uint16() {
    Ok((JLBracket, lexer.advance()))
  } else if c == ']'.to_int().to_uint16() {
    Ok((JRBracket, lexer.advance()))
  } else if c == ':'.to_int().to_uint16() {
    Ok((JColon, lexer.advance()))
  } else if c == ','.to_int().to_uint16() {
    Ok((JComma, lexer.advance()))
  } else if c == '"'.to_int().to_uint16() {
    match lexer.parse_string() {
      Ok((s, l2)) => Ok((JStringLit(s), l2))
      Err(e) => Err(e)
    }
  } else if c == 't'.to_int().to_uint16() {
    if lexer.pos + 4 <= lexer.len &&
      lexer.input[lexer.pos:lexer.pos + 4].to_string() == "true" {
      Ok((JTrueLit, { ..lexer, pos: lexer.pos + 4 }))
    } else {
      Err("unexpected character: t")
    }
  } else if c == 'f'.to_int().to_uint16() {
    if lexer.pos + 5 <= lexer.len &&
      lexer.input[lexer.pos:lexer.pos + 5].to_string() == "false" {
      Ok((JFalseLit, { ..lexer, pos: lexer.pos + 5 }))
    } else {
      Err("unexpected character: f")
    }
  } else if c == 'n'.to_int().to_uint16() {
    if lexer.pos + 4 <= lexer.len &&
      lexer.input[lexer.pos:lexer.pos + 4].to_string() == "null" {
      Ok((JNullLit, { ..lexer, pos: lexer.pos + 4 }))
    } else {
      Err("unexpected character: n")
    }
  } else if c == '-'.to_int().to_uint16() ||
    (c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16()) {
    let (num, l2) = lexer.parse_number()
    Ok((JNumberLit(num), l2))
  } else {
    Err("unexpected character")
  }
}

///|
/// JSON parser state
priv struct JsonParser {
  lexer : JsonLexer
  current : JsonToken
}

///|
/// Create a new JSON parser
fn JsonParser::new(input : String) -> Result[JsonParser, String] {
  let lexer = JsonLexer::new(input)
  match lexer.next_token() {
    Ok((token, l2)) => Ok({ lexer: l2, current: token })
    Err(e) => Err(e)
  }
}

///|
/// Advance to next token
fn JsonParser::advance(self : JsonParser) -> Result[JsonParser, String] {
  match self.lexer.next_token() {
    Ok((token, l2)) => Ok({ lexer: l2, current: token })
    Err(e) => Err(e)
  }
}

///|
/// Parse a JSON value
fn JsonParser::parse_value(
  self : JsonParser,
) -> Result[(JsonValue, JsonParser), String] {
  match self.current {
    JNullLit =>
      match self.advance() {
        Ok(p2) => Ok((JsonNull, p2))
        Err(e) => Err(e)
      }
    JTrueLit =>
      match self.advance() {
        Ok(p2) => Ok((JsonBool(true), p2))
        Err(e) => Err(e)
      }
    JFalseLit =>
      match self.advance() {
        Ok(p2) => Ok((JsonBool(false), p2))
        Err(e) => Err(e)
      }
    JNumberLit(n) =>
      match self.advance() {
        Ok(p2) => Ok((JsonNumber(n), p2))
        Err(e) => Err(e)
      }
    JStringLit(s) =>
      match self.advance() {
        Ok(p2) => Ok((JsonString(s), p2))
        Err(e) => Err(e)
      }
    JLBracket => self.parse_array()
    JBrace => self.parse_object()
    _ => Err("unexpected token in value")
  }
}

///|
/// Parse a JSON array
fn JsonParser::parse_array(
  self : JsonParser,
) -> Result[(JsonValue, JsonParser), String] {
  let mut p = match self.advance() {
    Ok(p) => p
    Err(e) => return Err(e)
  }
  let items : Array[JsonValue] = []

  match p.current {
    JRBracket =>
      match p.advance() {
        Ok(p2) => return Ok((JsonArray(items), p2))
        Err(e) => return Err(e)
      }
    _ => ()
  }

  let mut done = false
  while !done {
    match p.parse_value() {
      Ok((val, p2)) => {
        items.push(val)
        p = p2
      }
      Err(e) => return Err(e)
    }

    match p.current {
      JComma =>
        match p.advance() {
          Ok(p2) => p = p2
          Err(e) => return Err(e)
        }
      JRBracket =>
        match p.advance() {
          Ok(p2) => {
            p = p2
            done = true
          }
          Err(e) => return Err(e)
        }
      _ => return Err("expected ',' or ']' in array")
    }
  }

  Ok((JsonArray(items), p))
}

///|
/// Parse a JSON object
fn JsonParser::parse_object(
  self : JsonParser,
) -> Result[(JsonValue, JsonParser), String] {
  let mut p = match self.advance() {
    Ok(p) => p
    Err(e) => return Err(e)
  }
  let pairs : Array[(String, JsonValue)] = []

  match p.current {
    JRBrace =>
      match p.advance() {
        Ok(p2) => return Ok((JsonObject(pairs), p2))
        Err(e) => return Err(e)
      }
    _ => ()
  }

  let mut done = false
  while !done {
    let key = match p.current {
      JStringLit(s) => s
      _ => return Err("expected string key in object")
    }
    match p.advance() {
      Ok(p2) => p = p2
      Err(e) => return Err(e)
    }
    match p.current {
      JColon => ()
      _ => return Err("expected ':' after key in object")
    }
    match p.advance() {
      Ok(p2) => p = p2
      Err(e) => return Err(e)
    }
    match p.parse_value() {
      Ok((val, p2)) => {
        pairs.push((key, val))
        p = p2
      }
      Err(e) => return Err(e)
    }

    match p.current {
      JComma =>
        match p.advance() {
          Ok(p2) => p = p2
          Err(e) => return Err(e)
        }
      JRBrace =>
        match p.advance() {
          Ok(p2) => {
            p = p2
            done = true
          }
          Err(e) => return Err(e)
        }
      _ => return Err("expected ',' or '}' in object")
    }
  }

  Ok((JsonObject(pairs), p))
}

///|
/// Parse hex string to Int
fn parse_hex(s : String) -> Int? {
  let mut result = 0
  let mut valid = true
  for c in s {
    let code = c.to_int()
    if code >= '0'.to_int() && code <= '9'.to_int() {
      result = result * 16 + (code - '0'.to_int())
    } else if code >= 'a'.to_int() && code <= 'f'.to_int() {
      result = result * 16 + (code - 'a'.to_int() + 10)
    } else if code >= 'A'.to_int() && code <= 'F'.to_int() {
      result = result * 16 + (code - 'A'.to_int() + 10)
    } else {
      valid = false
    }
  }
  if valid {
    Some(result)
  } else {
    None
  }
}

///|
/// Parse decimal string to Int
fn parse_int(s : String) -> Int? {
  if s.length() == 0 {
    return None
  }
  let mut result = 0
  let mut negative = false
  let mut started = false
  for c in s {
    let code = c.to_int()
    if code == '-'.to_int() && !started {
      negative = true
    } else if code >= '0'.to_int() && code <= '9'.to_int() {
      result = result * 10 + (code - '0'.to_int())
      started = true
    } else {
      return None
    }
  }
  if !started {
    return None
  }
  Some(if negative { -result } else { result })
}

///|
/// Parse float string to Double
fn parse_float(s : String) -> Double? {
  if s.length() == 0 {
    return None
  }
  let mut result = 0.0
  let mut decimal_place = 1.0
  let mut in_decimal = false
  let mut in_exponent = false
  let mut exponent = 0
  let mut exponent_negative = false
  let mut negative = false
  let mut has_digits = false

  for c in s {
    let code = c.to_int()
    if code == '-'.to_int() {
      if in_exponent {
        exponent_negative = true
      } else {
        negative = true
      }
    } else if code == '+'.to_int() {
      // skip
    } else if code == '.'.to_int() {
      in_decimal = true
    } else if code == 'e'.to_int() || code == 'E'.to_int() {
      in_exponent = true
    } else if code >= '0'.to_int() && code <= '9'.to_int() {
      has_digits = true
      if in_exponent {
        exponent = exponent * 10 + (code - '0'.to_int())
      } else if in_decimal {
        decimal_place = decimal_place * 10.0
        result = result + (code - '0'.to_int()).to_double() / decimal_place
      } else {
        result = result * 10.0 + (code - '0'.to_int()).to_double()
      }
    } else {
      return None
    }
  }

  if !has_digits {
    return None
  }

  if exponent != 0 {
    let e = if exponent_negative { -exponent } else { exponent }
    let mut exp_val = 1.0
    let abs_e = if e < 0 { -e } else { e }
    for _ in 0..<abs_e {
      exp_val = exp_val * 10.0
    }
    if e > 0 {
      result = result * exp_val
    } else {
      result = result / exp_val
    }
  }

  Some(if negative { -result } else { result })
}

///|
/// Parse JSON string into JsonValue
fn parse_json(input : String) -> Result[JsonValue, String] {
  match JsonParser::new(input) {
    Ok(parser) =>
      match parser.parse_value() {
        Ok((value, p2)) =>
          match p2.current {
            JEOF => Ok(value)
            _ => Err("unexpected content after JSON value")
          }
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// Convert JsonValue to Expression
fn json_value_to_expr(jv : JsonValue) -> Expression {
  match jv {
    JsonNull => ExprNull
    JsonBool(b) => ExprBool(b)
    JsonNumber(n) =>
      if n.contains(".") || n.contains("e") || n.contains("E") {
        match parse_float(n) {
          Some(f) => ExprFloat(f)
          None => ExprString(n)
        }
      } else {
        match parse_int(n) {
          Some(i) => ExprInt(i)
          None => ExprString(n)
        }
      }
    JsonString(s) => ExprString(s)
    JsonArray(arr) => ExprArray(arr.map(json_value_to_expr))
    JsonObject(obj) => {
      let pairs : ExprObject = []
      for pair in obj {
        let (k, v) = pair
        pairs.push((ObjectKey::Identifier(k), json_value_to_expr(v)))
      }
      ExprObject(pairs)
    }
  }
}

///|
/// Check if all elements in array are objects
fn all_objects(arr : Array[JsonValue]) -> Bool {
  for item in arr {
    match item {
      JsonObject(_) => ()
      _ => return false
    }
  }
  true
}

///|
/// Check if JsonValue is a single-key object whose value is also an object
fn is_nested_block(obj : Array[(String, JsonValue)]) -> Bool {
  if obj.length() == 1 {
    let (_, v) = obj[0]
    match v {
      JsonObject(_) => true
      _ => false
    }
  } else {
    false
  }
}

///|
/// Convert a single-key nested object to block with labels
fn nested_to_block(
  type_name : String,
  obj : Array[(String, JsonValue)],
) -> Array[BodyItem] {
  let (label, inner) = obj[0]
  match inner {
    JsonObject(inner_obj) =>
      if is_nested_block(inner_obj) {
        let labels = collect_labels(obj)
        let body_items = get_body_items(obj)
        [Block(Block::new(type_name, labels, Body::from_items(body_items)))]
      } else {
        [Block(Block::new(type_name, [label], json_obj_to_body(inner_obj)))]
      }
    _ => [Attribute(Attr::new(type_name, json_value_to_expr(JsonObject(obj))))]
  }
}

///|
/// Collect labels from nested single-key objects
fn collect_labels(obj : Array[(String, JsonValue)]) -> Array[String] {
  if obj.length() == 1 {
    let (key, val) = obj[0]
    match val {
      JsonObject(inner) =>
        if is_nested_block(inner) {
          [key] + collect_labels(inner)
        } else {
          [key]
        }
      _ => [key]
    }
  } else {
    []
  }
}

///|
/// Get the body items from the innermost nested object
fn get_body_items(obj : Array[(String, JsonValue)]) -> Array[BodyItem] {
  if obj.length() == 1 {
    let (_, val) = obj[0]
    match val {
      JsonObject(inner) =>
        if is_nested_block(inner) {
          get_body_items(inner)
        } else {
          json_obj_to_items(inner)
        }
      _ => []
    }
  } else {
    json_obj_to_items(obj)
  }
}

///|
/// Convert JSON object to body items
fn json_obj_to_items(obj : Array[(String, JsonValue)]) -> Array[BodyItem] {
  let items : Array[BodyItem] = []
  for pair in obj {
    let (key, val) = pair
    match val {
      JsonObject(child_obj) =>
        if is_nested_block(child_obj) {
          let sub_items = nested_to_block(key, child_obj)
          for item in sub_items {
            items.push(item)
          }
        } else {
          items.push(Block(Block::simple(key, json_obj_to_body(child_obj))))
        }
      JsonArray(arr) =>
        if arr.is_empty() {
          items.push(Attribute(Attr::new(key, ExprArray([]))))
        } else if all_objects(arr) {
          for obj_item in arr {
            match obj_item {
              JsonObject(oo) =>
                if is_nested_block(oo) {
                  let sub_items = nested_to_block(key, oo)
                  for item in sub_items {
                    items.push(item)
                  }
                } else {
                  items.push(Block(Block::simple(key, json_obj_to_body(oo))))
                }
              _ => ()
            }
          }
        } else {
          items.push(
            Attribute(Attr::new(key, json_value_to_expr(JsonArray(arr)))),
          )
        }
      _ => items.push(Attribute(Attr::new(key, json_value_to_expr(val))))
    }
  }
  items
}

///|
/// Convert JSON object pairs to Body
fn json_obj_to_body(obj : Array[(String, JsonValue)]) -> Body {
  Body::from_items(json_obj_to_items(obj))
}

///|
/// Convert JSON string to HCL Body
pub fn json_to_body(input : String) -> HCLResult[Body] {
  match parse_json(input) {
    Ok(JsonObject(obj)) => Ok(json_obj_to_body(obj))
    Ok(_) => Err(HCLError::invalid_value("top-level JSON must be an object"))
    Err(e) => Err(HCLError::invalid_value("JSON parse error: " + e))
  }
}

///|
/// Convert JSON string to HCL formatted string
pub fn json_to_hcl_string(input : String) -> HCLResult[String] {
  match json_to_body(input) {
    Ok(body) => Ok(format_body(body))
    Err(e) => Err(e)
  }
}
