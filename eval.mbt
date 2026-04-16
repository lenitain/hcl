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
