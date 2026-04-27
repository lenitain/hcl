///|
/// HCL Expression Evaluator - evaluates expressions to values
/// Simple implementation without complex expression tree

///|
/// Check if value is Unknown
fn is_unknown_value(v : HCLValue) -> Bool {
  match v {
    Unknown(_) => true
    _ => false
  }
}

///|
/// Convert string to bool value
fn string_to_bool(s : String) -> HCLResult[HCLValue] {
  match s {
    "true" | "1" => Ok(Bool(true, Decor::empty()))
    "false" | "0" => Ok(Bool(false, Decor::empty()))
    _ =>
      Err(HCLError::type_error("Cannot convert string \"" + s + "\" to bool"))
  }
}

///|
/// Convert string to number value
fn string_to_number(s : String) -> HCLResult[HCLValue] {
  let trimmed = s.trim()
  if trimmed.length() == 0 {
    return Err(HCLError::type_error("Cannot convert empty string to number"))
  }

  let mut has_digit = false
  let mut has_dot = false
  let mut negative = false
  let mut result_int = 0
  let mut result_float = 0.0
  let mut decimal_place = 1.0
  let mut in_decimal = false
  let mut started = false

  for c in trimmed {
    if !started && c == '-' {
      negative = true
      started = true
    } else if !started && c == '+' {
      started = true
    } else if c == '.' {
      if has_dot {
        return Err(HCLError::type_error("Invalid number format: " + s))
      }
      has_dot = true
      has_digit = true
      in_decimal = true
      started = true
    } else if c >= '0' && c <= '9' {
      has_digit = true
      started = true
      let digit = (c.to_int() - '0'.to_int()).to_double()
      if in_decimal {
        decimal_place = decimal_place * 10.0
        result_float = result_float + digit / decimal_place
      } else {
        result_int = result_int * 10 + (c.to_int() - '0'.to_int())
        result_float = result_float * 10.0 + digit
      }
    } else {
      return Err(HCLError::type_error("Invalid number format: " + s))
    }
  }

  if !has_digit {
    return Err(HCLError::type_error("Invalid number format: " + s))
  }

  if has_dot {
    let f = if negative { -result_float } else { result_float }
    Ok(Number(Number::from_finite_f64(f), Decor::empty()))
  } else {
    let n = if negative { -result_int } else { result_int }
    Ok(Number(Number::from_int(n), Decor::empty()))
  }
}

///|
/// Convert number to string value
fn number_to_string(n : Number) -> String {
  n.to_string()
}

///|
/// Convert bool to string value
fn bool_to_string(b : Bool) -> String {
  if b {
    "true"
  } else {
    "false"
  }
}

///|
/// Evaluate binary operation on two HCLValues
pub fn eval_binary(
  left : HCLValue,
  op : String,
  right : HCLValue,
) -> HCLResult[HCLValue] {
  if is_unknown_value(left) || is_unknown_value(right) {
    return Ok(Unknown(Decor::empty()))
  }
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
  if is_unknown_value(operand) {
    return Ok(Unknown(Decor::empty()))
  }
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
    (String(a, _), Number(b, _)) =>
      Ok(String(a + number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) =>
      Ok(String(number_to_string(a) + b, Decor::empty()))
    (String(a, _), Bool(b, _)) =>
      Ok(String(a + bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) =>
      Ok(String(bool_to_string(a) + b, Decor::empty()))
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
/// Evaluate equality with implicit conversion
fn eval_eq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  if left == right {
    return Ok(Bool(true, Decor::empty()))
  }
  match (left, right) {
    (String(s, _), Number(n, _)) =>
      Ok(Bool(s == number_to_string(n), Decor::empty()))
    (Number(n, _), String(s, _)) =>
      Ok(Bool(number_to_string(n) == s, Decor::empty()))
    (String(s, _), Bool(b, _)) =>
      Ok(Bool(s == bool_to_string(b), Decor::empty()))
    (Bool(b, _), String(s, _)) =>
      Ok(Bool(bool_to_string(b) == s, Decor::empty()))
    _ => Ok(Bool(false, Decor::empty()))
  }
}

///|
/// Evaluate inequality with implicit conversion
fn eval_neq(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match eval_eq(left, right) {
    Ok(Bool(b, _)) => Ok(Bool(!b, Decor::empty()))
    other => other
  }
}

///|
/// Evaluate less than with implicit conversion
fn eval_lt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a < b, Decor::empty()))
    (String(a, _), Number(b, _)) =>
      Ok(Bool(a < number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) =>
      Ok(Bool(number_to_string(a) < b, Decor::empty()))
    (String(a, _), Bool(b, _)) =>
      Ok(Bool(a < bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) =>
      Ok(Bool(bool_to_string(a) < b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for less than"))
  }
}

///|
/// Evaluate greater than with implicit conversion
fn eval_gt(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a > b, Decor::empty()))
    (String(a, _), Number(b, _)) =>
      Ok(Bool(a > number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) =>
      Ok(Bool(number_to_string(a) > b, Decor::empty()))
    (String(a, _), Bool(b, _)) =>
      Ok(Bool(a > bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) =>
      Ok(Bool(bool_to_string(a) > b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for greater than"))
  }
}

///|
/// Evaluate less than or equal with implicit conversion
fn eval_lte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a <= b, Decor::empty()))
    (String(a, _), Number(b, _)) =>
      Ok(Bool(a <= number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) =>
      Ok(Bool(number_to_string(a) <= b, Decor::empty()))
    (String(a, _), Bool(b, _)) =>
      Ok(Bool(a <= bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) =>
      Ok(Bool(bool_to_string(a) <= b, Decor::empty()))
    _ => Err(HCLError::type_error("Invalid types for less than or equal"))
  }
}

///|
/// Evaluate greater than or equal with implicit conversion
fn eval_gte(left : HCLValue, right : HCLValue) -> HCLResult[HCLValue] {
  match (left, right) {
    (Number(a, _), Number(b, _)) => Ok(Bool(a >= b, Decor::empty()))
    (String(a, _), Number(b, _)) =>
      Ok(Bool(a >= number_to_string(b), Decor::empty()))
    (Number(a, _), String(b, _)) =>
      Ok(Bool(number_to_string(a) >= b, Decor::empty()))
    (String(a, _), Bool(b, _)) =>
      Ok(Bool(a >= bool_to_string(b), Decor::empty()))
    (Bool(a, _), String(b, _)) =>
      Ok(Bool(bool_to_string(a) >= b, Decor::empty()))
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
  if is_unknown_value(condition) {
    return Ok(Unknown(Decor::empty()))
  }
  match condition {
    Bool(b, _) => if b { Ok(true_expr) } else { Ok(false_expr) }
    _ => Err(HCLError::type_error("Condition must be boolean"))
  }
}

///|
/// Evaluate expression (handles all expression types)
pub fn eval_expr(
  expr : Expression,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[HCLValue] {
  match expr {
    ExprNull => Ok(Null(Decor::empty()))
    ExprBool(b) => Ok(Bool(b, Decor::empty()))
    ExprInt(i) => Ok(Number(Number::from_int(i), Decor::empty()))
    ExprInt64(i) => Ok(Number(Number::from_int64(i), Decor::empty()))
    ExprFloat(f) => Ok(Number(Number::from_finite_f64(f), Decor::empty()))
    ExprString(s) => Ok(String(s, Decor::empty()))
    ExprArray(arr) => {
      let result = []
      for item in arr {
        match eval_expr(item, variables, functions) {
          Ok(value) => result.push(value)
          Err(e) => return Err(e)
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    ExprObject(obj) => {
      let result = {}
      for pair in obj {
        let (k, v) = pair
        let key = ObjectKey::to_string(k)
        match eval_expr(v, variables, functions) {
          Ok(value) => result[key] = value
          Err(e) => return Err(e)
        }
      }
      Ok(Object(result, Decor::empty()))
    }
    ExprVariable(v) =>
      match variables.get(v.name) {
        Some(value) => Ok(value)
        None => Err(HCLError::undefined_variable(v.name))
      }
    ExprTraversal(trav) =>
      match eval_expr(trav.base, variables, functions) {
        Ok(base_value) => {
          let mut current = base_value
          let ops = trav.operators
          let mut i = 0
          let ops_len = ops.length()
          while i < ops_len {
            let op = ops[i]
            match op {
              Attr(name) =>
                match current {
                  Object(target_obj, _) =>
                    match target_obj.get(name) {
                      Some(value) => {
                        current = value
                        i = i + 1
                      }
                      None => return Err(HCLError::undefined_property(name))
                    }
                  _ =>
                    return Err(
                      HCLError::type_error("Property access on non-object"),
                    )
                }
              Index(idx_expr) =>
                match eval_expr(idx_expr, variables, functions) {
                  Ok(index_value) =>
                    match (current, index_value) {
                      (Array(arr, _), Number(n, _)) =>
                        match n.as_int() {
                          Some(idx) =>
                            if idx >= 0 && idx < arr.length() {
                              current = arr[idx]
                              i = i + 1
                            } else {
                              return Err(
                                HCLError::invalid_value(
                                  "Array index out of bounds",
                                ),
                              )
                            }
                          None =>
                            return Err(
                              HCLError::type_error(
                                "Array index must be integer",
                              ),
                            )
                        }
                      (Object(target_obj, _), String(key, _)) =>
                        match target_obj.get(key) {
                          Some(value) => {
                            current = value
                            i = i + 1
                          }
                          None => return Err(HCLError::undefined_property(key))
                        }
                      (_, _) =>
                        return Err(HCLError::type_error("Invalid index access"))
                    }
                  Err(e) => return Err(e)
                }
              Splat => {
                let remaining_ops = []
                let mut j = i + 1
                while j < ops_len {
                  remaining_ops.push(ops[j])
                  j = j + 1
                }
                return eval_splat(current, remaining_ops, variables, functions)
              }
            }
          }
          Ok(current)
        }
        Err(e) => Err(e)
      }
    ExprFuncCall(fc) => {
      let evaluated_args = []
      for arg in fc.args {
        match eval_expr(arg, variables, functions) {
          Ok(value) => evaluated_args.push(value)
          Err(e) => return Err(e)
        }
      }
      match functions.get(fc.name) {
        Some(func_def) => func_def.call(evaluated_args)
        None => Err(HCLError::undefined_function(fc.name))
      }
    }
    ExprParenthesis(inner) => eval_expr(inner, variables, functions)
    ExprConditional(cond) =>
      match eval_expr(cond.condition, variables, functions) {
        Ok(Bool(b, _)) =>
          if b {
            eval_expr(cond.true_expr, variables, functions)
          } else {
            eval_expr(cond.false_expr, variables, functions)
          }
        Ok(_) => Err(HCLError::type_error("Condition must be boolean"))
        Err(e) => Err(e)
      }
    ExprOperation(op) => eval_operation(op, variables, functions)
    ExprTemplate(tmpl) => eval_template(tmpl, variables, functions)
    ExprFor(for_expr) => eval_for_expr(for_expr, variables, functions)
    ExprUnknown => Ok(Unknown(Decor::empty()))
  }
}

///|
/// Evaluate splat: apply remaining traversal operators to each element of a collection
fn eval_splat(
  value : HCLValue,
  remaining_ops : Array[TraversalOperator],
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[HCLValue] {
  match value {
    Array(arr, _) => {
      let result = []
      for elem in arr {
        match apply_traversal_ops(elem, remaining_ops, variables, functions) {
          Ok(v) => result.push(v)
          Err(e) => return Err(e)
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    Object(obj, _) => {
      let result = []
      for _key, val in obj {
        match apply_traversal_ops(val, remaining_ops, variables, functions) {
          Ok(v) => result.push(v)
          Err(e) => return Err(e)
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("Splat requires array or object"))
  }
}

///|
/// Apply a sequence of traversal operators to a value
fn apply_traversal_ops(
  value : HCLValue,
  ops : Array[TraversalOperator],
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[HCLValue] {
  let mut current = value
  let mut i = 0
  let ops_len = ops.length()
  while i < ops_len {
    let op = ops[i]
    match op {
      Attr(name) =>
        match current {
          Object(target_obj, _) =>
            match target_obj.get(name) {
              Some(v) => {
                current = v
                i = i + 1
              }
              None => return Err(HCLError::undefined_property(name))
            }
          _ => return Err(HCLError::type_error("Property access on non-object"))
        }
      Index(idx_expr) =>
        match eval_expr(idx_expr, variables, functions) {
          Ok(index_value) =>
            match (current, index_value) {
              (Array(arr, _), Number(n, _)) =>
                match n.as_int() {
                  Some(idx) =>
                    if idx >= 0 && idx < arr.length() {
                      current = arr[idx]
                      i = i + 1
                    } else {
                      return Err(
                        HCLError::invalid_value("Array index out of bounds"),
                      )
                    }
                  None =>
                    return Err(
                      HCLError::type_error("Array index must be integer"),
                    )
                }
              (Object(target_obj, _), String(key, _)) =>
                match target_obj.get(key) {
                  Some(v) => {
                    current = v
                    i = i + 1
                  }
                  None => return Err(HCLError::undefined_property(key))
                }
              (_, _) => return Err(HCLError::type_error("Invalid index access"))
            }
          Err(e) => return Err(e)
        }
      Splat =>
        return eval_splat(current, drop_first(ops, i + 1), variables, functions)
    }
  }
  Ok(current)
}

///|
/// Drop first n elements from array (returns new array)
fn[T] drop_first(arr : Array[T], n : Int) -> Array[T] {
  let result = []
  let mut i = n
  while i < arr.length() {
    result.push(arr[i])
    i = i + 1
  }
  result
}

///|
/// Evaluate operation expression
fn eval_operation(
  op : Operation,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[HCLValue] {
  match op {
    Binary(binop) =>
      match
        (
          eval_expr(binop.left, variables, functions),
          eval_expr(binop.right, variables, functions),
        ) {
        (Ok(left_val), Ok(right_val)) =>
          eval_binary_op(binop.op, left_val, right_val)
        (Err(e), _) => Err(e)
        (_, Err(e)) => Err(e)
      }
    Unary(unop) =>
      match eval_expr(unop.operand, variables, functions) {
        Ok(operand_val) => eval_unary_op(unop.op, operand_val)
        Err(e) => Err(e)
      }
  }
}

///|
/// Evaluate binary operation with typed operator
fn eval_binary_op(
  op : BinaryOperator,
  left : HCLValue,
  right : HCLValue,
) -> HCLResult[HCLValue] {
  if is_unknown_value(left) || is_unknown_value(right) {
    return Ok(Unknown(Decor::empty()))
  }
  match op {
    Plus => eval_add(left, right)
    Minus => eval_sub(left, right)
    Mul => eval_mul(left, right)
    Div => eval_div(left, right)
    Mod => eval_mod(left, right)
    Eq => eval_eq(left, right)
    Neq => eval_neq(left, right)
    Lt => eval_lt(left, right)
    Gt => eval_gt(left, right)
    Lte => eval_lte(left, right)
    Gte => eval_gte(left, right)
    And => eval_and(left, right)
    Or => eval_or(left, right)
  }
}

///|
/// Evaluate unary operation with typed operator
fn eval_unary_op(op : UnaryOperator, operand : HCLValue) -> HCLResult[HCLValue] {
  if is_unknown_value(operand) {
    return Ok(Unknown(Decor::empty()))
  }
  match op {
    Negate => eval_negate(operand)
    Not => eval_not(operand)
  }
}

///|
/// Evaluate template expression
fn eval_template(
  tmpl : TemplateExpr,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[HCLValue] {
  match tmpl {
    Heredoc(h) => {
      let template = Template::from_heredoc(
        h.content,
        h.delimiter,
        h.strip_mode == StripMode,
      )
      match template {
        Ok(t) =>
          match t.evaluate(variables, functions) {
            Ok(s) => Ok(String(s, Decor::empty()))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }
    InterpolatedString(s) => {
      let template = Template::from_string(s)
      match template {
        Ok(t) =>
          match t.evaluate(variables, functions) {
            Ok(result) => Ok(String(result, Decor::empty()))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    }
  }
}

///|
/// Evaluate for expression (list/object comprehension)
fn eval_for_expr(
  for_expr : ForExpr,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[HCLValue] {
  match for_expr {
    List(list) =>
      match eval_expr(list.collection, variables, functions) {
        Ok(Array(arr, _)) => {
          let result = []
          for item in arr {
            let should_include = match list.filter {
              Some(filter_expr) => {
                let loop_vars = variables.copy()
                loop_vars[list.var_name] = item
                match eval_expr(filter_expr, loop_vars, functions) {
                  Ok(Bool(b, _)) => b
                  Ok(_) =>
                    return Err(
                      HCLError::type_error("Filter must return boolean"),
                    )
                  Err(e) => return Err(e)
                }
              }
              None => true
            }
            if should_include {
              let loop_vars = variables.copy()
              loop_vars[list.var_name] = item
              match eval_expr(list.value_expr, loop_vars, functions) {
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
    Object(obj) =>
      match eval_expr(obj.collection, variables, functions) {
        Ok(Object(source_obj, _)) => {
          let result = {}
          for k, v in source_obj {
            let should_include = match obj.filter {
              Some(filter_expr) => {
                let loop_vars = variables.copy()
                loop_vars[obj.key_var] = String(k, Decor::empty())
                loop_vars[obj.value_var] = v
                match eval_expr(filter_expr, loop_vars, functions) {
                  Ok(Bool(b, _)) => b
                  Ok(_) =>
                    return Err(
                      HCLError::type_error("Filter must return boolean"),
                    )
                  Err(e) => return Err(e)
                }
              }
              None => true
            }
            if should_include {
              let loop_vars = variables.copy()
              loop_vars[obj.key_var] = String(k, Decor::empty())
              loop_vars[obj.value_var] = v
              match eval_expr(obj.key_expr, loop_vars, functions) {
                Ok(String(new_key, _)) =>
                  match eval_expr(obj.value_expr, loop_vars, functions) {
                    Ok(new_value) => result[new_key] = new_value
                    Err(e) => return Err(e)
                  }
                Ok(_) =>
                  return Err(HCLError::type_error("Object key must be string"))
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
}

///|
/// Evaluate expression with default empty context
pub fn eval_expr_simple(expr : Expression) -> HCLResult[HCLValue] {
  let empty_vars = {}
  let empty_funcs = {}
  eval_expr(expr, empty_vars, empty_funcs)
}

///|
/// Simplify a value by evaluating constant expressions
fn simplify_value(expr : Expression) -> Expression {
  match expr {
    ExprOperation(_) =>
      match eval_expr_simple(expr) {
        Ok(value) => hcl_value_to_expression(value)
        Err(_) => expr
      }
    ExprConditional(_) =>
      match eval_expr_simple(expr) {
        Ok(value) => hcl_value_to_expression(value)
        Err(_) => expr
      }
    ExprArray(arr) => ExprArray(arr.map(simplify_value))
    ExprObject(obj) => {
      let simplified = obj.map(fn(pair) {
        let (k, v) = pair
        (k, simplify_value(v))
      })
      ExprObject(simplified)
    }
    _ => expr
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
          Spanned::bare(simplified_value),
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
