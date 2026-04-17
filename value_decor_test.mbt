///|
test "HCLValue decoration" {
  let value = HCLValue::string("hello")
  assert_eq(value.get_decor().get_prefix(), None)

  let decor = Decor::new(Some(" "), Some("\n"))
  let value2 = value.set_decor(decor)
  assert_eq(value2.get_decor().get_prefix(), Some(" "))
  assert_eq(value2.as_string(), Some("hello"))
}

///|
test "HCLValue convenience constructors" {
  let null_val = HCLValue::null()
  assert_true(null_val.is_null())
  assert_eq(null_val.get_decor().get_prefix(), None)

  let bool_val = HCLValue::bool(true)
  assert_true(bool_val.is_bool())
  assert_eq(bool_val.as_bool(), Some(true))

  let int_val = HCLValue::int(42)
  assert_true(int_val.is_number())
  assert_eq(int_val.as_int(), Some(42))

  let str_val = HCLValue::string("test")
  assert_true(str_val.is_string())
  assert_eq(str_val.as_string(), Some("test"))

  let arr_val = HCLValue::array([HCLValue::int(1), HCLValue::int(2)])
  assert_true(arr_val.is_array())
  let arr = arr_val.as_array().unwrap()
  assert_eq(arr.length(), 2)
}

///|
test "HCLValue get_decor and set_decor" {
  let val = HCLValue::int(10)
  assert_true(val.get_decor() == Decor::empty())

  let new_decor = Decor::new(Some("/* comment */"), None)
  let val2 = val.set_decor(new_decor)
  assert_eq(val2.get_decor().get_prefix(), Some("/* comment */"))
  assert_eq(val2.get_decor().get_suffix(), None)
  assert_eq(val2.as_int(), Some(10))
}

///|
test "HCLValue is_* functions" {
  assert_true(HCLValue::null().is_null())
  assert_true(HCLValue::bool(false).is_bool())
  assert_true(HCLValue::int(0).is_number())
  assert_true(HCLValue::string("").is_string())
  assert_true(HCLValue::array([]).is_array())

  let obj = {}
  assert_true(HCLValue::object(obj).is_object())
}

///|
test "HCLValue as_* functions" {
  assert_eq(HCLValue::bool(true).as_bool(), Some(true))
  assert_eq(HCLValue::bool(false).as_bool(), Some(false))
  assert_eq(HCLValue::int(42).as_int(), Some(42))
  assert_eq(HCLValue::string("hello").as_string(), Some("hello"))

  // Wrong type returns None
  assert_eq(HCLValue::int(1).as_bool(), None)
  assert_eq(HCLValue::bool(true).as_string(), None)
}

///|
test "HCLValue to_json_string with decor" {
  assert_eq(HCLValue::null().to_json_string(), "null")
  assert_eq(HCLValue::bool(true).to_json_string(), "true")
  assert_eq(HCLValue::int(42).to_json_string(), "42")
  assert_eq(HCLValue::string("test").to_json_string(), "\"test\"")
}
