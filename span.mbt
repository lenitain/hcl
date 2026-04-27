///|
/// Source span - tracks position in source text
pub struct Span {
  start_line : Int
  start_col : Int
  start_offset : Int
  end_line : Int
  end_col : Int
  end_offset : Int
} derive(Debug, Eq)

///|
/// Create a new Span
pub fn Span::new(
  start_line : Int,
  start_col : Int,
  start_offset : Int,
  end_line : Int,
  end_col : Int,
  end_offset : Int,
) -> Span {
  { start_line, start_col, start_offset, end_line, end_col, end_offset }
}

///|
/// Create an empty (zero) Span
pub fn Span::empty() -> Span {
  {
    start_line: 0,
    start_col: 0,
    start_offset: 0,
    end_line: 0,
    end_col: 0,
    end_offset: 0,
  }
}

///|
/// Merge two spans: start from a, end from b
pub fn Span::merge(a : Span, b : Span) -> Span {
  {
    start_line: a.start_line,
    start_col: a.start_col,
    start_offset: a.start_offset,
    end_line: b.end_line,
    end_col: b.end_col,
    end_offset: b.end_offset,
  }
}

///|
/// Value with optional source span
pub struct Spanned[T] {
  value : T
  span : Span?
} derive(Debug, Eq)

///|
/// Create a Spanned value with span
pub fn[T] Spanned::new(value : T, span : Span) -> Spanned[T] {
  { value, span: Some(span) }
}

///|
/// Create a Spanned value without span
pub fn[T] Spanned::bare(value : T) -> Spanned[T] {
  { value, span: None }
}

///|
/// Get the inner value
pub fn[T] Spanned::unwrap(self : Spanned[T]) -> T {
  self.value
}

///|
/// Get the span
pub fn[T] Spanned::get_span(self : Spanned[T]) -> Span? {
  self.span
}
