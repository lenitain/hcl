///|
/// HCL value types with decoration
pub(all) enum HCLValue {
  /// Null value with decoration
  Null(Decor)
  /// Boolean value with decoration
  Bool(Bool, Decor)
  /// Integer value with decoration
  Int(Int, Decor)
  /// 64-bit integer value with decoration
  Int64(Int64, Decor)
  /// Floating point value with decoration
  Float(Double, Decor)
  /// String value with decoration
  String(String, Decor)
  /// Array of values with decoration
  Array(Array[HCLValue], Decor)
  /// Object (map of string to value) with decoration
  Object(Map[String, HCLValue], Decor)
} derive(Debug, Eq)

///|
/// Get decoration from HCLValue
pub fn HCLValue::get_decor(self : HCLValue) -> Decor {
  match self {
    Null(decor) => decor
    Bool(_, decor) => decor
    Int(_, decor) => decor
    Int64(_, decor) => decor
    Float(_, decor) => decor
    String(_, decor) => decor
    Array(_, decor) => decor
    Object(_, decor) => decor
  }
}

///|
/// Set decoration on HCLValue
pub fn HCLValue::set_decor(self : HCLValue, decor : Decor) -> HCLValue {
  match self {
    Null(_) => Null(decor)
    Bool(b, _) => Bool(b, decor)
    Int(i, _) => Int(i, decor)
    Int64(i, _) => Int64(i, decor)
    Float(f, _) => Float(f, decor)
    String(s, _) => String(s, decor)
    Array(a, _) => Array(a, decor)
    Object(o, _) => Object(o, decor)
  }
}

///|
/// Check if value is null
pub fn HCLValue::is_null(self : HCLValue) -> Bool {
  match self {
    Null(_) => true
    _ => false
  }
}

///|
/// Check if value is a boolean
pub fn HCLValue::is_bool(self : HCLValue) -> Bool {
  match self {
    Bool(_, _) => true
    _ => false
  }
}

///|
/// Check if value is a number (int or float)
pub fn HCLValue::is_number(self : HCLValue) -> Bool {
  match self {
    Int(_, _) | Int64(_, _) | Float(_, _) => true
    _ => false
  }
}

///|
/// Check if value is a string
pub fn HCLValue::is_string(self : HCLValue) -> Bool {
  match self {
    String(_, _) => true
    _ => false
  }
}

///|
/// Check if value is an array
pub fn HCLValue::is_array(self : HCLValue) -> Bool {
  match self {
    Array(_, _) => true
    _ => false
  }
}

///|
/// Check if value is an object
pub fn HCLValue::is_object(self : HCLValue) -> Bool {
  match self {
    Object(_, _) => true
    _ => false
  }
}

///|
/// Get the boolean value, or None if not a bool
pub fn HCLValue::as_bool(self : HCLValue) -> Bool? {
  match self {
    Bool(b, _) => Some(b)
    _ => None
  }
}

///|
/// Get the integer value, or None if not an int
pub fn HCLValue::as_int(self : HCLValue) -> Int? {
  match self {
    Int(i, _) => Some(i)
    _ => None
  }
}

///|
/// Get the int64 value, or None if not an int64
pub fn HCLValue::as_int64(self : HCLValue) -> Int64? {
  match self {
    Int64(i, _) => Some(i)
    _ => None
  }
}

///|
/// Get the float value, or None if not a float
pub fn HCLValue::as_float(self : HCLValue) -> Double? {
  match self {
    Float(f, _) => Some(f)
    _ => None
  }
}

///|
/// Get the string value, or None if not a string
pub fn HCLValue::as_string(self : HCLValue) -> String? {
  match self {
    String(s, _) => Some(s)
    _ => None
  }
}

///|
/// Get the array value, or None if not an array
pub fn HCLValue::as_array(self : HCLValue) -> Array[HCLValue]? {
  match self {
    Array(a, _) => Some(a)
    _ => None
  }
}

///|
/// Get the object value, or None if not an object
pub fn HCLValue::as_object(self : HCLValue) -> Map[String, HCLValue]? {
  match self {
    Object(o, _) => Some(o)
    _ => None
  }
}

///|
/// Create null value with empty decor
pub fn HCLValue::null() -> HCLValue {
  Null(Decor::empty())
}

///|
/// Create bool value with empty decor
pub fn HCLValue::bool(b : Bool) -> HCLValue {
  Bool(b, Decor::empty())
}

///|
/// Create int value with empty decor
pub fn HCLValue::int(i : Int) -> HCLValue {
  Int(i, Decor::empty())
}

///|
/// Create string value with empty decor
pub fn HCLValue::string(s : String) -> HCLValue {
  String(s, Decor::empty())
}

///|
/// Create array value with empty decor
pub fn HCLValue::array(arr : Array[HCLValue]) -> HCLValue {
  Array(arr, Decor::empty())
}

///|
/// Create object value with empty decor
pub fn HCLValue::object(obj : Map[String, HCLValue]) -> HCLValue {
  Object(obj, Decor::empty())
}

///|
/// Convert HCLValue to JSON-compatible string representation
pub fn HCLValue::to_json_string(self : HCLValue) -> String {
  match self {
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Int(i, _) => i.to_string()
    Int64(i, _) => i.to_string()
    Float(f, _) => f.to_string()
    String(s, _) => escape_string(s)
    Array(arr, _) =>
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { v.to_json_string() })
        "[" + items.join(", ") + "]"
      }
    Object(obj, _) =>
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
