///|
/// HCL Expression Evaluator - evaluates expressions to values
/// Simple implementation without complex expression tree

///|
/// Evaluate binary operation on two HCLValues
pub fn eval_binary(
  left : HCLValue,
  op : String,
  right : HCLValue,
) -> HCLResult[HCLValue] {
  match op {
    "+" => eval_add(left, right)
    "-" => eval_sub(left, right)
    "*" => eval_mul(left, right)
    "/" => eval_div(left, right)
    "%" => eval_mod(left, right)
    "==" => eval_eq(left, right)
    "!=" => eval_neq(left, right)
    "<" => eval_lt(left, right)
    ">" => eval_gt(left, right)
    "<=" => eval_lte(left, right)
    ">=" => eval_gte(left, right)
    "&&" => eval_and(left, right)
    "||" => eval_or(left, right)
    _ => Err(HCLError::invalid_value("Unknown operator: " + op))
  }
}

///|
/// Evaluate unary operation on HCLValue
pub fn eval_unary(op : String, operand : HCLValue) -> HCLResult[HCLValue] {
  match op {
    "-" => eval_negate(operand)
    "!" => eval_not(operand)
    _ => Err(HCLError::invalid_value("Unknown unary operator: " + op))
  }
}

///|
/// Evaluate addition
fn eval_add(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Number(a + b, Decor::empty()))
    (String(a, _), String(b, _)) => Ok(String(a + b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for addition"))
  }
}

///|
/// Evaluate subtraction
fn eval_sub(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Number(a - b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for subtraction"))
  }
}

///|
/// Evaluate multiplication
fn eval_mul(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Number(a * b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for multiplication"))
  }
}

///|
/// Evaluate division
fn eval_div(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => {
      let fb = b.as_f64()
      if fb == 0.0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Number(a / b, Decor::empty()))
      }
    }
    _ => Err(HCLError::type_error("Invalid types for division"))
  }
}

///|
/// Evaluate modulo
fn eval_mod(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => {
      let fb = b.as_f64()
      if fb == 0.0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Number(a % b, Decor::empty()))
      }
    }
    _ => Err(HCLError::type_error("Invalid types for modulo"))
  }
}

///|
/// Evaluate equality
fn eval_eq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  Ok(Bool(left == right, Decor::empty()))
}

///|
/// Evaluate inequality
fn eval_neq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  Ok(Bool(left != right, Decor::empty()))
}

///|
/// Evaluate less than
fn eval_lt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a < b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for less than"))
  }
}

///|
/// Evaluate greater than
fn eval_gt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a > b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for greater than"))
  }
}

///|
/// Evaluate less than or equal
fn eval_lte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a <= b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for less than or equal"))
  }
}

///|
/// Evaluate greater than or equal
fn eval_gte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a >= b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for greater than or equal"))
  }
}

///|
/// Evaluate logical and
fn eval_and(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Bool(a, _), Bool(b, _)) => Ok(Bool(a && b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for logical and"))
  }
}

///|
/// Evaluate logical or
fn eval_or(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Bool(a, _), Bool(b, _)) => Ok(Bool(a || b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for logical or"))
  }
}

///|
/// Evaluate negation
fn eval_negate(operand : HCLValue) -> HCLResult[HCLValue] {
  match operand {
    Number(n, _) => Ok(Number(-n, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid type for negation"))
  }
}

///|
/// Evaluate logical not
fn eval_not(operand : HCLValue) -> HCLResult[HCLValue] {
  match operand {
    Bool(b, _) => Ok(Bool(!b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid type for logical not"))
  }
}

///|
/// Evaluate conditional expression (cond ? true : false)
pub fn eval_conditional(
  condition : HCLValue,
  true_expr : HCLValue,
  false_expr : HCLValue,
) -> HCLResult[HCLValue] {
  match condition {
    Bool(b, _) => if b { Ok(true_expr) } else { Ok(false_expr) }
    _ => Err(HCLError::type_error("Condition must be boolean"))
  }
}

///|
/// Evaluate expression (handles all expression types)
pub fn eval_expr(
  expr : HCLValue,
  variables : Map[String, HCLValue],
  functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]],
) -> HCLResult[HCLValue] {
  match expr {
    // Basic values - return as-is
    Null(_) | Bool(_, _) | Number(_, _) | String(_, _) => Ok(expr)

    // Array - evaluate each element
    Array(arr, _) => {
      let result = []
      for item in arr {
        match eval_expr(item, variables, functions) {
          Ok(value) => result.push(value)
          Err(e) => return Err(e)
        }
      }
      Ok(Array(result, Decor::empty()))
    }

    // Object - check if it's a special expression type
    Object(obj, _) =>
      match obj.get("type") {
        Some(String("conditional", _)) => {
          let condition = obj.get("condition").unwrap()
          let true_expr = obj.get("true_expr").unwrap()
          let false_expr = obj.get("false_expr").unwrap()

          match eval_expr(condition, variables, functions) {
            Ok(cond_value) =>
              eval_conditional(cond_value, true_expr, false_expr)
            Err(e) => Err(e)
          }
        }
        Some(String("variable", _)) => {
          let name = obj.get("name").unwrap()
          match name {
            String(var_name, _) =>
              match variables.get(var_name) {
                Some(value) => Ok(value)
                None => Err(HCLError::undefined_variable(var_name))
              }
            _ => Err(HCLError::type_error("Variable name must be string"))
          }
        }
        Some(String("function_call", _)) => {
          let name = obj.get("name").unwrap()
          let args = obj.get("args").unwrap()

          match (name, args) {
            (String(func_name, _), Array(func_args, _)) => {
              // Evaluate arguments
              let evaluated_args = []
              for arg in func_args {
                match eval_expr(arg, variables, functions) {
                  Ok(value) => evaluated_args.push(value)
                  Err(e) => return Err(e)
                }
              }

              // Look up function
              match functions.get(func_name) {
                Some(func) => func(evaluated_args)
                None => Err(HCLError::undefined_function(func_name))
              }
            }
            _ => Err(HCLError::type_error("Invalid function call structure"))
          }
        }
        Some(String("property_access", _)) => {
          let obj_value = obj.get("object").unwrap()
          let property = obj.get("property").unwrap()

          match (eval_expr(obj_value, variables, functions), property) {
            (Ok(Object(target_obj, _)), String(prop_name, _)) =>
              match target_obj.get(prop_name) {
                Some(value) => Ok(value)
                None => Err(HCLError::undefined_property(prop_name))
              }
            (Ok(_), _) =>
              Err(HCLError::type_error("Property access on non-object"))
            (Err(e), _) => Err(e)
          }
        }
        Some(String("index_access", _)) => {
          let obj_value = obj.get("object").unwrap()
          let index = obj.get("index").unwrap()

          match
            (
              eval_expr(obj_value, variables, functions),
              eval_expr(index, variables, functions),
            ) {
            (Ok(Array(arr, _)), Ok(Number(n, _))) =>
              match n.as_int() {
                Some(i) =>
                  if i >= 0 && i < arr.length() {
                    Ok(arr[i])
                  } else {
                    Err(HCLError::invalid_value("Array index out of bounds"))
                  }
                None => Err(HCLError::type_error("Array index must be integer"))
              }
            (Ok(Object(target_obj, _)), Ok(String(key, _))) =>
              match target_obj.get(key) {
                Some(value) => Ok(value)
                None => Err(HCLError::undefined_property(key))
              }
            (Ok(_), _) => Err(HCLError::type_error("Invalid index access"))
            (Err(e), _) => Err(e)
          }
        }
        Some(String("binary_expr", _)) => {
          // Binary expression: left op right
          let op = obj.get("op").unwrap()
          let left = obj.get("left").unwrap()
          let right = obj.get("right").unwrap()

          match
            (
              eval_expr(left, variables, functions),
              eval_expr(right, variables, functions),
            ) {
            (Ok(left_val), Ok(right_val)) =>
              match op {
                String(op_str, _) => eval_binary(left_val, op_str, right_val)
                _ => Err(HCLError::type_error("Operator must be string"))
              }
            (Err(e), _) => Err(e)
            (_, Err(e)) => Err(e)
          }
        }
        Some(String("unary_expr", _)) => {
          let op = obj.get("op").unwrap()
          let operand = obj.get("operand").unwrap()

          match eval_expr(operand, variables, functions) {
            Ok(operand_val) =>
              match op {
                String(op_str, _) => eval_unary(op_str, operand_val)
                _ => Err(HCLError::type_error("Operator must be string"))
              }
            Err(e) => Err(e)
          }
        }
        Some(String("for_expr", _)) => {
          // List comprehension: [for x in list: expr]
          let loop_var_name = obj.get("var").unwrap()
          let collection = obj.get("collection").unwrap()
          let value_expr = obj.get("value_expr").unwrap()
          let filter = obj.get("filter").unwrap()

          match eval_expr(collection, variables, functions) {
            Ok(Array(arr, _)) => {
              let result = []
              for item in arr {
                // Check filter if present
                let should_include = match filter {
                  Null(_) => true
                  filter_expr => {
                    // Create new context with loop variable
                    let loop_vars = variables.copy()
                    match loop_var_name {
                      String(var_name, _) => loop_vars[var_name] = item
                      _ =>
                        return Err(
                          HCLError::type_error("Loop variable must be string"),
                        )
                    }
                    match eval_expr(filter_expr, loop_vars, functions) {
                      Ok(Bool(b, _)) => b
                      Ok(_) =>
                        return Err(
                          HCLError::type_error("Filter must return boolean"),
                        )
                      Err(e) => return Err(e)
                    }
                  }
                }

                if should_include {
                  // Create new context with loop variable
                  let loop_vars = variables.copy()
                  match loop_var_name {
                    String(var_name, _) => loop_vars[var_name] = item
                    _ =>
                      return Err(
                        HCLError::type_error("Loop variable must be string"),
                      )
                  }
                  match eval_expr(value_expr, loop_vars, functions) {
                    Ok(value) => result.push(value)
                    Err(e) => return Err(e)
                  }
                }
              }
              Ok(Array(result, Decor::empty()))
            }
            Ok(_) => Err(HCLError::type_error("For collection must be array"))
            Err(e) => Err(e)
          }
        }
        Some(String("for_object_expr", _)) => {
          // Object comprehension: {for k, v in obj: k => v}
          let loop_key_var = obj.get("key_var").unwrap()
          let loop_value_var = obj.get("value_var").unwrap()
          let collection = obj.get("collection").unwrap()
          let key_expr = obj.get("key_expr").unwrap()
          let value_expr = obj.get("value_expr").unwrap()
          let filter = obj.get("filter").unwrap()

          match eval_expr(collection, variables, functions) {
            Ok(Object(source_obj, _)) => {
              let result = {}
              for k, v in source_obj {
                // Check filter if present
                let should_include = match filter {
                  Null(_) => true
                  filter_expr => {
                    // Create new context with loop variables
                    let loop_vars = variables.copy()
                    match loop_key_var {
                      String(key_var_name, _) =>
                        loop_vars[key_var_name] = String(k, Decor::empty())
                      _ =>
                        return Err(
                          HCLError::type_error("Key variable must be string"),
                        )
                    }
                    match loop_value_var {
                      String(value_var_name, _) => loop_vars[value_var_name] = v
                      _ =>
                        return Err(
                          HCLError::type_error("Value variable must be string"),
                        )
                    }
                    match eval_expr(filter_expr, loop_vars, functions) {
                      Ok(Bool(b, _)) => b
                      Ok(_) =>
                        return Err(
                          HCLError::type_error("Filter must return boolean"),
                        )
                      Err(e) => return Err(e)
                    }
                  }
                }

                if should_include {
                  // Create new context with loop variables
                  let loop_vars = variables.copy()
                  match loop_key_var {
                    String(key_var_name, _) =>
                      loop_vars[key_var_name] = String(k, Decor::empty())
                    _ =>
                      return Err(
                        HCLError::type_error("Key variable must be string"),
                      )
                  }
                  match loop_value_var {
                    String(value_var_name, _) => loop_vars[value_var_name] = v
                    _ =>
                      return Err(
                        HCLError::type_error("Value variable must be string"),
                      )
                  }

                  match eval_expr(key_expr, loop_vars, functions) {
                    Ok(String(new_key, _)) =>
                      match eval_expr(value_expr, loop_vars, functions) {
                        Ok(new_value) => result[new_key] = new_value
                        Err(e) => return Err(e)
                      }
                    Ok(_) =>
                      return Err(
                        HCLError::type_error("Object key must be string"),
                      )
                    Err(e) => return Err(e)
                  }
                }
              }
              Ok(Object(result, Decor::empty()))
            }
            Ok(_) => Err(HCLError::type_error("For collection must be object"))
            Err(e) => Err(e)
          }
        }
        // Regular object - evaluate each value
        _ => {
          let result = {}
          for k, v in obj {
            match eval_expr(v, variables, functions) {
              Ok(value) => result[k] = value
              Err(e) => return Err(e)
            }
          }
          Ok(Object(result, Decor::empty()))
        }
      }
  }
}

///|
/// Evaluate expression with default empty context
pub fn eval_expr_simple(expr : HCLValue) -> HCLResult[HCLValue] {
  let empty_vars = {}
  let empty_funcs = {}
  eval_expr(expr, empty_vars, empty_funcs)
}

///|
/// Simplify a value by evaluating constant expressions
fn simplify_value(value : HCLValue) -> HCLValue {
  match value {
    // Try to evaluate expressions
    Object(obj, _) =>
      match obj.get("type") {
        Some(String("binary_expr", _))
        | Some(String("unary_expr", _))
        | Some(String("conditional", _)) =>
          // Try to evaluate the expression
          match eval_expr_simple(value) {
            Ok(simplified) => simplified
            Err(_) => value // Keep original if evaluation fails
          }
        _ => {
          // Regular object - simplify each value
          let result = {}
          for k, v in obj {
            result[k] = simplify_value(v)
          }
          Object(result, Decor::empty())
        }
      }
    // Array - simplify each element
    Array(arr, _) => {
      let result = []
      for item in arr {
        result.push(simplify_value(item))
      }
      Array(result, Decor::empty())
    }
    // Basic values - return as-is
    _ => value
  }
}

///|
/// Simplify all values in a Body by evaluating constant expressions
pub fn simplify_body(body : Body) -> Body {
  let items = body.get_items()
  let simplified_items = []

  for item in items {
    match item {
      Attribute(attr) => {
        let simplified_value = simplify_value(attr.get_value())
        let new_attr = Attr::with_decor(
          attr.get_decorated_key(),
          simplified_value,
          attr.get_decor(),
        )
        simplified_items.push(Attribute(new_attr))
      }
      Block(block) => {
        let simplified_body = simplify_body(block.get_body())
        let new_block = Block::with_decor(
          block.get_decorated_type_name(),
          block.get_decorated_labels(),
          simplified_body,
          block.get_decor(),
        )
        simplified_items.push(Block(new_block))
      }
    }
  }

  Body::with_decor(simplified_items, body.get_decor())
}
