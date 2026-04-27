///|
/// Schema validation tests
test "validate any schema" {
  let schema = TypeSchema::any()
  assert_true(is_valid(HCLValue::Null(Decor::empty()), schema))
  assert_true(
    is_valid(HCLValue::Number(Number::from_int(42), Decor::empty()), schema),
  )
  assert_true(is_valid(HCLValue::String("hello", Decor::empty()), schema))
}

///|
test "validate bool schema" {
  let schema = TypeSchema::bool()
  assert_true(is_valid(HCLValue::Bool(true, Decor::empty()), schema))
  assert_true(is_valid(HCLValue::Bool(false, Decor::empty()), schema))
  assert_false(
    is_valid(HCLValue::Number(Number::from_int(1), Decor::empty()), schema),
  )
  assert_false(is_valid(HCLValue::String("true", Decor::empty()), schema))
}

///|
test "validate int schema" {
  let schema = TypeSchema::int()
  assert_true(
    is_valid(HCLValue::Number(Number::from_int(42), Decor::empty()), schema),
  )
  assert_true(
    is_valid(HCLValue::Number(Number::from_int64(42), Decor::empty()), schema),
  )
  assert_false(
    is_valid(
      HCLValue::Number(Number::from_finite_f64(3.14), Decor::empty()),
      schema,
    ),
  )
  assert_false(is_valid(HCLValue::String("42", Decor::empty()), schema))
}

///|
test "validate string schema" {
  let schema = TypeSchema::string()
  assert_true(is_valid(HCLValue::String("hello", Decor::empty()), schema))
  assert_false(
    is_valid(HCLValue::Number(Number::from_int(42), Decor::empty()), schema),
  )
}

///|
test "validate array schema" {
  let schema = TypeSchema::array(TypeSchema::int())
  assert_true(
    is_valid(
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
      schema,
    ),
  )
  assert_false(
    is_valid(
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::String("a", Decor::empty()),
        ],
        Decor::empty(),
      ),
      schema,
    ),
  )
  assert_false(
    is_valid(HCLValue::Number(Number::from_int(42), Decor::empty()), schema),
  )
}

///|
test "validate object schema" {
  let schema = TypeSchema::object({
    "name": FieldSchema::required(TypeSchema::string()),
    "age": FieldSchema::optional(TypeSchema::int()),
  })
  assert_true(
    is_valid(
      HCLValue::Object(
        { "name": HCLValue::String("Alice", Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ),
  )
  assert_true(
    is_valid(
      HCLValue::Object(
        {
          "name": HCLValue::String("Bob", Decor::empty()),
          "age": HCLValue::Number(Number::from_int(30), Decor::empty()),
        },
        Decor::empty(),
      ),
      schema,
    ),
  )
  assert_false(is_valid(HCLValue::Object({}, Decor::empty()), schema))
  assert_false(
    is_valid(
      HCLValue::Object(
        { "name": HCLValue::Number(Number::from_int(42), Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ),
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
    HCLValue::Object(
      { "user": HCLValue::Object({}, Decor::empty()) },
      Decor::empty(),
    ),
    schema,
  )
  assert_eq(errors.length(), 1)
  assert_true(errors[0].message().contains("$.user.name"))
}

///|
test "validate nested array" {
  let schema = TypeSchema::array(TypeSchema::array(TypeSchema::int()))
  let value = HCLValue::Array(
    [
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Array(
        [HCLValue::Number(Number::from_int(3), Decor::empty())],
        Decor::empty(),
      ),
    ],
    Decor::empty(),
  )
  assert_true(is_valid(value, schema))
}

///|
test "validate_one returns first error" {
  let schema = TypeSchema::object({
    "a": FieldSchema::required(TypeSchema::int()),
    "b": FieldSchema::required(TypeSchema::string()),
  })
  let result = validate_one(HCLValue::Object({}, Decor::empty()), schema)
  assert_true(result is Err(_))
}

///|
test "custom validator - string not empty" {
  let schema = {
    "name": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string())).add_validator(
      string_not_empty(),
    ),
  }
  let errors = validate_ex(
    HCLValue::Object(
      { "name": HCLValue::String("", Decor::empty()) },
      Decor::empty(),
    ),
    schema,
  )
  assert_eq(errors.length(), 1)
  assert_true(errors[0].message().contains("must not be empty"))
}

///|
test "custom validator - int in range" {
  let schema = {
    "age": FieldSchemaEx::new(FieldSchema::required(TypeSchema::int())).add_validator(
      int_in_range(0, 150),
    ),
  }
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "age": HCLValue::Number(Number::from_int(25), Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    0,
  )
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "age": HCLValue::Number(Number::from_int(-1), Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    1,
  )
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "age": HCLValue::Number(Number::from_int(200), Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    1,
  )
}

///|
test "custom validator - string starts with" {
  let schema = {
    "id": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string())).add_validator(
      string_starts_with("usr_"),
    ),
  }
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "id": HCLValue::String("usr_123", Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    0,
  )
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "id": HCLValue::String("abc", Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    1,
  )
}

///|
test "multiple validators" {
  let schema = {
    "name": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
    .add_validator(string_not_empty())
    .add_validator(string_starts_with("A")),
  }
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "name": HCLValue::String("Alice", Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    0,
  )
  assert_eq(
    validate_ex(
      HCLValue::Object(
        { "name": HCLValue::String("", Decor::empty()) },
        Decor::empty(),
      ),
      schema,
    ).length(),
    2,
  )
}

///|
test "from_hcl_with_schema - valid config" {
  let hcl = "server {\n  host = \"localhost\"\n  port = 8080\n}"
  let schema = TypeSchema::object({
    "server": FieldSchema::required(
      TypeSchema::object({
        "host": FieldSchema::required(TypeSchema::string()),
        "port": FieldSchema::required(TypeSchema::int()),
      }),
    ),
  })
  let result = from_hcl_with_schema(hcl, schema)
  assert_true(result is Ok(_))
}

///|
test "from_hcl_with_schema - invalid config" {
  let hcl = "server {\n  host = \"localhost\"\n}"
  let schema = TypeSchema::object({
    "server": FieldSchema::required(
      TypeSchema::object({
        "host": FieldSchema::required(TypeSchema::string()),
        "port": FieldSchema::required(TypeSchema::int()),
      }),
    ),
  })
  let result = from_hcl_with_schema(hcl, schema)
  assert_true(result is Err(_))
}

///|
test "extract_body with simple attrs" {
  let body = parse("name = \"test\"\ncount = 42").unwrap()
  let schema = BodySchema::new().with_attrs({
    "name": AttrSchema::required(TypeSchema::string()),
    "count": AttrSchema::required(TypeSchema::int()),
  })
  let result = extract_body(body, schema)
  assert_true(result is Ok(_))
  match result {
    Ok(extracted) => {
      assert_true(extracted.get_attr("name") is Some(_))
      assert_true(extracted.get_attr("count") is Some(_))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "from_hcl_with_schema_full - multiple errors" {
  let hcl = "config {\n}"
  let schema = TypeSchema::object({
    "config": FieldSchema::required(
      TypeSchema::object({
        "name": FieldSchema::required(TypeSchema::string()),
        "value": FieldSchema::required(TypeSchema::int()),
      }),
    ),
  })
  let result = from_hcl_with_schema_full(hcl, schema)
  match result {
    Err(errors) => assert_eq(errors.length(), 2)
    _ => assert_true(false)
  }
}
