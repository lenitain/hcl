///|
/// HCL Lexer - tokenizes HCL input
pub struct Lexer {
  input : String
  pos : Int
  line : Int
  col : Int
}

///|
/// Create a new lexer from string input
pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, col: 1 }
}

///|
/// Get current position info
pub fn Lexer::location(self : Lexer) -> (Int, Int, Int) {
  (self.line, self.col, self.pos)
}

///|
/// Get a specific line from input (line number starts at 1)
pub fn Lexer::get_line(self : Lexer, line_number : Int) -> String {
  let mut current_line = 1
  let mut start = 0
  let len = self.input.length()
  let newline_code = '\n'.to_int().to_uint16()

  for i in 0..<len {
    if self.input[i] == newline_code {
      if current_line == line_number {
        return extract_line(self.input, start, i)
      }
      current_line = current_line + 1
      start = i + 1
    }
  }

  if current_line == line_number {
    return extract_line(self.input, start, len)
  }
  ""
}

///|
/// Extract substring from input[start:end] as String
fn extract_line(input : String, start : Int, end : Int) -> String {
  let line = input[start:end].to_string()
  if line.length() > 0 &&
    line.code_unit_at(line.length() - 1) == '\r'.to_int().to_uint16() {
    input[start:end - 1].to_string()
  } else {
    line
  }
}

///|
/// Check if at end of input
fn Lexer::is_at_end(self : Lexer) -> Bool {
  self.pos >= self.input.length()
}

///|
/// Peek at current char code
fn Lexer::peek(self : Lexer) -> UInt16? {
  if self.is_at_end() {
    None
  } else {
    Some(self.input[self.pos])
  }
}

///|
/// Peek at next char code
fn Lexer::peek_next(self : Lexer) -> UInt16? {
  if self.pos + 1 >= self.input.length() {
    None
  } else {
    Some(self.input[self.pos + 1])
  }
}

///|
/// Advance position by one char
fn Lexer::advance(self : Lexer) -> Lexer {
  if self.is_at_end() {
    self
  } else {
    let c = self.input[self.pos]
    let new_pos = self.pos + 1
    let (new_line, new_col) = if c == '\n'.to_int().to_uint16() {
      (self.line + 1, 1)
    } else {
      (self.line, self.col + 1)
    }
    { input: self.input, pos: new_pos, line: new_line, col: new_col }
  }
}

///|
/// Skip whitespace (except newlines)
fn Lexer::skip_whitespace(self : Lexer) -> Lexer {
  let mut lexer = self
  while !lexer.is_at_end() {
    match lexer.peek() {
      Some(c) if c == ' '.to_int().to_uint16() ||
        c == '\t'.to_int().to_uint16() ||
        c == '\r'.to_int().to_uint16() => lexer = lexer.advance()
      Some(c) if c == '/'.to_int().to_uint16() =>
        // Check for comments
        match lexer.peek_next() {
          Some(c2) if c2 == '/'.to_int().to_uint16() =>
            // Line comment - skip until newline
            lexer = lexer.skip_line_comment()
          Some(c2) if c2 == '*'.to_int().to_uint16() =>
            // Block comment - skip until */
            match lexer.skip_block_comment() {
              Ok(new_lexer) => lexer = new_lexer
              Err(_) => return lexer // Error will be caught later
            }
          _ => break
        }
      _ => break
    }
  }
  lexer
}

///|
/// Skip line comment
fn Lexer::skip_line_comment(self : Lexer) -> Lexer {
  let mut lexer = self.advance().advance() // skip //
  while !lexer.is_at_end() && lexer.peek() != Some('\n'.to_int().to_uint16()) {
    lexer = lexer.advance()
  }
  lexer
}

///|
/// Skip block comment
fn Lexer::skip_block_comment(self : Lexer) -> HCLResult[Lexer] {
  let mut lexer = self.advance().advance() // skip /*
  let start_line = self.line
  let start_col = self.col - 2

  while !lexer.is_at_end() {
    if lexer.peek() == Some('*'.to_int().to_uint16()) &&
      lexer.peek_next() == Some('/'.to_int().to_uint16()) {
      lexer = lexer.advance().advance()
      return Ok(lexer)
    }
    lexer = lexer.advance()
  }

  Err(
    HCLError::parse_error_with_context(
      "Unterminated block comment",
      start_line,
      start_col,
      self.pos,
      self.get_line(start_line),
    ),
  )
}

///|
/// Read a string literal
fn Lexer::read_string(self : Lexer) -> HCLResult[(Token, Lexer)] {
  let start_line = self.line
  let start_col = self.col
  let mut lexer = self.advance() // skip opening quote
  let mut result = ""

  while !lexer.is_at_end() {
    match lexer.peek() {
      Some(c) if c == '"'.to_int().to_uint16() => {
        lexer = lexer.advance()
        return Ok((StringLit(result), lexer))
      }
      Some(c) if c == '\\'.to_int().to_uint16() => {
        lexer = lexer.advance()
        if lexer.is_at_end() {
          return Err(
            HCLError::parse_error_with_context(
              "Unterminated string",
              start_line,
              start_col,
              self.pos,
              self.get_line(start_line),
            ),
          )
        }
        match lexer.read_escape_sequence() {
          Ok((ch, new_lexer)) => {
            result = result + ch.to_string()
            lexer = new_lexer
          }
          Err(e) => return Err(e)
        }
      }
      Some(c) => {
        result = result + c.to_int().unsafe_to_char().to_string()
        lexer = lexer.advance()
      }
      None =>
        return Err(
          HCLError::parse_error_with_context(
            "Unterminated string",
            start_line,
            start_col,
            self.pos,
            self.get_line(start_line),
          ),
        )
    }
  }

  Err(
    HCLError::parse_error_with_context(
      "Unterminated string",
      start_line,
      start_col,
      self.pos,
      self.get_line(start_line),
    ),
  )
}

///|
/// Read escape sequence
fn Lexer::read_escape_sequence(self : Lexer) -> HCLResult[(Char, Lexer)] {
  match self.peek() {
    Some(c) if c == 'n'.to_int().to_uint16() => Ok(('\n', self.advance()))
    Some(c) if c == 'r'.to_int().to_uint16() => Ok(('\r', self.advance()))
    Some(c) if c == 't'.to_int().to_uint16() => Ok(('\t', self.advance()))
    Some(c) if c == '\\'.to_int().to_uint16() => Ok(('\\', self.advance()))
    Some(c) if c == '"'.to_int().to_uint16() => Ok(('"', self.advance()))
    Some(c) if c == '/'.to_int().to_uint16() => Ok(('/', self.advance()))
    Some(c) if c == 'b'.to_int().to_uint16() => Ok(('\b', self.advance()))
    Some(c) if c == 'f'.to_int().to_uint16() => Ok(('\f', self.advance()))
    _ =>
      Err(
        HCLError::parse_error_with_context(
          "Invalid escape sequence",
          self.line,
          self.col,
          self.pos,
          self.get_line(self.line),
        ),
      )
  }
}

///|
/// Read a number literal
fn Lexer::read_number(self : Lexer) -> HCLResult[(Token, Lexer)] {
  let mut lexer = self
  let mut num = ""
  let mut is_float = false

  while !lexer.is_at_end() {
    match lexer.peek() {
      Some(c) if is_digit(c) => {
        num = num + c.to_int().unsafe_to_char().to_string()
        lexer = lexer.advance()
      }
      Some(c) if c == '_'.to_int().to_uint16() =>
        // Allow underscores in numbers
        lexer = lexer.advance()
      Some(c) if c == '.'.to_int().to_uint16() && !is_float => {
        is_float = true
        num = num + "."
        lexer = lexer.advance()
      }
      Some(c) if (
          c == 'e'.to_int().to_uint16() || c == 'E'.to_int().to_uint16()
        ) &&
        !is_float => {
        // Scientific notation
        is_float = true
        num = num + "e"
        lexer = lexer.advance()
        // Optional sign
        match lexer.peek() {
          Some(c2) if c2 == '+'.to_int().to_uint16() ||
            c2 == '-'.to_int().to_uint16() => {
            num = num + c2.to_int().unsafe_to_char().to_string()
            lexer = lexer.advance()
          }
          _ => ()
        }
      }
      _ => break
    }
  }

  if num.is_empty() {
    return Err(
      HCLError::parse_error_with_context(
        "Invalid number",
        self.line,
        self.col,
        self.pos,
        self.get_line(self.line),
      ),
    )
  }

  Ok((NumberLit(num), lexer))
}

///|
/// Read an identifier or keyword
fn Lexer::read_ident_or_keyword(self : Lexer) -> HCLResult[(Token, Lexer)] {
  let mut lexer = self
  let mut ident = ""

  while !lexer.is_at_end() {
    match lexer.peek() {
      Some(c) if is_ident_continue(c) => {
        ident = ident + c.to_int().unsafe_to_char().to_string()
        lexer = lexer.advance()
      }
      _ => break
    }
  }

  // Check for keywords
  match ident {
    "true" => Ok((BoolLit(true), lexer))
    "false" => Ok((BoolLit(false), lexer))
    "null" => Ok((NullLit, lexer))
    "for" => Ok((For, lexer))
    "in" => Ok((In, lexer))
    "if" => Ok((If, lexer))
    _ => Ok((Ident(ident), lexer))
  }
}

///|
/// Get the next token
pub fn Lexer::next_token(self : Lexer) -> HCLResult[(Token, Lexer)] {
  let lexer = self.skip_whitespace()

  if lexer.is_at_end() {
    return Ok((EOF, lexer))
  }

  let c = lexer.peek().unwrap()

  match c {
    c if c == '{'.to_int().to_uint16() => Ok((LBrace, lexer.advance()))
    c if c == '}'.to_int().to_uint16() => Ok((RBrace, lexer.advance()))
    c if c == '['.to_int().to_uint16() => Ok((LBracket, lexer.advance()))
    c if c == ']'.to_int().to_uint16() => Ok((RBracket, lexer.advance()))
    c if c == '('.to_int().to_uint16() => Ok((LParen, lexer.advance()))
    c if c == ')'.to_int().to_uint16() => Ok((RParen, lexer.advance()))
    c if c == '='.to_int().to_uint16() =>
      if lexer.peek_next() == Some('='.to_int().to_uint16()) {
        Ok((EqEq, lexer.advance().advance()))
      } else if lexer.peek_next() == Some('>'.to_int().to_uint16()) {
        Ok((FatArrow, lexer.advance().advance()))
      } else {
        Ok((Equals, lexer.advance()))
      }
    c if c == ','.to_int().to_uint16() => Ok((Comma, lexer.advance()))
    c if c == '.'.to_int().to_uint16() => Ok((Dot, lexer.advance()))
    c if c == '+'.to_int().to_uint16() => Ok((Plus, lexer.advance()))
    c if c == '-'.to_int().to_uint16() => Ok((Minus, lexer.advance()))
    c if c == '*'.to_int().to_uint16() => Ok((Star, lexer.advance()))
    c if c == '/'.to_int().to_uint16() => Ok((Slash, lexer.advance()))
    c if c == '%'.to_int().to_uint16() => Ok((Percent, lexer.advance()))
    c if c == '!'.to_int().to_uint16() =>
      if lexer.peek_next() == Some('='.to_int().to_uint16()) {
        Ok((BangEq, lexer.advance().advance()))
      } else {
        Ok((Bang, lexer.advance()))
      }
    c if c == '<'.to_int().to_uint16() =>
      if lexer.peek_next() == Some('='.to_int().to_uint16()) {
        Ok((LtEq, lexer.advance().advance()))
      } else if lexer.peek_next() == Some('<'.to_int().to_uint16()) {
        // Heredoc
        let hlexer = lexer.advance().advance()
        if hlexer.peek() == Some('-'.to_int().to_uint16()) {
          Ok((Heredoc(true), hlexer.advance()))
        } else {
          Ok((Heredoc(false), hlexer))
        }
      } else {
        Ok((Lt, lexer.advance()))
      }
    c if c == '>'.to_int().to_uint16() =>
      if lexer.peek_next() == Some('='.to_int().to_uint16()) {
        Ok((GtEq, lexer.advance().advance()))
      } else {
        Ok((Gt, lexer.advance()))
      }
    c if c == '&'.to_int().to_uint16() =>
      if lexer.peek_next() == Some('&'.to_int().to_uint16()) {
        Ok((AndAnd, lexer.advance().advance()))
      } else {
        Err(
          HCLError::parse_error_with_context(
            "Unexpected character '&'",
            lexer.line,
            lexer.col,
            lexer.pos,
            lexer.get_line(lexer.line),
          ),
        )
      }
    c if c == '|'.to_int().to_uint16() =>
      if lexer.peek_next() == Some('|'.to_int().to_uint16()) {
        Ok((OrOr, lexer.advance().advance()))
      } else {
        Err(
          HCLError::parse_error_with_context(
            "Unexpected character '|'",
            lexer.line,
            lexer.col,
            lexer.pos,
            lexer.get_line(lexer.line),
          ),
        )
      }
    c if c == '?'.to_int().to_uint16() => Ok((Question, lexer.advance()))
    c if c == ':'.to_int().to_uint16() => Ok((Colon, lexer.advance()))
    c if c == '"'.to_int().to_uint16() => lexer.read_string()
    c if c == '\n'.to_int().to_uint16() => Ok((Newline, lexer.advance()))
    c if is_digit(c) => lexer.read_number()
    c if is_ident_start(c) => lexer.read_ident_or_keyword()
    _ => {
      let ch = c.to_int().unsafe_to_char().to_string()
      Err(
        HCLError::parse_error_with_context(
          "Unexpected character '" + ch + "'",
          lexer.line,
          lexer.col,
          lexer.pos,
          lexer.get_line(lexer.line),
        ),
      )
    }
  }
}

///|
/// Tokenize entire input
pub fn Lexer::tokenize(self : Lexer) -> HCLResult[Array[Token]] {
  let tokens = []
  let mut lexer = self
  let mut done = false

  while !done {
    match lexer.next_token() {
      Ok((token, new_lexer)) => {
        tokens.push(token)
        lexer = new_lexer

        if token == EOF {
          done = true
        }
      }
      Err(e) => return Err(e)
    }
  }

  Ok(tokens)
}

///|
/// Check if char code is a digit
fn is_digit(c : UInt16) -> Bool {
  c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16()
}

///|
/// Check if char code is valid identifier start
fn is_ident_start(c : UInt16) -> Bool {
  (c >= 'a'.to_int().to_uint16() && c <= 'z'.to_int().to_uint16()) ||
  (c >= 'A'.to_int().to_uint16() && c <= 'Z'.to_int().to_uint16()) ||
  c == '_'.to_int().to_uint16()
}

///|
/// Check if char code is valid identifier continue
fn is_ident_continue(c : UInt16) -> Bool {
  is_ident_start(c) || is_digit(c) || c == '-'.to_int().to_uint16()
}
