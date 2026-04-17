///|
/// Expression Evaluation Tests - Conditional
test "evaluate conditional expression true" {
  let input = "x = true ? \"yes\" : \"no\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let eval_result = eval_expr_simple(value)
          match eval_result {
            Ok(v) => assert_true(v == String("yes", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate conditional expression false" {
  let input = "x = false ? \"yes\" : \"no\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let eval_result = eval_expr_simple(value)
          match eval_result {
            Ok(v) => assert_true(v == String("no", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate conditional with int result" {
  let input = "x = true ? 42 : 0"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let eval_result = eval_expr_simple(value)
          match eval_result {
            Ok(v) => assert_true(v == Int(42, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate variable reference" {
  let input = "x = var_name"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["var_name"] = Int(42, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == Int(42, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate undefined variable" {
  let input = "x = undefined_var"
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
            Ok(_) => panic()
            Err(e) => assert_true(e.message().contains("Undefined variable"))
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate function call" {
  let input = "x = add(5, 3)"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          let add_func = fn(args : Array[HCLValue]) -> HCLResult[HCLValue] {
            match args {
              [Int(a, _), Int(b, _)] => Ok(Int(a + b, Decor::empty()))
              _ => Err(HCLError::type_error("add expects two integers"))
            }
          }
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          functions["add"] = add_func
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == Int(8, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate undefined function" {
  let input = "x = unknown_func()"
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
            Ok(_) => panic()
            Err(e) => assert_true(e.message().contains("Undefined function"))
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate property access dot notation" {
  let input = "x = obj.name"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let obj_map : Map[String, HCLValue] = Map::new()
          obj_map["name"] = String("test", Decor::empty())
          obj_map["value"] = Int(123, Decor::empty())
          let variables : Map[String, HCLValue] = Map::new()
          variables["obj"] = Object(obj_map, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == String("test", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate property access bracket notation" {
  let input = "x = obj[\"value\"]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let obj_map : Map[String, HCLValue] = Map::new()
          obj_map["name"] = String("test", Decor::empty())
          obj_map["value"] = Int(123, Decor::empty())
          let variables : Map[String, HCLValue] = Map::new()
          variables["obj"] = Object(obj_map, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == Int(123, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate chained property access" {
  let input = "x = person.name"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let person_map : Map[String, HCLValue] = Map::new()
          person_map["name"] = String("Alice", Decor::empty())
          let variables : Map[String, HCLValue] = Map::new()
          variables["person"] = Object(person_map, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == String("Alice", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate array index access" {
  let input = "x = items[1]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["items"] = Array(
            [
              Int(10, Decor::empty()),
              Int(20, Decor::empty()),
              Int(30, Decor::empty()),
            ],
            Decor::empty(),
          )
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == Int(20, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate non-boolean condition" {
  let input = "x = 1 ? \"yes\" : \"no\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let eval_result = eval_expr_simple(value)
          match eval_result {
            Ok(_) => panic()
            Err(e) =>
              assert_true(e.message().contains("Condition must be boolean"))
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate property access on non-object" {
  let input = "x = num.missing"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["num"] = Int(42, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(_) => panic()
            Err(e) =>
              assert_true(e.message().contains("Property access on non-object"))
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate array index out of bounds" {
  let input = "x = items[5]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["items"] = Array(
            [Int(1, Decor::empty()), Int(2, Decor::empty())],
            Decor::empty(),
          )
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(_) => panic()
            Err(e) =>
              assert_true(e.message().contains("Array index out of bounds"))
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate function call with variable args" {
  let input = "x = multiply(a, b)"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["a"] = Int(6, Decor::empty())
          variables["b"] = Int(7, Decor::empty())
          let multiply_func = fn(
            args : Array[HCLValue],
          ) -> HCLResult[HCLValue] {
            match args {
              [Int(x, _), Int(y, _)] => Ok(Int(x * y, Decor::empty()))
              _ => Err(HCLError::type_error("multiply expects two integers"))
            }
          }
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          functions["multiply"] = multiply_func
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == Int(42, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate conditional with variable" {
  let input = "x = flag ? \"enabled\" : \"disabled\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let variables : Map[String, HCLValue] = Map::new()
          variables["flag"] = Bool(true, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == String("enabled", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "evaluate nested property access" {
  let input = "x = config.db.host"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let db_map : Map[String, HCLValue] = Map::new()
          db_map["host"] = String("localhost", Decor::empty())
          let config_map : Map[String, HCLValue] = Map::new()
          config_map["db"] = Object(db_map, Decor::empty())
          let variables : Map[String, HCLValue] = Map::new()
          variables["config"] = Object(config_map, Decor::empty())
          let functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]] = Map::new()
          let eval_result = eval_expr(value, variables, functions)
          match eval_result {
            Ok(v) => assert_true(v == String("localhost", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}
