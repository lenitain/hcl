///|
/// Expression Evaluator Tests
test "evaluate addition" {
  let result = eval_binary(
    Number(Number::from_int(5), Decor::empty()),
    "+",
    Number(Number::from_int(3), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_int(8), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate subtraction" {
  let result = eval_binary(
    Number(Number::from_int(10), Decor::empty()),
    "-",
    Number(Number::from_int(4), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_int(6), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate multiplication" {
  let result = eval_binary(
    Number(Number::from_int(6), Decor::empty()),
    "*",
    Number(Number::from_int(7), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_int(42), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate division" {
  let result = eval_binary(
    Number(Number::from_int(15), Decor::empty()),
    "/",
    Number(Number::from_int(3), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate division by zero" {
  let result = eval_binary(
    Number(Number::from_int(10), Decor::empty()),
    "/",
    Number(Number::from_int(0), Decor::empty()),
  )
  match result {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("Division by zero"))
  }
}

///|
test "evaluate modulo" {
  let result = eval_binary(
    Number(Number::from_int(10), Decor::empty()),
    "%",
    Number(Number::from_int(3), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_int(1), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate equality" {
  let result = eval_binary(
    Number(Number::from_int(5), Decor::empty()),
    "==",
    Number(Number::from_int(5), Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate inequality" {
  let result = eval_binary(
    Number(Number::from_int(5), Decor::empty()),
    "!=",
    Number(Number::from_int(3), Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate less than" {
  let result = eval_binary(
    Number(Number::from_int(3), Decor::empty()),
    "<",
    Number(Number::from_int(5), Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate greater than" {
  let result = eval_binary(
    Number(Number::from_int(5), Decor::empty()),
    ">",
    Number(Number::from_int(3), Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate less than or equal" {
  let result = eval_binary(
    Number(Number::from_int(3), Decor::empty()),
    "<=",
    Number(Number::from_int(3), Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate greater than or equal" {
  let result = eval_binary(
    Number(Number::from_int(5), Decor::empty()),
    ">=",
    Number(Number::from_int(5), Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate logical and" {
  let result = eval_binary(
    Bool(true, Decor::empty()),
    "&&",
    Bool(false, Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate logical or" {
  let result = eval_binary(
    Bool(true, Decor::empty()),
    "||",
    Bool(false, Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate negation" {
  let result = eval_unary("-", Number(Number::from_int(5), Decor::empty()))
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_int(-5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate logical not" {
  let result = eval_unary("!", Bool(true, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate string concatenation" {
  let result = eval_binary(
    String("hello ", Decor::empty()),
    "+",
    String("world", Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == String("hello world", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate float addition" {
  let result = eval_binary(
    Number(Number::from_finite_f64(1.5), Decor::empty()),
    "+",
    Number(Number::from_finite_f64(2.5), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_finite_f64(4.0), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate mixed int and float" {
  let result = eval_binary(
    Number(Number::from_int(2), Decor::empty()),
    "+",
    Number(Number::from_finite_f64(3.5), Decor::empty()),
  )
  match result {
    Ok(value) =>
      assert_true(value == Number(Number::from_finite_f64(5.5), Decor::empty()))
    Err(_) => panic()
  }
}
