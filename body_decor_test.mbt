///|
test "Attr with decoration" {
  let decor = Decor::new(Some(" "), Some("\n"))
  let key_decor = Decor::new(None, Some(" "))
  let key = Decorated::new("name", key_decor)
  let value = HCLValue::String("value", Decor::empty())

  let attr = Attr::with_decor(key, value, decor)
  assert_eq(attr.get_key(), "name")
  assert_eq(attr.get_decorated_key().get_decor().get_suffix(), Some(" "))
  assert_eq(attr.get_decor().get_prefix(), Some(" "))
}

///|
test "Attr basic constructor uses empty decor" {
  let attr = Attr::new(
    "name",
    HCLValue::Number(Number::from_int(42), Decor::empty()),
  )
  assert_eq(attr.get_key(), "name")
  assert_eq(attr.get_decorated_key().get_decor().get_prefix(), None)
  assert_eq(attr.get_decor().get_prefix(), None)
}

///|
test "Block with decoration" {
  let decor = Decor::new(Some("\n"), Some("\n"))
  let type_decor = Decor::new(None, Some(" "))
  let type_name = Decorated::new("resource", type_decor)
  let label_decor = Decor::new(Some(" "), Some(" "))
  let labels = [Decorated::new("aws_instance", label_decor)]
  let body = Body::new()

  let block = Block::with_decor(type_name, labels, body, decor)
  assert_eq(block.get_type_name(), "resource")
  assert_eq(block.get_decorated_type_name().get_decor().get_suffix(), Some(" "))
  assert_eq(block.get_labels()[0], "aws_instance")
  assert_eq(block.get_decorated_labels()[0].get_decor().get_prefix(), Some(" "))
  assert_eq(block.get_decor().get_prefix(), Some("\n"))
}

///|
test "Block basic constructor uses empty decor" {
  let body = Body::new()
  let block = Block::new("resource", ["aws_instance"], body)
  assert_eq(block.get_type_name(), "resource")
  assert_eq(block.get_labels(), ["aws_instance"])
  assert_eq(block.get_decor().get_prefix(), None)
  assert_eq(block.get_decorated_type_name().get_decor().get_prefix(), None)
  assert_eq(block.get_decorated_labels()[0].get_decor().get_prefix(), None)
}

///|
test "Body with decoration" {
  let decor = Decor::new(Some("# comment\n"), None)
  let body = Body::with_decor([], decor)
  assert_eq(body.get_decor().get_prefix(), Some("# comment\n"))
  assert_eq(body.is_empty(), true)
}

///|
test "Body basic constructor uses empty decor" {
  let body = Body::new()
  assert_eq(body.get_decor().get_prefix(), None)
}

///|
test "Body find_attr works with decorated keys" {
  let body = Body::new().add_attr(
    "name",
    HCLValue::String("test", Decor::empty()),
  )
  let attr = body.find_attr("name")
  assert_eq(attr is Some(_), true)
  assert_eq(attr.unwrap().get_key(), "name")
}

///|
test "Body find_block works with decorated type names" {
  let body = Body::new().add_block(
    Block::new("resource", ["aws_instance"], Body::new()),
  )
  let block = body.find_block("resource")
  assert_eq(block is Some(_), true)
  assert_eq(block.unwrap().get_type_name(), "resource")
}

///|
test "Body find_blocks works with decorated type names" {
  let body = Body::new()
    .add_block(Block::new("resource", ["aws_instance"], Body::new()))
    .add_block(Block::new("resource", ["aws_s3_bucket"], Body::new()))
  let blocks = body.find_blocks("resource")
  assert_eq(blocks.length(), 2)
}
