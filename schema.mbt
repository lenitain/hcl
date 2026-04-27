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
  if value.is_unknown() {
    return []
  }
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
        Number(n, _) =>
          if n.is_int() {
            []
          } else {
            [HCLError::validation_error(path, "expected int")]
          }
        _ => [HCLError::validation_error(path, "expected int")]
      }
    Int64Schema =>
      match value {
        Number(n, _) =>
          if n.is_int() {
            []
          } else {
            [HCLError::validation_error(path, "expected int64")]
          }
        _ => [HCLError::validation_error(path, "expected int64")]
      }
    FloatSchema =>
      match value {
        Number(n, _) =>
          if n.is_float() {
            []
          } else {
            [HCLError::validation_error(path, "expected float")]
          }
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
/// Schema for extracting structured data from HCL Body
pub struct BodySchema {
  attrs : Map[String, AttrSchema]
  blocks : Map[String, BlockSchema]
  extra_attrs : Bool
  extra_blocks : Bool
} derive(Debug, Eq)

///|
/// Schema for a body attribute
pub struct AttrSchema {
  required : Bool
  type_schema : TypeSchema
} derive(Debug, Eq)

///|
/// Schema for a body block
pub struct BlockSchema {
  required : Bool
  max_items : Int?
  labels : Array[LabelSchema]
  body : BodySchema
} derive(Debug, Eq)

///|
/// Schema for a block label
pub struct LabelSchema {
  required : Bool
} derive(Debug, Eq)

///|
/// Create an empty BodySchema
pub fn BodySchema::new() -> BodySchema {
  { attrs: {}, blocks: {}, extra_attrs: false, extra_blocks: false }
}

///|
/// Set attribute schemas on a BodySchema
pub fn BodySchema::with_attrs(
  self : BodySchema,
  attrs : Map[String, AttrSchema],
) -> BodySchema {
  { ..self, attrs, }
}

///|
/// Set block schemas on a BodySchema
pub fn BodySchema::with_blocks(
  self : BodySchema,
  blocks : Map[String, BlockSchema],
) -> BodySchema {
  { ..self, blocks, }
}

///|
/// Create a required AttrSchema
pub fn AttrSchema::required(type_schema : TypeSchema) -> AttrSchema {
  { required: true, type_schema }
}

///|
/// Create an optional AttrSchema
pub fn AttrSchema::optional(type_schema : TypeSchema) -> AttrSchema {
  { required: false, type_schema }
}

///|
/// Create a new BlockSchema
pub fn BlockSchema::new(body : BodySchema) -> BlockSchema {
  { required: false, max_items: None, labels: [], body }
}

///|
/// Mark an existing block schema as required
pub fn BlockSchema::mark_required(self : BlockSchema) -> BlockSchema {
  { ..self, required: true }
}

///|
/// Set max items for block
pub fn BlockSchema::with_max_items(
  self : BlockSchema,
  max : Int,
) -> BlockSchema {
  { ..self, max_items: Some(max) }
}

///|
/// Set labels for block
pub fn BlockSchema::with_labels(
  self : BlockSchema,
  labels : Array[LabelSchema],
) -> BlockSchema {
  { ..self, labels, }
}

///|
/// Create a required LabelSchema
pub fn LabelSchema::required() -> LabelSchema {
  { required: true }
}

///|
/// Create an optional LabelSchema
pub fn LabelSchema::optional() -> LabelSchema {
  { required: false }
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
      Number(n, _) =>
        match n.as_int() {
          Some(i) if i < min || i > max =>
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

///|
/// Result of extracting structured data from an HCL Body using a BodySchema
pub struct ExtractedBody {
  attrs : Map[String, HCLValue]
  blocks : Map[String, Array[ExtractedBlock]]
  extra_blocks : Array[ExtractedBlock]
} derive(Debug, Eq)

///|
/// A single extracted block with its labels and nested body
pub struct ExtractedBlock {
  labels : Array[String]
  body : ExtractedBody
} derive(Debug, Eq)

///|
/// Create an empty ExtractedBody
pub fn ExtractedBody::new() -> ExtractedBody {
  { attrs: {}, blocks: {}, extra_blocks: [] }
}

///|
/// Get all extra blocks (unknown blocks when extra_blocks=true)
pub fn ExtractedBody::get_extra_blocks(
  self : ExtractedBody,
) -> Array[ExtractedBlock] {
  self.extra_blocks
}

///|
/// Get an attribute value by key
pub fn ExtractedBody::get_attr(self : ExtractedBody, key : String) -> HCLValue? {
  self.attrs.get(key)
}

///|
/// Get all blocks of a given type name
pub fn ExtractedBody::get_blocks(
  self : ExtractedBody,
  type_name : String,
) -> Array[ExtractedBlock] {
  match self.blocks.get(type_name) {
    Some(blocks) => blocks
    None => []
  }
}

///|
/// Get the first block of a given type name
pub fn ExtractedBody::get_block(
  self : ExtractedBody,
  type_name : String,
) -> ExtractedBlock? {
  match self.blocks.get(type_name) {
    Some(blocks) if blocks.length() > 0 => Some(blocks[0])
    _ => None
  }
}

///|
/// Get a label by index from a block
pub fn ExtractedBlock::get_label(self : ExtractedBlock, index : Int) -> String? {
  if index >= 0 && index < self.labels.length() {
    Some(self.labels[index])
  } else {
    None
  }
}

///|
/// Validate block labels against label schemas
fn validate_labels(
  labels : Array[String],
  label_schemas : Array[LabelSchema],
  path : String,
) -> Array[HCLError] {
  let errors = []
  for i in 0..<label_schemas.length() {
    let label_schema = label_schemas[i]
    if label_schema.required && i >= labels.length() {
      errors.push(
        HCLError::validation_error(
          path + "[" + i.to_string() + "]",
          "required label missing",
        ),
      )
    }
  }
  if labels.length() > label_schemas.length() {
    errors.push(
      HCLError::validation_error(
        path,
        "unexpected labels (got " +
        labels.length().to_string() +
        ", expected at most " +
        label_schemas.length().to_string() +
        ")",
      ),
    )
  }
  errors
}

///|
/// Extract structured data from an HCL Body using a BodySchema
pub fn extract_body(
  body : Body,
  schema : BodySchema,
) -> Result[ExtractedBody, Array[HCLError]] {
  extract_body_with_prefix(body, schema, "$")
}

///|
/// Extract structured data with a custom path prefix for error reporting
fn extract_body_with_prefix(
  body : Body,
  schema : BodySchema,
  path_prefix : String,
) -> Result[ExtractedBody, Array[HCLError]] {
  let errors = []
  let attrs : Map[String, HCLValue] = {}
  let blocks : Map[String, Array[ExtractedBlock]] = {}
  let extra_blocks : Array[ExtractedBlock] = []

  for item in body.get_items() {
    match item {
      Attribute(attr) => {
        let key = attr.get_key()
        match schema.attrs.get(key) {
          Some(attr_schema) => {
            let value = expr_to_hcl_value(attr.get_value())
            let validation_errors = validate_at(
              value,
              attr_schema.type_schema,
              path_prefix + "." + key,
            )
            for e in validation_errors {
              errors.push(e)
            }
            attrs[key] = value
          }
          None => {
            if !schema.extra_attrs {
              errors.push(
                HCLError::validation_error(
                  path_prefix + "." + key,
                  "unexpected attribute",
                ),
              )
            }
            attrs[key] = expr_to_hcl_value(attr.get_value())
          }
        }
      }
      Block(block) => {
        let type_name = block.get_type_name()
        match schema.blocks.get(type_name) {
          Some(block_schema) => {
            let block_path = path_prefix + "." + type_name
            let labels = block.get_labels()
            let label_errors = validate_labels(
              labels,
              block_schema.labels,
              block_path,
            )
            for e in label_errors {
              errors.push(e)
            }
            match
              extract_body_with_prefix(
                block.get_body(),
                block_schema.body,
                block_path,
              ) {
              Ok(nested_body) => {
                let extracted = { labels, body: nested_body }
                match blocks.get(type_name) {
                  Some(arr) => {
                    let new_arr = arr.copy()
                    new_arr.push(extracted)
                    blocks[type_name] = new_arr
                  }
                  None => blocks[type_name] = [extracted]
                }
              }
              Err(nested_errors) =>
                for e in nested_errors {
                  errors.push(e)
                }
            }
          }
          None =>
            if !schema.extra_blocks {
              errors.push(
                HCLError::validation_error(
                  path_prefix + "." + type_name,
                  "unexpected block",
                ),
              )
            } else {
              let block_path = path_prefix + "." + type_name
              match
                extract_body_with_prefix(
                  block.get_body(),
                  BodySchema::new(),
                  block_path,
                ) {
                Ok(nested_body) =>
                  extra_blocks.push({
                    labels: block.get_labels(),
                    body: nested_body,
                  })
                Err(nested_errors) =>
                  for e in nested_errors {
                    errors.push(e)
                  }
              }
            }
        }
      }
    }
  }

  for key, attr_schema in schema.attrs {
    if attr_schema.required {
      match attrs.get(key) {
        None =>
          errors.push(
            HCLError::validation_error(
              path_prefix + "." + key,
              "required attribute missing",
            ),
          )
        Some(_) => ()
      }
    }
  }

  for type_name, block_schema in schema.blocks {
    if block_schema.required {
      match blocks.get(type_name) {
        None =>
          errors.push(
            HCLError::validation_error(
              path_prefix + "." + type_name,
              "required block missing",
            ),
          )
        Some(_) => ()
      }
    }
    match block_schema.max_items {
      Some(max) =>
        match blocks.get(type_name) {
          Some(arr) =>
            if arr.length() > max {
              errors.push(
                HCLError::validation_error(
                  path_prefix + "." + type_name,
                  "expected at most " +
                  max.to_string() +
                  " blocks, got " +
                  arr.length().to_string(),
                ),
              )
            }
          None => ()
        }
      None => ()
    }
  }

  if errors.is_empty() {
    Ok({ attrs, blocks, extra_blocks })
  } else {
    Err(errors)
  }
}
