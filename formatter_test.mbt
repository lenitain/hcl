///|
/// Tests for FormatConfig and Formatter
test "FormatConfig default values" {
  let config = FormatConfig::default()
  assert_eq(config.indent, "  ")
  assert_eq(config.dense, false)
  assert_eq(config.compact_arrays, false)
  assert_eq(config.compact_objects, false)
  assert_eq(config.prefer_ident_keys, false)
}

///|
test "FormatConfig compact preset" {
  let config = FormatConfig::compact()
  assert_eq(config.dense, true)
  assert_eq(config.compact_arrays, true)
  assert_eq(config.compact_objects, true)
  assert_eq(config.prefer_ident_keys, true)
}

///|
test "FormatConfig dense preset" {
  let config = FormatConfig::dense()
  assert_eq(config.dense, true)
  assert_eq(config.compact_arrays, false)
  assert_eq(config.compact_objects, false)
  assert_eq(config.prefer_ident_keys, false)
}

///|
test "Formatter builder pattern" {
  let fmt = Formatter::new()
    .set_indent("    ")
    .set_dense(true)
    .set_compact_arrays(true)
    .set_prefer_ident_keys(true)
  let config = fmt.get_config()
  assert_eq(config.indent, "    ")
  assert_eq(config.dense, true)
  assert_eq(config.compact_arrays, true)
  assert_eq(config.prefer_ident_keys, true)
}

///|
test "formatter default matches format_hcl_value" {
  let value = HCLValue::array([hcl_int(1), hcl_int(2), hcl_int(3)])
  let fmt = Formatter::new()
  let result = fmt.format_value(value)
  // Default: multi-line array
  assert_true(result.contains("[\n"))
  assert_true(result.contains("1"))
  assert_true(result.contains("2"))
  assert_true(result.contains("3"))
}

///|
test "formatter compact array" {
  let value = HCLValue::array([hcl_int(1), hcl_int(2), hcl_int(3)])
  let fmt = Formatter::new().set_compact_arrays(true)
  let result = fmt.format_value(value)
  assert_eq(result, "[1, 2, 3]")
}

///|
test "formatter compact object" {
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = hcl_int(1)
  obj["b"] = hcl_int(2)
  let value = HCLValue::Object(obj, Decor::empty())
  let fmt = Formatter::new()
    .set_compact_objects(true)
    .set_prefer_ident_keys(true)
  let result = fmt.format_value(value)
  // compact: { a = 1, b = 2 }
  assert_true(result.has_prefix("{ "))
  assert_true(result.has_suffix(" }"))
  assert_true(result.contains(", "))
}

///|
test "formatter compact object with prefer_ident_keys" {
  let obj : Map[String, HCLValue] = Map::new()
  obj["host"] = hcl_str("localhost")
  obj["port"] = hcl_int(8080)
  let value = HCLValue::Object(obj, Decor::empty())
  let fmt = Formatter::new()
    .set_compact_objects(true)
    .set_prefer_ident_keys(true)
  let result = fmt.format_value(value)
  // Should use unquoted keys
  assert_true(result.contains("host = "))
  assert_true(result.contains("port = "))
  assert_false(result.contains("\"host\""))
  assert_false(result.contains("\"port\""))
}

///|
test "formatter prefer_ident_keys quotes invalid identifiers" {
  let obj : Map[String, HCLValue] = Map::new()
  obj["valid-key"] = hcl_int(1)
  obj["invalid key!"] = hcl_int(2)
  let value = HCLValue::Object(obj, Decor::empty())
  let fmt = Formatter::new()
    .set_compact_objects(true)
    .set_prefer_ident_keys(true)
  let result = fmt.format_value(value)
  // "valid-key" is valid ident (hyphen allowed), should not be quoted
  assert_true(result.contains("valid-key = "))
  // "invalid key!" contains space and !, must be quoted
  assert_true(result.contains("\"invalid key!\""))
}

///|
test "formatter dense body - no empty lines between items" {
  let items = [
    BodyItem::Attribute(Attr::new("a", expr_int(1))),
    BodyItem::Attribute(Attr::new("b", expr_int(2))),
  ]
  let body = Body::from_items(items)
  let fmt = Formatter::new().set_dense(true).set_prefer_ident_keys(true)
  let result = fmt.format_body(body)
  // Dense: items joined by single newline
  assert_eq(result, "a = 1\nb = 2")
}

///|
test "formatter non-dense body - empty lines between items" {
  let items = [
    BodyItem::Attribute(Attr::new("a", expr_int(1))),
    BodyItem::Attribute(Attr::new("b", expr_int(2))),
  ]
  let body = Body::from_items(items)
  let fmt = Formatter::new().set_dense(false).set_prefer_ident_keys(true)
  let result = fmt.format_body(body)
  // Non-dense: items joined by double newline
  assert_eq(result, "a = 1\n\nb = 2")
}

///|
test "formatter body with block" {
  let block = Block::simple(
    "resource",
    Body::from_items([BodyItem::Attribute(Attr::new("name", expr_str("test")))]),
  )
  let body = Body::from_items([BodyItem::Block(block)])
  let fmt = Formatter::new()
  let result = fmt.format_body(body)
  assert_true(result.contains("resource {"))
  assert_true(result.contains("  \"name\" = \"test\""))
  assert_true(result.contains("}"))
}

///|
test "formatter compact preset formats body" {
  let items = [
    BodyItem::Attribute(Attr::new("x", expr_array([expr_int(1), expr_int(2)]))),
  ]
  let body = Body::from_items(items)
  let fmt = Formatter::with_config(FormatConfig::compact())
  let result = fmt.format_body(body)
  // compact arrays inline, ident keys unquoted
  assert_eq(result, "x = [1, 2]")
}

///|
test "formatter custom indent" {
  let items = [BodyItem::Attribute(Attr::new("x", expr_array([expr_int(1)])))]
  let body = Body::from_items(items)
  let fmt = Formatter::new().set_indent("    ")
  let result = fmt.format_body(body)
  // 4-space indent
  assert_true(result.contains("    1"))
}

///|
test "formatter empty array" {
  let value = HCLValue::Array([], Decor::empty())
  let fmt = Formatter::new()
  assert_eq(fmt.format_value(value), "[]")
}

///|
test "formatter empty object" {
  let obj : Map[String, HCLValue] = Map::new()
  let value = HCLValue::Object(obj, Decor::empty())
  let fmt = Formatter::new()
  assert_eq(fmt.format_value(value), "{}")
}

///|
test "formatter null value" {
  let fmt = Formatter::new()
  assert_eq(fmt.format_value(HCLValue::null()), "null")
}

///|
test "formatter bool values" {
  let fmt = Formatter::new()
  assert_eq(fmt.format_value(hcl_bool(true)), "true")
  assert_eq(fmt.format_value(hcl_bool(false)), "false")
}

///|
test "formatter number values" {
  let fmt = Formatter::new()
  assert_eq(fmt.format_value(hcl_int(42)), "42")
  assert_eq(fmt.format_value(hcl_float(3.14)), "3.14")
}

///|
test "formatter string value" {
  let fmt = Formatter::new()
  assert_eq(fmt.format_value(hcl_str("hello")), "\"hello\"")
}

///|
test "formatter nested compact arrays" {
  let inner = HCLValue::array([hcl_int(1), hcl_int(2)])
  let outer = HCLValue::array([inner, hcl_int(3)])
  let fmt = Formatter::new().set_compact_arrays(true)
  let result = fmt.format_value(outer)
  assert_eq(result, "[[1, 2], 3]")
}
