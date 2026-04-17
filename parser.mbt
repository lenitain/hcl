///|
/// HCL Parser - parses HCL input into structured data
pub struct Parser {
  lexer : Lexer
  current : Token
  peek : Token
}

///|
/// Create a new parser from string input
pub fn Parser::new(input : String) -> HCLResult[Parser] {
  let lexer = Lexer::new(input)
  match lexer.next_token() {
    Ok((current, lexer)) =>
      match lexer.next_token() {
        Ok((peek, lexer)) => Ok({ lexer, current, peek })
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// Create a new parser from lexer
pub fn Parser::from_lexer(lexer : Lexer) -> HCLResult[Parser] {
  match lexer.next_token() {
    Ok((current, lexer)) =>
      match lexer.next_token() {
        Ok((peek, lexer)) => Ok({ lexer, current, peek })
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// Advance to next token
fn Parser::advance(self : Parser) -> HCLResult[Parser] {
  match self.lexer.next_token() {
    Ok((new_peek, new_lexer)) =>
      Ok({ lexer: new_lexer, current: self.peek, peek: new_peek })
    Err(e) => Err(e)
  }
}

///|
/// Check if current token matches expected
fn Parser::check(self : Parser, expected : Token) -> Bool {
  self.current == expected
}

///|
/// Consume token if it matches expected
fn Parser::expect(self : Parser, expected : Token) -> HCLResult[Parser] {
  if self.check(expected) {
    self.advance()
  } else {
    let (line, col, offset) = self.lexer.location()
    Err(
      HCLError::parse_error_with_context(
        "Expected " +
        token_to_string(expected) +
        ", got " +
        token_to_string(self.current),
        line,
        col,
        offset,
        self.lexer.get_line(line),
      ),
    )
  }
}

///|
/// Skip newlines
fn Parser::skip_newlines(self : Parser) -> HCLResult[Parser] {
  let mut parser = self
  while parser.check(Newline) {
    match parser.advance() {
      Ok(p) => parser = p
      Err(e) => return Err(e)
    }
  }
  Ok(parser)
}

///|
/// Parse HCL input into a Body
pub fn Parser::parse_body(self : Parser) -> HCLResult[Body] {
  match self.skip_newlines() {
    Ok(start_parser) => {
      let items = []
      let mut parser = start_parser

      while !parser.check(EOF) {
        match parser.current {
          Ident(name) =>
            if parser.check(Equals) || parser.peek == Equals {
              // Attribute
              match parser.parse_attr() {
                Ok((attr, new_parser)) => {
                  items.push(Attribute(attr))
                  parser = new_parser
                }
                Err(e) => return Err(e)
              }
            } else {
              // Block
              match parser.parse_block() {
                Ok((block, new_parser)) => {
                  items.push(Block(block))
                  parser = new_parser
                }
                Err(e) => return Err(e)
              }
            }
          Newline =>
            match parser.advance() {
              Ok(p) => parser = p
              Err(e) => return Err(e)
            }
          EOF => break
          _ => {
            let (line, col, offset) = parser.lexer.location()
            return Err(
              HCLError::parse_error_with_context(
                "Unexpected token: " + token_to_string(parser.current),
                line,
                col,
                offset,
                parser.lexer.get_line(line),
              ),
            )
          }
        }
        match parser.skip_newlines() {
          Ok(p) => parser = p
          Err(e) => return Err(e)
        }
      }

      Ok(Body::from_items(items))
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse an attribute
fn Parser::parse_attr(self : Parser) -> HCLResult[(Attr, Parser)] {
  let name = match self.current {
    Ident(n) => n
    _ => {
      let (line, col, offset) = self.lexer.location()
      return Err(
        HCLError::parse_error_with_context(
          "Expected identifier",
          line,
          col,
          offset,
          self.lexer.get_line(line),
        ),
      )
    }
  }

  match self.advance() {
    Ok(parser) =>
      match parser.expect(Equals) {
        Ok(parser) =>
          match parser.parse_value() {
            Ok((value, parser)) => Ok((Attr::new(name, value), parser))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// Parse a block
fn Parser::parse_block(self : Parser) -> HCLResult[(Block, Parser)] {
  let type_name = match self.current {
    Ident(n) => n
    _ => {
      let (line, col, offset) = self.lexer.location()
      return Err(
        HCLError::parse_error_with_context(
          "Expected block type name",
          line,
          col,
          offset,
          self.lexer.get_line(line),
        ),
      )
    }
  }

  let labels = []
  let mut result = match self.advance() {
    Ok(p) => p
    Err(e) => return Err(e)
  }

  // Parse labels (optional)
  while !result.check(LBrace) && !result.check(EOF) {
    match result.current {
      StringLit(s) => {
        labels.push(s)
        match result.advance() {
          Ok(p) => result = p
          Err(e) => return Err(e)
        }
      }
      Ident(s) => {
        labels.push(s)
        match result.advance() {
          Ok(p) => result = p
          Err(e) => return Err(e)
        }
      }
      _ => {
        let (line, col, offset) = result.lexer.location()
        return Err(
          HCLError::parse_error_with_context(
            "Expected block label or '{'",
            line,
            col,
            offset,
            result.lexer.get_line(line),
          ),
        )
      }
    }
  }

  match result.expect(LBrace) {
    Ok(start_parser) => {
      let items = []
      let mut parser = start_parser

      match parser.skip_newlines() {
        Ok(p) => parser = p
        Err(e) => return Err(e)
      }

      while !parser.check(RBrace) && !parser.check(EOF) {
        match parser.current {
          Ident(name) =>
            if parser.check(Equals) || parser.peek == Equals {
              // Attribute
              match parser.parse_attr() {
                Ok((attr, new_parser)) => {
                  items.push(Attribute(attr))
                  parser = new_parser
                }
                Err(e) => return Err(e)
              }
            } else {
              // Block
              match parser.parse_block() {
                Ok((block, new_parser)) => {
                  items.push(Block(block))
                  parser = new_parser
                }
                Err(e) => return Err(e)
              }
            }
          Newline =>
            match parser.advance() {
              Ok(p) => parser = p
              Err(e) => return Err(e)
            }
          _ => {
            let (line, col, offset) = parser.lexer.location()
            return Err(
              HCLError::parse_error_with_context(
                "Unexpected token: " + token_to_string(parser.current),
                line,
                col,
                offset,
                parser.lexer.get_line(line),
              ),
            )
          }
        }
        match parser.skip_newlines() {
          Ok(p) => parser = p
          Err(e) => return Err(e)
        }
      }

      match parser.expect(RBrace) {
        Ok(final_parser) =>
          Ok((Block::new(type_name, labels, { items, }), final_parser))
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse a value (including expressions with binary operators)
fn Parser::parse_value(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.parse_primary() {
    Ok((expr, parser)) => parser.parse_binary_expr(expr, 0)
    Err(e) => Err(e)
  }
}

///|
/// Parse binary expression with operator precedence (Pratt parser)
fn Parser::parse_binary_expr(
  self : Parser,
  left : HCLValue,
  min_prec : Int,
) -> HCLResult[(HCLValue, Parser)] {
  let mut result = left
  let mut parser = self
  let mut continue_loop = true

  while continue_loop {
    let prec = parser.current.precedence()
    if prec == 0 || prec < min_prec {
      continue_loop = false
      continue
    }

    let op_token = parser.current
    let op_str = match op_token {
      Plus => "+"
      Minus => "-"
      Star => "*"
      Slash => "/"
      Percent => "%"
      EqEq => "=="
      BangEq => "!="
      Lt => "<"
      Gt => ">"
      LtEq => "<="
      GtEq => ">="
      AndAnd => "&&"
      OrOr => "||"
      _ => {
        continue_loop = false
        continue
      }
    }

    match parser.advance() {
      Ok(p) => parser = p
      Err(e) => return Err(e)
    }

    match parser.parse_primary() {
      Ok((right, p)) => {
        parser = p
        let next_prec = parser.current.precedence()
        if next_prec > prec {
          match parser.parse_binary_expr(right, prec + 1) {
            Ok((new_right, p)) => {
              parser = p
              // Create binary operation as object
              let bin_obj = {
                "type": String("binary_expr"),
                "op": String(op_str),
                "left": result,
                "right": new_right,
              }
              result = Object(bin_obj)
            }
            Err(e) => return Err(e)
          }
        } else {
          // Create binary operation as object
          let bin_obj = {
            "type": String("binary_expr"),
            "op": String(op_str),
            "left": result,
            "right": right,
          }
          result = Object(bin_obj)
        }
      }
      Err(e) => return Err(e)
    }
  }

  // Check for conditional expression
  parser.parse_conditional_expr(result)
}

///|
/// Parse conditional expression (cond ? true : false)
fn Parser::parse_conditional_expr(
  self : Parser,
  condition : HCLValue,
) -> HCLResult[(HCLValue, Parser)] {
  if self.check(Question) {
    match self.advance() {
      Ok(parser) =>
        match parser.parse_value() {
          Ok((true_expr, parser)) =>
            match parser.expect(Colon) {
              Ok(parser) =>
                match parser.parse_value() {
                  Ok((false_expr, parser)) => {
                    // Create a conditional expression as an object
                    let cond_obj = {
                      "type": String("conditional"),
                      "condition": condition,
                      "true_expr": true_expr,
                      "false_expr": false_expr,
                    }
                    Ok((Object(cond_obj), parser))
                  }
                  Err(e) => Err(e)
                }
              Err(e) => Err(e)
            }
          Err(e) => Err(e)
        }
      Err(e) => Err(e)
    }
  } else {
    Ok((condition, self))
  }
}

///|
/// Parse primary value
fn Parser::parse_primary(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.current {
    StringLit(s) =>
      match self.advance() {
        Ok(p) => Ok((String(s), p))
        Err(e) => Err(e)
      }
    HeredocLit(delimiter, content, strip) =>
      // Parse heredoc as template and evaluate without variables
      match Template::from_heredoc(content, delimiter, strip) {
        Ok(template) =>
          match template.evaluate({}, {}) {
            Ok(result) =>
              match self.advance() {
                Ok(p) => Ok((String(result), p))
                Err(e) => Err(e)
              }
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    NumberLit(n) =>
      // Detect prefix: 0x (hex), 0o (octal), 0b (binary)
      if n.has_prefix("0x") || n.has_prefix("0X") {
        // Hex parsing
        let mut result = 0
        for c in n[2:] {
          if c == '_' {
            // skip underscores
          } else if c >= '0' && c <= '9' {
            result = result * 16 + (c.to_int() - '0'.to_int())
          } else if c >= 'a' && c <= 'f' {
            result = result * 16 + (c.to_int() - 'a'.to_int() + 10)
          } else if c >= 'A' && c <= 'F' {
            result = result * 16 + (c.to_int() - 'A'.to_int() + 10)
          }
        }
        match self.advance() {
          Ok(p) => Ok((Int(result), p))
          Err(e) => Err(e)
        }
      } else if n.has_prefix("0o") || n.has_prefix("0O") {
        // Octal parsing
        let mut result = 0
        for c in n[2:] {
          if c == '_' {
            // skip underscores
          } else if c >= '0' && c <= '7' {
            result = result * 8 + (c.to_int() - '0'.to_int())
          }
        }
        match self.advance() {
          Ok(p) => Ok((Int(result), p))
          Err(e) => Err(e)
        }
      } else if n.has_prefix("0b") || n.has_prefix("0B") {
        // Binary parsing
        let mut result = 0
        for c in n[2:] {
          if c == '_' {
            // skip underscores
          } else if c == '0' || c == '1' {
            result = result * 2 + (c.to_int() - '0'.to_int())
          }
        }
        match self.advance() {
          Ok(p) => Ok((Int(result), p))
          Err(e) => Err(e)
        }
      } else {
        // Decimal parsing
        let mut is_float = false
        for c in n {
          if c == '-' {
            // Skip negative sign
          } else if c >= '0' && c <= '9' {
            // Parse digit
          } else {
            // Contains non-digit, treat as float
            is_float = true
            break
          }
        }
        if is_float {
          // Parse float value
          let mut result = 0.0
          let mut decimal_place = 1.0
          let mut in_decimal = false
          for c in n {
            if c == '-' {
              // Skip negative sign
            } else if c == '.' {
              in_decimal = true
            } else if c >= '0' && c <= '9' {
              if in_decimal {
                decimal_place = decimal_place * 10.0
                result = result +
                  (c.to_int() - '0'.to_int()).to_double() / decimal_place
              } else {
                result = result * 10.0 + (c.to_int() - '0'.to_int()).to_double()
              }
            }
          }
          match self.advance() {
            Ok(p) => Ok((Float(result), p))
            Err(e) => Err(e)
          }
        } else {
          // Parse integer value
          let mut result = 0
          for c in n {
            if c >= '0' && c <= '9' {
              result = result * 10 + (c.to_int() - '0'.to_int())
            }
          }
          match self.advance() {
            Ok(p) => Ok((Int(result), p))
            Err(e) => Err(e)
          }
        }
      }
    BoolLit(b) =>
      match self.advance() {
        Ok(p) => Ok((Bool(b), p))
        Err(e) => Err(e)
      }
    NullLit =>
      match self.advance() {
        Ok(p) => Ok((Null, p))
        Err(e) => Err(e)
      }
    LBracket => self.parse_array()
    LBrace => self.parse_object()
    LParen => self.parse_paren_expr()
    Minus => self.parse_negative()
    Ident(name) => self.parse_ident_expr(name)
    _ => {
      let (line, col, offset) = self.lexer.location()
      Err(
        HCLError::parse_error_with_context(
          "Unexpected token: " + token_to_string(self.current),
          line,
          col,
          offset,
          self.lexer.get_line(line),
        ),
      )
    }
  }
}

///|
/// Parse identifier expression (variable, function call, or property access)
fn Parser::parse_ident_expr(
  self : Parser,
  name : String,
) -> HCLResult[(HCLValue, Parser)] {
  match self.advance() {
    Ok(parser) =>
      // Check for function call
      if parser.check(LParen) {
        parser.parse_function_call(name)
      } else {
        // Variable reference
        let var_obj = { "type": String("variable"), "name": String(name) }
        // Check for property access
        parser.parse_property_access(Object(var_obj))
      }
    Err(e) => Err(e)
  }
}

///|
/// Parse function call
fn Parser::parse_function_call(
  self : Parser,
  name : String,
) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(LParen) {
    Ok(parser) => {
      let args = []
      let mut p = parser

      // Skip newlines
      match p.skip_newlines() {
        Ok(new_p) => p = new_p
        Err(e) => return Err(e)
      }

      // Parse arguments
      while !p.check(RParen) && !p.check(EOF) {
        match p.parse_value() {
          Ok((arg, new_p)) => {
            args.push(arg)
            p = new_p
          }
          Err(e) => return Err(e)
        }

        // Skip newlines
        match p.skip_newlines() {
          Ok(new_p) => p = new_p
          Err(e) => return Err(e)
        }

        if p.check(Comma) {
          match p.advance() {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }
          // Skip newlines
          match p.skip_newlines() {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }
        } else if !p.check(RParen) {
          let (line, col, offset) = p.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected ',' or ')'",
              line,
              col,
              offset,
              p.lexer.get_line(line),
            ),
          )
        }
      }

      match p.expect(RParen) {
        Ok(final_p) => {
          // Create function call as an object
          let func_obj = {
            "type": String("function_call"),
            "name": String(name),
            "args": Array(args),
          }
          // Check for property access on result
          final_p.parse_property_access(Object(func_obj))
        }
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse property access (obj.key or obj["key"])
fn Parser::parse_property_access(
  self : Parser,
  obj : HCLValue,
) -> HCLResult[(HCLValue, Parser)] {
  if self.check(Dot) {
    // Property access with dot notation
    match self.advance() {
      Ok(parser) => {
        let property = match parser.current {
          Ident(name) => name
          _ => {
            let (line, col, offset) = parser.lexer.location()
            return Err(
              HCLError::parse_error_with_context(
                "Expected property name",
                line,
                col,
                offset,
                parser.lexer.get_line(line),
              ),
            )
          }
        }

        match parser.advance() {
          Ok(p) => {
            let access_obj = {
              "type": String("property_access"),
              "object": obj,
              "property": String(property),
            }
            // Check for chained property access
            p.parse_property_access(Object(access_obj))
          }
          Err(e) => Err(e)
        }
      }
      Err(e) => Err(e)
    }
  } else if self.check(LBracket) {
    // Property access with bracket notation
    match self.advance() {
      Ok(parser) =>
        match parser.parse_value() {
          Ok((key, parser)) =>
            match parser.expect(RBracket) {
              Ok(p) => {
                let access_obj = {
                  "type": String("index_access"),
                  "object": obj,
                  "index": key,
                }
                // Check for chained property access
                p.parse_property_access(Object(access_obj))
              }
              Err(e) => Err(e)
            }
          Err(e) => Err(e)
        }
      Err(e) => Err(e)
    }
  } else {
    Ok((obj, self))
  }
}

///|
/// Parse an array or for expression
fn Parser::parse_array(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(LBracket) {
    Ok(start_parser) => {
      let mut parser = start_parser

      match parser.skip_newlines() {
        Ok(p) => parser = p
        Err(e) => return Err(e)
      }

      // Check for for expression
      if parser.check(For) {
        return parser.parse_for_expr()
      }

      // Regular array
      let items = []
      while !parser.check(RBracket) && !parser.check(EOF) {
        match parser.parse_value() {
          Ok((value, new_parser)) => {
            items.push(value)
            parser = new_parser
          }
          Err(e) => return Err(e)
        }

        match parser.skip_newlines() {
          Ok(p) => parser = p
          Err(e) => return Err(e)
        }

        if parser.check(Comma) {
          match parser.advance() {
            Ok(p) => parser = p
            Err(e) => return Err(e)
          }
          match parser.skip_newlines() {
            Ok(p) => parser = p
            Err(e) => return Err(e)
          }
        } else if !parser.check(RBracket) {
          let (line, col, offset) = parser.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected ',' or ']'",
              line,
              col,
              offset,
              parser.lexer.get_line(line),
            ),
          )
        }
      }

      match parser.expect(RBracket) {
        Ok(parser) => Ok((Array(items), parser))
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse for expression [for x in list: expr] or {for k, v in obj: k => v}
fn Parser::parse_for_expr(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(For) {
    Ok(parser) => {
      // Parse loop variable(s)
      let vars = []
      let mut p = parser

      // Parse first variable
      match p.current {
        Ident(name) => {
          vars.push(name)
          match p.advance() {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }
        }
        _ => {
          let (line, col, offset) = p.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected identifier after 'for'",
              line,
              col,
              offset,
              p.lexer.get_line(line),
            ),
          )
        }
      }

      // Check for comma (object for expression has two variables)
      if p.check(Comma) {
        match p.advance() {
          Ok(new_p) => p = new_p
          Err(e) => return Err(e)
        }
        match p.current {
          Ident(name) => {
            vars.push(name)
            match p.advance() {
              Ok(new_p) => p = new_p
              Err(e) => return Err(e)
            }
          }
          _ => {
            let (line, col, offset) = p.lexer.location()
            return Err(
              HCLError::parse_error_with_context(
                "Expected identifier after ','",
                line,
                col,
                offset,
                p.lexer.get_line(line),
              ),
            )
          }
        }
      }

      // Parse 'in'
      match p.expect(In) {
        Ok(new_p) => p = new_p
        Err(e) => return Err(e)
      }

      // Parse collection expression
      match p.parse_value() {
        Ok((collection, new_p)) => {
          p = new_p

          // Parse colon
          match p.expect(Colon) {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }

          // Parse value expression
          match p.parse_value() {
            Ok((value_expr, new_p)) => {
              p = new_p

              // Check for conditional filter
              let filter = if p.check(If) {
                match p.advance() {
                  Ok(new_p) => {
                    p = new_p
                    match p.parse_value() {
                      Ok((filter_expr, new_p)) => {
                        p = new_p
                        Some(filter_expr)
                      }
                      Err(e) => return Err(e)
                    }
                  }
                  Err(e) => return Err(e)
                }
              } else {
                None
              }

              // Determine if this is list or object comprehension
              if vars.length() == 1 {
                // List comprehension: [for x in list: expr]
                let for_obj = {
                  "type": String("for_expr"),
                  "var": String(vars[0]),
                  "collection": collection,
                  "value_expr": value_expr,
                  "filter": match filter {
                    Some(f) => f
                    None => Null
                  },
                }
                match p.expect(RBracket) {
                  Ok(final_p) => Ok((Object(for_obj), final_p))
                  Err(e) => Err(e)
                }
              } else {
                // Object comprehension: {for k, v in obj: k => v}
                // We need to check for RBrace instead of RBracket
                let for_obj = {
                  "type": String("for_object_expr"),
                  "key_var": String(vars[0]),
                  "value_var": String(vars[1]),
                  "collection": collection,
                  "key_expr": value_expr,
                  "value_expr": Null,
                  "filter": match filter {
                    Some(f) => f
                    None => Null
                  },
                }

                // For object comprehension, we expect key => value syntax
                // But we already parsed the first expression as value_expr
                // Need to re-parse the key_expr
                // Actually, object comprehension syntax is: {for k, v in obj: k => v}
                // So after colon, we expect key_expr => value_expr
                // Let me re-think this...

                // For now, let's handle it as a simple case
                // The value_expr is actually the key_expr, and we need to parse => and value_expr
                match p.expect(FatArrow) {
                  Ok(new_p) => {
                    p = new_p
                    match p.parse_value() {
                      Ok((obj_value_expr, new_p)) => {
                        p = new_p
                        let for_obj = {
                          "type": String("for_object_expr"),
                          "key_var": String(vars[0]),
                          "value_var": String(vars[1]),
                          "collection": collection,
                          "key_expr": value_expr,
                          "value_expr": obj_value_expr,
                          "filter": match filter {
                            Some(f) => f
                            None => Null
                          },
                        }
                        match p.expect(RBrace) {
                          Ok(final_p) => Ok((Object(for_obj), final_p))
                          Err(e) => Err(e)
                        }
                      }
                      Err(e) => Err(e)
                    }
                  }
                  Err(e) => Err(e)
                }
              }
            }
            Err(e) => Err(e)
          }
        }
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse for expression for object comprehension {for k, v in obj: k => v}
fn Parser::parse_for_expr_for_object(
  self : Parser,
) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(For) {
    Ok(parser) => {
      // Parse loop variables (key, value)
      let vars = []
      let mut p = parser

      // Parse first variable (key)
      match p.current {
        Ident(name) => {
          vars.push(name)
          match p.advance() {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }
        }
        _ => {
          let (line, col, offset) = p.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected identifier after 'for'",
              line,
              col,
              offset,
              p.lexer.get_line(line),
            ),
          )
        }
      }

      // Parse comma
      match p.expect(Comma) {
        Ok(new_p) => p = new_p
        Err(e) => return Err(e)
      }

      // Parse second variable (value)
      match p.current {
        Ident(name) => {
          vars.push(name)
          match p.advance() {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }
        }
        _ => {
          let (line, col, offset) = p.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected identifier after ','",
              line,
              col,
              offset,
              p.lexer.get_line(line),
            ),
          )
        }
      }

      // Parse 'in'
      match p.expect(In) {
        Ok(new_p) => p = new_p
        Err(e) => return Err(e)
      }

      // Parse collection expression
      match p.parse_value() {
        Ok((collection, new_p)) => {
          p = new_p

          // Parse colon
          match p.expect(Colon) {
            Ok(new_p) => p = new_p
            Err(e) => return Err(e)
          }

          // Parse key expression
          match p.parse_value() {
            Ok((key_expr, new_p)) => {
              p = new_p

              // Parse =>
              match p.expect(FatArrow) {
                Ok(new_p) => p = new_p
                Err(e) => return Err(e)
              }

              // Parse value expression
              match p.parse_value() {
                Ok((value_expr, new_p)) => {
                  p = new_p

                  // Check for conditional filter
                  let filter = if p.check(If) {
                    match p.advance() {
                      Ok(new_p) => {
                        p = new_p
                        match p.parse_value() {
                          Ok((filter_expr, new_p)) => {
                            p = new_p
                            Some(filter_expr)
                          }
                          Err(e) => return Err(e)
                        }
                      }
                      Err(e) => return Err(e)
                    }
                  } else {
                    None
                  }

                  // Create object for expression
                  let for_obj = {
                    "type": String("for_object_expr"),
                    "key_var": String(vars[0]),
                    "value_var": String(vars[1]),
                    "collection": collection,
                    "key_expr": key_expr,
                    "value_expr": value_expr,
                    "filter": match filter {
                      Some(f) => f
                      None => Null
                    },
                  }

                  match p.expect(RBrace) {
                    Ok(final_p) => Ok((Object(for_obj), final_p))
                    Err(e) => Err(e)
                  }
                }
                Err(e) => Err(e)
              }
            }
            Err(e) => Err(e)
          }
        }
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse an object or object for expression
fn Parser::parse_object(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(LBrace) {
    Ok(start_parser) => {
      let mut parser = start_parser

      match parser.skip_newlines() {
        Ok(p) => parser = p
        Err(e) => return Err(e)
      }

      // Check for object for expression
      if parser.check(For) {
        // Parse for expression for object comprehension
        // This should be handled by parse_for_expr but we need to handle closing brace
        // Let's parse the for expression and expect RBrace at the end
        match parser.parse_for_expr_for_object() {
          Ok(result) => return Ok(result)
          Err(e) => return Err(e)
        }
      }

      // Regular object
      let obj = {}
      while !parser.check(RBrace) && !parser.check(EOF) {
        // Parse key
        let key = match parser.current {
          StringLit(s) => s
          Ident(s) => s
          _ => {
            let (line, col, offset) = parser.lexer.location()
            return Err(
              HCLError::parse_error_with_context(
                "Expected object key",
                line,
                col,
                offset,
                parser.lexer.get_line(line),
              ),
            )
          }
        }

        match parser.advance() {
          Ok(p) => parser = p
          Err(e) => return Err(e)
        }

        // Check for assignment operator
        if parser.check(Equals) {
          match parser.advance() {
            Ok(p) => parser = p
            Err(e) => return Err(e)
          }
        } else if parser.check(Colon) {
          match parser.advance() {
            Ok(p) => parser = p
            Err(e) => return Err(e)
          }
        } else {
          let (line, col, offset) = parser.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected '=' or ':'",
              line,
              col,
              offset,
              parser.lexer.get_line(line),
            ),
          )
        }

        // Parse value
        match parser.parse_value() {
          Ok((value, new_parser)) => {
            obj[key] = value
            parser = new_parser
          }
          Err(e) => return Err(e)
        }

        match parser.skip_newlines() {
          Ok(p) => parser = p
          Err(e) => return Err(e)
        }

        if parser.check(Comma) {
          match parser.advance() {
            Ok(p) => parser = p
            Err(e) => return Err(e)
          }
          match parser.skip_newlines() {
            Ok(p) => parser = p
            Err(e) => return Err(e)
          }
        } else if !parser.check(RBrace) {
          let (line, col, offset) = parser.lexer.location()
          return Err(
            HCLError::parse_error_with_context(
              "Expected ',' or '}'",
              line,
              col,
              offset,
              parser.lexer.get_line(line),
            ),
          )
        }
      }

      match parser.expect(RBrace) {
        Ok(parser) => Ok((Object(obj), parser))
        Err(e) => Err(e)
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Parse parenthesized expression
fn Parser::parse_paren_expr(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(LParen) {
    Ok(parser) =>
      match parser.parse_value() {
        Ok((value, parser)) =>
          match parser.expect(RParen) {
            Ok(parser) => Ok((value, parser))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// Parse negative number
fn Parser::parse_negative(self : Parser) -> HCLResult[(HCLValue, Parser)] {
  match self.expect(Minus) {
    Ok(parser) =>
      match parser.parse_value() {
        Ok((value, parser)) =>
          match value {
            Int(i) => Ok((Int(-i), parser))
            Float(f) => Ok((Float(-f), parser))
            _ => {
              let (line, col, offset) = parser.lexer.location()
              Err(
                HCLError::parse_error_with_context(
                  "Expected number after '-'",
                  line,
                  col,
                  offset,
                  parser.lexer.get_line(line),
                ),
              )
            }
          }
        Err(e) => Err(e)
      }
    Err(e) => Err(e)
  }
}

///|
/// Parse HCL string into Body
pub fn parse(input : String) -> HCLResult[Body] {
  match Parser::new(input) {
    Ok(parser) => parser.parse_body()
    Err(e) => Err(e)
  }
}

///|
/// Convert token to string for error messages
fn token_to_string(token : Token) -> String {
  match token {
    Ident(s) => s
    StringLit(s) => "\"" + s + "\""
    NumberLit(s) => s
    BoolLit(b) => if b { "true" } else { "false" }
    NullLit => "null"
    LBrace => "{"
    RBrace => "}"
    LBracket => "["
    RBracket => "]"
    LParen => "("
    RParen => ")"
    Equals => "="
    Comma => ","
    Dot => "."
    Plus => "+"
    Minus => "-"
    Star => "*"
    Slash => "/"
    Percent => "%"
    Bang => "!"
    Lt => "<"
    Gt => ">"
    LtEq => "<="
    GtEq => ">="
    EqEq => "=="
    BangEq => "!="
    AndAnd => "&&"
    OrOr => "||"
    Question => "?"
    Colon => ":"
    FatArrow => "=>"
    Heredoc(strip) => if strip { "<<-" } else { "<<" }
    HeredocLit(_, _, _) => "heredoc"
    Newline => "newline"
    EOF => "end of file"
    For => "for"
    In => "in"
    If => "if"
  }
}
