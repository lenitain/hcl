///|
/// HCL Schema - type definitions for validation

///|
/// Schema for validating HCL values
pub(all) enum TypeSchema {
  /// Any value is accepted
  Any
  /// Null value
  NullSchema
  /// Boolean value
  BoolSchema
  /// Integer value
  IntSchema
  /// 64-bit integer
  Int64Schema
  /// Float value
  FloatSchema
  /// Number (int or float)
  NumberSchema
  /// String value
  StringSchema
  /// Array with element schema
  ArraySchema(TypeSchema)
  /// Object with field schemas
  ObjectSchema(Map[String, FieldSchema])
} derive(Debug, Eq)

///|
/// Schema for an object field
pub struct FieldSchema {
  /// Field type schema
  schema : TypeSchema
  /// Whether field is required
  required : Bool
  /// Optional description
  description : String
} derive(Debug, Eq)

///|
/// Create a required field schema
pub fn FieldSchema::required(schema : TypeSchema) -> FieldSchema {
  { schema, required: true, description: "" }
}

///|
/// Create an optional field schema
pub fn FieldSchema::optional(schema : TypeSchema) -> FieldSchema {
  { schema, required: false, description: "" }
}

///|
/// Create a field schema with description
pub fn FieldSchema::with_description(
  self : FieldSchema,
  desc : String,
) -> FieldSchema {
  { ..self, description: desc }
}

///|
/// Schema for any value
pub fn TypeSchema::any() -> TypeSchema {
  Any
}

///|
/// Schema for null
pub fn TypeSchema::null() -> TypeSchema {
  NullSchema
}

///|
/// Schema for boolean
pub fn TypeSchema::bool() -> TypeSchema {
  BoolSchema
}

///|
/// Schema for integer
pub fn TypeSchema::int() -> TypeSchema {
  IntSchema
}

///|
/// Schema for 64-bit integer
pub fn TypeSchema::int64() -> TypeSchema {
  Int64Schema
}

///|
/// Schema for float
pub fn TypeSchema::float() -> TypeSchema {
  FloatSchema
}

///|
/// Schema for number (int or float)
pub fn TypeSchema::number() -> TypeSchema {
  NumberSchema
}

///|
/// Schema for string
pub fn TypeSchema::string() -> TypeSchema {
  StringSchema
}

///|
/// Schema for array
pub fn TypeSchema::array(element : TypeSchema) -> TypeSchema {
  ArraySchema(element)
}

///|
/// Schema for object
pub fn TypeSchema::object(fields : Map[String, FieldSchema]) -> TypeSchema {
  ObjectSchema(fields)
}

///|
/// Validate a value against a schema
pub fn validate(value : HCLValue, schema : TypeSchema) -> Array[HCLError] {
  validate_at(value, schema, "$")
}

///|
/// Validate with path tracking
fn validate_at(
  value : HCLValue,
  schema : TypeSchema,
  path : String,
) -> Array[HCLError] {
  match schema {
    Any => []
    NullSchema =>
      if value.is_null() {
        []
      } else {
        [HCLError::validation_error(path, "expected null")]
      }
    BoolSchema =>
      if value.is_bool() {
        []
      } else {
        [HCLError::validation_error(path, "expected bool")]
      }
    IntSchema =>
      match value {
        Int(_, _) => []
        _ => [HCLError::validation_error(path, "expected int")]
      }
    Int64Schema =>
      match value {
        Int64(_, _) => []
        _ => [HCLError::validation_error(path, "expected int64")]
      }
    FloatSchema =>
      match value {
        Float(_, _) => []
        _ => [HCLError::validation_error(path, "expected float")]
      }
    NumberSchema =>
      if value.is_number() {
        []
      } else {
        [HCLError::validation_error(path, "expected number")]
      }
    StringSchema =>
      if value.is_string() {
        []
      } else {
        [HCLError::validation_error(path, "expected string")]
      }
    ArraySchema(elem_schema) => validate_array(value, elem_schema, path)
    ObjectSchema(field_schemas) => validate_object(value, field_schemas, path)
  }
}

///|
/// Validate array value
fn validate_array(
  value : HCLValue,
  elem_schema : TypeSchema,
  path : String,
) -> Array[HCLError] {
  match value {
    Array(arr, _) => {
      let errors = []
      for i in 0..<arr.length() {
        let elem_path = path + "[" + i.to_string() + "]"
        let elem_errors = validate_at(arr[i], elem_schema, elem_path)
        for e in elem_errors {
          errors.push(e)
        }
      }
      errors
    }
    _ => [HCLError::validation_error(path, "expected array")]
  }
}

///|
/// Validate object value
fn validate_object(
  value : HCLValue,
  field_schemas : Map[String, FieldSchema],
  path : String,
) -> Array[HCLError] {
  match value {
    Object(obj, _) => {
      let errors = []
      for name, field_schema in field_schemas {
        let field_path = path + "." + name
        match obj.get(name) {
          Some(field_value) => {
            let field_errors = validate_at(
              field_value,
              field_schema.schema,
              field_path,
            )
            for e in field_errors {
              errors.push(e)
            }
          }
          None =>
            if field_schema.required {
              errors.push(
                HCLError::validation_error(field_path, "required field missing"),
              )
            }
        }
      }
      errors
    }
    _ => [HCLError::validation_error(path, "expected object")]
  }
}

///|
/// Validate and return first error, or Ok
pub fn validate_one(value : HCLValue, schema : TypeSchema) -> HCLResult[Unit] {
  let errors = validate(value, schema)
  if errors.is_empty() {
    Ok(())
  } else {
    Err(errors[0])
  }
}

///|
/// Check if value is valid
pub fn is_valid(value : HCLValue, schema : TypeSchema) -> Bool {
  validate(value, schema).is_empty()
}

///|
/// Custom validator function type
pub type Validator = (HCLValue, String) -> Array[HCLError]

///|
/// Extended field schema with custom validators
pub struct FieldSchemaEx {
  /// Base field schema
  base : FieldSchema
  /// Custom validators
  validators : Array[Validator]
}

///|
/// Create extended field schema
pub fn FieldSchemaEx::new(base : FieldSchema) -> FieldSchemaEx {
  { base, validators: [] }
}

///|
/// Add validator to field schema
pub fn FieldSchemaEx::add_validator(
  self : FieldSchemaEx,
  v : Validator,
) -> FieldSchemaEx {
  let vs = self.validators.copy()
  vs.push(v)
  { ..self, validators: vs }
}

///|
/// Validate with custom validators
pub fn validate_ex(
  value : HCLValue,
  schema : Map[String, FieldSchemaEx],
) -> Array[HCLError] {
  validate_object_ex(value, schema, "$")
}

///|
/// Validate object with extended field schemas
fn validate_object_ex(
  value : HCLValue,
  field_schemas : Map[String, FieldSchemaEx],
  path : String,
) -> Array[HCLError] {
  match value {
    Object(obj, _) => {
      let errors = []
      for name, field_schema in field_schemas {
        let field_path = path + "." + name
        match obj.get(name) {
          Some(field_value) => {
            // Base validation
            let base_errors = validate_at(
              field_value,
              field_schema.base.schema,
              field_path,
            )
            for e in base_errors {
              errors.push(e)
            }
            // Custom validators
            for v in field_schema.validators {
              let custom_errors = v(field_value, field_path)
              for e in custom_errors {
                errors.push(e)
              }
            }
          }
          None =>
            if field_schema.base.required {
              errors.push(
                HCLError::validation_error(field_path, "required field missing"),
              )
            }
        }
      }
      errors
    }
    _ => [HCLError::validation_error(path, "expected object")]
  }
}

///|
/// Validator: string not empty
pub fn string_not_empty() -> Validator {
  fn(value, path) {
    match value {
      String(s, _) if s.is_empty() =>
        [HCLError::validation_error(path, "string must not be empty")]
      _ => []
    }
  }
}

///|
/// Validator: int in range
pub fn int_in_range(min : Int, max : Int) -> Validator {
  fn(value, path) {
    match value {
      Int(i, _) if i < min || i > max =>
        [
          HCLError::validation_error(
            path,
            "value " +
            i.to_string() +
            " not in range [" +
            min.to_string() +
            ", " +
            max.to_string() +
            "]",
          ),
        ]
      _ => []
    }
  }
}

///|
/// Validator: string matches pattern (simple prefix/suffix check)
pub fn string_starts_with(prefix : String) -> Validator {
  fn(value, path) {
    match value {
      String(s, _) if !s.has_prefix(prefix) =>
        [HCLError::validation_error(path, "string must start with " + prefix)]
      _ => []
    }
  }
}
