///|
/// HCL Error types
pub(all) enum HCLError {
  /// Parse error with location info
  ParseError(String, Int, Int, Int)
  /// Type mismatch error
  TypeError(String, String)
  /// Missing field error
  MissingField(String)
  /// Invalid value error
  InvalidValue(String)
  /// IO error
  IOError(String)
  /// Division by zero error
  DivisionByZero
  /// Undefined variable error
  UndefinedVariable(String)
  /// Undefined function error
  UndefinedFunction(String)
  /// Undefined property error
  UndefinedProperty(String)
  /// Validation error with path
  ValidationError(String, String)
} derive(Debug, Eq)

///|
/// Create a parse error
pub fn HCLError::parse_error(
  msg : String,
  line : Int,
  column : Int,
  offset : Int,
) -> HCLError {
  ParseError(msg, line, column, offset)
}

///|
/// Create a type error
pub fn HCLError::type_error(msg : String) -> HCLError {
  TypeError("type error", msg)
}

///|
/// Create a type mismatch error
pub fn HCLError::type_mismatch(expected : String, got : String) -> HCLError {
  TypeError(expected, got)
}

///|
/// Create a missing field error
pub fn HCLError::missing_field(field : String) -> HCLError {
  MissingField(field)
}

///|
/// Create an invalid value error
pub fn HCLError::invalid_value(msg : String) -> HCLError {
  InvalidValue(msg)
}

///|
/// Create an IO error
pub fn HCLError::io_error(msg : String) -> HCLError {
  IOError(msg)
}

///|
/// Create a division by zero error
pub fn HCLError::division_by_zero() -> HCLError {
  DivisionByZero
}

///|
/// Create an undefined variable error
pub fn HCLError::undefined_variable(name : String) -> HCLError {
  UndefinedVariable(name)
}

///|
/// Create an undefined function error
pub fn HCLError::undefined_function(name : String) -> HCLError {
  UndefinedFunction(name)
}

///|
/// Create an undefined property error
pub fn HCLError::undefined_property(name : String) -> HCLError {
  UndefinedProperty(name)
}

///|
/// Create a validation error
pub fn HCLError::validation_error(path : String, msg : String) -> HCLError {
  ValidationError(path, msg)
}

///|
/// Get error message
pub fn HCLError::message(self : HCLError) -> String {
  match self {
    ParseError(msg, line, column, _) =>
      "Parse error at line " +
      line.to_string() +
      ", column " +
      column.to_string() +
      ": " +
      msg
    TypeError(expected, got) =>
      "Type error: expected " + expected + ", got " + got
    MissingField(field) => "Missing field: " + field
    InvalidValue(msg) => "Invalid value: " + msg
    IOError(msg) => "IO error: " + msg
    DivisionByZero => "Division by zero"
    UndefinedVariable(name) => "Undefined variable: " + name
    UndefinedFunction(name) => "Undefined function: " + name
    UndefinedProperty(name) => "Undefined property: " + name
    ValidationError(path, msg) => "Validation error at " + path + ": " + msg
  }
}

///|
/// Result type for HCL operations
pub type HCLResult[T] = Result[T, HCLError]
