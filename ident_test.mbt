///|
/// Tests for Ident type and validation functions
test "is_id_start accepts lowercase letters" {
  assert_true(is_id_start('a'))
  assert_true(is_id_start('z'))
  assert_true(is_id_start('m'))
}

///|
test "is_id_start accepts uppercase letters" {
  assert_true(is_id_start('A'))
  assert_true(is_id_start('Z'))
  assert_true(is_id_start('M'))
}

///|
test "is_id_start accepts underscore" {
  assert_true(is_id_start('_'))
}

///|
test "is_id_start rejects digits" {
  assert_false(is_id_start('0'))
  assert_false(is_id_start('9'))
}

///|
test "is_id_start rejects hyphen" {
  assert_false(is_id_start('-'))
}

///|
test "is_id_start rejects whitespace" {
  assert_false(is_id_start(' '))
  assert_false(is_id_start('\t'))
  assert_false(is_id_start('\n'))
}

///|
test "is_id_start rejects special characters" {
  assert_false(is_id_start('.'))
  assert_false(is_id_start('+'))
  assert_false(is_id_start('='))
  assert_false(is_id_start('{'))
  assert_false(is_id_start('}'))
  assert_false(is_id_start('"'))
}

///|
test "is_id_continue accepts letters" {
  assert_true(is_id_continue('a'))
  assert_true(is_id_continue('Z'))
}

///|
test "is_id_continue accepts digits" {
  assert_true(is_id_continue('0'))
  assert_true(is_id_continue('9'))
  assert_true(is_id_continue('5'))
}

///|
test "is_id_continue accepts underscore" {
  assert_true(is_id_continue('_'))
}

///|
test "is_id_continue accepts hyphen" {
  assert_true(is_id_continue('-'))
}

///|
test "is_id_continue rejects whitespace" {
  assert_false(is_id_continue(' '))
  assert_false(is_id_continue('\t'))
}

///|
test "is_id_continue rejects special characters" {
  assert_false(is_id_continue('.'))
  assert_false(is_id_continue('+'))
  assert_false(is_id_continue('='))
  assert_false(is_id_continue('/'))
  assert_false(is_id_continue('@'))
}

///|
test "is_ident accepts simple identifiers" {
  assert_true(is_ident("foo"))
  assert_true(is_ident("bar"))
  assert_true(is_ident("x"))
}

///|
test "is_ident accepts underscore identifiers" {
  assert_true(is_ident("_"))
  assert_true(is_ident("_foo"))
  assert_true(is_ident("foo_bar"))
  assert_true(is_ident("_private"))
  assert_true(is_ident("__init__"))
}

///|
test "is_ident accepts identifiers with hyphens" {
  assert_true(is_ident("foo-bar"))
  assert_true(is_ident("my-var"))
  assert_true(is_ident("a-b-c"))
}

///|
test "is_ident accepts identifiers with digits" {
  assert_true(is_ident("foo123"))
  assert_true(is_ident("x1"))
  assert_true(is_ident("var2name"))
}

///|
test "is_ident accepts mixed valid characters" {
  assert_true(is_ident("foo_bar-baz123"))
  assert_true(is_ident("MY_VAR"))
  assert_true(is_ident("CamelCase"))
  assert_true(is_ident("snake_case"))
  assert_true(is_ident("kebab-case"))
  assert_true(is_ident("_123"))
  assert_true(is_ident("foo_"))
  assert_true(is_ident("foo-"))
}

///|
test "is_ident rejects empty string" {
  assert_false(is_ident(""))
}

///|
test "is_ident rejects digit-starting identifiers" {
  assert_false(is_ident("1foo"))
  assert_false(is_ident("123"))
  assert_false(is_ident("9abc"))
}

///|
test "is_ident rejects hyphen-starting identifiers" {
  assert_false(is_ident("-foo"))
  assert_false(is_ident("-"))
}

///|
test "is_ident rejects identifiers with spaces" {
  assert_false(is_ident("foo bar"))
  assert_false(is_ident(" foo"))
  assert_false(is_ident("foo "))
}

///|
test "is_ident rejects identifiers with special chars" {
  assert_false(is_ident("foo.bar"))
  assert_false(is_ident("foo+bar"))
  assert_false(is_ident("foo=bar"))
  assert_false(is_ident("foo/bar"))
  assert_false(is_ident("foo@bar"))
  assert_false(is_ident("foo!bar"))
}

///|
test "Ident::new creates valid identifier" {
  let id = Ident::new("foo")
  assert_eq(id.as_str(), "foo")
}

///|
test "Ident::new creates identifier with hyphens" {
  let id = Ident::new("my-var")
  assert_eq(id.as_str(), "my-var")
}

///|
test "Ident::new creates identifier with underscores" {
  let id = Ident::new("_private")
  assert_eq(id.as_str(), "_private")
}

///|
test "Ident::try_new succeeds for valid identifier" {
  let result = Ident::try_new("foo")
  match result {
    Ok(id) => assert_eq(id.as_str(), "foo")
    Err(_) => panic()
  }
}

///|
test "Ident::try_new fails for empty string" {
  let result = Ident::try_new("")
  assert_true(result is Err(_))
}

///|
test "Ident::try_new fails for digit-starting" {
  let result = Ident::try_new("123abc")
  assert_true(result is Err(_))
}

///|
test "Ident::try_new fails for whitespace" {
  let result = Ident::try_new("foo bar")
  assert_true(result is Err(_))
}

///|
test "Ident::try_new fails for hyphen-starting" {
  let result = Ident::try_new("-foo")
  assert_true(result is Err(_))
}

///|
test "Ident::new_sanitized keeps valid identifier" {
  let id = Ident::new_sanitized("foo")
  assert_eq(id.as_str(), "foo")
}

///|
test "Ident::new_sanitized replaces empty with underscore" {
  let id = Ident::new_sanitized("")
  assert_eq(id.as_str(), "_")
}

///|
test "Ident::new_sanitized prefixes digit-starting" {
  let id = Ident::new_sanitized("1two3")
  assert_eq(id.as_str(), "_1two3")
}

///|
test "Ident::new_sanitized replaces whitespace" {
  let id = Ident::new_sanitized("with whitespace")
  assert_eq(id.as_str(), "with_whitespace")
}

///|
test "Ident::new_sanitized replaces special characters" {
  let id = Ident::new_sanitized("foo.bar@baz")
  assert_eq(id.as_str(), "foo_bar_baz")
}

///|
test "Ident::new_sanitized handles all invalid chars" {
  let id = Ident::new_sanitized("@#$%")
  assert_eq(id.as_str(), "____")
}

///|
test "Ident::new_sanitized handles hyphen-starting" {
  let id = Ident::new_sanitized("-foo")
  assert_eq(id.as_str(), "_-foo")
}

///|
test "Ident::new_unchecked creates without validation" {
  let id = Ident::new_unchecked("anything goes")
  assert_eq(id.as_str(), "anything goes")
}

///|
test "Ident::into_string consumes and returns string" {
  let id = Ident::new("foo")
  let s = id.into_string()
  assert_eq(s, "foo")
}

///|
test "Ident::is_empty returns false for valid ident" {
  let id = Ident::new("foo")
  assert_false(id.is_empty())
}

///|
test "Ident::len returns correct length" {
  let id = Ident::new("foobar")
  assert_eq(id.len(), 6)
}

///|
test "Ident::to_string shows debug format" {
  let id = Ident::new("foo")
  assert_eq(id.to_string(), "Ident(foo)")
}

///|
test "Ident equality works" {
  let id1 = Ident::new("foo")
  let id2 = Ident::new("foo")
  let id3 = Ident::new("bar")
  assert_true(id1 == id2)
  assert_false(id1 == id3)
}

///|
test "Ident single char identifier" {
  let id = Ident::new("x")
  assert_eq(id.as_str(), "x")
}

///|
test "Ident underscore only" {
  let id = Ident::new("_")
  assert_eq(id.as_str(), "_")
}

///|
test "Ident double underscore" {
  let id = Ident::new("__")
  assert_eq(id.as_str(), "__")
}

///|
test "Ident long identifier" {
  let id = Ident::new("this_is_a_very_long_identifier_name_123")
  assert_eq(id.len(), 39)
  assert_eq(id.as_str(), "this_is_a_very_long_identifier_name_123")
}

///|
test "is_ident edge case: hyphen at end" {
  assert_true(is_ident("foo-"))
}

///|
test "is_ident edge case: underscore at end" {
  assert_true(is_ident("foo_"))
}

///|
test "is_ident edge case: all underscores" {
  assert_true(is_ident("___"))
}

///|
test "is_ident edge case: all hyphens after first char" {
  assert_true(is_ident("a---"))
}

///|
test "Ident::new_sanitized handles hyphens in middle" {
  let id = Ident::new_sanitized("foo-bar")
  assert_eq(id.as_str(), "foo-bar")
}
