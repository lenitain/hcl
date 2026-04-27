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
/// Validate input encoding (no BOM allowed)
pub fn Lexer::validate_input(input : String) -> HCLResult[Unit] {
  if input.length() >= 1 && input[0] == '\u{FEFF}'.to_int().to_uint16() {
    Err(
      HCLError::encoding_error(
        "HCL input must not contain a UTF-8 byte order mark (BOM)",
      ),
    )
  } else {
    Ok(())
  }
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
        match lexer.peek_next() {
          Some(c2) if c2 == '/'.to_int().to_uint16() =>
            lexer = lexer.skip_line_comment()
          Some(c2) if c2 == '*'.to_int().to_uint16() =>
            match lexer.skip_block_comment() {
              Ok(new_lexer) => lexer = new_lexer
              Err(_) => return lexer
            }
          _ => break
        }
      Some(c) if c == '#'.to_int().to_uint16() =>
        lexer = lexer.skip_line_comment()
      _ => break
    }
  }
  lexer
}

///|
/// Skip line comment
fn Lexer::skip_line_comment(self : Lexer) -> Lexer {
  let mut lexer = self.advance().advance()
  while !lexer.is_at_end() && lexer.peek() != Some('\n'.to_int().to_uint16()) {
    lexer = lexer.advance()
  }
  lexer
}

///|
/// Skip block comment
fn Lexer::skip_block_comment(self : Lexer) -> HCLResult[Lexer] {
  let mut lexer = self.advance().advance()
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
  let mut lexer = self.advance()
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
    Some(c) if c == 'u'.to_int().to_uint16() => self.read_unicode_escape()
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
/// Read Unicode escape sequence (\uXXXX or \u{XXXX})
fn Lexer::read_unicode_escape(self : Lexer) -> HCLResult[(Char, Lexer)] {
  let lexer = self.advance()
  if lexer.is_at_end() {
    return Err(
      HCLError::parse_error_with_context(
        "Invalid unicode escape sequence",
        lexer.line,
        lexer.col,
        lexer.pos,
        lexer.get_line(lexer.line),
      ),
    )
  }

  if lexer.peek() == Some('{'.to_int().to_uint16()) {
    let lexer = lexer.advance()
    let mut code_point = 0
    let mut digits = 0
    let mut l = lexer

    while !l.is_at_end() {
      match l.peek() {
        Some(c) if c == '}'.to_int().to_uint16() => {
          if digits == 0 {
            return Err(
              HCLError::parse_error_with_context(
                "Invalid unicode escape: empty code point",
                l.line,
                l.col,
                l.pos,
                l.get_line(l.line),
              ),
            )
          }
          l = l.advance()
          if code_point > 0x10FFFF {
            return Err(
              HCLError::parse_error_with_context(
                "Invalid unicode escape: code point out of range",
                lexer.line,
                lexer.col,
                lexer.pos,
                lexer.get_line(lexer.line),
              ),
            )
          }
          return Ok((code_point.unsafe_to_char(), l))
        }
        Some(c) if is_hex_digit(c) => {
          if digits >= 6 {
            return Err(
              HCLError::parse_error_with_context(
                "Invalid unicode escape: too many hex digits",
                l.line,
                l.col,
                l.pos,
                l.get_line(l.line),
              ),
            )
          }
          code_point = code_point * 16 + hex_digit_value(c)
          digits = digits + 1
          l = l.advance()
        }
        _ =>
          return Err(
            HCLError::parse_error_with_context(
              "Invalid unicode escape: expected hex digit or '}'",
              l.line,
              l.col,
              l.pos,
              l.get_line(l.line),
            ),
          )
      }
    }

    return Err(
      HCLError::parse_error_with_context(
        "Invalid unicode escape: unterminated \\u{} sequence",
        l.line,
        l.col,
        l.pos,
        l.get_line(l.line),
      ),
    )
  }

  let mut code_point = 0
  let mut digits = 0
  let mut l = lexer

  while digits < 4 && !l.is_at_end() {
    match l.peek() {
      Some(c) if is_hex_digit(c) => {
        code_point = code_point * 16 + hex_digit_value(c)
        digits = digits + 1
        l = l.advance()
      }
      _ => break
    }
  }

  if digits != 4 {
    return Err(
      HCLError::parse_error_with_context(
        "Invalid unicode escape: expected 4 hex digits",
        lexer.line,
        lexer.col,
        lexer.pos,
        lexer.get_line(lexer.line),
      ),
    )
  }

  Ok((code_point.unsafe_to_char(), l))
}

///|
/// Read a number literal (decimal, hex 0x, octal 0o, binary 0b)
fn Lexer::read_number(self : Lexer) -> HCLResult[(Token, Lexer)] {
  let mut lexer = self
  let mut num = ""
  let mut is_float = false

  match lexer.peek() {
    Some(c) if c == '0'.to_int().to_uint16() =>
      match lexer.peek_next() {
        Some(c2) if c2 == 'x'.to_int().to_uint16() ||
          c2 == 'X'.to_int().to_uint16() => {
          lexer = lexer.advance().advance()
          num = "0x"
          while !lexer.is_at_end() {
            match lexer.peek() {
              Some(c) if is_hex_digit(c) => {
                num = num + c.to_int().unsafe_to_char().to_string()
                lexer = lexer.advance()
              }
              Some(c) if c == '_'.to_int().to_uint16() =>
                lexer = lexer.advance()
              _ => break
            }
          }
          return Ok((NumberLit(num), lexer))
        }
        Some(c2) if c2 == 'o'.to_int().to_uint16() ||
          c2 == 'O'.to_int().to_uint16() => {
          lexer = lexer.advance().advance()
          num = "0o"
          while !lexer.is_at_end() {
            match lexer.peek() {
              Some(c) if is_octal_digit(c) => {
                num = num + c.to_int().unsafe_to_char().to_string()
                lexer = lexer.advance()
              }
              Some(c) if c == '_'.to_int().to_uint16() =>
                lexer = lexer.advance()
              _ => break
            }
          }
          return Ok((NumberLit(num), lexer))
        }
        Some(c2) if c2 == 'b'.to_int().to_uint16() ||
          c2 == 'B'.to_int().to_uint16() => {
          lexer = lexer.advance().advance()
          num = "0b"
          while !lexer.is_at_end() {
            match lexer.peek() {
              Some(c) if c == '0'.to_int().to_uint16() ||
                c == '1'.to_int().to_uint16() => {
                num = num + c.to_int().unsafe_to_char().to_string()
                lexer = lexer.advance()
              }
              Some(c) if c == '_'.to_int().to_uint16() =>
                lexer = lexer.advance()
              _ => break
            }
          }
          return Ok((NumberLit(num), lexer))
        }
        _ => ()
      }
    _ => ()
  }

  while !lexer.is_at_end() {
    match lexer.peek() {
      Some(c) if is_digit(c) => {
        num = num + c.to_int().unsafe_to_char().to_string()
        lexer = lexer.advance()
      }
      Some(c) if c == '_'.to_int().to_uint16() => lexer = lexer.advance()
      Some(c) if c == '.'.to_int().to_uint16() && !is_float => {
        is_float = true
        num = num + "."
        lexer = lexer.advance()
      }
      Some(c) if (
          c == 'e'.to_int().to_uint16() || c == 'E'.to_int().to_uint16()
        ) &&
        !is_float => {
        is_float = true
        num = num + "e"
        lexer = lexer.advance()
        match lexer.peek() {
          Some(c2) if c2 == '+'.to_int().to_uint16() ||
            c2 == '-'.to_int().to_uint16() => {
            num = num + c2.to_int().unsafe_to_char().to_string()
            lexer = lexer.advance()
          }
          _ => ()
        }
      }
      Some(c) if (
          c == 'e'.to_int().to_uint16() || c == 'E'.to_int().to_uint16()
        ) &&
        is_float => {
        num = num + "e"
        lexer = lexer.advance()
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
/// Get the next token with leading trivia (whitespace, newlines, and comments)
pub fn Lexer::next_token_with_trivia(
  self : Lexer,
) -> HCLResult[(Token, Lexer, String?)] {
  let mut trivia = ""
  let mut lexer = self
  let newline_code = '\n'.to_int().to_uint16()
  let slash_code = '/'.to_int().to_uint16()

  let mut has_more = true
  while has_more {
    has_more = false

    let start = lexer.pos
    while !lexer.is_at_end() {
      match lexer.peek() {
        Some(c) if c == ' '.to_int().to_uint16() ||
          c == '\t'.to_int().to_uint16() ||
          c == '\r'.to_int().to_uint16() ||
          c == newline_code => lexer = lexer.advance()
        _ => break
      }
    }
    if lexer.pos > start {
      trivia = trivia + lexer.input[start:lexer.pos].to_string()
      has_more = true
    }

    if !lexer.is_at_end() && lexer.peek() == Some(slash_code) {
      match lexer.peek_next() {
        Some(c) if c == slash_code => {
          let cstart = lexer.pos
          lexer = lexer.advance().advance()
          while !lexer.is_at_end() && lexer.peek() != Some(newline_code) {
            lexer = lexer.advance()
          }
          trivia = trivia + lexer.input[cstart:lexer.pos].to_string()
          has_more = true
        }
        Some(c) if c == '*'.to_int().to_uint16() => {
          let cstart = lexer.pos
          lexer = lexer.advance().advance()
          let star_code = '*'.to_int().to_uint16()
          let slash2_code = '/'.to_int().to_uint16()
          while !lexer.is_at_end() {
            if lexer.peek() == Some(star_code) &&
              lexer.peek_next() == Some(slash2_code) {
              lexer = lexer.advance().advance()
              break
            }
            lexer = lexer.advance()
          }
          trivia = trivia + lexer.input[cstart:lexer.pos].to_string()
          has_more = true
        }
        _ => ()
      }
    }
  }

  let token_start = lexer.pos

  match lexer.next_token() {
    Ok((token, final_lexer)) => {
      let full_trivia = self.input[self.pos:token_start].to_string()
      let prefix = if full_trivia == "" { None } else { Some(full_trivia) }
      Ok((token, final_lexer, prefix))
    }
    Err(e) => Err(e)
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
        lexer.read_heredoc()
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
/// Check if char code is valid identifier start (Unicode XID_Start)
fn is_ident_start(c : UInt16) -> Bool {
  let cp = c.to_int()
  if (cp >= 0x0041 && cp <= 0x005A) ||
    (cp >= 0x0061 && cp <= 0x007A) ||
    cp == 0x005F {
    return true
  }
  // Latin Extended (À-ÿ) excluding × and ÷
  if cp >= 0x00C0 && cp <= 0x00FF && cp != 0x00D7 && cp != 0x00F7 {
    return true
  }
  // Latin Extended-A
  if cp >= 0x0100 && cp <= 0x017F {
    return true
  }
  // Latin Extended-B
  if cp >= 0x0180 && cp <= 0x024F {
    return true
  }
  // Greek
  if cp >= 0x0370 && cp <= 0x03FF {
    return true
  }
  // Cyrillic
  if cp >= 0x0400 && cp <= 0x04FF {
    return true
  }
  // Arabic
  if cp >= 0x0600 && cp <= 0x06FF {
    return true
  }
  // Devanagari
  if cp >= 0x0900 && cp <= 0x097F {
    return true
  }
  // Thai
  if cp >= 0x0E00 && cp <= 0x0E7F {
    return true
  }
  // CJK Extension A
  if cp >= 0x3400 && cp <= 0x4DBF {
    return true
  }
  // CJK Unified Ideographs
  if cp >= 0x4E00 && cp <= 0x9FFF {
    return true
  }
  // Hangul Syllables
  if cp >= 0xAC00 && cp <= 0xD7AF {
    return true
  }
  false
}

///|
/// Check if char code is valid identifier continue (Unicode XID_Continue)
fn is_ident_continue(c : UInt16) -> Bool {
  if is_ident_start(c) {
    return true
  }
  let cp = c.to_int()
  if cp >= 0x0030 && cp <= 0x0039 {
    return true
  }
  if cp == 0x002D {
    return true
  }
  // Combining Diacritical Marks
  if cp >= 0x0300 && cp <= 0x036F {
    return true
  }
  false
}

///|
/// Check if char code is a hex digit (0-9, a-f, A-F)
fn is_hex_digit(c : UInt16) -> Bool {
  is_digit(c) ||
  (c >= 'a'.to_int().to_uint16() && c <= 'f'.to_int().to_uint16()) ||
  (c >= 'A'.to_int().to_uint16() && c <= 'F'.to_int().to_uint16())
}

///|
/// Convert hex digit char code to its integer value
fn hex_digit_value(c : UInt16) -> Int {
  if c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16() {
    c.to_int() - '0'.to_int()
  } else if c >= 'a'.to_int().to_uint16() && c <= 'f'.to_int().to_uint16() {
    c.to_int() - 'a'.to_int() + 10
  } else {
    c.to_int() - 'A'.to_int() + 10
  }
}

///|
/// Check if char code is an octal digit (0-7)
fn is_octal_digit(c : UInt16) -> Bool {
  c >= '0'.to_int().to_uint16() && c <= '7'.to_int().to_uint16()
}

///|
/// Collect whitespace (spaces, tabs, CR) without consuming, returns collected text
pub fn Lexer::collect_whitespace(self : Lexer) -> (Lexer, String?) {
  let start = self.pos
  let mut lexer = self
  while !lexer.is_at_end() {
    match lexer.peek() {
      Some(c) if c == ' '.to_int().to_uint16() ||
        c == '\t'.to_int().to_uint16() ||
        c == '\r'.to_int().to_uint16() => lexer = lexer.advance()
      _ => break
    }
  }
  if lexer.pos > start {
    (lexer, Some(lexer.input[start:lexer.pos].to_string()))
  } else {
    (lexer, None)
  }
}

///|
/// Collect comment (line or block) without consuming, returns collected text
pub fn Lexer::collect_comment(self : Lexer) -> (Lexer, String?) {
  if self.is_at_end() {
    return (self, None)
  }

  let slash_code = '/'.to_int().to_uint16()
  let newline_code = '\n'.to_int().to_uint16()
  let star_code = '*'.to_int().to_uint16()

  if self.peek() == Some(slash_code) {
    match self.peek_next() {
      Some(c) if c == slash_code => {
        let start = self.pos
        let mut lexer = self.advance().advance()
        while !lexer.is_at_end() && lexer.peek() != Some(newline_code) {
          lexer = lexer.advance()
        }
        (lexer, Some(lexer.input[start:lexer.pos].to_string()))
      }
      Some(c) if c == star_code => {
        let start = self.pos
        let mut lexer = self.advance().advance()
        while !lexer.is_at_end() {
          if lexer.peek() == Some(star_code) &&
            lexer.peek_next() == Some(slash_code) {
            lexer = lexer.advance().advance()
            return (lexer, Some(lexer.input[start:lexer.pos].to_string()))
          }
          lexer = lexer.advance()
        }
        (lexer, Some(lexer.input[start:lexer.pos].to_string()))
      }
      _ => (self, None)
    }
  } else {
    (self, None)
  }
}

///|
/// Read a heredoc literal
fn Lexer::read_heredoc(self : Lexer) -> HCLResult[(Token, Lexer)] {
  let start_line = self.line
  let start_col = self.col
  let mut lexer = self.advance().advance()
  let strip = if lexer.peek() == Some('-'.to_int().to_uint16()) {
    lexer = lexer.advance()
    true
  } else {
    false
  }

  let mut delimiter = ""
  while !lexer.is_at_end() && is_ident_continue(lexer.peek().unwrap_or(0)) {
    let c = lexer.peek().unwrap_or(0)
    delimiter = delimiter + c.to_int().unsafe_to_char().to_string()
    lexer = lexer.advance()
  }

  if delimiter.is_empty() {
    return Err(
      HCLError::parse_error_with_context(
        "Expected heredoc delimiter after <<",
        start_line,
        start_col,
        self.pos,
        self.get_line(start_line),
      ),
    )
  }

  if lexer.peek() == Some('\r'.to_int().to_uint16()) {
    lexer = lexer.advance()
  }
  if lexer.peek() == Some('\n'.to_int().to_uint16()) {
    lexer = lexer.advance()
  }

  let mut content = ""
  let mut line_start = lexer.pos
  let mut found_end = false

  while !lexer.is_at_end() {
    if lexer.peek() == Some('\n'.to_int().to_uint16()) {
      let line = lexer.input[line_start:lexer.pos].to_string()
      let trimmed = line.trim()
      if trimmed == delimiter {
        lexer = lexer.advance()
        found_end = true
        break
      }
      content = content + line + "\n"
      lexer = lexer.advance()
      line_start = lexer.pos
    } else {
      lexer = lexer.advance()
    }
  }

  if !found_end {
    if line_start <= lexer.pos {
      let line = lexer.input[line_start:lexer.pos].to_string()
      let trimmed = line.trim()
      if trimmed == delimiter {
        found_end = true
      } else {
        content = content + line
      }
    }
  }

  if !found_end {
    return Err(
      HCLError::parse_error_with_context(
        "Unterminated heredoc: expected \"" + delimiter + "\" to end",
        start_line,
        start_col,
        self.pos,
        self.get_line(start_line),
      ),
    )
  }

  Ok((HeredocLit(delimiter, content, strip), lexer))
}
