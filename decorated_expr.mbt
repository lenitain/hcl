///|
/// Create a bare decorated expression (no decor)
pub fn Decorated::expr(expr : Expression) -> Decorated[Expression] {
  Decorated::bare(expr)
}

///|
/// Create a decorated expression with decor
pub fn Decorated::expr_with_decor(
  expr : Expression,
  decor : Decor,
) -> Decorated[Expression] {
  Decorated::new(expr, decor)
}

///|
/// Extract the inner expression
pub fn Decorated::get_expr(self : Decorated[Expression]) -> Expression {
  self.value
}

///|
/// Convert Decorated[Expression] to string
pub fn decorated_expr_to_string(de : Decorated[Expression]) -> String {
  let mut result = ""
  match de.decor.get_prefix() {
    Some(p) => result = result + p
    None => ()
  }
  result = result + expr_to_string(de.value)
  match de.decor.get_suffix() {
    Some(s) => result = result + s
    None => ()
  }
  result
}
