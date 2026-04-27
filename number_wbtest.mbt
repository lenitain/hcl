///|
/// Tests for Number type

// --- Construction tests ---

test "number from_int positive" {
  let n = Number::from_int(42)
  assert_true(n.is_pos_int())
  assert_false(n.is_neg_int())
  assert_false(n.is_f64())
  assert_true(n.as_u64() == Some(42UL))
  assert_true(n.as_i64() == Some(42L))
}

///|
test "number from_int zero" {
  let n = Number::from_int(0)
  assert_true(n.is_pos_int())
  assert_true(n.as_u64() == Some(0UL))
}

///|
test "number from_int negative" {
  let n = Number::from_int(-5)
  assert_true(n.is_neg_int())
  assert_false(n.is_pos_int())
  assert_false(n.is_f64())
  assert_true(n.as_i64() == Some(-5L))
  assert_true(n.as_u64() == None)
}

///|
test "number from_int64 positive" {
  let n = Number::from_int64(100L)
  assert_true(n.is_pos_int())
  assert_true(n.as_u64() == Some(100UL))
}

///|
test "number from_int64 negative" {
  let n = Number::from_int64(-100L)
  assert_true(n.is_neg_int())
  assert_true(n.as_i64() == Some(-100L))
}

///|
test "number from_uint64" {
  let n = Number::from_uint64(999UL)
  assert_true(n.is_pos_int())
  assert_true(n.as_u64() == Some(999UL))
}

///|
test "number from_double with fraction" {
  let n = Number::from_double(3.14)
  assert_true(n.is_f64())
  assert_false(n.is_pos_int())
  assert_false(n.is_neg_int())
  assert_true(n.as_f64() == 3.14)
}

///|
test "number from_double whole number" {
  let n = Number::from_double(42.0)
  assert_true(n.is_pos_int())
  assert_false(n.is_f64())
  assert_true(n.as_u64() == Some(42UL))
}

///|
test "number from_double negative whole" {
  let n = Number::from_double(-3.0)
  assert_true(n.is_neg_int())
  assert_false(n.is_f64())
  assert_true(n.as_i64() == Some(-3L))
}

///|
test "number from_f64 valid" {
  let n = Number::from_f64(1.5)
  assert_true(n is Some(_))
  match n {
    Some(v) => assert_true(v.is_f64())
    None => panic()
  }
}

///|
test "number from_f64 NaN" {
  let nan = 0.0 / 0.0
  let n = Number::from_f64(nan)
  assert_true(n == None)
}

///|
test "number from_f64 infinity" {
  let inf = 1.0 / 0.0
  let n = Number::from_f64(inf)
  assert_true(n == None)
}

///|
test "number from_f64 neg infinity" {
  let neginf = -(1.0 / 0.0)
  let n = Number::from_f64(neginf)
  assert_true(n == None)
}

// --- Equality tests ---

///|
test "number eq same type" {
  let a = Number::from_int(42)
  let b = Number::from_int(42)
  assert_true(a == b)
}

///|
test "number eq different values" {
  let a = Number::from_int(42)
  let b = Number::from_int(43)
  assert_false(a == b)
}

///|
test "number eq int64" {
  let a = Number::from_int64(-10L)
  let b = Number::from_int64(-10L)
  assert_true(a == b)
}

///|
test "number eq float" {
  let a = Number::from_double(1.5)
  let b = Number::from_double(1.5)
  assert_true(a == b)
}

///|
test "number eq cross-type coercion" {
  let a = Number::from_double(5.0)
  let b = Number::from_uint64(5UL)
  assert_true(a == b)
}

// --- Comparison tests ---

///|
test "number compare same type" {
  let a = Number::from_int(10)
  let b = Number::from_int(20)
  assert_true(a < b)
  assert_true(b > a)
}

///|
test "number compare negative" {
  let a = Number::from_int64(-5L)
  let b = Number::from_int64(-3L)
  assert_true(a < b)
}

///|
test "number compare float" {
  let a = Number::from_double(1.5)
  let b = Number::from_double(2.5)
  assert_true(a < b)
}

///|
test "number compare equal" {
  let a = Number::from_int(42)
  let b = Number::from_int(42)
  assert_true(a <= b)
  assert_true(a >= b)
}

// --- Arithmetic tests ---

///|
test "number add posint" {
  let a = Number::from_uint64(1UL)
  let b = Number::from_uint64(2UL)
  let c = a + b
  assert_true(c == Number::from_uint64(3UL))
  assert_true(c.is_pos_int())
}

///|
test "number add negint" {
  let a = Number::from_int64(-1L)
  let b = Number::from_int64(-2L)
  let c = a + b
  assert_true(c == Number::from_int64(-3L))
  assert_true(c.is_neg_int())
}

///|
test "number add float" {
  let a = Number::from_double(1.5)
  let b = Number::from_double(1.5)
  let c = a + b
  assert_true(c == Number::from_uint64(3UL))
  assert_true(c.is_pos_int())
}

///|
test "number add mixed" {
  let a = Number::from_double(1.5)
  let b = Number::from_int64(-1L)
  let c = a + b
  assert_true(c == Number::from_double(0.5))
  assert_true(c.is_f64())
}

///|
test "number sub posint" {
  let a = Number::from_uint64(5UL)
  let b = Number::from_uint64(3UL)
  let c = a - b
  assert_true(c == Number::from_uint64(2UL))
  assert_true(c.is_pos_int())
}

///|
test "number sub posint underflow" {
  let a = Number::from_uint64(1UL)
  let b = Number::from_uint64(2UL)
  let c = a - b
  assert_true(c == Number::from_int64(-1L))
  assert_true(c.is_neg_int())
}

///|
test "number sub negint" {
  let a = Number::from_int64(-1L)
  let b = Number::from_int64(-2L)
  let c = a - b
  assert_true(c == Number::from_uint64(1UL))
  assert_true(c.is_pos_int())
}

///|
test "number sub float" {
  let a = Number::from_double(1.5)
  let b = Number::from_double(1.5)
  let c = a - b
  assert_true(c == Number::from_uint64(0UL))
  assert_true(c.is_pos_int())
}

///|
test "number mul neg times pos" {
  let a = Number::from_int64(-1L)
  let b = Number::from_uint64(2UL)
  let c = a * b
  assert_true(c == Number::from_int64(-2L))
  assert_true(c.is_neg_int())
}

///|
test "number mul neg times neg" {
  let a = Number::from_int64(-1L)
  let b = Number::from_int64(-2L)
  let c = a * b
  assert_true(c == Number::from_uint64(2UL))
  assert_true(c.is_pos_int())
}

///|
test "number mul float" {
  let a = Number::from_double(1.5)
  let b = Number::from_double(1.5)
  let c = a * b
  assert_true(c == Number::from_double(2.25))
  assert_true(c.is_f64())
}

///|
test "number div int" {
  let a = Number::from_uint64(1UL)
  let b = Number::from_uint64(2UL)
  let c = a / b
  assert_true(c == Number::from_double(0.5))
  assert_true(c.is_f64())
}

///|
test "number div even" {
  let a = Number::from_uint64(4UL)
  let b = Number::from_uint64(2UL)
  let c = a / b
  assert_true(c == Number::from_uint64(2UL))
  assert_true(c.is_pos_int())
}

///|
test "number div neg" {
  let a = Number::from_int64(-4L)
  let b = Number::from_uint64(2UL)
  let c = a / b
  assert_true(c == Number::from_int64(-2L))
  assert_true(c.is_neg_int())
}

///|
test "number div float" {
  let a = Number::from_double(4.1)
  let b = Number::from_double(2.0)
  let c = a / b
  assert_true(c == Number::from_double(2.05))
  assert_true(c.is_f64())
}

///|
test "number mod posint" {
  let a = Number::from_uint64(3UL)
  let b = Number::from_uint64(2UL)
  let c = a % b
  assert_true(c == Number::from_uint64(1UL))
  assert_true(c.is_pos_int())
}

///|
test "number mod neg" {
  let a = Number::from_int64(-4L)
  let b = Number::from_uint64(3UL)
  let c = a % b
  assert_true(c == Number::from_int64(-1L))
  assert_true(c.is_neg_int())
}

///|
test "number mod float" {
  let a = Number::from_double(4.1)
  let b = Number::from_double(2.0)
  let c = a % b
  assert_true(c.is_f64())
}

///|
test "number neg posint" {
  let a = Number::from_uint64(1UL)
  let b = -a
  assert_true(b == Number::from_int64(-1L))
  assert_true(b.is_neg_int())
}

///|
test "number neg negint" {
  let a = Number::from_int64(-1L)
  let b = -a
  assert_true(b == Number::from_uint64(1UL))
  assert_true(b.is_pos_int())
}

///|
test "number neg float" {
  let a = Number::from_double(1.5)
  let b = -a
  assert_true(b == Number::from_double(-1.5))
  assert_true(b.is_f64())
}

// --- Display tests ---

///|
test "number to_string posint" {
  let n = Number::from_uint64(42UL)
  assert_true(n.to_string() == "42")
}

///|
test "number to_string negint" {
  let n = Number::from_int64(-42L)
  assert_true(n.to_string() == "-42")
}

///|
test "number to_string float" {
  let n = Number::from_double(3.14)
  assert_true(n.to_string() == "3.14")
}

///|
test "number to_string zero" {
  let n = Number::from_int(0)
  assert_true(n.to_string() == "0")
}

// --- Debug tests ---

///|
test "number to_debug" {
  let n = Number::from_uint64(42UL)
  assert_true(n._to_debug() == "Number(42)")
}

// --- Edge case tests ---

///|
test "number neg zero" {
  let a = Number::from_uint64(0UL)
  let b = -a
  assert_true(b == Number::from_uint64(0UL))
  assert_true(b.is_pos_int())
}

///|
test "number neg large posint exceeds i64" {
  let big = 9223372036854775807UL + 1UL
  let a = Number::from_uint64(big)
  let b = -a
  assert_true(b.is_f64())
  assert_true(b.as_f64() == -big.to_double())
}

///|
test "number sub 0 minus 1" {
  let a = Number::from_uint64(0UL)
  let b = Number::from_uint64(1UL)
  let c = a - b
  assert_true(c == Number::from_int64(-1L))
  assert_true(c.is_neg_int())
}

///|
test "number sub large posint underflow" {
  let small = Number::from_uint64(1UL)
  let big = Number::from_uint64(9223372036854775807UL)
  let c = small - big
  assert_true(c.is_neg_int())
  assert_true(c.as_i64() == Some(-9223372036854775806L))
}

///|
test "number to_i64 large posint returns none" {
  let big = 9223372036854775807UL + 1UL
  let n = Number::from_uint64(big)
  assert_true(n.as_i64() == None)
  assert_true(n.is_pos_int())
}

///|
test "number from_finite_f64 very large stays float" {
  let n = Number::from_double(1.0e100)
  assert_true(n.is_f64())
  assert_true(n.as_u64() == None)
  assert_true(n.as_i64() == None)
}

///|
test "number from_finite_f64 very large negative stays float" {
  let n = Number::from_double(-1.0e100)
  assert_true(n.is_f64())
}

///|
test "number neg Int64::MIN edge" {
  let n = Number::from_int64(-9223372036854775808L)
  let b = -n
  assert_true(b.is_f64())
  assert_true(b.as_f64() == 9223372036854775808.0)
}

///|
test "number div by zero" {
  let a = Number::from_uint64(1UL)
  let b = Number::from_uint64(0UL)
  let c = a / b
  assert_true(c.is_f64())
}

///|
test "number mod by zero" {
  let a = Number::from_uint64(1UL)
  let b = Number::from_uint64(0UL)
  let c = a % b
  assert_true(c.is_f64())
}

///|
test "number Int64::MIN direct construction" {
  let n = Number::from_int64(-9223372036854775808L)
  assert_true(n.is_neg_int())
  assert_true(n.as_i64() == Some(-9223372036854775808L))
}
