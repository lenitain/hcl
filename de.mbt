///|
/// HCL Deserialization - convert HCL to MoonBit types

///|
/// Deserialize from HCL string to Int
pub fn from_hcl_int(input : String) -> Result[Int, HCLError] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      match value {
        Number(n, _) =>
          match n.as_int() {
            Some(i) => Ok(i)
            None =>
              Err(HCLError::type_mismatch("Int", value_to_type_name(value)))
          }
        _ => Err(HCLError::type_mismatch("Int", value_to_type_name(value)))
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Deserialize from HCL string to String
pub fn from_hcl_string(input : String) -> Result[String, HCLError] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      match value {
        String(s, _) => Ok(s)
        _ => Err(HCLError::type_mismatch("String", value_to_type_name(value)))
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Deserialize from HCL string to Bool
pub fn from_hcl_bool(input : String) -> Result[Bool, HCLError] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      match value {
        Bool(b, _) => Ok(b)
        _ => Err(HCLError::type_mismatch("Bool", value_to_type_name(value)))
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Deserialize from HCL string to HCLValue
pub fn from_hcl_value(input : String) -> Result[HCLValue, HCLError] {
  match parse(input) {
    Ok(body) => Ok(body_to_value(body))
    Err(e) => Err(e)
  }
}

///|
/// Deserialize from HCL string to Body
pub fn from_hcl_body(input : String) -> Result[Body, HCLError] {
  parse(input)
}

///|
/// Convert Body to HCLValue
fn body_to_value(body : Body) -> HCLValue {
  let obj = {}
  for item in body.get_items() {
    match item {
      Attribute(attr) =>
        obj[attr.get_key()] = expr_to_hcl_value(attr.get_value())
      Block(block) => {
        let block_obj = body_to_value(block.get_body())
        obj[block.get_type_name()] = block_obj
      }
    }
  }
  Object(obj, Decor::empty())
}

///|
/// Deserialize HCL with schema validation
pub fn from_hcl_with_schema(
  input : String,
  schema : TypeSchema,
) -> HCLResult[HCLValue] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      let errors = validate(value, schema)
      if errors.is_empty() {
        Ok(value)
      } else {
        Err(errors[0])
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Deserialize HCL with schema, return all errors
pub fn from_hcl_with_schema_full(
  input : String,
  schema : TypeSchema,
) -> Result[HCLValue, Array[HCLError]] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      let errors = validate(value, schema)
      if errors.is_empty() {
        Ok(value)
      } else {
        Err(errors)
      }
    }
    Err(e) => Err([e])
  }
}

///|
/// Get type name for error messages
fn value_to_type_name(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(_, _) => "bool"
    Number(_, _) => "number"
    String(_, _) => "string"
    Array(_, _) => "array"
    Object(_, _) => "object"
  }
}
