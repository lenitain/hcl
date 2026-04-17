///|
/// Whitespace and comment decorators, stores prefix and suffix
pub struct Decor {
  prefix : String?
  suffix : String?
} derive(Debug, Eq)

///|
/// Create new Decor
pub fn Decor::new(prefix : String?, suffix : String?) -> Decor {
  { prefix, suffix }
}

///|
/// Create empty Decor
pub fn Decor::empty() -> Decor {
  { prefix: None, suffix: None }
}

///|
/// Set prefix
pub fn Decor::set_prefix(self : Decor, prefix : String) -> Decor {
  { prefix: Some(prefix), suffix: self.suffix }
}

///|
/// Set suffix
pub fn Decor::set_suffix(self : Decor, suffix : String) -> Decor {
  { prefix: self.prefix, suffix: Some(suffix) }
}

///|
/// Get prefix
pub fn Decor::get_prefix(self : Decor) -> String? {
  self.prefix
}

///|
/// Get suffix
pub fn Decor::get_suffix(self : Decor) -> String? {
  self.suffix
}

///|
/// Clear decorations
pub fn Decor::clear(_self : Decor) -> Decor {
  { prefix: None, suffix: None }
}

///|
/// Value with decorations
pub struct Decorated[T] {
  value : T
  decor : Decor
} derive(Debug, Eq)

///|
/// Create decorated value
pub fn[T] Decorated::new(value : T, decor : Decor) -> Decorated[T] {
  { value, decor }
}

///|
/// Create value with empty decor
pub fn[T] Decorated::bare(value : T) -> Decorated[T] {
  { value, decor: Decor::empty() }
}

///|
/// Get value
pub fn[T] Decorated::get_value(self : Decorated[T]) -> T {
  self.value
}

///|
/// Get decor
pub fn[T] Decorated::get_decor(self : Decorated[T]) -> Decor {
  self.decor
}

///|
/// Set decor
pub fn[T] Decorated::set_decor(
  self : Decorated[T],
  decor : Decor,
) -> Decorated[T] {
  { value: self.value, decor }
}
