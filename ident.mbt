///|
/// HCL Identifier type with validation
///
/// Represents a validated HCL identifier. Identifiers are used for attribute
/// names, block labels, variable references, etc.
///
/// Validation uses ASCII character rules matching the lexer:
/// - First character: a-z, A-Z, underscore
/// - Remaining characters: a-z, A-Z, 0-9, underscore, hyphen
///
/// Note: Unicode identifiers (XID_Start/XID_Continue) are not supported yet.
pub struct Ident {
  inner : String
} derive(Eq)

///|
/// Create a new Ident after validating.
///
/// Panics if the identifier is empty or contains invalid characters.
pub fn Ident::new(s : String) -> Ident {
  if !is_ident(s) {
    panic()
  }
  { inner: s }
}

///|
/// Create a new Ident after validating, returning error on failure.
pub fn Ident::try_new(s : String) -> HCLResult[Ident] {
  if !is_ident(s) {
    Err(HCLError::invalid_value("invalid identifier: " + s))
  } else {
    Ok({ inner: s })
  }
}

///|
/// Create a new Ident, sanitizing invalid input.
///
/// Rules:
/// - Empty string becomes "_"
/// - Invalid characters replaced with "_"
/// - If first char is valid as id_continue but not id_start, prefix with "_"
pub fn Ident::new_sanitized(s : String) -> Ident {
  if s.is_empty() {
    return { inner: "_" }
  }
  let buf = StringBuilder::new(size_hint=s.length())
  let mut i = 0
  let len = s.length()
  while i < len {
    let ch = s[i].to_int().unsafe_to_char()
    if i == 0 && is_id_start(ch) {
      buf.write_char(ch)
    } else if is_id_continue(ch) {
      if i == 0 {
        buf.write_char('_')
      }
      buf.write_char(ch)
    } else {
      buf.write_char('_')
    }
    i = i + 1
  }
  { inner: buf.to_string() }
}

///|
/// Create a new Ident without validation.
///
/// Caller must ensure the string is a valid identifier.
/// Invalid identifiers will produce broken HCL output when serialized.
pub fn Ident::new_unchecked(s : String) -> Ident {
  { inner: s }
}

///|
/// Get the identifier as a string reference.
pub fn Ident::as_str(self : Ident) -> String {
  self.inner
}

///|
/// Consume the Ident and return the inner String.
pub fn Ident::into_string(self : Ident) -> String {
  self.inner
}

///|
/// Check if the identifier is empty (should never happen for valid idents).
pub fn Ident::is_empty(self : Ident) -> Bool {
  self.inner.is_empty()
}

///|
/// Get the length of the identifier.
pub fn Ident::len(self : Ident) -> Int {
  self.inner.length()
}

///|
/// Determines if ch is a valid HCL identifier start character.
///
/// Valid start: a-z, A-Z, underscore
pub fn is_id_start(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

///|
/// Determines if ch is a valid HCL identifier continue character.
///
/// Valid continue: a-z, A-Z, 0-9, underscore, hyphen
pub fn is_id_continue(ch : Char) -> Bool {
  is_id_start(ch) || (ch >= '0' && ch <= '9') || ch == '-'
}

///|
/// Determines if s is a valid HCL identifier.
///
/// A valid identifier must:
/// - Not be empty
/// - First char passes is_id_start
/// - All remaining chars pass is_id_continue
pub fn is_ident(s : String) -> Bool {
  if s.is_empty() {
    return false
  }
  let mut i = 0
  let len = s.length()
  while i < len {
    let ch = s[i].to_int().unsafe_to_char()
    if i == 0 {
      if !is_id_start(ch) {
        return false
      }
    } else if !is_id_continue(ch) {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Implement Display for Ident (output the raw string)
pub fn Ident::output(self : Ident) -> String {
  self.inner
}

///|
/// Debug representation
pub fn Ident::to_string(self : Ident) -> String {
  "Ident(" + self.inner + ")"
}

///|
/// Implement hash for Ident (delegates to inner string)
pub fn Ident::hash(self : Ident) -> Int {
  self.inner.hash()
}
