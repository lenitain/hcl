///|
/// HCL Serialization - convert MoonBit types to HCL

///|
/// Serialize Int to HCL string
pub fn to_hcl_int(value : Int) -> String {
  format_hcl_value(Int(value, Decor::empty()), 0)
}

///|
/// Serialize String to HCL string
pub fn to_hcl_string(value : String) -> String {
  format_hcl_value(String(value, Decor::empty()), 0)
}

///|
/// Serialize Bool to HCL string
pub fn to_hcl_bool(value : Bool) -> String {
  format_hcl_value(Bool(value, Decor::empty()), 0)
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
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Int(i, _) => i.to_string()
    Int64(i, _) => i.to_string()
    Float(f, _) => f.to_string()
    String(s, _) => escape_hcl_string(s)
    Array(arr, _) =>
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { format_hcl_value(v, indent + 1) })
        "[\n" +
        prefix +
        "  " +
        items.join(",\n" + prefix + "  ") +
        "\n" +
        prefix +
        "]"
      }
    Object(obj, _) =>
      if obj.is_empty() {
        "{}"
      } else {
        let items = []
        for k, v in obj {
          items.push(
            prefix +
            "  " +
            escape_hcl_string(k) +
            " = " +
            format_hcl_value(v, indent + 1),
          )
        }
        "{\n" + items.join("\n") + "\n" + prefix + "}"
      }
  }
}

///|
/// Format HCL Body to string
pub fn format_body(body : Body) -> String {
  let lines = []
  for item in body.get_items() {
    match item {
      Attribute(attr) =>
        lines.push(
          attr.get_key() + " = " + format_hcl_value(attr.get_value(), 0),
        )
      Block(block) => {
        let labels = block.get_labels()
        let block_header = if labels.is_empty() {
          block.get_type_name()
        } else {
          block.get_type_name() +
          " " +
          labels.map(fn(l) { escape_hcl_string(l) }).join(" ")
        }
        lines.push(
          block_header + " {\n" + format_body(block.get_body()) + "\n}",
        )
      }
    }
  }
  lines.join("\n")
}

///|
/// Format Body with decor
pub fn format_body_with_decor(body : Body) -> String {
  let mut result = ""

  match body.decor.get_prefix() {
    Some(prefix) => result = result + prefix
    None => ()
  }

  for item in body.get_items() {
    result = result + format_body_item_with_decor(item)
  }

  match body.decor.get_suffix() {
    Some(suffix) => result = result + suffix
    None => ()
  }

  result
}

///|
/// Format BodyItem with decor
fn format_body_item_with_decor(item : BodyItem) -> String {
  match item {
    Attribute(attr) => format_attr_with_decor(attr)
    Block(block) => format_block_with_decor(block)
  }
}

///|
/// Format Block with decor
fn format_block_with_decor(block : Block) -> String {
  let mut result = ""

  match block.decor.get_prefix() {
    Some(prefix) => result = result + prefix
    None => ()
  }

  let type_decor = block.type_name.get_decor()
  match type_decor.get_prefix() {
    Some(tp) => result = result + tp
    None => ()
  }
  result = result + block.type_name.get_value()
  match type_decor.get_suffix() {
    Some(ts) => result = result + ts
    None => ()
  }

  for label in block.labels {
    result = result + " "
    let ld = label.get_decor()
    match ld.get_prefix() {
      Some(lp) => result = result + lp
      None => ()
    }
    result = result + escape_hcl_string(label.get_value())
    match ld.get_suffix() {
      Some(ls) => result = result + ls
      None => ()
    }
  }

  result = result + " {\n"
  result = result + format_body_with_decor(block.body)
  result = result + "\n}"

  match block.decor.get_suffix() {
    Some(suffix) => result = result + suffix
    None => ()
  }

  result
}

///|
/// Format Attr with decor
pub fn format_attr_with_decor(attr : Attr) -> String {
  let mut result = ""

  match attr.decor.get_prefix() {
    Some(prefix) => result = result + prefix
    None => ()
  }

  let key_decor = attr.key.get_decor()
  match key_decor.get_prefix() {
    Some(key_prefix) => result = result + key_prefix
    None => ()
  }
  result = result + attr.key.get_value()
  match key_decor.get_suffix() {
    Some(key_suffix) => result = result + key_suffix
    None => ()
  }

  result = result + " = "

  result = result + format_value_with_decor(attr.value)

  match attr.decor.get_suffix() {
    Some(suffix) => result = result + suffix
    None => ()
  }

  result
}

///|
/// Format HCLValue with decor
pub fn format_value_with_decor(value : HCLValue) -> String {
  let mut result = ""

  match value.get_decor().get_prefix() {
    Some(prefix) => result = result + prefix
    None => ()
  }

  result = result + format_value_content(value)

  match value.get_decor().get_suffix() {
    Some(suffix) => result = result + suffix
    None => ()
  }

  result
}

///|
/// Format HCLValue content without decor
pub fn format_value_content(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Int(i, _) => i.to_string()
    Int64(i, _) => i.to_string()
    Float(f, _) => f.to_string()
    String(s, _) => escape_hcl_string(s)
    Array(arr, _) =>
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { format_value_with_decor(v) })
        "[" + items.join(", ") + "]"
      }
    Object(obj, _) =>
      if obj.is_empty() {
        "{}"
      } else {
        let items = []
        for k, v in obj {
          items.push(escape_hcl_string(k) + " = " + format_value_with_decor(v))
        }
        "{" + items.join(", ") + "}"
      }
  }
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

///|
/// Create Int HCLValue
pub fn hcl_int(v : Int) -> HCLValue {
  Int(v, Decor::empty())
}

///|
/// Create Int64 HCLValue
pub fn hcl_int64(v : Int64) -> HCLValue {
  Int64(v, Decor::empty())
}

///|
/// Create Float HCLValue
pub fn hcl_float(v : Double) -> HCLValue {
  Float(v, Decor::empty())
}

///|
/// Create Bool HCLValue
pub fn hcl_bool(v : Bool) -> HCLValue {
  Bool(v, Decor::empty())
}

///|
/// Create String HCLValue
pub fn hcl_str(v : String) -> HCLValue {
  String(v, Decor::empty())
}

///|
/// Create Null HCLValue
pub fn hcl_null() -> HCLValue {
  Null(Decor::empty())
}

///|
/// Create Array HCLValue
pub fn hcl_array(items : Array[HCLValue]) -> HCLValue {
  Array(items, Decor::empty())
}

///|
/// Create Object HCLValue
pub fn hcl_object(entries : Map[String, HCLValue]) -> HCLValue {
  Object(entries, Decor::empty())
}
