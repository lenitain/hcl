///|
/// Type Unification Tests

// type_of tests

test "type_of Null" {
  let v : HCLValue = Null(Decor::empty())
  assert_true(type_of(v) == TNull)
}

///|
test "type_of Bool" {
  let v : HCLValue = Bool(true, Decor::empty())
  assert_true(type_of(v) == TBool)
}

///|
test "type_of Number" {
  assert_true(type_of(HCLValue::int(1)) == TNumber)
}

///|
test "type_of String" {
  assert_true(type_of(HCLValue::string("hello")) == TString)
}

///|
test "type_of Array" {
  assert_true(type_of(HCLValue::array([])) == TArray)
}

///|
test "type_of Object" {
  assert_true(type_of(HCLValue::object({})) == TObject)
}

///|
test "type_of Unknown" {
  assert_true(type_of(HCLValue::unknown()) == TUnknown)
}

// unify_types valid combinations

///|
test "unify_types same type" {
  match unify_types(TNumber, TNumber) {
    Ok(TNumber) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types number and string" {
  match unify_types(TNumber, TString) {
    Ok(TString) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types bool and string" {
  match unify_types(TBool, TString) {
    Ok(TString) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types null and string" {
  match unify_types(TNull, TString) {
    Ok(TString) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types null and number" {
  match unify_types(TNull, TNumber) {
    Ok(TNumber) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types unknown and string" {
  match unify_types(TUnknown, TString) {
    Ok(TUnknown) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types unknown and number" {
  match unify_types(TUnknown, TNumber) {
    Ok(TUnknown) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types null and bool" {
  match unify_types(TNull, TBool) {
    Ok(TBool) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types null and array" {
  match unify_types(TNull, TArray) {
    Ok(TArray) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types null and object" {
  match unify_types(TNull, TObject) {
    Ok(TObject) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types array and array" {
  match unify_types(TArray, TArray) {
    Ok(TArray) => assert_true(true)
    _ => panic()
  }
}

///|
test "unify_types object and object" {
  match unify_types(TObject, TObject) {
    Ok(TObject) => assert_true(true)
    _ => panic()
  }
}

// unify_types invalid combinations

///|
test "unify_types number and bool" {
  assert_true(unify_types(TNumber, TBool) is Err(_))
}

///|
test "unify_types array and string" {
  assert_true(unify_types(TArray, TString) is Err(_))
}

///|
test "unify_types object and number" {
  assert_true(unify_types(TObject, TNumber) is Err(_))
}

///|
test "unify_types bool and number reversed" {
  assert_true(unify_types(TBool, TNumber) is Err(_))
}

// convert_value tests

///|
test "convert_value number to string" {
  let v = HCLValue::int(42)
  match convert_value(v, TString) {
    Ok(String(s, _)) => assert_true(s == "42")
    _ => panic()
  }
}

///|
test "convert_value bool true to string" {
  let v = HCLValue::bool(true)
  match convert_value(v, TString) {
    Ok(String(s, _)) => assert_true(s == "true")
    _ => panic()
  }
}

///|
test "convert_value bool false to string" {
  let v = HCLValue::bool(false)
  match convert_value(v, TString) {
    Ok(String(s, _)) => assert_true(s == "false")
    _ => panic()
  }
}

///|
test "convert_value null to string" {
  let v = HCLValue::null()
  match convert_value(v, TString) {
    Ok(Null(_)) => assert_true(true)
    _ => panic()
  }
}

///|
test "convert_value null to number" {
  let v = HCLValue::null()
  match convert_value(v, TNumber) {
    Ok(Null(_)) => assert_true(true)
    _ => panic()
  }
}

///|
test "convert_value same type returns as-is" {
  let v = HCLValue::string("hello")
  match convert_value(v, TString) {
    Ok(String(s, _)) => assert_true(s == "hello")
    _ => panic()
  }
}

///|
test "convert_value unknown to string" {
  let v = HCLValue::unknown()
  match convert_value(v, TString) {
    Ok(Unknown(_)) => assert_true(true)
    _ => panic()
  }
}

///|
test "convert_value string to number fails" {
  let v = HCLValue::string("hello")
  assert_true(convert_value(v, TNumber) is Err(_))
}

// eval_conditional integration tests

///|
test "eval_conditional mixed types number and string" {
  let result = eval_conditional(
    Bool(true, Decor::empty()),
    Number(Number::from_int(1), Decor::empty()),
    String("hello", Decor::empty()),
  )
  match result {
    Ok(String(s, _)) => assert_true(s == "1")
    _ => panic()
  }
}

///|
test "eval_conditional mixed types false branch" {
  let result = eval_conditional(
    Bool(false, Decor::empty()),
    Number(Number::from_int(1), Decor::empty()),
    String("hello", Decor::empty()),
  )
  match result {
    Ok(String(s, _)) => assert_true(s == "hello")
    _ => panic()
  }
}

///|
test "eval_conditional same types" {
  let result = eval_conditional(
    Bool(true, Decor::empty()),
    Number(Number::from_int(1), Decor::empty()),
    Number(Number::from_int(2), Decor::empty()),
  )
  match result {
    Ok(Number(n, _)) =>
      match n.as_int() {
        Some(i) => assert_true(i == 1)
        None => panic()
      }
    _ => panic()
  }
}

///|
test "eval_conditional incompatible types number and bool" {
  let result = eval_conditional(
    Bool(true, Decor::empty()),
    Number(Number::from_int(1), Decor::empty()),
    Bool(true, Decor::empty()),
  )
  match result {
    Ok(Number(n, _)) =>
      match n.as_int() {
        Some(i) => assert_true(i == 1)
        None => panic()
      }
    _ => panic()
  }
}

///|
test "eval_conditional with null" {
  let result = eval_conditional(
    Bool(true, Decor::empty()),
    Null(Decor::empty()),
    String("hello", Decor::empty()),
  )
  match result {
    Ok(Null(_)) => assert_true(true)
    _ => panic()
  }
}

///|
test "eval_conditional with unknown condition" {
  let result = eval_conditional(
    Unknown(Decor::empty()),
    Bool(true, Decor::empty()),
    Bool(false, Decor::empty()),
  )
  match result {
    Ok(v) => assert_true(v.is_unknown())
    Err(_) => panic()
  }
}

///|
test "eval_conditional bool and string true branch" {
  let result = eval_conditional(
    Bool(true, Decor::empty()),
    Bool(true, Decor::empty()),
    String("no", Decor::empty()),
  )
  match result {
    Ok(String(s, _)) => assert_true(s == "true")
    _ => panic()
  }
}

///|
test "eval_conditional non-bool condition" {
  let result = eval_conditional(
    Number(Number::from_int(1), Decor::empty()),
    Bool(true, Decor::empty()),
    Bool(false, Decor::empty()),
  )
  assert_true(result is Err(_))
}

// eval_expr integration tests via parse

///|
test "eval conditional mixed number string via parse" {
  let input = "x = true ? 1 : \"hello\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let eval_result = eval_expr_simple(attr.get_value())
          match eval_result {
            Ok(String(s, _)) => assert_true(s == "1")
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "eval conditional mixed number string false via parse" {
  let input = "x = false ? 1 : \"hello\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let eval_result = eval_expr_simple(attr.get_value())
          match eval_result {
            Ok(String(s, _)) => assert_true(s == "hello")
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "eval conditional same type via parse" {
  let input = "x = true ? 1 : 2"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let eval_result = eval_expr_simple(attr.get_value())
          match eval_result {
            Ok(Number(n, _)) =>
              match n.as_int() {
                Some(i) => assert_true(i == 1)
                None => panic()
              }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "eval conditional incompatible via parse uses selected" {
  let input = "x = true ? 1 : true"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let eval_result = eval_expr_simple(attr.get_value())
          match eval_result {
            Ok(Number(n, _)) =>
              match n.as_int() {
                Some(i) => assert_true(i == 1)
                None => panic()
              }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "eval conditional null and string via parse" {
  let input = "x = true ? null : \"hello\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let eval_result = eval_expr_simple(attr.get_value())
          match eval_result {
            Ok(Null(_)) => assert_true(true)
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}
