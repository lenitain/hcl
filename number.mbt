///|
/// HCL Number type - represents numeric values in HCL
///
/// Follows hcl-rs Number design: PosInt(UInt64), NegInt(Int64), Float(Double)
/// with automatic coercion during arithmetic operations.
pub(all) enum N {
  PosInt(UInt64)
  /// Always less than zero
  NegInt(Int64)
  /// Always finite
  Float(Double)
}

///|
pub struct Number {
  n : N
}

///|
/// Coerce two numbers to a common type for binary operations
fn coerce(a : N, b : N) -> (Double, Double) {
  match (a, b) {
    (PosInt(a), PosInt(b)) => (a.to_double(), b.to_double())
    (NegInt(a), NegInt(b)) => (a.to_double(), b.to_double())
    (Float(a), Float(b)) => (a, b)
    (a, b) => (N::to_f64(a), N::to_f64(b))
  }
}

///|
/// Convert N to f64
fn N::to_f64(self : N) -> Double {
  match self {
    PosInt(n) => n.to_double()
    NegInt(n) => n.to_double()
    Float(n) => n
  }
}

///|
/// Try to convert N to i64
fn N::to_i64(self : N) -> Int64? {
  match self {
    PosInt(n) => {
      let i = n.reinterpret_as_int64()
      if i >= 0L {
        Some(i)
      } else {
        None
      }
    }
    NegInt(n) => Some(n)
    Float(_) => None
  }
}

///|
/// Try to convert N to UInt64
fn N::to_u64(self : N) -> UInt64? {
  match self {
    PosInt(n) => Some(n)
    NegInt(_) => None
    Float(_) => None
  }
}

///|
/// Check if N is a float
fn N::is_f64(self : N) -> Bool {
  match self {
    Float(_) => true
    PosInt(_) | NegInt(_) => false
  }
}

///|
/// Check if N is a negative integer
fn N::is_i64(self : N) -> Bool {
  match self {
    NegInt(_) => true
    PosInt(_) | Float(_) => false
  }
}

///|
/// Check if N is a positive integer
fn N::is_u64(self : N) -> Bool {
  match self {
    PosInt(_) => true
    NegInt(_) | Float(_) => false
  }
}

///|
/// Create N from finite f64, converting to int if no fractional part
fn N::from_finite_f64(value : Double) -> N {
  let int_part = value.floor()
  if int_part == value {
    if value < 0.0 {
      NegInt(int_part.to_int64())
    } else {
      PosInt(int_part.to_uint64())
    }
  } else {
    Float(value)
  }
}

///|
/// Create N from i64
fn N::from_i64(i : Int64) -> N {
  if i < 0L {
    NegInt(i)
  } else {
    PosInt(i.reinterpret_as_uint64())
  }
}

// Eq for N

///|
impl Eq for N with equal(self, rhs) {
  match (self, rhs) {
    (PosInt(a), PosInt(b)) => a == b
    (NegInt(a), NegInt(b)) => a == b
    (Float(a), Float(b)) => a == b
    (a, b) => {
      let (fa, fb) = coerce(a, b)
      fa == fb
    }
  }
}

// Compare for N

///|
impl Compare for N with compare(self, rhs) {
  match (self, rhs) {
    (PosInt(a), PosInt(b)) => a.compare(b)
    (NegInt(a), NegInt(b)) => a.compare(b)
    (Float(a), Float(b)) => a.compare(b)
    (a, b) => {
      let (fa, fb) = coerce(a, b)
      fa.compare(fb)
    }
  }
}

// Neg for N

///|
impl Neg for N with neg(self) {
  match self {
    PosInt(value) => NegInt(-value.reinterpret_as_int64())
    NegInt(value) => N::from_i64(-value)
    Float(value) => Float(-value)
  }
}

// Add for N

///|
impl Add for N with add(self, rhs) {
  match (self, rhs) {
    (PosInt(a), PosInt(b)) => PosInt(a + b)
    (NegInt(a), NegInt(b)) => NegInt(a + b)
    (a, b) => {
      let (fa, fb) = coerce(a, b)
      N::from_finite_f64(fa + fb)
    }
  }
}

// Sub for N

///|
impl Sub for N with sub(self, rhs) {
  match (self, rhs) {
    (PosInt(a), PosInt(b)) =>
      if b > a {
        NegInt(a.reinterpret_as_int64() - b.reinterpret_as_int64())
      } else {
        PosInt(a - b)
      }
    (NegInt(a), NegInt(b)) => N::from_i64(a - b)
    (a, b) => {
      let (fa, fb) = coerce(a, b)
      N::from_finite_f64(fa - fb)
    }
  }
}

// Mul for N

///|
impl Mul for N with mul(self, rhs) {
  match (self, rhs) {
    (PosInt(a), PosInt(b)) => PosInt(a * b)
    (NegInt(a), NegInt(b)) => N::from_i64(a * b)
    (a, b) => {
      let (fa, fb) = coerce(a, b)
      N::from_finite_f64(fa * fb)
    }
  }
}

// Div for N

///|
impl Div for N with div(self, rhs) {
  let (fa, fb) = coerce(self, rhs)
  N::from_finite_f64(fa / fb)
}

// Mod for N

///|
impl Mod for N with mod(self, rhs) {
  match (self, rhs) {
    (PosInt(a), PosInt(b)) => PosInt(a % b)
    (NegInt(a), NegInt(b)) => NegInt(a % b)
    (a, b) => {
      let (fa, fb) = coerce(a, b)
      N::from_finite_f64(fa % fb)
    }
  }
}

// Show for N

///|
fn N::to_string(self : N) -> String {
  match self {
    PosInt(v) => v.to_string()
    NegInt(v) => v.to_string()
    Float(v) => v.to_string()
  }
}

// --- Number public API ---

///|
/// Create a Number from a finite f64. Returns None if f is NaN or infinite.
pub fn Number::from_f64(f : Double) -> Number? {
  if f != f || f == 1.0 / 0.0 || f == -(1.0 / 0.0) {
    None
  } else {
    Some({ n: N::from_finite_f64(f) })
  }
}

///|
/// Create a Number from f64, assumes finite
pub fn Number::from_finite_f64(f : Double) -> Number {
  { n: N::from_finite_f64(f) }
}

///|
/// If Number is an integer, return as Int64
pub fn Number::as_i64(self : Number) -> Int64? {
  self.n.to_i64()
}

///|
/// If Number is a positive integer, return as UInt64
pub fn Number::as_u64(self : Number) -> UInt64? {
  self.n.to_u64()
}

///|
/// Get Number value as f64 (always succeeds)
pub fn Number::as_f64(self : Number) -> Double {
  N::to_f64(self.n)
}

///|
/// Check if Number is a float
pub fn Number::is_f64(self : Number) -> Bool {
  N::is_f64(self.n)
}

///|
/// Check if Number is a negative integer
pub fn Number::is_i64(self : Number) -> Bool {
  N::is_i64(self.n)
}

///|
/// Check if Number is a positive integer
pub fn Number::is_u64(self : Number) -> Bool {
  N::is_u64(self.n)
}

///|
/// Check if Number is any integer (PosInt or NegInt)
pub fn Number::is_int(self : Number) -> Bool {
  match self.n {
    PosInt(_) | NegInt(_) => true
    Float(_) => false
  }
}

///|
/// Check if Number is a negative integer (alias for is_i64)
pub fn Number::is_int64(self : Number) -> Bool {
  N::is_i64(self.n)
}

///|
/// Check if Number is a float (alias for is_f64)
pub fn Number::is_float(self : Number) -> Bool {
  N::is_f64(self.n)
}

///|
/// If Number fits in Int (32-bit), return as Int
pub fn Number::as_int(self : Number) -> Int? {
  match self.n {
    PosInt(n) => {
      let i = n.to_int()
      if i >= 0 {
        Some(i)
      } else {
        None
      }
    }
    NegInt(n) => {
      let i = n.to_int()
      if i.to_int64() == n {
        Some(i)
      } else {
        None
      }
    }
    Float(_) => None
  }
}

///|
/// If Number is an integer, return as Int64 (alias for as_i64)
pub fn Number::as_int64(self : Number) -> Int64? {
  self.n.to_i64()
}

///|
/// Get Number value as Double (alias for as_f64)
pub fn Number::as_float(self : Number) -> Double {
  N::to_f64(self.n)
}

///|
/// Create Number from Int
pub fn Number::from_int(i : Int) -> Number {
  if i < 0 {
    { n: NegInt(i.to_int64()) }
  } else {
    { n: PosInt(i.to_uint64()) }
  }
}

///|
/// Create Number from Int64
pub fn Number::from_int64(i : Int64) -> Number {
  { n: N::from_i64(i) }
}

///|
/// Create Number from UInt64
pub fn Number::from_uint64(u : UInt64) -> Number {
  { n: PosInt(u) }
}

///|
/// Create Number from Double
pub fn Number::from_double(d : Double) -> Number {
  { n: N::from_finite_f64(d) }
}

// Eq for Number

///|
impl Eq for Number with equal(self, rhs) {
  self.n == rhs.n
}

// Compare for Number

///|
impl Compare for Number with compare(self, rhs) {
  self.n.compare(rhs.n)
}

// Add for Number

///|
impl Add for Number with add(self, rhs) {
  { n: self.n + rhs.n }
}

// Sub for Number

///|
impl Sub for Number with sub(self, rhs) {
  { n: self.n - rhs.n }
}

// Mul for Number

///|
impl Mul for Number with mul(self, rhs) {
  { n: self.n * rhs.n }
}

// Div for Number

///|
impl Div for Number with div(self, rhs) {
  { n: self.n / rhs.n }
}

// Mod for Number

///|
impl Mod for Number with mod(self, rhs) {
  { n: self.n % rhs.n }
}

// Neg for Number

///|
impl Neg for Number with neg(self) {
  { n: -self.n }
}

// Show for Number

///|
impl Show for Number with output(self, logger) {
  logger.write_string(N::to_string(self.n))
}

///|
fn Number::to_string(self : Number) -> String {
  N::to_string(self.n)
}

// Debug for Number

///|
fn Number::to_debug(self : Number) -> String {
  "Number(" + N::to_string(self.n) + ")"
}
