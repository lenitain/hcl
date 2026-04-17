///|
/// Multiline Expression Tests
test "multiline conditional in array true" {
  let input = "x = [\n  true\n  ? \"a\"\n  : \"b\"\n]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          match value {
            Array(items, _) => {
              let eval_result = eval_expr_simple(items[0])
              match eval_result {
                Ok(v) => assert_true(v == String("a", Decor::empty()))
                Err(_) => panic()
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
test "multiline conditional in array false" {
  let input = "x = [\n  false\n  ? \"a\"\n  : \"b\"\n]"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          match value {
            Array(items, _) => {
              let eval_result = eval_expr_simple(items[0])
              match eval_result {
                Ok(v) => assert_true(v == String("b", Decor::empty()))
                Err(_) => panic()
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
test "multiline conditional single line still works" {
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
test "multiline binary expression" {
  let input = "x = 1\n+ 2"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let eval_result = eval_expr_simple(value)
          match eval_result {
            Ok(v) => assert_true(v == Int(3, Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "multiline conditional top level" {
  let input = "x = true\n? \"a\"\n: \"b\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let value = attr.get_value()
          let eval_result = eval_expr_simple(value)
          match eval_result {
            Ok(v) => assert_true(v == String("a", Decor::empty()))
            Err(_) => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}
