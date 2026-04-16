///|
/// Expression Evaluator Tests
test "evaluate addition" {
  let result = eval_binary(Int(5), "+", Int(3))
  match result {
    Ok(value) => assert_true(value == Int(8))
    Err(_) => panic()
  }
}

///|
test "evaluate subtraction" {
  let result = eval_binary(Int(10), "-", Int(4))
  match result {
    Ok(value) => assert_true(value == Int(6))
    Err(_) => panic()
  }
}

///|
test "evaluate multiplication" {
  let result = eval_binary(Int(6), "*", Int(7))
  match result {
    Ok(value) => assert_true(value == Int(42))
    Err(_) => panic()
  }
}

///|
test "evaluate division" {
  let result = eval_binary(Int(15), "/", Int(3))
  match result {
    Ok(value) => assert_true(value == Int(5))
    Err(_) => panic()
  }
}

///|
test "evaluate division by zero" {
  let result = eval_binary(Int(10), "/", Int(0))
  match result {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("Division by zero"))
  }
}

///|
test "evaluate modulo" {
  let result = eval_binary(Int(10), "%", Int(3))
  match result {
    Ok(value) => assert_true(value == Int(1))
    Err(_) => panic()
  }
}

///|
test "evaluate equality" {
  let result = eval_binary(Int(5), "==", Int(5))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate inequality" {
  let result = eval_binary(Int(5), "!=", Int(3))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate less than" {
  let result = eval_binary(Int(3), "<", Int(5))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate greater than" {
  let result = eval_binary(Int(5), ">", Int(3))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate less than or equal" {
  let result = eval_binary(Int(3), "<=", Int(3))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate greater than or equal" {
  let result = eval_binary(Int(5), ">=", Int(5))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate logical and" {
  let result = eval_binary(Bool(true), "&&", Bool(false))
  match result {
    Ok(value) => assert_true(value == Bool(false))
    Err(_) => panic()
  }
}

///|
test "evaluate logical or" {
  let result = eval_binary(Bool(true), "||", Bool(false))
  match result {
    Ok(value) => assert_true(value == Bool(true))
    Err(_) => panic()
  }
}

///|
test "evaluate negation" {
  let result = eval_unary("-", Int(5))
  match result {
    Ok(value) => assert_true(value == Int(-5))
    Err(_) => panic()
  }
}

///|
test "evaluate logical not" {
  let result = eval_unary("!", Bool(true))
  match result {
    Ok(value) => assert_true(value == Bool(false))
    Err(_) => panic()
  }
}

///|
test "evaluate string concatenation" {
  let result = eval_binary(String("hello "), "+", String("world"))
  match result {
    Ok(value) => assert_true(value == String("hello world"))
    Err(_) => panic()
  }
}

///|
test "evaluate float addition" {
  let result = eval_binary(Float(1.5), "+", Float(2.5))
  match result {
    Ok(value) => assert_true(value == Float(4.0))
    Err(_) => panic()
  }
}

///|
test "evaluate mixed int and float" {
  let result = eval_binary(Int(2), "+", Float(3.5))
  match result {
    Ok(value) => assert_true(value == Float(5.5))
    Err(_) => panic()
  }
}
