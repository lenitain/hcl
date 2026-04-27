///|
test "unknown construction" {
  let v = HCLValue::unknown()
  assert_true(v.is_unknown())
}

///|
test "unknown is_unknown true, others false" {
  let v = HCLValue::unknown()
  assert_true(v.is_unknown())
  assert_false(v.is_null())
  assert_false(v.is_bool())
  assert_false(v.is_number())
  assert_false(v.is_string())
  assert_false(v.is_array())
  assert_false(v.is_object())
}

///|
test "unknown get_decor" {
  let v = HCLValue::unknown()
  let decor = v.get_decor()
  assert_eq(decor.get_prefix(), None)
  assert_eq(decor.get_suffix(), None)
}

///|
test "unknown set_decor" {
  let v = HCLValue::unknown()
  let new_decor = Decor::new(Some(" "), Some(" "))
  let v2 = v.set_decor(new_decor)
  assert_true(v2.is_unknown())
  assert_eq(v2.get_decor().get_prefix(), Some(" "))
  assert_eq(v2.get_decor().get_suffix(), Some(" "))
}

///|
test "unknown to_json_string" {
  let v = HCLValue::unknown()
  assert_eq(v.to_json_string(), "null")
}

///|
test "expr_unknown factory" {
  let e = expr_unknown()
  assert_true(e == ExprUnknown)
}

///|
test "expr_to_string ExprUnknown" {
  assert_eq(expr_to_string(ExprUnknown), "unknown")
}

///|
test "expr_to_hcl_value ExprUnknown returns Unknown" {
  let v = expr_to_hcl_value(ExprUnknown)
  assert_true(v.is_unknown())
}

///|
test "hcl_value_to_expression Unknown returns ExprUnknown" {
  let v = HCLValue::unknown()
  let e = hcl_value_to_expression(v)
  assert_true(e == ExprUnknown)
}

///|
test "to_hcl_value Unknown returns unknown" {
  let v = HCLValue::unknown()
  assert_eq(to_hcl_value(v), "unknown")
}

///|
test "eval_binary unknown left propagates" {
  let result = eval_binary(
    HCLValue::unknown(),
    "+",
    Number(Number::from_int(1), Decor::empty()),
  )
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => panic()
  }
}

///|
test "eval_binary unknown right propagates" {
  let result = eval_binary(
    Number(Number::from_int(1), Decor::empty()),
    "+",
    HCLValue::unknown(),
  )
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => panic()
  }
}

///|
test "eval_unary unknown negate propagates" {
  let result = eval_unary("-", HCLValue::unknown())
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => panic()
  }
}

///|
test "eval_unary unknown not propagates" {
  let result = eval_unary("!", HCLValue::unknown())
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => panic()
  }
}

///|
test "eval_conditional unknown condition propagates" {
  let result = eval_conditional(
    HCLValue::unknown(),
    Bool(true, Decor::empty()),
    Bool(false, Decor::empty()),
  )
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => panic()
  }
}

///|
test "validate unknown passes BoolSchema" {
  let errors = validate(HCLValue::unknown(), BoolSchema)
  assert_eq(errors.length(), 0)
}

///|
test "validate unknown passes Any" {
  let errors = validate(HCLValue::unknown(), Any)
  assert_eq(errors.length(), 0)
}

///|
test "tostring unknown returns \"unknown\"" {
  let fns = builtin_functions()
  let tostring = fns.get("tostring")
  assert_true(tostring.is_some())
  let result = tostring.unwrap().call([HCLValue::unknown()])
  match result {
    Ok(String(s, _)) => assert_eq(s, "unknown")
    _ => panic()
  }
}
