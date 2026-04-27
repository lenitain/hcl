///|
test "BOM at start of input returns error" {
  let input = "\u{FEFF}key = \"value\""
  let result = parse(input)
  assert_true(result is Err(_))
  match result {
    Err(EncodingError(msg)) =>
      assert_eq(msg, "HCL input must not contain a UTF-8 byte order mark (BOM)")
    _ => panic()
  }
}

///|
test "no BOM parses successfully" {
  let input = "key = \"value\""
  let result = parse(input)
  assert_true(result is Ok(_))
}

///|
test "BOM in middle of input does not trigger error" {
  let input = "key = \"\u{FEFF}value\""
  let result = parse(input)
  assert_true(result is Ok(_))
}

///|
test "empty input parses successfully" {
  let input = ""
  let result = parse(input)
  assert_true(result is Ok(_))
}

///|
test "validate_input rejects BOM" {
  let input = "\u{FEFF}hello"
  let result = Lexer::validate_input(input)
  assert_true(result is Err(_))
  match result {
    Err(EncodingError(_)) => assert_true(true)
    _ => panic()
  }
}

///|
test "validate_input accepts normal string" {
  let input = "hello world"
  let result = Lexer::validate_input(input)
  assert_true(result is Ok(_))
}
