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
} derive(Debug, Eq)

///|
/// Create a parse error
pub fn HCLError::parse_error(msg : String, line : Int, column : Int, offset : Int) -> HCLError {
  ParseError(msg, line, column, offset)
}

///|
/// Create a type error
pub fn HCLError::type_error(expected : String, got : String) -> HCLError {
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
/// Get error message
pub fn HCLError::message(self : HCLError) -> String {
  match self {
    ParseError(msg, line, column, _) =>
      "Parse error at line " + line.to_string() + ", column " + column.to_string() + ": " + msg
    TypeError(expected, got) =>
      "Type error: expected " + expected + ", got " + got
    MissingField(field) =>
      "Missing field: " + field
    InvalidValue(msg) =>
      "Invalid value: " + msg
    IOError(msg) =>
      "IO error: " + msg
  }
}

///|
/// Result type for HCL operations
pub type HCLResult[T] = Result[T, HCLError]
