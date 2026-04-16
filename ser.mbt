///|
/// HCL Serialization - convert MoonBit types to HCL

///|
/// Serialize Int to HCL string
pub fn to_hcl_int(value : Int) -> String {
  format_hcl_value(Int(value), 0)
}

///|
/// Serialize String to HCL string
pub fn to_hcl_string(value : String) -> String {
  format_hcl_value(String(value), 0)
}

///|
/// Serialize Bool to HCL string
pub fn to_hcl_bool(value : Bool) -> String {
  format_hcl_value(Bool(value), 0)
}

///|
/// Serialize HCLValue to HCL string
pub fn to_hcl_value(value : HCLValue) -> String {
  format_hcl_value(value, 0)
}

///|
/// Serialize Body to HCL string
pub fn to_hcl_body(body : Body) -> String {
  format_body(body)
}

///|
/// Format HCL value to string
fn format_hcl_value(value : HCLValue, indent : Int) -> String {
  let prefix = repeat_string("  ", indent)
  
  match value {
    Null => "null"
    Bool(b) => if b { "true" } else { "false" }
    Int(i) => i.to_string()
    Int64(i) => i.to_string()
    Float(f) => f.to_string()
    String(s) => escape_hcl_string(s)
    Array(arr) => {
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { format_hcl_value(v, indent + 1) })
        "[\n" + prefix + "  " + items.join(",\n" + prefix + "  ") + "\n" + prefix + "]"
      }
    }
    Object(obj) => {
      if obj.is_empty() {
        "{}"
      } else {
        let items = []
        for k, v in obj {
          items.push(prefix + "  " + escape_hcl_string(k) + " = " + format_hcl_value(v, indent + 1))
        }
        "{\n" + items.join("\n") + "\n" + prefix + "}"
      }
    }
  }
}

///|
/// Format HCL Body to string
pub fn format_body(body : Body) -> String {
  let lines = []
  for item in body.get_items() {
    match item {
      Attribute(attr) => {
        lines.push(attr.get_key() + " = " + format_hcl_value(attr.get_value(), 0))
      }
      Block(block) => {
        let labels = block.get_labels()
        let block_header = if labels.is_empty() {
          block.get_type_name()
        } else {
          block.get_type_name() + " " + labels.map(fn(l) { escape_hcl_string(l) }).join(" ")
        }
        lines.push(block_header + " {\n" + format_body(block.get_body()) + "\n}")
      }
    }
  }
  lines.join("\n")
}

///|
/// Escape a string for HCL
fn escape_hcl_string(s : String) -> String {
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
      _ => result = result + c.to_string()
    }
  }
  result + "\""
}

///|
/// Repeat a string n times
fn repeat_string(s : String, n : Int) -> String {
  let mut result = ""
  for _ in 0..<n {
    result = result + s
  }
  result
}
