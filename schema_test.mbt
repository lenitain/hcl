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
test "extract_body with blocks" {
  let body = parse(
    "server \"web\" {\n  port = 8080\n}\nserver \"api\" {\n  port = 3000\n}",
  ).unwrap()
  let schema = BodySchema::new().with_blocks({
    "server": BlockSchema::new(
      BodySchema::new().with_attrs({
        "port": AttrSchema::required(TypeSchema::int()),
      }),
    )
    .with_labels([LabelSchema::required()])
    .with_max_items(2),
  })
  let result = extract_body(body, schema)
  match result {
    Ok(extracted) => {
      let servers = extracted.get_blocks("server")
      assert_eq(servers.length(), 2)
      let first = servers[0]
      assert_eq(first.get_label(0), Some("web"))
      assert_true(first.body.get_attr("port") is Some(_))
      let second = servers[1]
      assert_eq(second.get_label(0), Some("api"))
      assert_true(second.body.get_attr("port") is Some(_))
    }
    Err(e) => {
      for err in e {
        println(err.message())
      }
      assert_true(false)
    }
  }
}

///|
test "extract_body nested block error path" {
  let body = parse("server {\n  host = \"localhost\"\n}").unwrap()
  let schema = BodySchema::new().with_blocks({
    "server": BlockSchema::new(
      BodySchema::new().with_attrs({
        "host": AttrSchema::required(TypeSchema::string()),
        "port": AttrSchema::required(TypeSchema::int()),
      }),
    ),
  })
  let result = extract_body(body, schema)
  match result {
    Err(errors) => {
      assert_true(errors.length() > 0)
      let found = errors.any(fn(e) {
        match e {
          ValidationError(path, _) => path == "$.server.port"
          _ => false
        }
      })
      assert_true(found)
    }
    Ok(_) => assert_true(false)
  }
}

///|
test "from_hcl_with_body_schema" {
  let input = "name = \"test\"\nserver {\n  port = 8080\n}"
  let schema = BodySchema::new()
    .with_attrs({ "name": AttrSchema::required(TypeSchema::string()) })
    .with_blocks({
      "server": BlockSchema::new(
        BodySchema::new().with_attrs({
          "port": AttrSchema::required(TypeSchema::int()),
        }),
      ),
    })
  let result = from_hcl_with_body_schema(input, schema)
  match result {
    Ok(extracted) => {
      match extracted.get_attr("name") {
        Some(HCLValue::String(s, _)) => assert_eq(s, "test")
        _ => assert_true(false)
      }
      let server = extracted.get_block("server")
      assert_true(server is Some(_))
      match server {
        Some(s) => assert_true(s.body.get_attr("port") is Some(_))
        None => assert_true(false)
      }
    }
    Err(e) => {
      for err in e {
        println(err.message())
      }
      assert_true(false)
    }
  }
}

///|
test "from_hcl_with_body_schema - parse error" {
  let input = "name = "
  let schema = BodySchema::new()
  let result = from_hcl_with_body_schema(input, schema)
  assert_true(result is Err(_))
}

///|
test "from_hcl_with_body_schema_full - multiple errors" {
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

///|
test "extract_body missing required attr" {
  let body = parse("name = \"test\"").unwrap()
  let schema = BodySchema::new().with_attrs({
    "name": AttrSchema::required(TypeSchema::string()),
    "port": AttrSchema::required(TypeSchema::int()),
  })
  let result = extract_body(body, schema)
  match result {
    Err(errors) => {
      assert_true(errors.length() > 0)
      let found = errors.any(fn(e) {
        match e {
          ValidationError(path, msg) =>
            path == "$.port" && msg == "required attribute missing"
          _ => false
        }
      })
      assert_true(found)
    }
    Ok(_) => assert_true(false)
  }
}

///|
test "extract_body extra_attrs false" {
  let body = parse("name = \"test\"\nunknown = 42").unwrap()
  let schema = BodySchema::new().with_attrs({
    "name": AttrSchema::required(TypeSchema::string()),
  })
  let result = extract_body(body, schema)
  match result {
    Err(errors) => {
      let found = errors.any(fn(e) {
        match e {
          ValidationError(path, msg) =>
            path == "$.unknown" && msg == "unexpected attribute"
          _ => false
        }
      })
      assert_true(found)
    }
    Ok(_) => assert_true(false)
  }
}

///|
test "extract_body nested blocks" {
  let body = parse("server \"web\" {\n  location {\n    path = \"/\"\n  }\n}").unwrap()
  let schema = BodySchema::new().with_blocks({
    "server": BlockSchema::new(
      BodySchema::new().with_blocks({
        "location": BlockSchema::new(
          BodySchema::new().with_attrs({
            "path": AttrSchema::required(TypeSchema::string()),
          }),
        ),
      }),
    ).with_labels([LabelSchema::required()]),
  })
  let result = extract_body(body, schema)
  match result {
    Ok(extracted) => {
      let servers = extracted.get_blocks("server")
      assert_eq(servers.length(), 1)
      let server = servers[0]
      assert_eq(server.get_label(0), Some("web"))
      let locations = server.body.get_blocks("location")
      assert_eq(locations.length(), 1)
      match locations[0].body.get_attr("path") {
        Some(HCLValue::String(s, _)) => assert_eq(s, "/")
        _ => assert_true(false)
      }
    }
    Err(e) => {
      for err in e {
        println(err.message())
      }
      assert_true(false)
    }
  }
}

///|
test "extract_body block max_items exceeded" {
  let body = parse(
    "server \"a\" {\n  port = 1\n}\nserver \"b\" {\n  port = 2\n}\nserver \"c\" {\n  port = 3\n}",
  ).unwrap()
  let schema = BodySchema::new().with_blocks({
    "server": BlockSchema::new(
      BodySchema::new().with_attrs({
        "port": AttrSchema::required(TypeSchema::int()),
      }),
    )
    .with_labels([LabelSchema::required()])
    .with_max_items(2),
  })
  let result = extract_body(body, schema)
  match result {
    Err(errors) => {
      let found = errors.any(fn(e) {
        match e {
          ValidationError(path, msg) =>
            path == "$.server" && msg.contains("expected at most 2")
          _ => false
        }
      })
      assert_true(found)
    }
    Ok(_) => assert_true(false)
  }
}

///|
test "extract_body optional attr" {
  let body = parse("name = \"test\"").unwrap()
  let schema = BodySchema::new().with_attrs({
    "name": AttrSchema::required(TypeSchema::string()),
    "port": AttrSchema::optional(TypeSchema::int()),
  })
  let result = extract_body(body, schema)
  match result {
    Ok(extracted) => {
      match extracted.get_attr("name") {
        Some(HCLValue::String(s, _)) => assert_eq(s, "test")
        _ => assert_true(false)
      }
      assert_true(extracted.get_attr("port") is None)
    }
    Err(_) => assert_true(false)
  }
}
