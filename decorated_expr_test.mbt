///|
test "Decorated::expr creates bare decorated expression" {
  let de = Decorated::expr(ExprInt(42))
  assert_true(de.get_value() == ExprInt(42))
  assert_eq(de.get_decor().get_prefix(), None)
  assert_eq(de.get_decor().get_suffix(), None)
}

///|
test "Decorated::expr_with_decor preserves decor" {
  let decor = Decor::new(Some("/* prefix */ "), Some(" /* suffix */"))
  let de = Decorated::expr_with_decor(ExprString("hello"), decor)
  assert_true(de.get_value() == ExprString("hello"))
  assert_eq(de.get_decor().get_prefix(), Some("/* prefix */ "))
  assert_eq(de.get_decor().get_suffix(), Some(" /* suffix */"))
}

///|
test "Decorated::get_expr extracts inner expression" {
  let de = Decorated::expr(ExprBool(true))
  assert_true(de.get_expr() == ExprBool(true))
}

///|
test "decorated_expr_to_string with no decor" {
  let de = Decorated::expr(ExprInt(42))
  assert_eq(decorated_expr_to_string(de), "42")
}

///|
test "decorated_expr_to_string with prefix and suffix" {
  let decor = Decor::new(Some(" "), Some("\n"))
  let de = Decorated::expr_with_decor(ExprString("test"), decor)
  assert_eq(decorated_expr_to_string(de), " \"test\"\n")
}

///|
test "decorated_expr_to_string with prefix only" {
  let decor = Decor::empty().set_prefix("# comment\n")
  let de = Decorated::expr_with_decor(ExprNull, decor)
  assert_eq(decorated_expr_to_string(de), "# comment\nnull")
}

///|
test "decorated_expr_to_string with suffix only" {
  let decor = Decor::empty().set_suffix(" ")
  let de = Decorated::expr_with_decor(ExprInt(99), decor)
  assert_eq(decorated_expr_to_string(de), "99 ")
}
