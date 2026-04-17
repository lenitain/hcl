///|
/// Schema validation tests
test "validate any schema" {
  let schema = TypeSchema::any()
  assert_true(is_valid(HCLValue::Null, schema))
  assert_true(is_valid(HCLValue::Int(42), schema))
  assert_true(is_valid(HCLValue::String("hello"), schema))
}

///|
test "validate bool schema" {
  let schema = TypeSchema::bool()
  assert_true(is_valid(HCLValue::Bool(true), schema))
  assert_true(is_valid(HCLValue::Bool(false), schema))
  assert_false(is_valid(HCLValue::Int(1), schema))
  assert_false(is_valid(HCLValue::String("true"), schema))
}

///|
test "validate int schema" {
  let schema = TypeSchema::int()
  assert_true(is_valid(HCLValue::Int(42), schema))
  assert_false(is_valid(HCLValue::Int64(42), schema))
  assert_false(is_valid(HCLValue::Float(3.14), schema))
  assert_false(is_valid(HCLValue::String("42"), schema))
}

///|
test "validate string schema" {
  let schema = TypeSchema::string()
  assert_true(is_valid(HCLValue::String("hello"), schema))
  assert_false(is_valid(HCLValue::Int(42), schema))
}

///|
test "validate array schema" {
  let schema = TypeSchema::array(TypeSchema::int())
  assert_true(
    is_valid(
      HCLValue::Array([HCLValue::Int(1), HCLValue::Int(2), HCLValue::Int(3)]),
      schema,
    ),
  )
  assert_false(
    is_valid(HCLValue::Array([HCLValue::Int(1), HCLValue::String("a")]), schema),
  )
  assert_false(is_valid(HCLValue::Int(42), schema))
}

///|
test "validate object schema" {
  let schema = TypeSchema::object({
    "name": FieldSchema::required(TypeSchema::string()),
    "age": FieldSchema::optional(TypeSchema::int()),
  })
  assert_true(
    is_valid(HCLValue::Object({ "name": HCLValue::String("Alice") }), schema),
  )
  assert_true(
    is_valid(
      HCLValue::Object({
        "name": HCLValue::String("Bob"),
        "age": HCLValue::Int(30),
      }),
      schema,
    ),
  )
  assert_false(is_valid(HCLValue::Object({}), schema))
  assert_false(
    is_valid(HCLValue::Object({ "name": HCLValue::Int(42) }), schema),
  )
}

///|
test "validate returns error path" {
  let schema = TypeSchema::object({
    "user": FieldSchema::required(
      TypeSchema::object({ "name": FieldSchema::required(TypeSchema::string()) }),
    ),
  })
  let errors = validate(
    HCLValue::Object({ "user": HCLValue::Object({}) }),
    schema,
  )
  assert_eq(errors.length(), 1)
  assert_true(errors[0].message().contains("$.user.name"))
}

///|
test "validate nested array" {
  let schema = TypeSchema::array(TypeSchema::array(TypeSchema::int()))
  let value = HCLValue::Array([
    HCLValue::Array([HCLValue::Int(1), HCLValue::Int(2)]),
    HCLValue::Array([HCLValue::Int(3)]),
  ])
  assert_true(is_valid(value, schema))
}

///|
test "validate_one returns first error" {
  let schema = TypeSchema::object({
    "a": FieldSchema::required(TypeSchema::int()),
    "b": FieldSchema::required(TypeSchema::string()),
  })
  let result = validate_one(HCLValue::Object({}), schema)
  assert_true(result is Err(_))
}

///|
test "custom validator - string not empty" {
  let schema = {
    "name": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
      .add_validator(string_not_empty()),
  }
  let errors = validate_ex(HCLValue::Object({"name": HCLValue::String("")}), schema)
  assert_eq(errors.length(), 1)
  assert_true(errors[0].message().contains("must not be empty"))
}

///|
test "custom validator - int in range" {
  let schema = {
    "age": FieldSchemaEx::new(FieldSchema::required(TypeSchema::int()))
      .add_validator(int_in_range(0, 150)),
  }
  assert_eq(validate_ex(HCLValue::Object({"age": HCLValue::Int(25)}), schema).length(), 0)
  assert_eq(validate_ex(HCLValue::Object({"age": HCLValue::Int(-1)}), schema).length(), 1)
  assert_eq(validate_ex(HCLValue::Object({"age": HCLValue::Int(200)}), schema).length(), 1)
}

///|
test "custom validator - string starts with" {
  let schema = {
    "id": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
      .add_validator(string_starts_with("usr_")),
  }
  assert_eq(validate_ex(HCLValue::Object({"id": HCLValue::String("usr_123")}), schema).length(), 0)
  assert_eq(validate_ex(HCLValue::Object({"id": HCLValue::String("abc")}), schema).length(), 1)
}

///|
test "multiple validators" {
  let schema = {
    "name": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
      .add_validator(string_not_empty())
      .add_validator(string_starts_with("A")),
  }
  assert_eq(validate_ex(HCLValue::Object({"name": HCLValue::String("Alice")}), schema).length(), 0)
  assert_eq(validate_ex(HCLValue::Object({"name": HCLValue::String("")}), schema).length(), 2)
}
