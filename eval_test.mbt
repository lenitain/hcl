///|
/// Expression Evaluator Tests
test "evaluate addition" {
  let result = eval_binary(Int(5, Decor::empty()), "+", Int(3, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Int(8, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate subtraction" {
  let result = eval_binary(Int(10, Decor::empty()), "-", Int(4, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Int(6, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate multiplication" {
  let result = eval_binary(Int(6, Decor::empty()), "*", Int(7, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Int(42, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate division" {
  let result = eval_binary(Int(15, Decor::empty()), "/", Int(3, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Int(5, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate division by zero" {
  let result = eval_binary(Int(10, Decor::empty()), "/", Int(0, Decor::empty()))
  match result {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("Division by zero"))
  }
}

///|
test "evaluate modulo" {
  let result = eval_binary(Int(10, Decor::empty()), "%", Int(3, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Int(1, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate equality" {
  let result = eval_binary(Int(5, Decor::empty()), "==", Int(5, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate inequality" {
  let result = eval_binary(Int(5, Decor::empty()), "!=", Int(3, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate less than" {
  let result = eval_binary(Int(3, Decor::empty()), "<", Int(5, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate greater than" {
  let result = eval_binary(Int(5, Decor::empty()), ">", Int(3, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate less than or equal" {
  let result = eval_binary(Int(3, Decor::empty()), "<=", Int(3, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate greater than or equal" {
  let result = eval_binary(Int(5, Decor::empty()), ">=", Int(5, Decor::empty()))
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
  let result = eval_unary("-", Int(5, Decor::empty()))
  match result {
    Ok(value) => assert_true(value == Int(-5, Decor::empty()))
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
    Float(1.5, Decor::empty()),
    "+",
    Float(2.5, Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Float(4.0, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "evaluate mixed int and float" {
  let result = eval_binary(
    Int(2, Decor::empty()),
    "+",
    Float(3.5, Decor::empty()),
  )
  match result {
    Ok(value) => assert_true(value == Float(5.5, Decor::empty()))
    Err(_) => panic()
  }
}
