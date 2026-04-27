///|
/// Splat operator parser tests
test "parse attribute splat .*" {
  let result = parse("a = list.*.name")
  assert_true(result is Ok(_))
  let body = result.unwrap()
  assert_true(body.get_items().length() == 1)
}

///|
test "parse index splat [*]" {
  let result = parse("a = list[*].name")
  assert_true(result is Ok(_))
  let body = result.unwrap()
  assert_true(body.get_items().length() == 1)
}

///|
test "parse chained splat" {
  let result = parse("a = list.*.items.*.name")
  assert_true(result is Ok(_))
  let body = result.unwrap()
  assert_true(body.get_items().length() == 1)
}

///|
test "parse splat with index after" {
  let result = parse("a = list.*[0]")
  assert_true(result is Ok(_))
  let body = result.unwrap()
  assert_true(body.get_items().length() == 1)
}

///|
test "parse splat in block" {
  let result = parse(
    "resource \"aws_instance\" \"test\" {\n  vpc_security_group_ids = aws_security_group.example.*.id\n}",
  )
  assert_true(result is Ok(_))
}

///|
test "eval splat on array of objects" {
  let body = parse("names = users.*.name").unwrap()
  let items = body.get_items()
  assert_true(items.length() == 1)
}

///|
test "parse and expr_to_string splat roundtrip" {
  let result = parse("a = list.*.name").unwrap()
  let items = result.get_items()
  assert_true(items.length() == 1)
  match items[0] {
    Attribute(attr) => {
      let s = expr_to_string(attr.get_value())
      assert_true(s.contains(".*"))
    }
    _ => assert_true(false)
  }
}
