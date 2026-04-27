///|
/// HCL Type Unification Lattice
/// Implements type compatibility rules per HCL spec for conditional expressions

///|
/// HCL type categories for unification
pub(all) enum TypeName {
  TNull
  TBool
  TNumber
  TString
  TArray
  TObject
  TUnknown
} derive(Debug, Eq)

///|
/// Get the TypeName for a given HCLValue
pub fn type_of(v : HCLValue) -> TypeName {
  match v {
    Null(_) => TNull
    Bool(_, _) => TBool
    Number(_, _) => TNumber
    String(_, _) => TString
    Array(_, _) => TArray
    Object(_, _) => TObject
    Unknown(_) => TUnknown
  }
}

///|
/// Find the common type for two types per HCL spec rules
pub fn unify_types(a : TypeName, b : TypeName) -> HCLResult[TypeName] {
  match (a, b) {
    (x, y) if x == y => Ok(x)
    (TNull, x) | (x, TNull) => Ok(x)
    (TUnknown, _) | (_, TUnknown) => Ok(TUnknown)
    (TNumber, TString) | (TString, TNumber) => Ok(TString)
    (TBool, TString) | (TString, TBool) => Ok(TString)
    (TNumber, TBool) | (TBool, TNumber) =>
      Err(
        HCLError::type_error("Incompatible types: cannot unify number and bool"),
      )
    (TArray, _) | (_, TArray) =>
      Err(
        HCLError::type_error(
          "Incompatible types: cannot unify " +
          type_name_str(a) +
          " and " +
          type_name_str(b),
        ),
      )
    (TObject, _) | (_, TObject) =>
      Err(
        HCLError::type_error(
          "Incompatible types: cannot unify " +
          type_name_str(a) +
          " and " +
          type_name_str(b),
        ),
      )
    _ =>
      Err(
        HCLError::type_error(
          "Incompatible types: cannot unify " +
          type_name_str(a) +
          " and " +
          type_name_str(b),
        ),
      )
  }
}

///|
/// Get human-readable name for TypeName
fn type_name_str(t : TypeName) -> String {
  match t {
    TNull => "null"
    TBool => "bool"
    TNumber => "number"
    TString => "string"
    TArray => "array"
    TObject => "object"
    TUnknown => "unknown"
  }
}

///|
/// Convert a value to the target type per HCL conversion rules
pub fn convert_value(v : HCLValue, target : TypeName) -> HCLResult[HCLValue] {
  let current = type_of(v)
  if current == target {
    return Ok(v)
  }
  match (current, target) {
    (TNull, _) => Ok(v)
    (TUnknown, _) => Ok(v)
    (_, TUnknown) => Ok(v)
    (TNumber, TString) =>
      match v {
        Number(n, _) => Ok(String(n.to_string(), Decor::empty()))
        _ => Err(HCLError::type_error("Expected number value"))
      }
    (TBool, TString) =>
      match v {
        Bool(b, _) =>
          Ok(String(if b { "true" } else { "false" }, Decor::empty()))
        _ => Err(HCLError::type_error("Expected bool value"))
      }
    _ =>
      Err(
        HCLError::type_error(
          "Cannot convert " +
          type_name_str(current) +
          " to " +
          type_name_str(target),
        ),
      )
  }
}
