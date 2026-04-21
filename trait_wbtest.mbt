///|
test "to_hcl_str Int" {
  let result = to_hcl_str(42)
  assert_eq(result, "42")
}

///|
test "to_hcl_str String" {
  let result = to_hcl_str("hello")
  assert_eq(result, "\"hello\"")
}

///|
test "to_hcl_str Bool true" {
  let result = to_hcl_str(true)
  assert_eq(result, "true")
}

///|
test "to_hcl_str Bool false" {
  let result = to_hcl_str(false)
  assert_eq(result, "false")
}

///|
test "to_hcl_str Double" {
  let result = to_hcl_str(3.14)
  assert_eq(result, "3.14")
}

///|
test "to_hcl_str Int64" {
  let result = to_hcl_str(100L)
  assert_eq(result, "100")
}

///|
test "to_hcl_str Option Some" {
  let opt : Int? = Some(42)
  let result = to_hcl_str(opt)
  assert_eq(result, "42")
}

///|
test "to_hcl_str Option None" {
  let opt : Int? = None
  let result = to_hcl_str(opt)
  assert_eq(result, "null")
}

///|
test "to_hcl_str Array" {
  let arr : Array[Int] = [1, 2, 3]
  let result = to_hcl_str(arr)
  assert_true(result.contains("1"))
  assert_true(result.contains("2"))
  assert_true(result.contains("3"))
}

///|
test "from_hcl_str Array" {
  let result : @lexer.HCLResult[Map[String, Array[Int]]] = from_hcl_str(
    "items = [1, 2, 3]",
  )
  assert_true(result is Ok(_))
  let m = result.unwrap()
  let arr = m["items"]
  assert_eq(arr.length(), 3)
  assert_eq(arr[0], 1)
  assert_eq(arr[1], 2)
  assert_eq(arr[2], 3)
}

///|
test "to_hcl_str Map" {
  let m : Map[String, Int] = { "a": 1 }
  let result = to_hcl_str(m)
  assert_true(result.contains("a"))
  assert_true(result.contains("1"))
}

///|
test "from_hcl_str Map" {
  let input = "a = 1\nb = 2"
  let result : @lexer.HCLResult[Map[String, Int]] = from_hcl_str(input)
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["a"], 1)
  assert_eq(m["b"], 2)
}

///|
test "from_hcl_str Int via body" {
  let result : @lexer.HCLResult[Map[String, Int]] = from_hcl_str("val = 42")
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["val"], 42)
}

///|
test "from_hcl_str String via body" {
  let result : @lexer.HCLResult[Map[String, String]] = from_hcl_str(
    "val = \"hello\"",
  )
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["val"], "hello")
}

///|
test "from_hcl_str Bool via body" {
  let result : @lexer.HCLResult[Map[String, Bool]] = from_hcl_str("val = true")
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["val"], true)
}

///|
test "roundtrip String via body" {
  let original = "hello world"
  let hcl = to_hcl_str(original)
  let result : @lexer.HCLResult[Map[String, String]] = from_hcl_str(
    "val = " + hcl,
  )
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["val"], original)
}

///|
test "roundtrip Bool via body" {
  let original = true
  let hcl = to_hcl_str(original)
  let result : @lexer.HCLResult[Map[String, Bool]] = from_hcl_str(
    "val = " + hcl,
  )
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["val"], original)
}

///|
test "roundtrip Int via body" {
  let original = 42
  let hcl = to_hcl_str(original)
  let result : @lexer.HCLResult[Map[String, Int]] = from_hcl_str("val = " + hcl)
  assert_true(result is Ok(_))
  let m = result.unwrap()
  assert_eq(m["val"], original)
}

///|
test "hcl_int helper" {
  let v = hcl_int(42)
  assert_true(v.is_number())
  assert_eq(v.as_int(), Some(42))
}

///|
test "hcl_int64 helper" {
  let v = hcl_int64(100L)
  assert_true(v.is_number())
  assert_eq(v.as_int64(), Some(100L))
}

///|
test "hcl_float helper" {
  let v = hcl_float(3.14)
  assert_true(v.is_number())
  assert_eq(v.as_float(), Some(3.14))
}

///|
test "hcl_str helper" {
  let v = hcl_str("hello")
  assert_true(v.is_string())
  assert_eq(v.as_string(), Some("hello"))
}

///|
test "hcl_bool helper" {
  let v1 = hcl_bool(true)
  assert_true(v1.is_bool())
  assert_eq(v1.as_bool(), Some(true))
  let v2 = hcl_bool(false)
  assert_eq(v2.as_bool(), Some(false))
}

///|
test "hcl_null helper" {
  let v = hcl_null()
  assert_true(v.is_null())
}

///|
test "hcl_array helper" {
  let arr = hcl_array([hcl_int(1), hcl_str("two")])
  assert_true(arr.is_array())
  let items = arr.as_array().unwrap()
  assert_eq(items.length(), 2)
}

///|
test "hcl_object helper" {
  let obj = hcl_object({ "key": hcl_str("value") })
  assert_true(obj.is_object())
  let m = obj.as_object().unwrap()
  assert_true(m["key"].is_string())
  assert_eq(m["key"].as_string(), Some("value"))
}
