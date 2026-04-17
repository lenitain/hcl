///|
test "parse attribute with leading line comment" {
  let input = "// This is a comment\nname = \"value\""
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert_true(attr.is_some())
  let decor = attr.unwrap().get_decor()
  assert_true(decor.get_prefix().is_some())
  let prefix = decor.get_prefix().unwrap()
  assert_true(prefix.contains("// This is a comment"))
}

///|
test "parse attribute with leading block comment" {
  let input = "/* block comment */\nname = \"value\""
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert_true(attr.is_some())
  let decor = attr.unwrap().get_decor()
  assert_true(decor.get_prefix().is_some())
  let prefix = decor.get_prefix().unwrap()
  assert_true(prefix.contains("/* block comment */"))
}

///|
test "parse attribute with leading whitespace" {
  let input = "  name = \"value\""
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert_true(attr.is_some())
  let decor = attr.unwrap().get_decor()
  assert_true(decor.get_prefix().is_some())
  let prefix = decor.get_prefix().unwrap()
  assert_true(prefix == "  ")
}

///|
test "parse attribute with whitespace and comment" {
  let input = "  // indented comment\nname = \"value\""
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert_true(attr.is_some())
  let decor = attr.unwrap().get_decor()
  assert_true(decor.get_prefix().is_some())
  let prefix = decor.get_prefix().unwrap()
  assert_true(prefix.contains("// indented comment"))
}

///|
test "parse attribute without decor" {
  let input = "name = \"value\""
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert_true(attr.is_some())
  let decor = attr.unwrap().get_decor()
  assert_true(decor.get_prefix().is_none())
}

///|
test "parse block with leading comment" {
  let input = "// Block comment\nresource \"aws_instance\" \"example\" {\n  ami = \"ami-123\"\n}"
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let block = body.find_block("resource")
  assert_true(block.is_some())
  let decor = block.unwrap().get_decor()
  assert_true(decor.get_prefix().is_some())
  let prefix = decor.get_prefix().unwrap()
  assert_true(prefix.contains("// Block comment"))
}

///|
test "parse multiple attributes with comments" {
  let input = "// First\nname = \"alice\"\n// Second\nage = 30"
  let result = parse(input)
  assert_true(result.is_ok())
  let body = result.unwrap()
  let attr1 = body.find_attr("name")
  assert_true(attr1.is_some())
  assert_true(attr1.unwrap().get_decor().get_prefix().is_some())
  let attr2 = body.find_attr("age")
  assert_true(attr2.is_some())
  assert_true(attr2.unwrap().get_decor().get_prefix().is_some())
}
