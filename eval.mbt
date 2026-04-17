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
    (Int(a), Int(b)) => Ok(Int(a + b))
    (Int64(a), Int64(b)) => Ok(Int64(a + b))
    (Float(a), Float(b)) => Ok(Float(a + b))
    (Int(a), Float(b)) => Ok(Float(a.to_double() + b))
    (Float(a), Int(b)) => Ok(Float(a + b.to_double()))
    (String(a), String(b)) => Ok(String(a + b))
    _ => Err(HCLError::type_error("Invalid types for addition"))
  }
}

///|
/// Evaluate subtraction
fn eval_sub(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) => Ok(Int(a - b))
    (Int64(a), Int64(b)) => Ok(Int64(a - b))
    (Float(a), Float(b)) => Ok(Float(a - b))
    (Int(a), Float(b)) => Ok(Float(a.to_double() - b))
    (Float(a), Int(b)) => Ok(Float(a - b.to_double()))
    _ => Err(HCLError::type_error("Invalid types for subtraction"))
  }
}

///|
/// Evaluate multiplication
fn eval_mul(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) => Ok(Int(a * b))
    (Int64(a), Int64(b)) => Ok(Int64(a * b))
    (Float(a), Float(b)) => Ok(Float(a * b))
    (Int(a), Float(b)) => Ok(Float(a.to_double() * b))
    (Float(a), Int(b)) => Ok(Float(a * b.to_double()))
    _ => Err(HCLError::type_error("Invalid types for multiplication"))
  }
}

///|
/// Evaluate division
fn eval_div(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) =>
      if b == 0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Int(a / b))
      }
    (Int64(a), Int64(b)) =>
      if b == 0L {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Int64(a / b))
      }
    (Float(a), Float(b)) =>
      if b == 0.0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Float(a / b))
      }
    (Int(a), Float(b)) =>
      if b == 0.0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Float(a.to_double() / b))
      }
    (Float(a), Int(b)) =>
      if b == 0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Float(a / b.to_double()))
      }
    _ => Err(HCLError::type_error("Invalid types for division"))
  }
}

///|
/// Evaluate modulo
fn eval_mod(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) =>
      if b == 0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Int(a % b))
      }
    (Int64(a), Int64(b)) =>
      if b == 0L {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Int64(a % b))
      }
    (Float(a), Float(b)) =>
      if b == 0.0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Float(a % b))
      }
    (Int(a), Float(b)) =>
      if b == 0.0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Float(a.to_double() % b))
      }
    (Float(a), Int(b)) =>
      if b == 0 {
        Err(HCLError::division_by_zero())
      } else {
        Ok(Float(a % b.to_double()))
      }
    _ => Err(HCLError::type_error("Invalid types for modulo"))
  }
}

///|
/// Evaluate equality
fn eval_eq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  Ok(Bool(left == right))
}

///|
/// Evaluate inequality
fn eval_neq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  Ok(Bool(left != right))
}

///|
/// Evaluate less than
fn eval_lt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) => Ok(Bool(a < b))
    (Int64(a), Int64(b)) => Ok(Bool(a < b))
    (Float(a), Float(b)) => Ok(Bool(a < b))
    (Int(a), Float(b)) => Ok(Bool(a.to_double() < b))
    (Float(a), Int(b)) => Ok(Bool(a < b.to_double()))
    _ => Err(HCLError::type_error("Invalid types for less than"))
  }
}

///|
/// Evaluate greater than
fn eval_gt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) => Ok(Bool(a > b))
    (Int64(a), Int64(b)) => Ok(Bool(a > b))
    (Float(a), Float(b)) => Ok(Bool(a > b))
    (Int(a), Float(b)) => Ok(Bool(a.to_double() > b))
    (Float(a), Int(b)) => Ok(Bool(a > b.to_double()))
    _ => Err(HCLError::type_error("Invalid types for greater than"))
  }
}

///|
/// Evaluate less than or equal
fn eval_lte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) => Ok(Bool(a <= b))
    (Int64(a), Int64(b)) => Ok(Bool(a <= b))
    (Float(a), Float(b)) => Ok(Bool(a <= b))
    (Int(a), Float(b)) => Ok(Bool(a.to_double() <= b))
    (Float(a), Int(b)) => Ok(Bool(a <= b.to_double()))
    _ => Err(HCLError::type_error("Invalid types for less than or equal"))
  }
}

///|
/// Evaluate greater than or equal
fn eval_gte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Int(a), Int(b)) => Ok(Bool(a >= b))
    (Int64(a), Int64(b)) => Ok(Bool(a >= b))
    (Float(a), Float(b)) => Ok(Bool(a >= b))
    (Int(a), Float(b)) => Ok(Bool(a.to_double() >= b))
    (Float(a), Int(b)) => Ok(Bool(a >= b.to_double()))
    _ => Err(HCLError::type_error("Invalid types for greater than or equal"))
  }
}

///|
/// Evaluate logical and
fn eval_and(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Bool(a), Bool(b)) => Ok(Bool(a && b))
    _ => Err(HCLError::type_error("Invalid types for logical and"))
  }
}

///|
/// Evaluate logical or
fn eval_or(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Bool(a), Bool(b)) => Ok(Bool(a || b))
    _ => Err(HCLError::type_error("Invalid types for logical or"))
  }
}

///|
/// Evaluate negation
fn eval_negate(operand : HCLValue) -> HCLResult[HCLValue] {
  match operand {
    Int(i) => Ok(Int(-i))
    Int64(i) => Ok(Int64(-i))
    Float(f) => Ok(Float(-f))
    _ => Err(HCLError::type_error("Invalid type for negation"))
  }
}

///|
/// Evaluate logical not
fn eval_not(operand : HCLValue) -> HCLResult[HCLValue] {
  match operand {
    Bool(b) => Ok(Bool(!b))
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
    Bool(b) => if b { Ok(true_expr) } else { Ok(false_expr) }
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
    Null | Bool(_) | Int(_) | Int64(_) | Float(_) | String(_) => Ok(expr)

    // Array - evaluate each element
    Array(arr) => {
      let result = []
      for item in arr {
        match eval_expr(item, variables, functions) {
          Ok(value) => result.push(value)
          Err(e) => return Err(e)
        }
      }
      Ok(Array(result))
    }

    // Object - check if it's a special expression type
    Object(obj) =>
      match obj.get("type") {
        Some(String("conditional")) => {
          let condition = obj.get("condition").unwrap()
          let true_expr = obj.get("true_expr").unwrap()
          let false_expr = obj.get("false_expr").unwrap()

          match eval_expr(condition, variables, functions) {
            Ok(cond_value) =>
              eval_conditional(cond_value, true_expr, false_expr)
            Err(e) => Err(e)
          }
        }
        Some(String("variable")) => {
          let name = obj.get("name").unwrap()
          match name {
            String(var_name) =>
              match variables.get(var_name) {
                Some(value) => Ok(value)
                None => Err(HCLError::undefined_variable(var_name))
              }
            _ => Err(HCLError::type_error("Variable name must be string"))
          }
        }
        Some(String("function_call")) => {
          let name = obj.get("name").unwrap()
          let args = obj.get("args").unwrap()

          match (name, args) {
            (String(func_name), Array(func_args)) => {
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
        Some(String("property_access")) => {
          let obj_value = obj.get("object").unwrap()
          let property = obj.get("property").unwrap()

          match (eval_expr(obj_value, variables, functions), property) {
            (Ok(Object(target_obj)), String(prop_name)) =>
              match target_obj.get(prop_name) {
                Some(value) => Ok(value)
                None => Err(HCLError::undefined_property(prop_name))
              }
            (Ok(_), _) =>
              Err(HCLError::type_error("Property access on non-object"))
            (Err(e), _) => Err(e)
          }
        }
        Some(String("index_access")) => {
          let obj_value = obj.get("object").unwrap()
          let index = obj.get("index").unwrap()

          match
            (
              eval_expr(obj_value, variables, functions),
              eval_expr(index, variables, functions),
            ) {
            (Ok(Array(arr)), Ok(Int(i))) =>
              if i >= 0 && i < arr.length() {
                Ok(arr[i])
              } else {
                Err(HCLError::invalid_value("Array index out of bounds"))
              }
            (Ok(Object(target_obj)), Ok(String(key))) =>
              match target_obj.get(key) {
                Some(value) => Ok(value)
                None => Err(HCLError::undefined_property(key))
              }
            (Ok(_), _) => Err(HCLError::type_error("Invalid index access"))
            (Err(e), _) => Err(e)
          }
        }
        Some(String("binary_expr")) => {
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
                String(op_str) => eval_binary(left_val, op_str, right_val)
                _ => Err(HCLError::type_error("Operator must be string"))
              }
            (Err(e), _) => Err(e)
            (_, Err(e)) => Err(e)
          }
        }
        Some(String("unary_expr")) => {
          let op = obj.get("op").unwrap()
          let operand = obj.get("operand").unwrap()

          match eval_expr(operand, variables, functions) {
            Ok(operand_val) =>
              match op {
                String(op_str) => eval_unary(op_str, operand_val)
                _ => Err(HCLError::type_error("Operator must be string"))
              }
            Err(e) => Err(e)
          }
        }
        Some(String("for_expr")) => {
          // List comprehension: [for x in list: expr]
          let loop_var_name = obj.get("var").unwrap()
          let collection = obj.get("collection").unwrap()
          let value_expr = obj.get("value_expr").unwrap()
          let filter = obj.get("filter").unwrap()

          match eval_expr(collection, variables, functions) {
            Ok(Array(arr)) => {
              let result = []
              for item in arr {
                // Check filter if present
                let should_include = match filter {
                  Null => true
                  filter_expr => {
                    // Create new context with loop variable
                    let loop_vars = variables.copy()
                    match loop_var_name {
                      String(var_name) => loop_vars[var_name] = item
                      _ =>
                        return Err(
                          HCLError::type_error("Loop variable must be string"),
                        )
                    }
                    match eval_expr(filter_expr, loop_vars, functions) {
                      Ok(Bool(b)) => b
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
                    String(var_name) => loop_vars[var_name] = item
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
              Ok(Array(result))
            }
            Ok(_) => Err(HCLError::type_error("For collection must be array"))
            Err(e) => Err(e)
          }
        }
        Some(String("for_object_expr")) => {
          // Object comprehension: {for k, v in obj: k => v}
          let loop_key_var = obj.get("key_var").unwrap()
          let loop_value_var = obj.get("value_var").unwrap()
          let collection = obj.get("collection").unwrap()
          let key_expr = obj.get("key_expr").unwrap()
          let value_expr = obj.get("value_expr").unwrap()
          let filter = obj.get("filter").unwrap()

          match eval_expr(collection, variables, functions) {
            Ok(Object(source_obj)) => {
              let result = {}
              for k, v in source_obj {
                // Check filter if present
                let should_include = match filter {
                  Null => true
                  filter_expr => {
                    // Create new context with loop variables
                    let loop_vars = variables.copy()
                    match loop_key_var {
                      String(key_var_name) =>
                        loop_vars[key_var_name] = String(k)
                      _ =>
                        return Err(
                          HCLError::type_error("Key variable must be string"),
                        )
                    }
                    match loop_value_var {
                      String(value_var_name) => loop_vars[value_var_name] = v
                      _ =>
                        return Err(
                          HCLError::type_error("Value variable must be string"),
                        )
                    }
                    match eval_expr(filter_expr, loop_vars, functions) {
                      Ok(Bool(b)) => b
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
                    String(key_var_name) => loop_vars[key_var_name] = String(k)
                    _ =>
                      return Err(
                        HCLError::type_error("Key variable must be string"),
                      )
                  }
                  match loop_value_var {
                    String(value_var_name) => loop_vars[value_var_name] = v
                    _ =>
                      return Err(
                        HCLError::type_error("Value variable must be string"),
                      )
                  }

                  match eval_expr(key_expr, loop_vars, functions) {
                    Ok(String(new_key)) =>
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
              Ok(Object(result))
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
          Ok(Object(result))
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
