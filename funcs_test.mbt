///|
/// Built-in Functions Tests

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
fn fn_add_stub(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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
