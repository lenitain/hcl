///|
/// Built-in Functions Tests

///| =========================================================================
/// Numeric Functions Tests

///| =========================================================================

///|
test "abs positive" {
  let funcs = builtin_functions()
  let f = funcs["abs"]
  match f([HCLValue::Int(5, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(5, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "abs negative" {
  let funcs = builtin_functions()
  let f = funcs["abs"]
  match f([HCLValue::Int(-5, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(5, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "abs float" {
  let funcs = builtin_functions()
  let f = funcs["abs"]
  match f([HCLValue::Float(-3.14, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Float(3.14, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "ceil" {
  let funcs = builtin_functions()
  let f = funcs["ceil"]
  match f([HCLValue::Float(3.2, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(4, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "ceil negative" {
  let funcs = builtin_functions()
  let f = funcs["ceil"]
  match f([HCLValue::Float(-3.2, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(-3, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "floor" {
  let funcs = builtin_functions()
  let f = funcs["floor"]
  match f([HCLValue::Float(3.8, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(3, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "floor negative" {
  let funcs = builtin_functions()
  let f = funcs["floor"]
  match f([HCLValue::Float(-3.2, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(-4, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "log" {
  let funcs = builtin_functions()
  let f = funcs["log"]
  match
    f([
      HCLValue::Float(8.0, Decor::empty()),
      HCLValue::Float(2.0, Decor::empty()),
    ]) {
    Ok(HCLValue::Float(v, _)) => assert_true((v - 3.0).abs() < 0.0001)
    _ => panic()
  }
}

///|
test "log invalid base" {
  let funcs = builtin_functions()
  let f = funcs["log"]
  match
    f([
      HCLValue::Float(8.0, Decor::empty()),
      HCLValue::Float(1.0, Decor::empty()),
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
    f([HCLValue::Int(3, Decor::empty()), HCLValue::Int(7, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(7, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "max multiple args" {
  let funcs = builtin_functions()
  let f = funcs["max"]
  match
    f([
      HCLValue::Int(3, Decor::empty()),
      HCLValue::Int(7, Decor::empty()),
      HCLValue::Int(5, Decor::empty()),
      HCLValue::Int(9, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(9, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "min two args" {
  let funcs = builtin_functions()
  let f = funcs["min"]
  match
    f([HCLValue::Int(3, Decor::empty()), HCLValue::Int(7, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(3, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "min multiple args" {
  let funcs = builtin_functions()
  let f = funcs["min"]
  match
    f([
      HCLValue::Int(10, Decor::empty()),
      HCLValue::Int(3, Decor::empty()),
      HCLValue::Int(7, Decor::empty()),
      HCLValue::Int(5, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(3, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "parseint base 10" {
  let funcs = builtin_functions()
  let f = funcs["parseint"]
  match
    f([
      HCLValue::String("42", Decor::empty()),
      HCLValue::Int(10, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(42, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "parseint base 16" {
  let funcs = builtin_functions()
  let f = funcs["parseint"]
  match
    f([
      HCLValue::String("ff", Decor::empty()),
      HCLValue::Int(16, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(255, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "parseint base 2" {
  let funcs = builtin_functions()
  let f = funcs["parseint"]
  match
    f([
      HCLValue::String("1010", Decor::empty()),
      HCLValue::Int(2, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(10, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "pow" {
  let funcs = builtin_functions()
  let f = funcs["pow"]
  match
    f([
      HCLValue::Float(2.0, Decor::empty()),
      HCLValue::Float(3.0, Decor::empty()),
    ]) {
    Ok(HCLValue::Float(v, _)) => assert_true((v - 8.0).abs() < 0.0001)
    _ => panic()
  }
}

///|
test "signum positive" {
  let funcs = builtin_functions()
  let f = funcs["signum"]
  match f([HCLValue::Int(5, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(1, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "signum negative" {
  let funcs = builtin_functions()
  let f = funcs["signum"]
  match f([HCLValue::Int(-5, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(-1, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "signum zero" {
  let funcs = builtin_functions()
  let f = funcs["signum"]
  match f([HCLValue::Int(0, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(0, Decor::empty()))
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
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(3, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "length string" {
  let funcs = builtin_functions()
  let f = funcs["length"]
  match f([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(5, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "length object" {
  let funcs = builtin_functions()
  let f = funcs["length"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Int(1, Decor::empty())
  obj["b"] = HCLValue::Int(2, Decor::empty())
  match f([HCLValue::Object(obj, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(2, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "keys" {
  let funcs = builtin_functions()
  let f = funcs["keys"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Int(1, Decor::empty())
  obj["b"] = HCLValue::Int(2, Decor::empty())
  match f([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 2)
    _ => panic()
  }
}

///|
test "values" {
  let funcs = builtin_functions()
  let f = funcs["values"]
  let obj : Map[String, HCLValue] = Map::new()
  obj["a"] = HCLValue::Int(1, Decor::empty())
  obj["b"] = HCLValue::Int(2, Decor::empty())
  match f([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 2)
    _ => panic()
  }
}

///|
test "contains true" {
  let funcs = builtin_functions()
  let f = funcs["contains"]
  match
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Int(2, Decor::empty()),
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
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Int(5, Decor::empty()),
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
    f([
      HCLValue::Array(
        [
          HCLValue::Array(
            [HCLValue::Int(1, Decor::empty()), HCLValue::Int(2, Decor::empty())],
            Decor::empty(),
          ),
          HCLValue::Array([HCLValue::Int(3, Decor::empty())], Decor::empty()),
          HCLValue::Int(4, Decor::empty()),
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
  obj1["a"] = HCLValue::Int(1, Decor::empty())
  let obj2 : Map[String, HCLValue] = Map::new()
  obj2["b"] = HCLValue::Int(2, Decor::empty())
  match
    f([
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
  obj1["a"] = HCLValue::Int(1, Decor::empty())
  let obj2 : Map[String, HCLValue] = Map::new()
  obj2["a"] = HCLValue::Int(99, Decor::empty())
  match
    f([
      HCLValue::Object(obj1, Decor::empty()),
      HCLValue::Object(obj2, Decor::empty()),
    ]) {
    Ok(HCLValue::Object(result, _)) =>
      assert_true(result["a"] == HCLValue::Int(99, Decor::empty()))
    _ => panic()
  }
}

///|
test "reverse array" {
  let funcs = builtin_functions()
  let f = funcs["reverse"]
  match
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr[0] == HCLValue::Int(3, Decor::empty()))
      assert_true(arr[1] == HCLValue::Int(2, Decor::empty()))
      assert_true(arr[2] == HCLValue::Int(1, Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "reverse string" {
  let funcs = builtin_functions()
  let f = funcs["reverse"]
  match f([HCLValue::String("abc", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("cba", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "distinct" {
  let funcs = builtin_functions()
  let f = funcs["distinct"]
  match
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
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
    f([
      HCLValue::Array(
        [
          HCLValue::Int(3, Decor::empty()),
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
        ],
        Decor::empty(),
      ),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr[0] == HCLValue::Int(1, Decor::empty()))
      assert_true(arr[1] == HCLValue::Int(2, Decor::empty()))
      assert_true(arr[2] == HCLValue::Int(3, Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "sort strings" {
  let funcs = builtin_functions()
  let f = funcs["sort"]
  match
    f([
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
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
          HCLValue::Int(4, Decor::empty()),
          HCLValue::Int(5, Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Int(1, Decor::empty()),
      HCLValue::Int(4, Decor::empty()),
    ]) {
    Ok(HCLValue::Array(arr, _)) => {
      assert_true(arr.length() == 3)
      assert_true(arr[0] == HCLValue::Int(2, Decor::empty()))
      assert_true(arr[1] == HCLValue::Int(3, Decor::empty()))
      assert_true(arr[2] == HCLValue::Int(4, Decor::empty()))
    }
    _ => panic()
  }
}

///|
test "element" {
  let funcs = builtin_functions()
  let f = funcs["element"]
  match
    f([
      HCLValue::Array(
        [
          HCLValue::Int(10, Decor::empty()),
          HCLValue::Int(20, Decor::empty()),
          HCLValue::Int(30, Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Int(1, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(20, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "element wrap around" {
  let funcs = builtin_functions()
  let f = funcs["element"]
  match
    f([
      HCLValue::Array(
        [
          HCLValue::Int(10, Decor::empty()),
          HCLValue::Int(20, Decor::empty()),
          HCLValue::Int(30, Decor::empty()),
        ],
        Decor::empty(),
      ),
      HCLValue::Int(5, Decor::empty()),
    ]) {
    Ok(v) => assert_true(v == HCLValue::Int(30, Decor::empty()))
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
  match f([HCLValue::String("hello\n", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "chomp crlf" {
  let funcs = builtin_functions()
  let f = funcs["chomp"]
  match f([HCLValue::String("hello\r\n", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "chomp no newline" {
  let funcs = builtin_functions()
  let f = funcs["chomp"]
  match f([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "indent" {
  let funcs = builtin_functions()
  let f = funcs["indent"]
  match
    f([
      HCLValue::Int(2, Decor::empty()),
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
    f([
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
  match f([HCLValue::String("HELLO", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "upper" {
  let funcs = builtin_functions()
  let f = funcs["upper"]
  match f([HCLValue::String("hello", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("HELLO", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "replace" {
  let funcs = builtin_functions()
  let f = funcs["replace"]
  match
    f([
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
    f([
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
  match f([HCLValue::String("abc", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("cba", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "substr" {
  let funcs = builtin_functions()
  let f = funcs["substr"]
  match
    f([
      HCLValue::String("hello world", Decor::empty()),
      HCLValue::Int(6, Decor::empty()),
      HCLValue::Int(5, Decor::empty()),
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
    f([
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
    f([
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
    f([
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
    f([
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
    f([
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
  match f([HCLValue::String("  hello  ", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("hello", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "format" {
  let funcs = builtin_functions()
  let f = funcs["format"]
  match
    f([
      HCLValue::String("Hello %s, you are %d years old", Decor::empty()),
      HCLValue::String("Alice", Decor::empty()),
      HCLValue::Int(30, Decor::empty()),
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
  match f([HCLValue::String("100%%", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("100%", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "formatlist" {
  let funcs = builtin_functions()
  let f = funcs["formatlist"]
  match
    f([
      HCLValue::String("item-%d", Decor::empty()),
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
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
  match f([HCLValue::String("true", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tobool from string false" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f([HCLValue::String("FALSE", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tobool from int" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f([HCLValue::Int(1, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(true, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tobool from int zero" {
  let funcs = builtin_functions()
  let f = funcs["tobool"]
  match f([HCLValue::Int(0, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Bool(false, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tonumber from string" {
  let funcs = builtin_functions()
  let f = funcs["tonumber"]
  match f([HCLValue::String("42", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(42, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tonumber from string float" {
  let funcs = builtin_functions()
  let f = funcs["tonumber"]
  match f([HCLValue::String("3.14", Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Float(3.14, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tonumber from bool" {
  let funcs = builtin_functions()
  let f = funcs["tonumber"]
  match f([HCLValue::Bool(true, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::Int(1, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tolist" {
  let funcs = builtin_functions()
  let f = funcs["tolist"]
  match f([HCLValue::Int(42, Decor::empty())]) {
    Ok(HCLValue::Array(arr, _)) => assert_true(arr.length() == 1)
    _ => panic()
  }
}

///|
test "tolist already array" {
  let funcs = builtin_functions()
  let f = funcs["tolist"]
  match
    f([
      HCLValue::Array(
        [HCLValue::Int(1, Decor::empty()), HCLValue::Int(2, Decor::empty())],
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
  obj["a"] = HCLValue::Int(1, Decor::empty())
  match f([HCLValue::Object(obj, Decor::empty())]) {
    Ok(HCLValue::Object(result, _)) =>
      assert_true(result["a"] == HCLValue::Int(1, Decor::empty()))
    _ => panic()
  }
}

///|
test "tomap error" {
  let funcs = builtin_functions()
  let f = funcs["tomap"]
  match f([HCLValue::Int(42, Decor::empty())]) {
    Ok(_) => panic()
    Err(e) => assert_true(e.message().contains("object"))
  }
}

///|
test "toset" {
  let funcs = builtin_functions()
  let f = funcs["toset"]
  match
    f([
      HCLValue::Array(
        [
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(2, Decor::empty()),
          HCLValue::Int(1, Decor::empty()),
          HCLValue::Int(3, Decor::empty()),
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
  match f([HCLValue::Int(42, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("42", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tostring from bool" {
  let funcs = builtin_functions()
  let f = funcs["tostring"]
  match f([HCLValue::Bool(true, Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("true", Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "tostring from null" {
  let funcs = builtin_functions()
  let f = funcs["tostring"]
  match f([HCLValue::Null(Decor::empty())]) {
    Ok(v) => assert_true(v == HCLValue::String("null", Decor::empty()))
    Err(_) => panic()
  }
}

///| =========================================================================
/// Integration Tests

///| =========================================================================

///|
test "builtin functions integrated in eval" {
  let obj : Map[String, HCLValue] = Map::new()
  obj["type"] = HCLValue::String("function_call", Decor::empty())
  obj["name"] = HCLValue::String("abs", Decor::empty())
  obj["args"] = HCLValue::Array(
    [HCLValue::Int(-5, Decor::empty())],
    Decor::empty(),
  )
  let expr = HCLValue::Object(obj, Decor::empty())
  let result = eval_expr(expr, Map::new(), builtin_functions())
  match result {
    Ok(v) => assert_true(v == HCLValue::Int(5, Decor::empty()))
    Err(_) => panic()
  }
}

///|
test "nested function calls" {
  let inner_obj : Map[String, HCLValue] = Map::new()
  inner_obj["type"] = HCLValue::String("function_call", Decor::empty())
  inner_obj["name"] = HCLValue::String("tostring", Decor::empty())
  inner_obj["args"] = HCLValue::Array(
    [HCLValue::Int(42, Decor::empty())],
    Decor::empty(),
  )

  let outer_obj : Map[String, HCLValue] = Map::new()
  outer_obj["type"] = HCLValue::String("function_call", Decor::empty())
  outer_obj["name"] = HCLValue::String("upper", Decor::empty())
  outer_obj["args"] = HCLValue::Array(
    [HCLValue::Object(inner_obj, Decor::empty())],
    Decor::empty(),
  )

  let expr = HCLValue::Object(outer_obj, Decor::empty())
  let result = eval_expr(expr, Map::new(), builtin_functions())
  match result {
    Ok(v) => assert_true(v == HCLValue::String("42", Decor::empty()))
    Err(_) => panic()
  }
}
