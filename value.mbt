///|
/// HCL value types - represents all possible values in HCL
pub(all) enum HCLValue {
  /// Null value
  Null
  /// Boolean value
  Bool(Bool)
  /// Integer value
  Int(Int)
  /// 64-bit integer value
  Int64(Int64)
  /// Floating point value
  Float(Double)
  /// String value
  String(String)
  /// Array of values
  Array(Array[HCLValue])
  /// Object (map of string to value)
  Object(Map[String, HCLValue])
} derive(Debug, Eq)

///|
/// Check if value is null
pub fn HCLValue::is_null(self : HCLValue) -> Bool {
  match self {
    Null => true
    _ => false
  }
}

///|
/// Check if value is a boolean
pub fn HCLValue::is_bool(self : HCLValue) -> Bool {
  match self {
    Bool(_) => true
    _ => false
  }
}

///|
/// Check if value is a number (int or float)
pub fn HCLValue::is_number(self : HCLValue) -> Bool {
  match self {
    Int(_) | Int64(_) | Float(_) => true
    _ => false
  }
}

///|
/// Check if value is a string
pub fn HCLValue::is_string(self : HCLValue) -> Bool {
  match self {
    String(_) => true
    _ => false
  }
}

///|
/// Check if value is an array
pub fn HCLValue::is_array(self : HCLValue) -> Bool {
  match self {
    Array(_) => true
    _ => false
  }
}

///|
/// Check if value is an object
pub fn HCLValue::is_object(self : HCLValue) -> Bool {
  match self {
    Object(_) => true
    _ => false
  }
}

///|
/// Get the boolean value, or None if not a bool
pub fn HCLValue::as_bool(self : HCLValue) -> Bool? {
  match self {
    Bool(b) => Some(b)
    _ => None
  }
}

///|
/// Get the integer value, or None if not an int
pub fn HCLValue::as_int(self : HCLValue) -> Int? {
  match self {
    Int(i) => Some(i)
    _ => None
  }
}

///|
/// Get the int64 value, or None if not an int64
pub fn HCLValue::as_int64(self : HCLValue) -> Int64? {
  match self {
    Int64(i) => Some(i)
    _ => None
  }
}

///|
/// Get the float value, or None if not a float
pub fn HCLValue::as_float(self : HCLValue) -> Double? {
  match self {
    Float(f) => Some(f)
    _ => None
  }
}

///|
/// Get the string value, or None if not a string
pub fn HCLValue::as_string(self : HCLValue) -> String? {
  match self {
    String(s) => Some(s)
    _ => None
  }
}

///|
/// Get the array value, or None if not an array
pub fn HCLValue::as_array(self : HCLValue) -> Array[HCLValue]? {
  match self {
    Array(a) => Some(a)
    _ => None
  }
}

///|
/// Get the object value, or None if not an object
pub fn HCLValue::as_object(self : HCLValue) -> Map[String, HCLValue]? {
  match self {
    Object(o) => Some(o)
    _ => None
  }
}

///|
/// Convert HCLValue to JSON-compatible string representation
pub fn HCLValue::to_json_string(self : HCLValue) -> String {
  match self {
    Null => "null"
    Bool(b) => if b { "true" } else { "false" }
    Int(i) => i.to_string()
    Int64(i) => i.to_string()
    Float(f) => f.to_string()
    String(s) => escape_string(s)
    Array(arr) =>
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { v.to_json_string() })
        "[" + items.join(", ") + "]"
      }
    Object(obj) =>
      if obj.is_empty() {
        "{}"
      } else {
        let items = []
        for k, v in obj {
          items.push(escape_string(k) + ": " + v.to_json_string())
        }
        "{" + items.join(", ") + "}"
      }
  }
}

///|
/// Escape a string for JSON
fn escape_string(s : String) -> String {
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
