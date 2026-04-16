///|
/// For Expression Tests
test "tokenize for keyword" {
  let lexer = Lexer::new("for")
  match lexer.next_token() {
    Ok((token, _)) => assert_true(token == For)
    Err(_) => panic()
  }
}

///|
test "tokenize for expression" {
  let input = "[for x in numbers: x * 2]"
  let lexer = Lexer::new(input)
  let tokens = lexer.tokenize()
  match tokens {
    Ok(token_list) => {
      // Should have: LBracket, For, Ident("x"), In, Ident("numbers"), Colon, Ident("x"), Star, NumberLit("2"), RBracket
      assert_true(token_list.length() >= 10)
      assert_true(token_list[0] == LBracket)
      assert_true(token_list[1] == For)
      assert_true(token_list[2] == Ident("x"))
      assert_true(token_list[3] == In)
    }
    Err(_) => panic()
  }
}

///|
test "parse simple array" {
  let input = "items = [1, 2, 3]"
  let result = parse(input)
  assert_true(result is Ok(_))
}

///|
test "parse for expr simple" {
  // Test parsing just the for expression as an attribute value
  let input = "result = [for x in items: x]"
  let result = parse(input)
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "result")
          match attr.get_value() {
            Object(obj) =>
              assert_true(obj.get("type") == Some(String("for_expr")))
            Array(_) =>
              // If it parsed as array, the for expression parsing failed
              panic()
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "eval for expr simple" {
  let input = "doubled = [for x in numbers: x * 2]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["numbers"] = Array([Int(1), Int(2), Int(3)])
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          match eval_expr(value, variables, functions) {
            Ok(Array(arr)) => {
              assert_eq(arr.length(), 3)
              assert_true(arr[0] == Int(2))
              assert_true(arr[1] == Int(4))
              assert_true(arr[2] == Int(6))
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
test "parse object comprehension" {
  let input = "upper_keys = {for k, v in config: k => upper(v)}"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "upper_keys")
          match attr.get_value() {
            Object(obj) => {
              assert_true(obj.get("type") == Some(String("for_object_expr")))
              assert_true(obj.get("key_var") == Some(String("k")))
              assert_true(obj.get("value_var") == Some(String("v")))
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse list comprehension with filter" {
  let input = "evens = [for x in numbers: x if x % 2 == 0]"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "evens")
          match attr.get_value() {
            Object(obj) => {
              assert_true(obj.get("type") == Some(String("for_expr")))
              assert_true(obj.get("var") == Some(String("x")))
              assert_true(obj.get("filter") != Some(Null))
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "evaluate list comprehension" {
  let input = "doubled = [for x in numbers: x * 2]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["numbers"] = Array([Int(1), Int(2), Int(3)])
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Array(arr)) => {
              assert_eq(arr.length(), 3)
              assert_true(arr[0] == Int(2))
              assert_true(arr[1] == Int(4))
              assert_true(arr[2] == Int(6))
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
test "evaluate list comprehension with filter" {
  let input = "evens = [for x in numbers: x if x % 2 == 0]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["numbers"] = Array([Int(1), Int(2), Int(3), Int(4)])
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Array(arr)) => {
              assert_eq(arr.length(), 2)
              assert_true(arr[0] == Int(2))
              assert_true(arr[1] == Int(4))
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
test "evaluate object comprehension" {
  let input = "upper_values = {for k, v in config: k => v}"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          let config : Map[String, HCLValue] = Map::new()
          config["host"] = String("localhost")
          config["port"] = Int(8080)
          variables["config"] = Object(config)
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Object(obj)) => {
              assert_true(obj.get("host") == Some(String("localhost")))
              assert_true(obj.get("port") == Some(Int(8080)))
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
test "evaluate nested for expressions" {
  let input = "nested = [for x in [1, 2]: [for y in [3, 4]: x * y]]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Array(arr)) => {
              assert_eq(arr.length(), 2)
              // First element: [3, 4]
              match arr[0] {
                Array(inner) => {
                  assert_eq(inner.length(), 2)
                  assert_true(inner[0] == Int(3))
                  assert_true(inner[1] == Int(4))
                }
                _ => panic()
              }
              // Second element: [6, 8]
              match arr[1] {
                Array(inner) => {
                  assert_eq(inner.length(), 2)
                  assert_true(inner[0] == Int(6))
                  assert_true(inner[1] == Int(8))
                }
                _ => panic()
              }
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
test "for expression with empty collection" {
  let input = "empty = [for x in []: x]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Array(arr)) => assert_eq(arr.length(), 0)
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "for expression with string transformation" {
  let input = "greetings = [for name in names: \"Hello, ${name}!\"]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["names"] = Array([String("Alice"), String("Bob")])
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Array(arr)) => assert_eq(arr.length(), 2)
            // Note: Template evaluation would be needed for full string interpolation
            // For now, we just check the structure is correct
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "for expression with conditional filter false" {
  let input = "filtered = [for x in numbers: x if x > 10]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["numbers"] = Array([Int(1), Int(2), Int(3)])
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(Array(arr)) => assert_eq(arr.length(), 0)
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}
