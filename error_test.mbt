///|
/// Tests for ParseError message formatting
test "parse error shows context line and column pointer" {
  let input = "name \"John\""
  let result = parse(input)
  match result {
    Err(err) => {
      let msg = err.message()
      assert_true(msg.contains("name \"John\""))
      assert_true(msg.contains("^"))
      assert_true(msg.contains("Parse error at line 1, column"))
    }
    Ok(_) => panic()
  }
}

///|
test "parse error shows correct context for multiline input" {
  let input = "name = \"John\"\nage thirty"
  let result = parse(input)
  match result {
    Err(err) => {
      let msg = err.message()
      assert_true(msg.contains("age thirty"))
      assert_true(msg.contains("Parse error at line 2"))
      assert_true(msg.contains("^"))
    }
    Ok(_) => panic()
  }
}

///|
test "parse error without context does not show extra lines" {
  let err = HCLError::parse_error("something went wrong", 1, 5, 4)
  let msg = err.message()
  assert_eq(msg, "Parse error at line 1, column 5: something went wrong")
  assert_false(msg.contains("^"))
}

///|
test "parse error with context shows full message format" {
  let err = HCLError::parse_error_with_context(
    "Expected '=', got end of file", 1, 6, 5, "name =",
  )
  let msg = err.message()
  assert_true(
    msg.contains(
      "Parse error at line 1, column 6: Expected '=', got end of file",
    ),
  )
  assert_true(msg.contains("name ="))
  assert_true(msg.contains("^"))
}
