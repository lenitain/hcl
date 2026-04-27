///|
/// Tests for parse error recovery feature
test "multiple syntax errors - partial body still returned" {
  let input = "a = 1\nb =\nc = 3"
  let (result, errors) = parse_with_recovery(input)
  assert_true(errors.length() >= 1)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_true(items.length() >= 1)
    }
    Err(_) => panic()
  }
}

///|
test "unexpected token mid-file - items before error preserved" {
  let input = "a = 1\nb = 2\n42"
  let (result, errors) = parse_with_recovery(input)
  assert_true(errors.length() >= 1)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 2)
    }
    Err(_) => panic()
  }
}

///|
test "block with bad body content - error returned" {
  let input = "resource \"x\" {\n  42\n}"
  let (result, errors) = parse_with_recovery(input)
  assert_true(errors.length() >= 1)
  match result {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "clean input produces no errors" {
  let input = "name = \"hello\"\ncount = 42"
  let (result, errors) = parse_with_recovery(input)
  assert_eq(errors.length(), 0)
  match result {
    Ok(body) => assert_eq(body.get_items().length(), 2)
    Err(_) => panic()
  }
}

///|
test "empty input" {
  let (result, errors) = parse_with_recovery("")
  assert_eq(errors.length(), 0)
  match result {
    Ok(body) => assert_eq(body.get_items().length(), 0)
    Err(_) => panic()
  }
}

///|
test "only newlines input" {
  let (result, errors) = parse_with_recovery("\n\n\n")
  assert_eq(errors.length(), 0)
  match result {
    Ok(body) => assert_eq(body.get_items().length(), 0)
    Err(_) => panic()
  }
}

///|
test "error on first line - result is error when nothing parsed" {
  let input = "42"
  let (result, errors) = parse_with_recovery(input)
  assert_true(errors.length() >= 1)
  match result {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "error on last line - earlier lines still parsed" {
  let input = "a = 1\nb = 2\nc ="
  let (result, errors) = parse_with_recovery(input)
  assert_true(errors.length() >= 1)
  match result {
    Ok(body) => {
      let items = body.get_items()
      assert_true(items.length() >= 2)
    }
    Err(_) => panic()
  }
}

///|
test "consecutive errors - first error recorded" {
  let input = "42\n42"
  let (result, errors) = parse_with_recovery(input)
  assert_true(errors.length() >= 1)
  match result {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "HCLError::multi factory and message joining" {
  let e1 = HCLError::parse_error("first error", 1, 1, 0)
  let e2 = HCLError::parse_error("second error", 2, 1, 5)
  let multi = HCLError::multi([e1, e2])
  let msg = multi.message()
  assert_true(msg.contains("first error"))
  assert_true(msg.contains("second error"))
}
