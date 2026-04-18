///|
/// Serialization Tests
test "escape_hcl_string basic" {
  assert_eq(escape_hcl_string("hello"), "\"hello\"")
}

///|
test "escape_hcl_string with double quote" {
  let input = "say \"hello\""
  let result = escape_hcl_string(input)
  assert_eq(result, "\"say \\\"hello\\\"\"")
}

///|
test "escape_hcl_string with backslash" {
  let result = escape_hcl_string("path\\to\\file")
  assert_eq(result, "\"path\\\\to\\\\file\"")
}

///|
test "escape_hcl_string with newline" {
  assert_eq(escape_hcl_string("line1\nline2"), "\"line1\\nline2\"")
}

///|
test "escape_hcl_string with carriage return" {
  assert_eq(escape_hcl_string("line1\rline2"), "\"line1\\rline2\"")
}

///|
test "escape_hcl_string with tab" {
  assert_eq(escape_hcl_string("col1\tcol2"), "\"col1\\tcol2\"")
}

///|
test "escape_hcl_string with backspace" {
  assert_eq(escape_hcl_string("back\bspace"), "\"back\\bspace\"")
}

///|
test "escape_hcl_string with form feed" {
  assert_eq(escape_hcl_string("page\fbreak"), "\"page\\fbreak\"")
}

///|
test "escape_hcl_string with dollar brace" {
  let result = escape_hcl_string("cost ${price}")
  assert_eq(result, "\"cost $${price}\"")
}

///|
test "escape_hcl_string with percent brace" {
  let result = escape_hcl_string("cond %{if x}")
  assert_eq(result, "\"cond %%{if x}\"")
}

///|
test "escape_hcl_string with multiple markers" {
  let result = escape_hcl_string("a ${b} and %{c}")
  assert_eq(result, "\"a $${b} and %%{c}\"")
}

///|
test "escape_hcl_string with dollar not followed by brace" {
  let result = escape_hcl_string("price $100")
  assert_eq(result, "\"price $100\"")
}

///|
test "escape_hcl_string with percent not followed by brace" {
  assert_eq(escape_hcl_string("100% complete"), "\"100% complete\"")
}

///|
test "escape_hcl_string empty" {
  assert_eq(escape_hcl_string(""), "\"\"")
}

///|
test "escape_hcl_string single char" {
  assert_eq(escape_hcl_string("a"), "\"a\"")
}

///|
test "escape_hcl_string single dollar" {
  let result = escape_hcl_string("$")
  assert_eq(result, "\"$\"")
}

///|
test "escape_hcl_string single percent" {
  assert_eq(escape_hcl_string("%"), "\"%\"")
}

///|
test "escape_hcl_string dollar at end" {
  let result = escape_hcl_string("cost $")
  assert_eq(result, "\"cost $\"")
}

///|
test "escape_hcl_string percent at end" {
  assert_eq(escape_hcl_string("100%"), "\"100%\"")
}
