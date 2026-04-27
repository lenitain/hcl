///|
/// Built-in Functions Tests

///| =========================================================================
/// Test Helpers

///| =========================================================================

///|
fn num(n : Int) -> HCLValue {
  HCLValue::Number(Number::from_int(n), Decor::empty())
}

///|
fn str(s : String) -> HCLValue {
  HCLValue::String(s, Decor::empty())
}

///|
fn bool_true() -> HCLValue {
  HCLValue::Bool(true, Decor::empty())
}

///|
fn bool_false() -> HCLValue {
  HCLValue::Bool(false, Decor::empty())
}

///| =========================================================================
/// Numeric Functions Tests

///| =========================================================================

///|
test "abs positive" {
  let funcs = builtin_functions()
  let f = funcs["abs"]
  match f.call([HCLValue::Number(Number::from_int(5), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "abs negative" {
  let funcs = builtin_functions()
  let f = funcs["abs"]
  match f.call([HCLValue::Number(Number::from_int(-5), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "abs float" {
  let funcs = builtin_functions()
  let f = funcs["abs"]
  match
    f.call([HCLValue::Number(Number::from_finite_f64(-3.14), Decor::empty())]) {
    Ok(v) =>
      assert_true(
        v == HCLValue::Number(Number::from_finite_f64(3.14), Decor::empty()),
      )
    Err(_) => panic()
  }
}

///|
test "ceil" {
  let funcs = builtin_functions()
  let f = funcs["ceil"]
  match
    f.call([HCLValue::Number(Number::from_finite_f64(3.2), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(4), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "ceil negative" {
  let funcs = builtin_functions()
  let f = funcs["ceil"]
  match
    f.call([HCLValue::Number(Number::from_finite_f64(-3.2), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(-3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "floor" {
  let funcs = builtin_functions()
  let f = funcs["floor"]
  match
    f.call([HCLValue::Number(Number::from_finite_f64(3.8), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "floor negative" {
  let funcs = builtin_functions()
  let f = funcs["floor"]
  match
    f.call([HCLValue::Number(Number::from_finite_f64(-3.2), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(-4), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "log" {
  let funcs = builtin_functions()
  let f = funcs["log"]
  match
    f.call([
      HCLValue::Number(Number::from_finite_f64(8.0), Decor::empty()),
      HCLValue::Number(Number::from_finite_f64(2.0), Decor::empty()),
    ]) {
    Ok(HCLValue::Number(n, _)) =>
      assert_true((n.as_float() - 3.0).abs() < 0.0001)
    _ => panic()
  }
}

///|
test "log invalid base" {
  let funcs = builtin_functions()
  let f = funcs["log"]
  match
    f.call([
      HCLValue::Number(Number::from_finite_f64(8.0), Decor::empty()),
      HCLValue::Number(Number::from_finite_f64(1.0), Decor::empty()),
    ]) {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("base"))
  }
}

///|
test "max two args" {
  let funcs = builtin_functions()
  let f = funcs["max"]
  match
    f.call([
      HCLValue::Number(Number::from_int(3), Decor::empty()),
      HCLValue::Number(Number::from_int(7), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(7), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "max multiple args" {
  let funcs = builtin_functions()
  let f = funcs["max"]
  match
    f.call([
      HCLValue::Number(Number::from_int(3), Decor::empty()),
      HCLValue::Number(Number::from_int(7), Decor::empty()),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
      HCLValue::Number(Number::from_int(9), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(9), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "min two args" {
  let funcs = builtin_functions()
  let f = funcs["min"]
  match
    f.call([
      HCLValue::Number(Number::from_int(3), Decor::empty()),
      HCLValue::Number(Number::from_int(7), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "min multiple args" {
  let funcs = builtin_functions()
  let f = funcs["min"]
  match
    f.call([
      HCLValue::Number(Number::from_int(10), Decor::empty()),
      HCLValue::Number(Number::from_int(3), Decor::empty()),
      HCLValue::Number(Number::from_int(7), Decor::empty()),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "parseint base 10" {
  let funcs = builtin_functions()
  let f = funcs["parseint"]
  match
    f.call([
      HCLValue::String("42", Decor::empty()),
      HCLValue::Number(Number::from_int(10), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(42), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "parseint base 16" {
  let funcs = builtin_functions()
  let f = funcs["parseint"]
  match
    f.call([
      HCLValue::String("ff", Decor::empty()),
      HCLValue::Number(Number::from_int(16), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(255), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "parseint base 2" {
  let funcs = builtin_functions()
  let f = funcs["parseint"]
  match
    f.call([
      HCLValue::String("1010", Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(10), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "pow" {
  let funcs = builtin_functions()
  let f = funcs["pow"]
  match
    f.call([
      HCLValue::Number(Number::from_finite_f64(2.0), Decor::empty()),
      HCLValue::Number(Number::from_finite_f64(3.0), Decor::empty()),
    ]) {
    Ok(HCLValue::Number(n, _)) =>
      assert_true((n.as_float() - 8.0).abs() < 0.0001)
    _ => panic()
  }
}

///|
test "signum positive" {
  let funcs = builtin_functions()
  let f = funcs["signum"]
  match f.call([HCLValue::Number(Number::from_int(5), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(1), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "signum negative" {
  let funcs = builtin_functions()
  let f = funcs["signum"]
  match f.call([HCLValue::Number(Number::from_int(-5), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(-1), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "signum zero" {
  let funcs = builtin_functions()
  let f = funcs["signum"]
  match f.call([HCLValue::Number(Number::from_int(0), Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(0), Decor::empty()))
    Err(_) => panic()
  }
}

///| =========================================================================
/// Collection Functions Tests

///| =========================================================================

///|
test "length array" {
  let funcs = builtin_functions()
  let f = funcs["length"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "length string" {
  let funcs = builtin_functions()
  let f = funcs["length"]
  match f.call([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "length object" {
  let funcs = builtin_functions()
  let f = funcs["length"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  obj["b"] = HCLValue::Number(Number::from_int(2), Decor::empty())
  match f.call([HCLValue::Object(obj, Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(2), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "keys" {
  let funcs = builtin_functions()
  let f = funcs["keys"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  obj["b"] = HCLValue::Number(Number::from_int(2), Decor::empty())
  match f.call([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 2)
    _ => panic()
  }
}

///|
test "values" {
  let funcs = builtin_functions()
  let f = funcs["values"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  obj["b"] = HCLValue::Number(Number::from_int(2), Decor::empty())
  match f.call([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 2)
    _ => panic()
  }
}

///|
test "contains true" {
  let funcs = builtin_functions()
  let f = funcs["contains"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "contains false" {
  let funcs = builtin_functions()
  let f = funcs["contains"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "flatten nested" {
  let funcs = builtin_functions()
  let f = funcs["flatten"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Array(
            [
              HCLValue::Number(Number::from_int(1), Decor::empty()),
              HCLValue::Number(Number::from_int(2), Decor::empty()),
            ],
            Decor::empty(),
          ),
          HCLValue::Array(
            [HCLValue::Number(Number::from_int(3), Decor::empty())],
            Decor::empty(),
          ),
          HCLValue::Number(Number::from_int(4), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 4)
    _ => panic()
  }
}

///|
test "merge" {
  let funcs = builtin_functions()
  let f = funcs["merge"]
  let obj1 : Map[String, HCLValue] = Map::new()
  obj1["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  let obj2 : Map[String, HCLValue] = Map::new()
  obj2["b"] = HCLValue::Number(Number::from_int(2), Decor::empty())
  match
    f.call([
      HCLValue::Object(obj1, Decor::empty()),
      HCLValue::Object(obj2, Decor::empty()),
    ]) {
    Ok(HCLValue::Object(result, _)) => assert_true(result.length() == 2)
    _ => panic()
  }
}

///|
test "merge override" {
  let funcs = builtin_functions()
  let f = funcs["merge"]
  let obj1 : Map[String, HCLValue] = Map::new()
  obj1["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  let obj2 : Map[String, HCLValue] = Map::new()
  obj2["a"] = HCLValue::Number(Number::from_int(99), Decor::empty())
  match
    f.call([
      HCLValue::Object(obj1, Decor::empty()),
      HCLValue::Object(obj2, Decor::empty()),
    ]) {
    Ok(HCLValue::Object(result, _)) =>
      assert_true(
        result["a"] == HCLValue::Number(Number::from_int(99), Decor::empty()),
      )
    _ => panic()
  }
}

///|
test "reverse array" {
  let funcs = builtin_functions()
  let f = funcs["reverse"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(3), Decor::empty()),
      )
      assert_true(
        arr[1] == HCLValue::Number(Number::from_int(2), Decor::empty()),
      )
      assert_true(
        arr[2] == HCLValue::Number(Number::from_int(1), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "reverse string" {
  let funcs = builtin_functions()
  let f = funcs["reverse"]
  match f.call([HCLValue::String("abc", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("cba", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "distinct" {
  let funcs = builtin_functions()
  let f = funcs["distinct"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 3)
    _ => panic()
  }
}

///|
test "sort" {
  let funcs = builtin_functions()
  let f = funcs["sort"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(3), Decor::empty()),
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(1), Decor::empty()),
      )
      assert_true(
        arr[1] == HCLValue::Number(Number::from_int(2), Decor::empty()),
      )
      assert_true(
        arr[2] == HCLValue::Number(Number::from_int(3), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "sort strings" {
  let funcs = builtin_functions()
  let f = funcs["sort"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::String("c", Decor::empty()),
          HCLValue::String("a", Decor::empty()),
          HCLValue::String("b", Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr[0] == HCLValue::String("a", Decor::empty()))
      assert_true(arr[1] == HCLValue::String("b", Decor::empty()))
      assert_true(arr[2] == HCLValue::String("c", Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "slice" {
  let funcs = builtin_functions()
  let f = funcs["slice"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
          HCLValue::Number(Number::from_int(4), Decor::empty()),
          HCLValue::Number(Number::from_int(5), Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(4), Decor::empty()),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr.length() == 3)
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(2), Decor::empty()),
      )
      assert_true(
        arr[1] == HCLValue::Number(Number::from_int(3), Decor::empty()),
      )
      assert_true(
        arr[2] == HCLValue::Number(Number::from_int(4), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "element" {
  let funcs = builtin_functions()
  let f = funcs["element"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(10), Decor::empty()),
          HCLValue::Number(Number::from_int(20), Decor::empty()),
          HCLValue::Number(Number::from_int(30), Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Number(Number::from_int(1), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(20), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "element wrap around" {
  let funcs = builtin_functions()
  let f = funcs["element"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(10), Decor::empty()),
          HCLValue::Number(Number::from_int(20), Decor::empty()),
          HCLValue::Number(Number::from_int(30), Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(30), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "concat basic" {
  let funcs = builtin_functions()
  let f = funcs["concat"]
  let arr1 = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ],
    Decor::empty(),
  )
  let arr2 = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(3), Decor::empty()),
      HCLValue::Number(Number::from_int(4), Decor::empty()),
    ],
    Decor::empty(),
  )
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 4)
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(1), Decor::empty()),
      )
      assert_true(
        arr[3] == HCLValue::Number(Number::from_int(4), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "concat empty arrays" {
  let funcs = builtin_functions()
  let f = funcs["concat"]
  let arr1 = HCLValue::Array([], Decor::empty())
  let arr2 = HCLValue::Array(
    [HCLValue::Number(Number::from_int(1), Decor::empty())],
    Decor::empty(),
  )
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => assert_eq(arr.length(), 1)
    _ => panic()
  }
}

///|
test "concat type error" {
  let funcs = builtin_functions()
  let f = funcs["concat"]
  match
    f.call([
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "coalesce first non-null" {
  let funcs = builtin_functions()
  let f = funcs["coalesce"]
  match
    f.call([
      HCLValue::Null(Decor::empty()),
      HCLValue::Number(Number::from_int(42), Decor::empty()),
      HCLValue::String("hello", Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(42), Decor::empty()))
    _ => panic()
  }
}

///|
test "coalesce all null" {
  let funcs = builtin_functions()
  let f = funcs["coalesce"]
  match
    f.call([HCLValue::Null(Decor::empty()), HCLValue::Null(Decor::empty())]) {
    Ok(HCLValue::Null(_)) => assert_true(true)
    _ => panic()
  }
}

///|
test "range single arg" {
  let funcs = builtin_functions()
  let f = funcs["range"]
  match f.call([HCLValue::Number(Number::from_int(3), Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 3)
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(0), Decor::empty()),
      )
      assert_true(
        arr[2] == HCLValue::Number(Number::from_int(2), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "range two args" {
  let funcs = builtin_functions()
  let f = funcs["range"]
  match
    f.call([
      HCLValue::Number(Number::from_int(2), Decor::empty()),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 3)
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(2), Decor::empty()),
      )
      assert_true(
        arr[2] == HCLValue::Number(Number::from_int(4), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "range empty" {
  let funcs = builtin_functions()
  let f = funcs["range"]
  match f.call([HCLValue::Number(Number::from_int(0), Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_eq(arr.length(), 0)
    _ => panic()
  }
}

///|
test "chunklist basic" {
  let funcs = builtin_functions()
  let f = funcs["chunklist"]
  let arr = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
      HCLValue::Number(Number::from_int(3), Decor::empty()),
      HCLValue::Number(Number::from_int(4), Decor::empty()),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
    ],
    Decor::empty(),
  )
  match f.call([arr, HCLValue::Number(Number::from_int(2), Decor::empty())]) {
    Ok(HCLValue::Array(chunks, _)) => {
      assert_eq(chunks.length(), 3)
      match chunks[0] {
        HCLValue::Array(c, _) => assert_eq(c.length(), 2)
        _ => panic()
      }
      match chunks[2] {
        HCLValue::Array(c, _) => assert_eq(c.length(), 1)
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "chunklist size larger than array" {
  let funcs = builtin_functions()
  let f = funcs["chunklist"]
  let arr = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ],
    Decor::empty(),
  )
  match f.call([arr, HCLValue::Number(Number::from_int(10), Decor::empty())]) {
    Ok(HCLValue::Array(chunks, _)) => assert_eq(chunks.length(), 1)
    _ => panic()
  }
}

///|
test "chunklist invalid size" {
  let funcs = builtin_functions()
  let f = funcs["chunklist"]
  let arr = HCLValue::Array(
    [HCLValue::Number(Number::from_int(1), Decor::empty())],
    Decor::empty(),
  )
  match f.call([arr, HCLValue::Number(Number::from_int(0), Decor::empty())]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "lookup found" {
  let funcs = builtin_functions()
  let f = funcs["lookup"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  obj["b"] = HCLValue::Number(Number::from_int(2), Decor::empty())
  match
    f.call([
      HCLValue::Object(obj, Decor::empty()),
      HCLValue::String("b", Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(2), Decor::empty()))
    _ => panic()
  }
}

///|
test "lookup with default" {
  let funcs = builtin_functions()
  let f = funcs["lookup"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  match
    f.call([
      HCLValue::Object(obj, Decor::empty()),
      HCLValue::String("missing", Decor::empty()),
      HCLValue::Number(Number::from_int(99), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(99), Decor::empty()))
    _ => panic()
  }
}

///|
test "lookup not found no default" {
  let funcs = builtin_functions()
  let f = funcs["lookup"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  match
    f.call([
      HCLValue::Object(obj, Decor::empty()),
      HCLValue::String("missing", Decor::empty()),
    ]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "zipmap basic" {
  let funcs = builtin_functions()
  let f = funcs["zipmap"]
  let keys = HCLValue::Array(
    [
      HCLValue::String("a", Decor::empty()),
      HCLValue::String("b", Decor::empty()),
    ],
    Decor::empty(),
  )
  let values = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ],
    Decor::empty(),
  )
  match f.call([keys, values]) {
    Ok(HCLValue::Object(m, _)) => {
      assert_true(
        m["a"] == HCLValue::Number(Number::from_int(1), Decor::empty()),
      )
      assert_true(
        m["b"] == HCLValue::Number(Number::from_int(2), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "zipmap different lengths" {
  let funcs = builtin_functions()
  let f = funcs["zipmap"]
  let keys = HCLValue::Array(
    [
      HCLValue::String("a", Decor::empty()),
      HCLValue::String("b", Decor::empty()),
      HCLValue::String("c", Decor::empty()),
    ],
    Decor::empty(),
  )
  let values = HCLValue::Array(
    [HCLValue::Number(Number::from_int(1), Decor::empty())],
    Decor::empty(),
  )
  match f.call([keys, values]) {
    Ok(HCLValue::Object(m, _)) => assert_eq(m.length(), 1)
    _ => panic()
  }
}

///| =========================================================================
/// String Functions Tests

///| =========================================================================

///|
test "chomp newline" {
  let funcs = builtin_functions()
  let f = funcs["chomp"]
  match f.call([HCLValue::String("hello\n", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "chomp crlf" {
  let funcs = builtin_functions()
  let f = funcs["chomp"]
  match f.call([HCLValue::String("hello\r\n", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "chomp no newline" {
  let funcs = builtin_functions()
  let f = funcs["chomp"]
  match f.call([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "indent" {
  let funcs = builtin_functions()
  let f = funcs["indent"]
  match
    f.call([
      HCLValue::Number(Number::from_int(2), Decor::empty()),
      HCLValue::String("a\nb", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("  a\n  b", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "join" {
  let funcs = builtin_functions()
  let f = funcs["join"]
  match
    f.call([
      HCLValue::String(", ", Decor::empty()),
      HCLValue::Array(
        [
          HCLValue::String("a", Decor::empty()),
          HCLValue::String("b", Decor::empty()),
          HCLValue::String("c", Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("a, b, c", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "lower" {
  let funcs = builtin_functions()
  let f = funcs["lower"]
  match f.call([HCLValue::String("HELLO", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "upper" {
  let funcs = builtin_functions()
  let f = funcs["upper"]
  match f.call([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("HELLO", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "replace" {
  let funcs = builtin_functions()
  let f = funcs["replace"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("world", Decor::empty()),
      HCLValue::String("moon", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("hello moon", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "split" {
  let funcs = builtin_functions()
  let f = funcs["split"]
  match
    f.call([
      HCLValue::String(",", Decor::empty()),
      HCLValue::String("a,b,c", Decor::empty()),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr.length() == 3)
      assert_true(arr[0] == HCLValue::String("a", Decor::empty()))
      assert_true(arr[1] == HCLValue::String("b", Decor::empty()))
      assert_true(arr[2] == HCLValue::String("c", Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "strrev" {
  let funcs = builtin_functions()
  let f = funcs["strrev"]
  match f.call([HCLValue::String("abc", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("cba", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "substr" {
  let funcs = builtin_functions()
  let f = funcs["substr"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::Number(Number::from_int(6), Decor::empty()),
      HCLValue::Number(Number::from_int(5), Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("world", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "trim" {
  let funcs = builtin_functions()
  let f = funcs["trim"]
  match
    f.call([
      HCLValue::String("  hello  ", Decor::empty()),
      HCLValue::String(" ", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "trimprefix" {
  let funcs = builtin_functions()
  let f = funcs["trimprefix"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("hello ", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("world", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "trimprefix no match" {
  let funcs = builtin_functions()
  let f = funcs["trimprefix"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("bye ", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("hello world", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "trimsuffix" {
  let funcs = builtin_functions()
  let f = funcs["trimsuffix"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String(" world", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "trimsuffix no match" {
  let funcs = builtin_functions()
  let f = funcs["trimsuffix"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String(" moon", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::String("hello world", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "trimspace" {
  let funcs = builtin_functions()
  let f = funcs["trimspace"]
  match f.call([HCLValue::String("  hello  ", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "format" {
  let funcs = builtin_functions()
  let f = funcs["format"]
  match
    f.call([
      HCLValue::String("Hello %s, you are %d years old", Decor::empty()),
      HCLValue::String("Alice", Decor::empty()),
      HCLValue::Number(Number::from_int(30), Decor::empty()),
    ]) {
    Ok(v) =>
      assert_true(
        v ==
        HCLValue::String("Hello Alice, you are 30 years old", Decor::empty()),
      )
    Err(_) => panic()
  }
}

///|
test "format percent escape" {
  let funcs = builtin_functions()
  let f = funcs["format"]
  match f.call([HCLValue::String("100%%", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("100%", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "formatlist" {
  let funcs = builtin_functions()
  let f = funcs["formatlist"]
  match
    f.call([
      HCLValue::String("item-%d", Decor::empty()),
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr.length() == 3)
      assert_true(arr[0] == HCLValue::String("item-1", Decor::empty()))
      assert_true(arr[1] == HCLValue::String("item-2", Decor::empty()))
      assert_true(arr[2] == HCLValue::String("item-3", Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "startswith match" {
  let funcs = builtin_functions()
  let f = funcs["startswith"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("hello", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "startswith no match" {
  let funcs = builtin_functions()
  let f = funcs["startswith"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("world", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "startswith empty prefix" {
  let funcs = builtin_functions()
  let f = funcs["startswith"]
  match
    f.call([
      HCLValue::String("hello", Decor::empty()),
      HCLValue::String("", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "endswith match" {
  let funcs = builtin_functions()
  let f = funcs["endswith"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("world", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "endswith no match" {
  let funcs = builtin_functions()
  let f = funcs["endswith"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("hello", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "endswith empty suffix" {
  let funcs = builtin_functions()
  let f = funcs["endswith"]
  match
    f.call([
      HCLValue::String("hello", Decor::empty()),
      HCLValue::String("", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "title basic" {
  let funcs = builtin_functions()
  let f = funcs["title"]
  match f.call([HCLValue::String("hello world", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("Hello World", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "title already titled" {
  let funcs = builtin_functions()
  let f = funcs["title"]
  match f.call([HCLValue::String("Hello World", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("Hello World", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "title all caps" {
  let funcs = builtin_functions()
  let f = funcs["title"]
  match f.call([HCLValue::String("HELLO WORLD", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("Hello World", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "title single word" {
  let funcs = builtin_functions()
  let f = funcs["title"]
  match f.call([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("Hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "contains string match" {
  let funcs = builtin_functions()
  let f = funcs["contains"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("world", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "contains string no match" {
  let funcs = builtin_functions()
  let f = funcs["contains"]
  match
    f.call([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::String("moon", Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "contains string error" {
  let funcs = builtin_functions()
  let f = funcs["contains"]
  match
    f.call([
      HCLValue::String("hello", Decor::empty()),
      HCLValue::Number(Number::from_int(42), Decor::empty()),
    ]) {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("string substring"))
  }
}

///| =========================================================================
/// Type Conversion Functions Tests

///| =========================================================================

///|
test "tobool from string" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f.call([HCLValue::String("true", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tobool from string false" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f.call([HCLValue::String("FALSE", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tobool from int" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f.call([HCLValue::Number(Number::from_int(1), Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tobool from int zero" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f.call([HCLValue::Number(Number::from_int(0), Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tonumber from string" {
  let funcs = builtin_functions()
  let f = funcs["tonumber"]
  match f.call([HCLValue::String("42", Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(42), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tonumber from string float" {
  let funcs = builtin_functions()
  let f = funcs["tonumber"]
  match f.call([HCLValue::String("3.14", Decor::empty())]) {
    Ok(v) =>
      assert_true(
        v == HCLValue::Number(Number::from_finite_f64(3.14), Decor::empty()),
      )
    Err(_) => panic()
  }
}

///|
test "tonumber from bool" {
  let funcs = builtin_functions()
  let f = funcs["tonumber"]
  match f.call([HCLValue::Bool(true, Decor::empty())]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(1), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tolist" {
  let funcs = builtin_functions()
  let f = funcs["tolist"]
  match f.call([HCLValue::Number(Number::from_int(42), Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 1)
    _ => panic()
  }
}

///|
test "tolist already array" {
  let funcs = builtin_functions()
  let f = funcs["tolist"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 2)
    _ => panic()
  }
}

///|
test "tomap" {
  let funcs = builtin_functions()
  let f = funcs["tomap"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Number(Number::from_int(1), Decor::empty())
  match f.call([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::Object(result, _)) =>
      assert_true(
        result["a"] == HCLValue::Number(Number::from_int(1), Decor::empty()),
      )
    _ => panic()
  }
}

///|
test "tomap error" {
  let funcs = builtin_functions()
  let f = funcs["tomap"]
  match f.call([HCLValue::Number(Number::from_int(42), Decor::empty())]) {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("object"))
  }
}

///|
test "toset" {
  let funcs = builtin_functions()
  let f = funcs["toset"]
  match
    f.call([
      HCLValue::Array(
        [
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(2), Decor::empty()),
          HCLValue::Number(Number::from_int(1), Decor::empty()),
          HCLValue::Number(Number::from_int(3), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 3)
    _ => panic()
  }
}

///|
test "tostring from int" {
  let funcs = builtin_functions()
  let f = funcs["tostring"]
  match f.call([HCLValue::Number(Number::from_int(42), Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("42", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tostring from bool" {
  let funcs = builtin_functions()
  let f = funcs["tostring"]
  match f.call([HCLValue::Bool(true, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("true", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tostring from null" {
  let funcs = builtin_functions()
  let f = funcs["tostring"]
  match f.call([HCLValue::Null(Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("null", Decor::empty()))
    Err(_) => panic()
  }
}

///| =========================================================================
/// Integration Tests

///| =========================================================================

///|
test "builtin functions integrated in eval" {
  let fc = FuncCall::builder("abs").arg(expr_int(-5)).build()
  let expr = expr_func_call(fc)
  let result = eval_expr(expr, Map::new(), builtin_functions())
  match result {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "nested function calls" {
  let inner = FuncCall::builder("tostring").arg(expr_int(42)).build()
  let outer = FuncCall::builder("upper").arg(expr_func_call(inner)).build()
  let expr = expr_func_call(outer)
  let result = eval_expr(expr, Map::new(), builtin_functions())
  match result {
    Ok(v) => assert_true(v == HCLValue::String("42", Decor::empty()))
    Err(_) => panic()
  }
}

///| =========================================================================
/// FuncDef Parameter Validation Tests

///| =========================================================================

///|
test "ParamType Any accepts all types" {
  let any = ParamType::Any
  assert_true(any.is_satisfied_by(Bool(true, Decor::empty())))
  assert_true(any.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_true(any.is_satisfied_by(String("hi", Decor::empty())))
  assert_true(any.is_satisfied_by(Null(Decor::empty())))
  assert_true(any.is_satisfied_by(Array([], Decor::empty())))
}

///|
test "ParamType Bool rejects non-bool" {
  let pt = ParamType::ParamBool
  assert_true(pt.is_satisfied_by(Bool(true, Decor::empty())))
  assert_false(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_false(pt.is_satisfied_by(String("true", Decor::empty())))
}

///|
test "ParamType Number rejects non-number" {
  let pt = ParamType::ParamNumber
  assert_true(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_false(pt.is_satisfied_by(Bool(true, Decor::empty())))
  assert_false(pt.is_satisfied_by(String("1", Decor::empty())))
}

///|
test "ParamType String rejects non-string" {
  let pt = ParamType::ParamString
  assert_true(pt.is_satisfied_by(String("hi", Decor::empty())))
  assert_false(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
}

///|
test "ParamType Array checks elements" {
  let pt = ParamType::ParamArray(ParamString)
  assert_true(
    pt.is_satisfied_by(
      Array(
        [String("a", Decor::empty()), String("b", Decor::empty())],
        Decor::empty(),
      ),
    ),
  )
  assert_false(
    pt.is_satisfied_by(
      Array(
        [
          String("a", Decor::empty()),
          Number(Number::from_int(1), Decor::empty()),
        ],
        Decor::empty(),
      ),
    ),
  )
  assert_false(pt.is_satisfied_by(String("not array", Decor::empty())))
}

///|
test "ParamType Nullable accepts null" {
  let pt = ParamType::Nullable(ParamString)
  assert_true(pt.is_satisfied_by(Null(Decor::empty())))
  assert_true(pt.is_satisfied_by(String("hi", Decor::empty())))
  assert_false(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
}

///|
test "ParamType OneOf accepts any matching" {
  let pt = ParamType::OneOf([ParamString, ParamNumber])
  assert_true(pt.is_satisfied_by(String("hi", Decor::empty())))
  assert_true(pt.is_satisfied_by(Number(Number::from_int(1), Decor::empty())))
  assert_false(pt.is_satisfied_by(Bool(true, Decor::empty())))
}

///|
test "ParamType display_name" {
  assert_true(ParamType::Any.display_name() == "any")
  assert_true(ParamType::ParamBool.display_name() == "bool")
  assert_true(ParamType::ParamNumber.display_name() == "number")
  assert_true(ParamType::ParamString.display_name() == "string")
  assert_true(
    ParamType::ParamArray(ParamString).display_name() == "array(string)",
  )
  assert_true(ParamType::Nullable(ParamNumber).display_name() == "number?")
}

///|
fn fn_add_stub(_args : Array[HCLValue]) -> HCLResult[HCLValue] {
  Ok(Number(Number::from_int(0), Decor::empty()))
}

///|
test "FuncDef call validates too few args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .param(ParamNumber)
    .build("add", fn_add_stub)
  match fd.call([Number(Number::from_int(1), Decor::empty())]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef call validates too many args" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("one_param", fn_add_stub)
  match
    fd.call([
      Number(Number::from_int(1), Decor::empty()),
      Number(Number::from_int(2), Decor::empty()),
    ]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef call validates type mismatch" {
  let fd = FuncDefBuilder::new()
    .param(ParamNumber)
    .build("needs_num", fn_add_stub)
  match fd.call([String("not a number", Decor::empty())]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef call succeeds with valid args" {
  let funcs = builtin_functions()
  let fd = funcs["abs"]
  match fd.call([Number(Number::from_int(-5), Decor::empty())]) {
    Ok(v) => assert_true(v == Number(Number::from_int(5), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "FuncDef variadic accepts extra args" {
  let funcs = builtin_functions()
  let fd = funcs["max"]
  match
    fd.call([
      Number(Number::from_int(1), Decor::empty()),
      Number(Number::from_int(3), Decor::empty()),
      Number(Number::from_int(2), Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == Number(Number::from_int(3), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "FuncDef variadic rejects wrong type in extra args" {
  let funcs = builtin_functions()
  let fd = funcs["max"]
  match
    fd.call([
      Number(Number::from_int(1), Decor::empty()),
      String("not number", Decor::empty()),
    ]) {
    Err(_) => assert_true(true)
    Ok(_) => panic()
  }
}

///|
test "FuncDef builder factory" {
  let fd = FuncDef::builder().param(ParamString).build("test_fn", fn_add_stub)
  match fd.call([String("hello", Decor::empty())]) {
    Ok(_) => assert_true(true)
    Err(_) => panic()
  }
}

///| =========================================================================
/// Collection Functions - transpose, matchkeys

///| =========================================================================

///|
test "transpose basic" {
  let funcs = builtin_functions()
  let f = funcs["transpose"]
  let obj = HCLValue::Object(
    {
      "a": HCLValue::Array(
        [
          HCLValue::String("x", Decor::empty()),
          HCLValue::String("y", Decor::empty()),
        ],
        Decor::empty(),
      ),
      "b": HCLValue::Array(
        [
          HCLValue::String("y", Decor::empty()),
          HCLValue::String("z", Decor::empty()),
        ],
        Decor::empty(),
      ),
    },
    Decor::empty(),
  )
  match f.call([obj]) {
    Ok(HCLValue::Object(m, _)) => {
      assert_true(m.get("x") is Some(_))
      assert_true(m.get("y") is Some(_))
      assert_true(m.get("z") is Some(_))
      match m["x"] {
        HCLValue::Array(arr, _) => {
          assert_eq(arr.length(), 1)
          assert_true(arr[0] == HCLValue::String("a", Decor::empty()))
        }
        _ => panic()
      }
      match m["y"] {
        HCLValue::Array(arr, _) => assert_eq(arr.length(), 2)
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "transpose empty" {
  let funcs = builtin_functions()
  let f = funcs["transpose"]
  let obj = HCLValue::Object({}, Decor::empty())
  match f.call([obj]) {
    Ok(HCLValue::Object(m, _)) => assert_eq(m.length(), 0)
    _ => panic()
  }
}

///|
test "transpose type error" {
  let funcs = builtin_functions()
  let f = funcs["transpose"]
  match f.call([HCLValue::Number(Number::from_int(1), Decor::empty())]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "matchkeys basic" {
  let funcs = builtin_functions()
  let f = funcs["matchkeys"]
  let search = HCLValue::Array(
    [
      HCLValue::String("a", Decor::empty()),
      HCLValue::String("c", Decor::empty()),
    ],
    Decor::empty(),
  )
  let keys = HCLValue::Array(
    [
      HCLValue::String("a", Decor::empty()),
      HCLValue::String("b", Decor::empty()),
      HCLValue::String("c", Decor::empty()),
    ],
    Decor::empty(),
  )
  let values = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
      HCLValue::Number(Number::from_int(3), Decor::empty()),
    ],
    Decor::empty(),
  )
  match f.call([search, keys, values]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      assert_true(
        arr[0] == HCLValue::Number(Number::from_int(1), Decor::empty()),
      )
      assert_true(
        arr[1] == HCLValue::Number(Number::from_int(3), Decor::empty()),
      )
    }
    _ => panic()
  }
}

///|
test "matchkeys no match" {
  let funcs = builtin_functions()
  let f = funcs["matchkeys"]
  let search = HCLValue::Array(
    [HCLValue::String("x", Decor::empty())],
    Decor::empty(),
  )
  let keys = HCLValue::Array(
    [
      HCLValue::String("a", Decor::empty()),
      HCLValue::String("b", Decor::empty()),
    ],
    Decor::empty(),
  )
  let values = HCLValue::Array(
    [
      HCLValue::Number(Number::from_int(1), Decor::empty()),
      HCLValue::Number(Number::from_int(2), Decor::empty()),
    ],
    Decor::empty(),
  )
  match f.call([search, keys, values]) {
    Ok(HCLValue::Array(arr, _)) => assert_eq(arr.length(), 0)
    _ => panic()
  }
}

///| =========================================================================
/// Collection Functions - sum, alltrue, anytrue, one

///| =========================================================================

///|
test "sum basic" {
  let funcs = builtin_functions()
  let f = funcs["sum"]
  let arr = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == num(6))
    _ => panic()
  }
}

///|
test "sum empty" {
  let funcs = builtin_functions()
  let f = funcs["sum"]
  let arr = HCLValue::Array([], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == num(0))
    _ => panic()
  }
}

///|
test "sum type error" {
  let funcs = builtin_functions()
  let f = funcs["sum"]
  let arr = HCLValue::Array([str("a")], Decor::empty())
  match f.call([arr]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "alltrue all true" {
  let funcs = builtin_functions()
  let f = funcs["alltrue"]
  let arr = HCLValue::Array([bool_true(), bool_true()], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_true())
    _ => panic()
  }
}

///|
test "alltrue has false" {
  let funcs = builtin_functions()
  let f = funcs["alltrue"]
  let arr = HCLValue::Array([bool_true(), bool_false()], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_false())
    _ => panic()
  }
}

///|
test "alltrue empty" {
  let funcs = builtin_functions()
  let f = funcs["alltrue"]
  let arr = HCLValue::Array([], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_true())
    _ => panic()
  }
}

///|
test "anytrue mixed" {
  let funcs = builtin_functions()
  let f = funcs["anytrue"]
  let arr = HCLValue::Array([bool_false(), bool_true()], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_true())
    _ => panic()
  }
}

///|
test "anytrue all false" {
  let funcs = builtin_functions()
  let f = funcs["anytrue"]
  let arr = HCLValue::Array([bool_false(), bool_false()], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_false())
    _ => panic()
  }
}

///|
test "anytrue empty" {
  let funcs = builtin_functions()
  let f = funcs["anytrue"]
  let arr = HCLValue::Array([], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == bool_false())
    _ => panic()
  }
}

///|
test "one single element" {
  let funcs = builtin_functions()
  let f = funcs["one"]
  let arr = HCLValue::Array([num(42)], Decor::empty())
  match f.call([arr]) {
    Ok(v) => assert_true(v == num(42))
    _ => panic()
  }
}

///|
test "one empty" {
  let funcs = builtin_functions()
  let f = funcs["one"]
  let arr = HCLValue::Array([], Decor::empty())
  match f.call([arr]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "one multiple elements" {
  let funcs = builtin_functions()
  let f = funcs["one"]
  let arr = HCLValue::Array([num(1), num(2)], Decor::empty())
  match f.call([arr]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///| =========================================================================
/// Set Functions Tests

///| =========================================================================

///|
test "setunion basic" {
  let funcs = builtin_functions()
  let f = funcs["setunion"]
  let arr1 = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  let arr2 = HCLValue::Array([num(2), num(3), num(4)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 4)
      assert_true(arr[0] == num(1))
      assert_true(arr[1] == num(2))
      assert_true(arr[2] == num(3))
      assert_true(arr[3] == num(4))
    }
    _ => panic()
  }
}

///|
test "setunion single array" {
  let funcs = builtin_functions()
  let f = funcs["setunion"]
  let arr = HCLValue::Array([num(1), num(2), num(1)], Decor::empty())
  match f.call([arr]) {
    Ok(HCLValue::Array(result, _)) => assert_eq(result.length(), 2)
    _ => panic()
  }
}

///|
test "setunion type error" {
  let funcs = builtin_functions()
  let f = funcs["setunion"]
  match f.call([num(1), num(2)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "setintersection basic" {
  let funcs = builtin_functions()
  let f = funcs["setintersection"]
  let arr1 = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  let arr2 = HCLValue::Array([num(2), num(3), num(4)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      assert_true(arr[0] == num(2))
      assert_true(arr[1] == num(3))
    }
    _ => panic()
  }
}

///|
test "setintersection single array" {
  let funcs = builtin_functions()
  let f = funcs["setintersection"]
  let arr = HCLValue::Array([num(1), num(2), num(1)], Decor::empty())
  match f.call([arr]) {
    Ok(HCLValue::Array(result, _)) => assert_eq(result.length(), 2)
    _ => panic()
  }
}

///|
test "setintersection type error" {
  let funcs = builtin_functions()
  let f = funcs["setintersection"]
  match f.call([num(1), num(2)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "setsubtract basic" {
  let funcs = builtin_functions()
  let f = funcs["setsubtract"]
  let arr1 = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  let arr2 = HCLValue::Array([num(2), num(4)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      assert_true(arr[0] == num(1))
      assert_true(arr[1] == num(3))
    }
    _ => panic()
  }
}

///|
test "setsubtract no overlap" {
  let funcs = builtin_functions()
  let f = funcs["setsubtract"]
  let arr1 = HCLValue::Array([num(1), num(2)], Decor::empty())
  let arr2 = HCLValue::Array([num(3), num(4)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      assert_true(arr[0] == num(1))
      assert_true(arr[1] == num(2))
    }
    _ => panic()
  }
}

///|
test "setsubtract type error" {
  let funcs = builtin_functions()
  let f = funcs["setsubtract"]
  match f.call([num(1), num(2)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "setsymmetricdifference basic" {
  let funcs = builtin_functions()
  let f = funcs["setsymmetricdifference"]
  let arr1 = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  let arr2 = HCLValue::Array([num(2), num(3), num(4)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      assert_true(arr[0] == num(1))
      assert_true(arr[1] == num(4))
    }
    _ => panic()
  }
}

///|
test "setsymmetricdifference identical arrays" {
  let funcs = builtin_functions()
  let f = funcs["setsymmetricdifference"]
  let arr1 = HCLValue::Array([num(1), num(2)], Decor::empty())
  let arr2 = HCLValue::Array([num(1), num(2)], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => assert_eq(arr.length(), 0)
    _ => panic()
  }
}

///|
test "setsymmetricdifference type error" {
  let funcs = builtin_functions()
  let f = funcs["setsymmetricdifference"]
  match f.call([num(1), num(2)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "setproduct basic" {
  let funcs = builtin_functions()
  let f = funcs["setproduct"]
  let arr1 = HCLValue::Array([num(1), num(2)], Decor::empty())
  let arr2 = HCLValue::Array([str("a"), str("b")], Decor::empty())
  match f.call([arr1, arr2]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 4)
      assert_true(arr[0] == HCLValue::Array([num(1), str("a")], Decor::empty()))
      assert_true(arr[1] == HCLValue::Array([num(1), str("b")], Decor::empty()))
      assert_true(arr[2] == HCLValue::Array([num(2), str("a")], Decor::empty()))
      assert_true(arr[3] == HCLValue::Array([num(2), str("b")], Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "setproduct zero args" {
  let funcs = builtin_functions()
  let f = funcs["setproduct"]
  match f.call([]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 1)
      assert_true(arr[0] == HCLValue::Array([], Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "setproduct type error" {
  let funcs = builtin_functions()
  let f = funcs["setproduct"]
  match f.call([num(1)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "setissubset basic" {
  let funcs = builtin_functions()
  let f = funcs["setissubset"]
  let s1 = HCLValue::Array([num(1), num(2)], Decor::empty())
  let s2 = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  match f.call([s1, s2]) {
    Ok(HCLValue::Bool(b, _)) => assert_true(b)
    _ => panic()
  }
}

///|
test "setissubset not subset" {
  let funcs = builtin_functions()
  let f = funcs["setissubset"]
  let s1 = HCLValue::Array([num(1), num(4)], Decor::empty())
  let s2 = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  match f.call([s1, s2]) {
    Ok(HCLValue::Bool(b, _)) => assert_true(!b)
    _ => panic()
  }
}

///|
test "setissubset type error" {
  let funcs = builtin_functions()
  let f = funcs["setissubset"]
  match f.call([num(1), num(2)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///| =========================================================================
/// Encoding Functions Tests

///| =========================================================================

///|
test "jsondecode basic" {
  let funcs = builtin_functions()
  let f = funcs["jsondecode"]
  match f.call([str("{\"a\": 1, \"b\": \"hello\"}")]) {
    Ok(HCLValue::Object(o, _)) =>
      for k, v in o {
        if k == "a" {
          match v {
            HCLValue::Number(_, _) => assert_true(true)
            _ => panic()
          }
        }
        if k == "b" {
          match v {
            HCLValue::String(s, _) => assert_true(s == "hello")
            _ => panic()
          }
        }
      }
    _ => panic()
  }
}

///|
test "jsondecode nested" {
  let funcs = builtin_functions()
  let f = funcs["jsondecode"]
  match f.call([str("{\"arr\": [1, 2, 3]}")]) {
    Ok(HCLValue::Object(o, _)) =>
      for _, v in o {
        match v {
          HCLValue::Array(arr, _) => assert_eq(arr.length(), 3)
          _ => panic()
        }
      }
    _ => panic()
  }
}

///|
test "jsondecode error" {
  let funcs = builtin_functions()
  let f = funcs["jsondecode"]
  match f.call([str("not valid json")]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "jsonencode basic" {
  let funcs = builtin_functions()
  let f = funcs["jsonencode"]
  let obj : Map[String, HCLValue] = {}
  obj["name"] = str("test")
  obj["count"] = num(42)
  match f.call([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::String(s, _)) => {
      assert_true(s.contains("name"))
      assert_true(s.contains("test"))
      assert_true(s.contains("42"))
    }
    _ => panic()
  }
}

///|
test "jsonencode array" {
  let funcs = builtin_functions()
  let f = funcs["jsonencode"]
  let arr = HCLValue::Array([num(1), num(2), num(3)], Decor::empty())
  match f.call([arr]) {
    Ok(HCLValue::String(s, _)) => {
      assert_true(s.contains("1"))
      assert_true(s.contains("2"))
      assert_true(s.contains("3"))
    }
    _ => panic()
  }
}

///|
test "jsonencode null" {
  let funcs = builtin_functions()
  let f = funcs["jsonencode"]
  match f.call([HCLValue::Null(Decor::empty())]) {
    Ok(HCLValue::String(s, _)) => assert_eq(s, "null")
    _ => panic()
  }
}

///|
test "jsondecode jsonencode roundtrip" {
  let funcs = builtin_functions()
  let dec = funcs["jsondecode"]
  let enc = funcs["jsonencode"]
  let original = str("{\"key\": \"value\", \"num\": 123}")
  match dec.call([original]) {
    Ok(decoded) =>
      match enc.call([decoded]) {
        Ok(HCLValue::String(s, _)) => {
          assert_true(s.contains("key"))
          assert_true(s.contains("value"))
          assert_true(s.contains("123"))
        }
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "base64encode basic" {
  let funcs = builtin_functions()
  let f = funcs["base64encode"]
  match f.call([str("Hello, World!")]) {
    Ok(HCLValue::String(s, _)) => assert_eq(s, "SGVsbG8sIFdvcmxkIQ==")
    _ => panic()
  }
}

///|
test "base64decode basic" {
  let funcs = builtin_functions()
  let f = funcs["base64decode"]
  match f.call([str("SGVsbG8sIFdvcmxkIQ==")]) {
    Ok(HCLValue::String(s, _)) => assert_eq(s, "Hello, World!")
    _ => panic()
  }
}

///|
test "base64 roundtrip" {
  let funcs = builtin_functions()
  let enc = funcs["base64encode"]
  let dec = funcs["base64decode"]
  let original = str("Test data for base64 encoding")
  match enc.call([original]) {
    Ok(encoded) =>
      match dec.call([encoded]) {
        Ok(decoded) => assert_true(decoded == original)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "base64decode error" {
  let funcs = builtin_functions()
  let f = funcs["base64decode"]
  match f.call([str("not-valid-base64!!!")]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "base64encode type error" {
  let funcs = builtin_functions()
  let f = funcs["base64encode"]
  match f.call([num(123)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///|
test "csvdecode basic" {
  let funcs = builtin_functions()
  let f = funcs["csvdecode"]
  let csv = str("name,age\nAlice,30\nBob,25")
  match f.call([csv]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 2)
      match arr[0] {
        HCLValue::Object(o, _) =>
          for k, v in o {
            if k == "name" {
              assert_true(v == str("Alice"))
            }
          }
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "csvdecode quoted fields" {
  let funcs = builtin_functions()
  let f = funcs["csvdecode"]
  let csv = str("name,msg\nJohn,\"hello, world\"")
  match f.call([csv]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_eq(arr.length(), 1)
      match arr[0] {
        HCLValue::Object(o, _) =>
          for k, v in o {
            if k == "msg" {
              assert_true(v == str("hello, world"))
            }
          }
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "csvdecode empty" {
  let funcs = builtin_functions()
  let f = funcs["csvdecode"]
  match f.call([str("")]) {
    Ok(HCLValue::Array(arr, _)) => assert_eq(arr.length(), 0)
    _ => panic()
  }
}

///|
test "urlencode basic" {
  let funcs = builtin_functions()
  let f = funcs["urlencode"]
  match f.call([str("hello world")]) {
    Ok(HCLValue::String(s, _)) => assert_eq(s, "hello+world")
    _ => panic()
  }
}

///|
test "urlencode special chars" {
  let funcs = builtin_functions()
  let f = funcs["urlencode"]
  match f.call([str("a&b=c")]) {
    Ok(HCLValue::String(s, _)) => {
      assert_true(s.contains("%26"))
      assert_true(s.contains("%3D"))
    }
    _ => panic()
  }
}

///|
test "urlencode unreserved" {
  let funcs = builtin_functions()
  let f = funcs["urlencode"]
  match f.call([str("test-file_1.0~")]) {
    Ok(HCLValue::String(s, _)) => assert_eq(s, "test-file_1.0~")
    _ => panic()
  }
}

///|
test "urlencode type error" {
  let funcs = builtin_functions()
  let f = funcs["urlencode"]
  match f.call([num(42)]) {
    Err(_) => assert_true(true)
    _ => panic()
  }
}

///| =========================================================================
/// FuncRegistry Tests

///| =========================================================================

///|
test "FuncRegistry::new creates empty registry" {
  let reg = FuncRegistry::new()
  let built = reg.build()
  assert_eq(built.length(), 0)
}

///|
test "FuncRegistry::with_builtins has all builtins" {
  let reg = FuncRegistry::with_builtins()
  let built = reg.build()
  assert_true(built.length() > 0)
  assert_true(built.contains("abs"))
  assert_true(built.contains("upper"))
  assert_true(built.contains("lower"))
  assert_true(built.contains("length"))
}

///|
test "FuncRegistry::register adds custom function" {
  let reg = FuncRegistry::new()
  let custom_fn = FuncDef::builder()
    .param(Any)
    .build("greet", fn(_args) { Ok(HCLValue::String("hello", Decor::empty())) })
  let built = reg.register("greet", custom_fn).build()
  assert_true(built.contains("greet"))
  match built["greet"].call([str("world")]) {
    Ok(HCLValue::String(s, _)) => assert_eq(s, "hello")
    _ => panic()
  }
}

///|
test "FuncRegistry::build returns correct map" {
  let reg = FuncRegistry::new()
  let custom_fn = FuncDef::builder().build("noop", fn(_args) {
    Ok(HCLValue::Null(Decor::empty()))
  })
  let built = reg.register("noop", custom_fn).build()
  assert_eq(built.length(), 1)
  assert_true(built.contains("noop"))
}

///|
test "merge_funcs merges two maps" {
  let base = builtin_functions()
  let extra = Map::new()
  let custom_fn = FuncDef::builder().build("custom_add", fn(_args) {
    Ok(HCLValue::Number(Number::from_int(99), Decor::empty()))
  })
  extra["custom_add"] = custom_fn
  let merged = merge_funcs(base, extra)
  assert_true(merged.contains("abs"))
  assert_true(merged.contains("custom_add"))
}

///|
test "eval_expr_with_funcs evaluates with custom + builtin functions" {
  let fc = FuncCall::builder("abs").arg(expr_int(-7)).build()
  let expr = expr_func_call(fc)
  let result = eval_expr_with_funcs(expr, Map::new(), Map::new())
  match result {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(7), Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "custom function overrides builtin" {
  let reg = FuncRegistry::with_builtins()
  let custom_abs = FuncDef::builder()
    .param(ParamNumber)
    .build("abs", fn(_args) {
      Ok(HCLValue::Number(Number::from_int(999), Decor::empty()))
    })
  let built = reg.register("abs", custom_abs).build()
  match built["abs"].call([num(5)]) {
    Ok(v) =>
      assert_true(v == HCLValue::Number(Number::from_int(999), Decor::empty()))
    _ => panic()
  }
}

///| =========================================================================
/// Date/Time Functions Tests

///| =========================================================================

///|
test "formatdate basic tokens" {
  let funcs = builtin_functions()
  let f = funcs["formatdate"]
  match f.call([str("YYYY-MM-DD"), str("2023-06-15T12:30:45Z")]) {
    Ok(v) => assert_true(v == str("2023-06-15"))
    Err(_) => panic()
  }
}

///|
test "formatdate time tokens" {
  let funcs = builtin_functions()
  let f = funcs["formatdate"]
  match f.call([str("hh:mm:ss"), str("2023-06-15T12:30:45Z")]) {
    Ok(v) => assert_true(v == str("12:30:45"))
    Err(_) => panic()
  }
}

///|
test "formatdate combined format" {
  let funcs = builtin_functions()
  let f = funcs["formatdate"]
  match f.call([str("YYYY-MM-DDThh:mm:ssZ"), str("2023-06-15T12:30:45Z")]) {
    Ok(v) => assert_true(v == str("2023-06-15T12:30:45Z"))
    Err(_) => panic()
  }
}

///|
test "formatdate quoted literal" {
  let funcs = builtin_functions()
  let f = funcs["formatdate"]
  match f.call([str("YYYY 'year' MM 'month'"), str("2023-06-15T12:30:45Z")]) {
    Ok(v) => assert_true(v == str("2023 year 06 month"))
    Err(_) => panic()
  }
}

///|
test "formatdate error on invalid timestamp" {
  let funcs = builtin_functions()
  let f = funcs["formatdate"]
  match f.call([str("YYYY"), str("not-a-date")]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "timeadd hours" {
  let funcs = builtin_functions()
  let f = funcs["timeadd"]
  match f.call([str("2023-06-15T12:00:00Z"), str("2h")]) {
    Ok(v) => assert_true(v == str("2023-06-15T14:00:00Z"))
    Err(_) => panic()
  }
}

///|
test "timeadd minutes" {
  let funcs = builtin_functions()
  let f = funcs["timeadd"]
  match f.call([str("2023-06-15T12:00:00Z"), str("30m")]) {
    Ok(v) => assert_true(v == str("2023-06-15T12:30:00Z"))
    Err(_) => panic()
  }
}

///|
test "timeadd combined duration" {
  let funcs = builtin_functions()
  let f = funcs["timeadd"]
  match f.call([str("2023-06-15T12:00:00Z"), str("1h30m5s")]) {
    Ok(v) => assert_true(v == str("2023-06-15T13:30:05Z"))
    Err(_) => panic()
  }
}

///|
test "timeadd error on invalid duration" {
  let funcs = builtin_functions()
  let f = funcs["timeadd"]
  match f.call([str("2023-06-15T12:00:00Z"), str("invalid")]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "timecmp equal timestamps" {
  let funcs = builtin_functions()
  let f = funcs["timecmp"]
  match f.call([str("2023-06-15T12:00:00Z"), str("2023-06-15T12:00:00Z")]) {
    Ok(v) => assert_true(v == num(0))
    Err(_) => panic()
  }
}

///|
test "timecmp first before second" {
  let funcs = builtin_functions()
  let f = funcs["timecmp"]
  match f.call([str("2023-06-15T12:00:00Z"), str("2023-06-15T14:00:00Z")]) {
    Ok(v) => assert_true(v == num(-1))
    Err(_) => panic()
  }
}

///|
test "timecmp first after second" {
  let funcs = builtin_functions()
  let f = funcs["timecmp"]
  match f.call([str("2023-06-15T14:00:00Z"), str("2023-06-15T12:00:00Z")]) {
    Ok(v) => assert_true(v == num(1))
    Err(_) => panic()
  }
}

///|
test "timecmp error on invalid timestamp" {
  let funcs = builtin_functions()
  let f = funcs["timecmp"]
  match f.call([str("2023-06-15T12:00:00Z"), str("not-a-date")]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "cidrhost basic" {
  let funcs = builtin_functions()
  let f = funcs["cidrhost"]
  match f.call([str("192.168.1.0/24"), num(5)]) {
    Ok(v) => assert_true(v == str("192.168.1.5"))
    Err(_) => panic()
  }
}

///|
test "cidrhost negative hostnum" {
  let funcs = builtin_functions()
  let f = funcs["cidrhost"]
  match f.call([str("192.168.1.0/24"), num(-1)]) {
    Ok(v) => assert_true(v == str("192.168.1.255"))
    Err(_) => panic()
  }
}

///|
test "cidrhost error on invalid cidr" {
  let funcs = builtin_functions()
  let f = funcs["cidrhost"]
  match f.call([str("not-a-cidr"), num(0)]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "cidrhost error on hostnum overflow" {
  let funcs = builtin_functions()
  let f = funcs["cidrhost"]
  match f.call([str("192.168.1.0/24"), num(256)]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "cidrnetmask /24" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("24")]) {
    Ok(v) => assert_true(v == str("255.255.255.0"))
    Err(_) => panic()
  }
}

///|
test "cidrnetmask /16" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("16")]) {
    Ok(v) => assert_true(v == str("255.255.0.0"))
    Err(_) => panic()
  }
}

///|
test "cidrnetmask /8" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("8")]) {
    Ok(v) => assert_true(v == str("255.0.0.0"))
    Err(_) => panic()
  }
}

///|
test "cidrnetmask /32" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("32")]) {
    Ok(v) => assert_true(v == str("255.255.255.255"))
    Err(_) => panic()
  }
}

///|
test "cidrnetmask /0" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("0")]) {
    Ok(v) => assert_true(v == str("0.0.0.0"))
    Err(_) => panic()
  }
}

///|
test "cidrnetmask with slash prefix" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("/24")]) {
    Ok(v) => assert_true(v == str("255.255.255.0"))
    Err(_) => panic()
  }
}

///|
test "cidrnetmask error on out of range" {
  let funcs = builtin_functions()
  let f = funcs["cidrnetmask"]
  match f.call([str("33")]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "cidrsubnet basic" {
  let funcs = builtin_functions()
  let f = funcs["cidrsubnet"]
  match f.call([str("10.1.0.0/16"), num(8), num(1)]) {
    Ok(v) => assert_true(v == str("10.1.1.0/24"))
    Err(_) => panic()
  }
}

///|
test "cidrsubnet zero netnum" {
  let funcs = builtin_functions()
  let f = funcs["cidrsubnet"]
  match f.call([str("10.1.0.0/16"), num(8), num(0)]) {
    Ok(v) => assert_true(v == str("10.1.0.0/24"))
    Err(_) => panic()
  }
}

///|
test "cidrsubnet error on overflow" {
  let funcs = builtin_functions()
  let f = funcs["cidrsubnet"]
  match f.call([str("10.1.0.0/16"), num(8), num(256)]) {
    Ok(_) => panic()
    Err(_) => assert_true(true)
  }
}

///|
test "cidrsubnets basic" {
  let funcs = builtin_functions()
  let f = funcs["cidrsubnets"]
  match f.call([str("10.0.0.0/16"), num(4), num(4), num(4), num(4)]) {
    Ok(Array(arr, _)) => {
      assert_true(arr.length() == 4)
      assert_true(arr[0] == str("10.0.0.0/20"))
      assert_true(arr[1] == str("10.0.16.0/20"))
      assert_true(arr[2] == str("10.0.32.0/20"))
      assert_true(arr[3] == str("10.0.48.0/20"))
    }
    _ => panic()
  }
}

///| =========================================================================
/// Regex Functions Tests

///| =========================================================================

///|
test "regex basic match with groups" {
  let funcs = builtin_functions()
  let f = funcs["regex"]
  match f.call([str("([0-9]+)-([a-z]+)"), str("abc-123-def-456")]) {
    Ok(Array(arr, _)) => {
      assert_true(arr.length() == 3)
      assert_true(arr[0] == str("123-def"))
      assert_true(arr[1] == str("123"))
      assert_true(arr[2] == str("def"))
    }
    _ => panic()
  }
}

///|
test "regex no match" {
  let funcs = builtin_functions()
  let f = funcs["regex"]
  match f.call([str("[0-9]+"), str("no-digits-here")]) {
    Ok(Array(arr, _)) => assert_true(arr.length() == 0)
    _ => panic()
  }
}

///|
test "regex pattern with no groups" {
  let funcs = builtin_functions()
  let f = funcs["regex"]
  match f.call([str("[a-z]+"), str("hello-world")]) {
    Ok(Array(arr, _)) => {
      assert_true(arr.length() == 1)
      assert_true(arr[0] == str("hello"))
    }
    _ => panic()
  }
}

///|
test "regexall multiple matches" {
  let funcs = builtin_functions()
  let f = funcs["regexall"]
  match f.call([str("[0-9]+"), str("abc-123-def-456")]) {
    Ok(Array(arr, _)) => {
      assert_true(arr.length() == 2)
      match arr[0] {
        Array(inner, _) => {
          assert_true(inner.length() == 1)
          assert_true(inner[0] == str("123"))
        }
        _ => panic()
      }
      match arr[1] {
        Array(inner, _) => {
          assert_true(inner.length() == 1)
          assert_true(inner[0] == str("456"))
        }
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "regexall no matches" {
  let funcs = builtin_functions()
  let f = funcs["regexall"]
  match f.call([str("[0-9]+"), str("no-digits")]) {
    Ok(Array(arr, _)) => assert_true(arr.length() == 0)
    _ => panic()
  }
}

///|
test "regexall single match with groups" {
  let funcs = builtin_functions()
  let f = funcs["regexall"]
  match f.call([str("([a-z]+)-([0-9]+)"), str("foo-123 bar-456")]) {
    Ok(Array(arr, _)) => {
      assert_true(arr.length() == 2)
      match arr[0] {
        Array(inner, _) => {
          assert_true(inner.length() == 3)
          assert_true(inner[0] == str("foo-123"))
          assert_true(inner[1] == str("foo"))
          assert_true(inner[2] == str("123"))
        }
        _ => panic()
      }
    }
    _ => panic()
  }
}

///|
test "regex_replace basic" {
  let funcs = builtin_functions()
  let f = funcs["regex_replace"]
  match f.call([str("hello world"), str("world"), str("moonbit")]) {
    Ok(String(s, _)) => assert_true(s == "hello moonbit")
    _ => panic()
  }
}

///|
test "regex_replace with groups" {
  let funcs = builtin_functions()
  let f = funcs["regex_replace"]
  match f.call([str("abc-123-def-456"), str("([0-9]+)"), str("N$1N")]) {
    Ok(String(s, _)) => assert_true(s == "abc-N123N-def-N456N")
    _ => panic()
  }
}

///|
test "regex_replace no match" {
  let funcs = builtin_functions()
  let f = funcs["regex_replace"]
  match f.call([str("hello world"), str("xyz"), str("abc")]) {
    Ok(String(s, _)) => assert_true(s == "hello world")
    _ => panic()
  }
}
