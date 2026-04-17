///|
/// Trait for converting MoonBit types to HCLValue
pub trait ToHCL {
  to_hcl(Self) -> HCLValue
}

///|
/// Trait for converting HCLValue to MoonBit types
pub trait FromHCL {
  from_hcl(HCLValue) -> HCLResult[Self]
}

///|
/// Get type name for error messages
fn type_name_of(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(_, _) => "bool"
    Int(_, _) => "int"
    Int64(_, _) => "int64"
    Float(_, _) => "float"
    String(_, _) => "string"
    Array(_, _) => "array"
    Object(_, _) => "object"
  }
}

///|
/// Convert any ToHCL type to HCL string
pub fn[T : ToHCL] to_hcl_str(value : T) -> String {
  format_hcl_value(value.to_hcl(), 0)
}

///|
/// Parse HCL string to any FromHCL type
pub fn[T : FromHCL] from_hcl_str(input : String) -> HCLResult[T] {
  match parse(input) {
    Ok(body) => T::from_hcl(body_to_value(body))
    Err(e) => Err(e)
  }
}

///|
/// ToHCL implementation for HCLValue (identity)
impl ToHCL for HCLValue with to_hcl(self) {
  self
}

///|
/// FromHCL implementation for HCLValue (identity)
impl FromHCL for HCLValue with from_hcl(value) {
  Ok(value)
}

///|
/// ToHCL implementation for Int
impl ToHCL for Int with to_hcl(self) {
  Int(self, Decor::empty())
}

///|
/// FromHCL implementation for Int
impl FromHCL for Int with from_hcl(value) {
  match value {
    Int(i, _) => Ok(i)
    _ => Err(HCLError::type_mismatch("Int", type_name_of(value)))
  }
}

///|
/// ToHCL implementation for Int64
impl ToHCL for Int64 with to_hcl(self) {
  Int64(self, Decor::empty())
}

///|
/// FromHCL implementation for Int64
impl FromHCL for Int64 with from_hcl(value) {
  match value {
    Int64(i, _) => Ok(i)
    Int(i, _) => Ok(i.to_int64())
    _ => Err(HCLError::type_mismatch("Int64", type_name_of(value)))
  }
}

///|
/// ToHCL implementation for Double
impl ToHCL for Double with to_hcl(self) {
  Float(self, Decor::empty())
}

///|
/// FromHCL implementation for Double
impl FromHCL for Double with from_hcl(value) {
  match value {
    Float(f, _) => Ok(f)
    Int(i, _) => Ok(i.to_double())
    Int64(i, _) => Ok(i.to_double())
    _ => Err(HCLError::type_mismatch("Double", type_name_of(value)))
  }
}

///|
/// ToHCL implementation for Bool
impl ToHCL for Bool with to_hcl(self) {
  Bool(self, Decor::empty())
}

///|
/// FromHCL implementation for Bool
impl FromHCL for Bool with from_hcl(value) {
  match value {
    Bool(b, _) => Ok(b)
    _ => Err(HCLError::type_mismatch("Bool", type_name_of(value)))
  }
}

///|
/// ToHCL implementation for String
impl ToHCL for String with to_hcl(self) {
  String(self, Decor::empty())
}

///|
/// FromHCL implementation for String
impl FromHCL for String with from_hcl(value) {
  match value {
    String(s, _) => Ok(s)
    _ => Err(HCLError::type_mismatch("String", type_name_of(value)))
  }
}

///|
/// ToHCL implementation for Option
impl[T : ToHCL] ToHCL for T? with to_hcl(self) {
  match self {
    Some(v) => v.to_hcl()
    None => Null(Decor::empty())
  }
}

///|
/// FromHCL implementation for Option
impl[T : FromHCL] FromHCL for T? with from_hcl(value) {
  match value {
    Null(_) => Ok(None)
    _ =>
      match T::from_hcl(value) {
        Ok(v) => Ok(Some(v))
        Err(e) => Err(e)
      }
  }
}

///|
/// ToHCL implementation for Array
impl[T : ToHCL] ToHCL for Array[T] with to_hcl(self) {
  let items = self.map(fn(v) { v.to_hcl() })
  Array(items, Decor::empty())
}

///|
/// FromHCL implementation for Array
impl[T : FromHCL] FromHCL for Array[T] with from_hcl(value) {
  match value {
    Array(arr, _) => {
      let result = []
      for v in arr {
        match T::from_hcl(v) {
          Ok(item) => result.push(item)
          Err(e) => return Err(e)
        }
      }
      Ok(result)
    }
    _ => Err(HCLError::type_mismatch("Array", type_name_of(value)))
  }
}

///|
/// ToHCL implementation for Map
impl[T : ToHCL] ToHCL for Map[String, T] with to_hcl(self) {
  let obj = {}
  for k, v in self {
    obj[k] = v.to_hcl()
  }
  Object(obj, Decor::empty())
}

///|
/// FromHCL implementation for Map
impl[T : FromHCL] FromHCL for Map[String, T] with from_hcl(value) {
  match value {
    Object(obj, _) => {
      let result = {}
      for k, v in obj {
        match T::from_hcl(v) {
          Ok(item) => result[k] = item
          Err(e) => return Err(e)
        }
      }
      Ok(result)
    }
    _ => Err(HCLError::type_mismatch("Object", type_name_of(value)))
  }
}
