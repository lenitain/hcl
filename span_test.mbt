///|
/// Tests for Span and Spanned[T] types
test "span creation" {
  let span = Span::new(1, 1, 0, 1, 5, 4)
  assert_eq(span.start_line, 1)
  assert_eq(span.start_col, 1)
  assert_eq(span.start_offset, 0)
  assert_eq(span.end_line, 1)
  assert_eq(span.end_col, 5)
  assert_eq(span.end_offset, 4)
}

///|
test "span empty" {
  let span = Span::empty()
  assert_eq(span.start_line, 0)
  assert_eq(span.end_line, 0)
}

///|
test "span merge" {
  let a = Span::new(1, 1, 0, 1, 5, 4)
  let b = Span::new(2, 1, 10, 2, 3, 12)
  let merged = Span::merge(a, b)
  assert_eq(merged.start_line, 1)
  assert_eq(merged.start_offset, 0)
  assert_eq(merged.end_line, 2)
  assert_eq(merged.end_offset, 12)
}

///|
test "spanned bare" {
  let s = Spanned::bare(42)
  assert_eq(s.unwrap(), 42)
  assert_true(s.get_span() is None)
}

///|
test "spanned with span" {
  let span = Span::new(1, 1, 0, 1, 3, 2)
  let s = Spanned::new("hello", span)
  assert_eq(s.unwrap(), "hello")
  assert_true(s.get_span() is Some(_))
}

///|
test "parser attr span" {
  let result = parse("x = 42")
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let spanned = attr.get_spanned_value()
          assert_true(spanned.get_span() is Some(_))
          let span = spanned.get_span().unwrap()
          assert_eq(span.start_line, 1)
          assert_eq(span.end_line, 1)
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parser body span" {
  let result = parse("x = 1\ny = 2")
  match result {
    Ok(body) => {
      assert_true(body.get_span() is Some(_))
      let span = body.get_span().unwrap()
      assert_eq(span.start_line, 1)
      assert_eq(span.end_line, 2)
    }
    Err(_) => panic()
  }
}

///|
test "parser block span" {
  let result = parse("resource \"aws_instance\" \"web\" {\n  ami = \"abc\"\n}")
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Block(block) => {
          assert_true(block.get_span() is Some(_))
          let span = block.get_span().unwrap()
          assert_eq(span.start_line, 1)
          assert_eq(span.end_line, 3)
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parser nested block span" {
  let result = parse("outer {\n  inner {\n    x = 1\n  }\n}")
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Block(outer) => {
          assert_true(outer.get_span() is Some(_))
          match outer.get_body().get_items()[0] {
            Block(inner) => assert_true(inner.get_span() is Some(_))
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "span equality" {
  let a = Span::new(1, 2, 3, 4, 5, 6)
  let b = Span::new(1, 2, 3, 4, 5, 6)
  assert_true(a == b)
}

///|
test "span inequality" {
  let a = Span::new(1, 2, 3, 4, 5, 6)
  let b = Span::new(1, 2, 3, 4, 5, 7)
  assert_true(a != b)
}

///|
test "spanned string" {
  let span = Span::new(1, 1, 0, 1, 5, 4)
  let s = Spanned::new("test", span)
  assert_eq(s.unwrap(), "test")
  match s.get_span() {
    Some(sp) => {
      assert_eq(sp.start_line, 1)
      assert_eq(sp.end_col, 5)
    }
    _ => panic()
  }
}

///|
test "parser multi attr spans" {
  let result = parse("a = 1\nb = 2\nc = 3")
  match result {
    Ok(body) => {
      assert_eq(body.get_items().length(), 3)
      for item in body.get_items() {
        match item {
          Attribute(attr) =>
            assert_true(attr.get_spanned_value().get_span() is Some(_))
          _ => panic()
        }
      }
    }
    Err(_) => panic()
  }
}

///|
test "parser attr span offsets" {
  let result = parse("x = 42")
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => {
          let span = attr.get_spanned_value().get_span().unwrap()
          assert_true(span.start_offset >= 0)
          assert_true(span.end_offset >= span.start_offset)
        }
        _ => panic()
      }
    Err(_) => panic()
  }
}
