///|
/// HCL JSON Conversion - convert HCL to JSON format

///|
/// Convert HCL string to JSON string
pub fn hcl_to_json(input : String) -> HCLResult[String] {
  match parse(input) {
    Ok(body) => Ok(body_to_json(body))
    Err(e) => Err(e)
  }
}

///|
/// Convert HCL string to JSON string with pretty printing
pub fn hcl_to_json_pretty(input : String) -> HCLResult[String] {
  match parse(input) {
    Ok(body) => Ok(body_to_json_pretty(body))
    Err(e) => Err(e)
  }
}

///|
/// Convert Body to JSON string (HCL JSON spec-compliant)
pub fn body_to_json(body : Body) -> String {
  let items = body.get_items()
  if items.is_empty() {
    return "{}"
  }

  let attrs : Array[Attr] = []
  let block_types : Array[(String, Array[Block])] = []

  for item in items {
    match item {
      Attribute(attr) => attrs.push(attr)
      Block(block) => {
        let type_name = block.get_type_name()
        let mut found = false
        for i in 0..<block_types.length() {
          let pair = block_types[i]
          if pair.0 == type_name {
            pair.1.push(block)
            found = true
            break
          }
        }
        if !found {
          block_types.push((type_name, [block]))
        }
      }
    }
  }

  let mut result = "{"
  let mut first = true

  for attr in attrs {
    if !first {
      result = result + ","
    }
    first = false
    result = result +
      escape_json_string(attr.get_key()) +
      ":" +
      value_to_json(expr_to_hcl_value(attr.get_value()))
  }

  for pair in block_types {
    let type_name = pair.0
    let blocks = pair.1
    if !first {
      result = result + ","
    }
    first = false
    result = result + escape_json_string(type_name) + ":"
    if blocks.length() == 1 {
      result = result + block_to_json_value(blocks[0])
    } else {
      let parts = blocks.map(fn(b) { block_to_json_value(b) })
      result = result + "[" + parts.join(",") + "]"
    }
  }

  result + "}"
}

///|
/// Convert a block with labels to nested JSON value
fn block_to_json_value(block : Block) -> String {
  let labels = block.get_labels()
  if labels.is_empty() {
    body_to_json(block.get_body())
  } else {
    let body_json = body_to_json(block.get_body())
    let mut result = body_json
    let mut i = labels.length() - 1
    while i >= 0 {
      result = "{" + escape_json_string(labels[i]) + ":" + result + "}"
      i = i - 1
    }
    result
  }
}

///|
/// Convert Body to JSON string with pretty printing
pub fn body_to_json_pretty(body : Body) -> String {
  body_to_json_pretty_impl(body, 0)
}

///|
/// Internal implementation of pretty JSON conversion (HCL JSON spec-compliant)
fn body_to_json_pretty_impl(body : Body, indent : Int) -> String {
  let items = body.get_items()
  if items.is_empty() {
    return "{}"
  }

  let prefix = repeat_string("  ", indent)
  let inner_prefix = repeat_string("  ", indent + 1)

  let attrs : Array[Attr] = []
  let block_types : Array[(String, Array[Block])] = []

  for item in items {
    match item {
      Attribute(attr) => attrs.push(attr)
      Block(block) => {
        let type_name = block.get_type_name()
        let mut found = false
        for i in 0..<block_types.length() {
          let pair = block_types[i]
          if pair.0 == type_name {
            pair.1.push(block)
            found = true
            break
          }
        }
        if !found {
          block_types.push((type_name, [block]))
        }
      }
    }
  }

  let mut result = "{\n"
  let mut first = true

  for attr in attrs {
    if !first {
      result = result + ",\n"
    }
    first = false
    result = result +
      inner_prefix +
      escape_json_string(attr.get_key()) +
      ": " +
      value_to_json_pretty(expr_to_hcl_value(attr.get_value()), indent + 1)
  }

  for pair in block_types {
    let type_name = pair.0
    let blocks = pair.1
    if !first {
      result = result + ",\n"
    }
    first = false
    result = result + inner_prefix + escape_json_string(type_name) + ": "
    if blocks.length() == 1 {
      result = result + block_to_json_value_pretty(blocks[0], indent + 1)
    } else {
      let block_indent = repeat_string("  ", indent + 1)
      let item_indent = repeat_string("  ", indent + 2)
      result = result + "[\n"
      for i in 0..<blocks.length() {
        if i > 0 {
          result = result + ",\n"
        }
        result = result +
          item_indent +
          block_to_json_value_pretty(blocks[i], indent + 2)
      }
      result = result + "\n" + block_indent + "]"
    }
  }

  result + "\n" + prefix + "}"
}

///|
/// Convert a block with labels to nested JSON value (pretty)
fn block_to_json_value_pretty(block : Block, indent : Int) -> String {
  let labels = block.get_labels()
  if labels.is_empty() {
    body_to_json_pretty_impl(block.get_body(), indent)
  } else {
    let inner_prefix = repeat_string("  ", indent + 1)
    let body_json = body_to_json_pretty_impl(
      block.get_body(),
      indent + labels.length(),
    )
    let mut result = body_json
    let mut i = labels.length() - 1
    while i >= 0 {
      result = "{\n" +
        inner_prefix +
        repeat_string("  ", labels.length() - 1 - i) +
        escape_json_string(labels[i]) +
        ": " +
        result +
        "\n" +
        repeat_string("  ", indent + labels.length() - 1 - i) +
        "}"
      i = i - 1
    }
    result
  }
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
    Unknown(_) => "null"
  }
}

///|
/// Convert HCLValue to JSON string with pretty printing
fn value_to_json_pretty(value : HCLValue, indent : Int) -> String {
  match value {
    Null(_) => "null"
    Unknown(_) => "null"
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
