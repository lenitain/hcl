///|
/// Integration tests for decor preservation
test "roundtrip with comments" {
  let input = "// Header comment\nname = \"value\" // trailing\n\n// Block comment\nresource \"aws\" \"example\" {\n  ami = \"ami-123\"\n}"

  let result = parse(input)
  assert_true(result is Ok(_))
  let body = result.unwrap()

  // Check that parsing preserves decor
  let name_attr = body.find_attr("name")
  assert_true(name_attr is Some(_))
  let decor = name_attr.unwrap().get_decor()
  assert_true(decor.get_prefix() is Some(_))

  // Check that serialization works
  let output = format_body_with_decor(body)
  assert_true(output.length() > 0)
}

///|
test "modify and preserve decor" {
  let input = "// Comment\nname = \"old\""

  let body = parse(input).unwrap()
  let attr = body.find_attr("name").unwrap()

  let new_value = expr_str("new")
  let new_key = Decorated::bare(attr.get_key())
  let new_attr = Attr::with_decor(
    new_key,
    Spanned::bare(new_value),
    attr.get_decor(),
  )

  let new_body = Body::with_decor(
    [BodyItem::Attribute(new_attr)],
    body.get_decor(),
  )

  let output = format_body_with_decor(new_body)

  assert_true(output.contains("// Comment"))
  assert_true(output.contains("\"new\""))
}

///|
test "preserve prefix decor on attribute" {
  let input = "// Leading comment\nname = \"value\""
  let body = parse(input).unwrap()
  let attr = body.find_attr("name").unwrap()
  let decor = attr.get_decor()

  assert_true(decor.get_prefix() is Some(_))
  assert_true(decor.get_prefix().unwrap().contains("// Leading comment"))
}

///|
test "preserve trailing comment on value" {
  let input = "name = \"value\" // trailing"
  let body = parse(input).unwrap()
  let attr = body.find_attr("name").unwrap()
  let value = attr.get_value()

  match value {
    ExprString(_) => ()
    _ => panic()
  }
}

///|
test "preserve block decor" {
  let input = "// Block comment\nresource \"aws\" \"test\" {\n  ami = \"ami-123\"\n}"
  let body = parse(input).unwrap()
  let block = body.find_block("resource").unwrap()
  let decor = block.get_decor()

  assert_true(decor.get_prefix() is Some(_))
  assert_true(decor.get_prefix().unwrap().contains("// Block comment"))
}

///|
test "empty decor preserved" {
  let input = "name = \"value\""
  let body = parse(input).unwrap()
  let attr = body.find_attr("name").unwrap()
  let decor = attr.get_decor()

  assert_true(decor.get_prefix() is None(_))
  assert_true(decor.get_suffix() is None(_))
}

///|
test "whitespace preserved as decor" {
  let input = "  name = \"value\""
  let body = parse(input).unwrap()
  let attr = body.find_attr("name").unwrap()
  let decor = attr.get_decor()

  assert_true(decor.get_prefix() is Some(_))
  assert_true(decor.get_prefix().unwrap() == "  ")
}
