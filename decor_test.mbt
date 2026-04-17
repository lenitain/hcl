///|
test "Decor basic operations" {
  let decor = Decor::empty()
  assert_eq(decor.get_prefix(), None)
  assert_eq(decor.get_suffix(), None)

  let decor2 = decor.set_prefix(" ")
  assert_eq(decor2.get_prefix(), Some(" "))

  let decor3 = decor2.set_suffix("\n")
  assert_eq(decor3.get_suffix(), Some("\n"))
}

///|
test "Decorated basic operations" {
  let decorated = Decorated::bare("hello")
  assert_eq(decorated.get_value(), "hello")
  assert_eq(decorated.get_decor().get_prefix(), None)

  let decor = Decor::new(Some(" "), Some("\n"))
  let decorated2 = Decorated::new("world", decor)
  assert_eq(decorated2.get_value(), "world")
  assert_eq(decorated2.get_decor().get_prefix(), Some(" "))
}
