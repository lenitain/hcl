///|
/// HCL JSON Conversion - convert HCL to JSON format

///|
/// Convert HCL string to JSON string
pub fn hcl_to_json(input : String) -> @lexer.HCLResult[String] {
  match parse(input) {
    Ok(body) => Ok(body_to_json(body))
    Err(e) => Err(e)
  }
}

///|
/// Convert HCL string to JSON string with pretty printing
pub fn hcl_to_json_pretty(input : String) -> @lexer.HCLResult[String] {
  match parse(input) {
    Ok(body) => Ok(body_to_json_pretty(body))
    Err(e) => Err(e)
  }
}

///|
/// Convert Body to JSON string
pub fn body_to_json(body : Body) -> String {
  let items = body.get_items()
  if items.is_empty() {
    return "{}"
  }

  let mut result = "{"
  let mut first = true

  for item in items {
    match item {
      Attribute(attr) => {
        if !first {
          result = result + ","
        }
        first = false
        result = result +
          escape_json_string(attr.get_key()) +
          ":" +
          value_to_json(attr.get_value())
      }
      Block(block) => {
        if !first {
          result = result + ","
        }
        first = false
        let labels = block.get_labels()
        let block_key = if labels.is_empty() {
          block.get_type_name()
        } else {
          block.get_type_name() + "_" + labels.join("_")
        }
        result = result +
          escape_json_string(block_key) +
          ":" +
          body_to_json(block.get_body())
      }
    }
  }

  result + "}"
}

///|
/// Convert Body to JSON string with pretty printing
pub fn body_to_json_pretty(body : Body) -> String {
  body_to_json_pretty_impl(body, 0)
}

///|
/// Internal implementation of pretty JSON conversion
fn body_to_json_pretty_impl(body : Body, indent : Int) -> String {
  let items = body.get_items()
  if items.is_empty() {
    return "{}"
  }

  let prefix = repeat_string("  ", indent)
  let inner_prefix = repeat_string("  ", indent + 1)

  let mut result = "{\n"
  let mut first = true

  for item in items {
    match item {
      Attribute(attr) => {
        if !first {
          result = result + ",\n"
        }
        first = false
        result = result +
          inner_prefix +
          escape_json_string(attr.get_key()) +
          ": " +
          value_to_json_pretty(attr.get_value(), indent + 1)
      }
      Block(block) => {
        if !first {
          result = result + ",\n"
        }
        first = false
        let labels = block.get_labels()
        let block_key = if labels.is_empty() {
          block.get_type_name()
        } else {
          block.get_type_name() + "_" + labels.join("_")
        }
        result = result +
          inner_prefix +
          escape_json_string(block_key) +
          ": " +
          body_to_json_pretty_impl(block.get_body(), indent + 1)
      }
    }
  }

  result + "\n" + prefix + "}"
}

///|
/// Convert HCLValue to JSON string
fn value_to_json(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Number(n, _) => n.to_string()
    String(s, _) => escape_json_string(s)
    Array(arr, _) =>
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { value_to_json(v) })
        "[" + items.join(",") + "]"
      }
    Object(obj, _) =>
      if obj.is_empty() {
        "{}"
      } else {
        let mut result = "{"
        let mut first = true
        for k, v in obj {
          if !first {
            result = result + ","
          }
          first = false
          result = result + escape_json_string(k) + ":" + value_to_json(v)
        }
        result + "}"
      }
  }
}

///|
/// Convert HCLValue to JSON string with pretty printing
fn value_to_json_pretty(value : HCLValue, indent : Int) -> String {
  match value {
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Number(n, _) => n.to_string()
    String(s, _) => escape_json_string(s)
    Array(arr, _) =>
      if arr.is_empty() {
        "[]"
      } else {
        let inner_prefix = repeat_string("  ", indent + 1)
        let items = arr.map(fn(v) { value_to_json_pretty(v, indent + 1) })
        "[\n" +
        inner_prefix +
        items.join(",\n" + inner_prefix) +
        "\n" +
        repeat_string("  ", indent) +
        "]"
      }
    Object(obj, _) =>
      if obj.is_empty() {
        "{}"
      } else {
        let inner_prefix = repeat_string("  ", indent + 1)
        let mut result = "{\n"
        let mut first = true
        for k, v in obj {
          if !first {
            result = result + ",\n"
          }
          first = false
          result = result +
            inner_prefix +
            escape_json_string(k) +
            ": " +
            value_to_json_pretty(v, indent + 1)
        }
        result + "\n" + repeat_string("  ", indent) + "}"
      }
  }
}

///|
/// Escape a string for JSON
fn escape_json_string(s : String) -> String {
  let mut result = "\""
  for c in s {
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      '\b' => result = result + "\\b"
      '\f' => result = result + "\\f"
      _ => {
        let code = c.to_int()
        if code < 0x20 {
          result = result + "\\u" + format_hex(code, 4)
        } else {
          result = result + c.to_string()
        }
      }
    }
  }
  result + "\""
}

///|
/// Format a number as hexadecimal with specified width
fn format_hex(value : Int, width : Int) -> String {
  let hex_chars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  let mut result = ""
  let mut v = value
  for _ in 0..<width {
    result = hex_chars[v % 16].to_string() + result
    v = v / 16
  }
  result
}
