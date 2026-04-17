///|
test "format attribute with decor" {
  let key = Decorated::new("name", Decor::new(None, Some(" ")))
  let value = HCLValue::string("value")
  let decor = Decor::new(Some("// comment\n"), Some("\n"))
  let attr = Attr::with_decor(key, value, decor)

  let result = format_attr_with_decor(attr)
  assert_true(result.contains("// comment"))
  // The key has a suffix " " so the output will be: // comment\nname = "value" \n
  assert_true(result.contains("name"))
}

///|
test "format body with decor" {
  let items = [
    BodyItem::Attribute(Attr::new("name", HCLValue::string("value"))),
  ]
  let decor = Decor::new(Some("# Header\n"), Some("\n# Footer\n"))
  let body = Body::with_decor(items, decor)

  let result = format_body_with_decor(body)
  assert_true(result.contains("# Header"))
  assert_true(result.contains("# Footer"))
}

///|
test "format value with decor" {
  let value = HCLValue::String("hello", Decor::new(Some(" "), Some(" ")))
  let result = format_value_with_decor(value)
  assert_eq(result, " \"hello\" ")
}

///|
test "format value content" {
  assert_eq(format_value_content(HCLValue::Null(Decor::empty())), "null")
  assert_eq(format_value_content(HCLValue::Bool(true, Decor::empty())), "true")
  assert_eq(
    format_value_content(HCLValue::Number(Number::from_int(42), Decor::empty())),
    "42",
  )
  assert_eq(
    format_value_content(HCLValue::String("hi", Decor::empty())),
    "\"hi\"",
  )
}

///|
test "format array with decor" {
  let items = [
    HCLValue::String("a", Decor::new(None, Some(" "))),
    HCLValue::String("b", Decor::empty()),
  ]
  let value = HCLValue::Array(items, Decor::empty())
  let result = format_value_with_decor(value)
  assert_eq(result, "[\"a\" , \"b\"]")
}

///|
test "format object with decor" {
  let obj : Map[String, HCLValue] = Map::new()
  obj["key"] = HCLValue::String("val", Decor::new(Some(" "), None))
  let value = HCLValue::Object(obj, Decor::empty())
  let result = format_value_with_decor(value)
  assert_true(result.contains("\"key\" =  \"val\""))
}
