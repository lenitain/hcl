///|
/// Tests for implicit type conversion in HCL evaluation
test "string to number conversion" {
  // Valid integer
  let result = _string_to_number("123")
  assert_true(result is Ok(_))
  match result {
    Ok(Number(n, _)) => assert_true(n == Number::from_int(123))
    _ => panic()
  }

  // Valid float
  let result = _string_to_number("123.45")
  assert_true(result is Ok(_))
  match result {
    Ok(Number(n, _)) => assert_true(n == Number::from_finite_f64(123.45))
    _ => panic()
  }

  // Invalid string
  let result = _string_to_number("abc")
  assert_true(result is Err(_))

  // Empty string
  let result = _string_to_number("")
  assert_true(result is Err(_))

  // Negative number
  let result = _string_to_number("-42")
  assert_true(result is Ok(_))
  match result {
    Ok(Number(n, _)) => assert_true(n == Number::from_int(-42))
    _ => panic()
  }
}

///|
test "string to bool conversion" {
  // Valid true values
  let result = _string_to_bool("true")
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  let result = _string_to_bool("1")
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // Valid false values
  let result = _string_to_bool("false")
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_false(b)
    _ => panic()
  }

  let result = _string_to_bool("0")
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_false(b)
    _ => panic()
  }

  // Invalid string
  let result = _string_to_bool("yes")
  assert_true(result is Err(_))

  // Invalid string
  let result = _string_to_bool("TRUE")
  assert_true(result is Err(_))
}

///|
test "implicit conversion in addition" {
  // string + number
  let result = eval_binary(
    String("value: ", Decor::empty()),
    "+",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(String(s, _)) => assert_eq(s, "value: 42")
    _ => panic()
  }

  // number + string
  let result = eval_binary(
    Number(Number::from_int(42), Decor::empty()),
    "+",
    String(" is the answer", Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(String(s, _)) => assert_eq(s, "42 is the answer")
    _ => panic()
  }

  // string + bool
  let result = eval_binary(
    String("enabled: ", Decor::empty()),
    "+",
    Bool(true, Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(String(s, _)) => assert_eq(s, "enabled: true")
    _ => panic()
  }

  // bool + string
  let result = eval_binary(
    Bool(false, Decor::empty()),
    "+",
    String(" is the value", Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(String(s, _)) => assert_eq(s, "false is the value")
    _ => panic()
  }
}

///|
test "implicit conversion in equality" {
  // string == number (equal)
  let result = eval_binary(
    String("42", Decor::empty()),
    "==",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // string == number (not equal)
  let result = eval_binary(
    String("43", Decor::empty()),
    "==",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_false(b)
    _ => panic()
  }

  // number == string
  let result = eval_binary(
    Number(Number::from_int(42), Decor::empty()),
    "==",
    String("42", Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // string == bool (equal)
  let result = eval_binary(
    String("true", Decor::empty()),
    "==",
    Bool(true, Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // string == bool (not equal)
  let result = eval_binary(
    String("false", Decor::empty()),
    "==",
    Bool(true, Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_false(b)
    _ => panic()
  }
}

///|
test "implicit conversion in inequality" {
  // string != number
  let result = eval_binary(
    String("42", Decor::empty()),
    "!=",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_false(b)
    _ => panic()
  }

  // string != number (different)
  let result = eval_binary(
    String("43", Decor::empty()),
    "!=",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }
}

///|
test "implicit conversion in comparison" {
  // string < number
  let result = eval_binary(
    String("10", Decor::empty()),
    "<",
    Number(Number::from_int(20), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // string > number
  let result = eval_binary(
    String("20", Decor::empty()),
    ">",
    Number(Number::from_int(10), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // string <= number (equal)
  let result = eval_binary(
    String("42", Decor::empty()),
    "<=",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // string >= number (greater)
  let result = eval_binary(
    String("50", Decor::empty()),
    ">=",
    Number(Number::from_int(42), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }

  // number < string
  let result = eval_binary(
    Number(Number::from_int(10), Decor::empty()),
    "<",
    String("20", Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Bool(b, _)) => assert_true(b)
    _ => panic()
  }
}

///|
test "implicit conversion preserves types" {
  // number + number still works
  let result = eval_binary(
    Number(Number::from_int(5), Decor::empty()),
    "+",
    Number(Number::from_int(3), Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(Number(n, _)) => assert_true(n == Number::from_int(8))
    _ => panic()
  }

  // string + string still works
  let result = eval_binary(
    String("hello ", Decor::empty()),
    "+",
    String("world", Decor::empty()),
  )
  assert_true(result is Ok(_))
  match result {
    Ok(String(s, _)) => assert_eq(s, "hello world")
    _ => panic()
  }

  // bool + bool still fails (not supported)
  let result = eval_binary(
    Bool(true, Decor::empty()),
    "+",
    Bool(false, Decor::empty()),
  )
  assert_true(result is Err(_))
}
