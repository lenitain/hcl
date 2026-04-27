///|
/// Unicode identifier integration tests
test "parse Chinese identifier" {
  let result = parse("名字 = \"hello\"")
  assert_true(result is Ok(_))
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_eq(attr.get_key(), "名字")
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse Japanese identifier" {
  let result = parse("名前 = \"hello\"")
  assert_true(result is Ok(_))
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_eq(attr.get_key(), "名前")
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse Korean identifier" {
  let result = parse("이름 = \"hello\"")
  assert_true(result is Ok(_))
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_eq(attr.get_key(), "이름")
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse accented Latin identifier" {
  let result = parse("café = \"coffee\"")
  assert_true(result is Ok(_))
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_eq(attr.get_key(), "café")
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse Cyrillic identifier" {
  let result = parse("имя = \"hello\"")
  assert_true(result is Ok(_))
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_eq(attr.get_key(), "имя")
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse Unicode identifier in block label" {
  let result = parse("资源 \"main\" {\n  名称 = \"test\"\n}")
  assert_true(result is Ok(_))
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "资源")
          assert_eq(block.get_labels(), ["main"])
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse Unicode with hyphen in identifier" {
  let result = parse("my-变量 = \"test\"")
  assert_true(result is Ok(_))
}
