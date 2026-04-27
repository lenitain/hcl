///|
/// HCL value types with decoration
pub(all) enum HCLValue {
  /// Null value with decoration
  Null(Decor)
  /// Boolean value with decoration
  Bool(Bool, Decor)
  /// Number value with decoration (int, int64, or float)
  Number(Number, Decor)
  /// String value with decoration
  String(String, Decor)
  /// Array of values with decoration
  Array(Array[HCLValue], Decor)
  /// Object (ordered map of string to value) with decoration
  Object(HCLObject, Decor)
  /// Unknown value (Terraform plan-stage) with decoration
  Unknown(Decor)
} derive(Debug, Eq)

///|
/// Get decoration from HCLValue
pub fn HCLValue::get_decor(self : HCLValue) -> Decor {
  match self {
    Null(decor) => decor
    Bool(_, decor) => decor
    Number(_, decor) => decor
    String(_, decor) => decor
    Array(_, decor) => decor
    Object(_, decor) => decor
    Unknown(decor) => decor
  }
}

///|
/// Set decoration on HCLValue
pub fn HCLValue::set_decor(self : HCLValue, decor : Decor) -> HCLValue {
  match self {
    Null(_) => Null(decor)
    Bool(b, _) => Bool(b, decor)
    Number(n, _) => Number(n, decor)
    String(s, _) => String(s, decor)
    Array(a, _) => Array(a, decor)
    Object(o, _) => Object(o, decor)
    Unknown(_) => Unknown(decor)
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
/// Check if value is a number
pub fn HCLValue::is_number(self : HCLValue) -> Bool {
  match self {
    Number(_, _) => true
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
/// Check if value is unknown (Terraform plan-stage)
pub fn HCLValue::is_unknown(self : HCLValue) -> Bool {
  match self {
    Unknown(_) => true
    _ => false
  }
}

///|
/// Get type name as string
pub fn HCLValue::type_name(self : HCLValue) -> String {
  match self {
    Null(_) => "null"
    Bool(_, _) => "bool"
    Number(_, _) => "number"
    String(_, _) => "string"
    Array(_, _) => "array"
    Object(_, _) => "object"
    Unknown(_) => "unknown"
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
/// Get the Number value, or None if not a number
pub fn HCLValue::as_number(self : HCLValue) -> Number? {
  match self {
    Number(n, _) => Some(n)
    _ => None
  }
}

///|
/// Get the int value, or None if not a number representable as Int
pub fn HCLValue::as_int(self : HCLValue) -> Int? {
  match self {
    Number(n, _) => n.as_int()
    _ => None
  }
}

///|
/// Get the int64 value, or None if not a number representable as Int64
pub fn HCLValue::as_int64(self : HCLValue) -> Int64? {
  match self {
    Number(n, _) => n.as_int64()
    _ => None
  }
}

///|
/// Get the float value, or None if not a number
pub fn HCLValue::as_float(self : HCLValue) -> Double? {
  match self {
    Number(n, _) => Some(n.as_float())
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
pub fn HCLValue::as_object(self : HCLValue) -> HCLObject? {
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
  Number(Number::from_int(i), Decor::empty())
}

///|
/// Create int64 value with empty decor
pub fn HCLValue::int64(i : Int64) -> HCLValue {
  Number(Number::from_int64(i), Decor::empty())
}

///|
/// Create float value with empty decor
pub fn HCLValue::float(f : Double) -> HCLValue {
  Number(Number::from_finite_f64(f), Decor::empty())
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
pub fn HCLValue::object(obj : HCLObject) -> HCLValue {
  Object(obj, Decor::empty())
}

///|
/// Create unknown value with empty decor (Terraform plan-stage)
pub fn HCLValue::unknown() -> HCLValue {
  Unknown(Decor::empty())
}

///|
/// Convert HCLValue to JSON-compatible string representation
pub fn HCLValue::to_json_string(self : HCLValue) -> String {
  match self {
    Null(_) => "null"
    Unknown(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Number(n, _) => n.to_string()
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
