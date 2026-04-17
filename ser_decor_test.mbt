///|
test "format attribute with decor" {
  let key = Decorated::new("name", Decor::new(None, Some(" ")))
  let value = HCLValue::string("value")
  let decor = Decor::new(Some("// comment\n"), Some("\n"))
  let attr = Attr::with_decor(key, value, decor)

  let result = format_attr_with_decor(attr)
  assert(result.contains("// comment"))
  assert(result.contains("name = \"value\""))
}

///|
test "format body with decor" {
  let items = [Attribute(Attr::new("name", HCLValue::string("value")))]
  let decor = Decor::new(Some("# Header\n"), Some("\n# Footer\n"))
  let body = Body::with_decor(items, decor)

  let result = format_body_with_decor(body)
  assert(result.contains("# Header"))
  assert(result.contains("# Footer"))
}

///|
test "format value with decor" {
  let value = String("hello", Decor::new(Some(" "), Some(" ")))
  let result = format_value_with_decor(value)
  assert_eq(result, " \"hello\" ")
}

///|
test "format value content" {
  assert_eq(format_value_content(Null(Decor::empty())), "null")
  assert_eq(format_value_content(Bool(true, Decor::empty())), "true")
  assert_eq(format_value_content(Int(42, Decor::empty())), "42")
  assert_eq(format_value_content(String("hi", Decor::empty())), "\"hi\"")
}

///|
test "format array with decor" {
  let items = [
    String("a", Decor::new(None, Some(" "))),
    String("b", Decor::empty()),
  ]
  let value = Array(items, Decor::empty())
  let result = format_value_with_decor(value)
  assert_eq(result, "[\"a\" , \"b\"]")
}

///|
test "format object with decor" {
  let obj : Map[String, HCLValue] = Map::new()
  obj["key"] = String("val", Decor::new(Some(" "), None))
  let value = Object(obj, Decor::empty())
  let result = format_value_with_decor(value)
  assert(result.contains("\"key\" =  \"val\""))
}
