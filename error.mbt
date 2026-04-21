///|
/// HCL Error types
pub(all) enum HCLError {
  ParseError(String, Int, Int, Int, String)
  TypeError(String, String)
  MissingField(String)
  InvalidValue(String)
  IOError(String)
  DivisionByZero
  UndefinedVariable(String)
  UndefinedFunction(String)
  UndefinedProperty(String)
  ValidationError(String, String)
} derive(Debug, Eq)

///|
pub fn HCLError::parse_error(
  msg : String,
  line : Int,
  column : Int,
  offset : Int,
) -> HCLError {
  ParseError(msg, line, column, offset, "")
}

///|
pub fn HCLError::parse_error_with_context(
  msg : String,
  line : Int,
  column : Int,
  offset : Int,
  context : String,
) -> HCLError {
  ParseError(msg, line, column, offset, context)
}

///|
pub fn HCLError::type_error(msg : String) -> HCLError {
  TypeError("type error", msg)
}

///|
pub fn HCLError::type_mismatch(expected : String, got : String) -> HCLError {
  TypeError(expected, got)
}

///|
pub fn HCLError::missing_field(field : String) -> HCLError {
  MissingField(field)
}

///|
pub fn HCLError::invalid_value(msg : String) -> HCLError {
  InvalidValue(msg)
}

///|
pub fn HCLError::io_error(msg : String) -> HCLError {
  IOError(msg)
}

///|
pub fn HCLError::division_by_zero() -> HCLError {
  DivisionByZero
}

///|
pub fn HCLError::undefined_variable(name : String) -> HCLError {
  UndefinedVariable(name)
}

///|
pub fn HCLError::undefined_function(name : String) -> HCLError {
  UndefinedFunction(name)
}

///|
pub fn HCLError::undefined_property(name : String) -> HCLError {
  UndefinedProperty(name)
}

///|
pub fn HCLError::validation_error(path : String, msg : String) -> HCLError {
  ValidationError(path, msg)
}

///|
pub fn HCLError::message(self : HCLError) -> String {
  match self {
    ParseError(msg, line, column, _, context) => {
      let base = "Parse error at line " +
        line.to_string() +
        ", column " +
        column.to_string() +
        ": " +
        msg
      if context == "" {
        base
      } else if column > 0 {
        let pointer = StringBuilder::new(size_hint=column + 2)
        let mut i = 0
        while i < column - 1 {
          pointer.write_string(" ")
          i = i + 1
        }
        pointer.write_string("^")
        base + "\n" + context + "\n" + pointer.to_string()
      } else {
        base + "\n" + context
      }
    }
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
pub type HCLResult[T] = Result[T, HCLError]
