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
