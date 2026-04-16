///|
/// HCL Token types
pub(all) enum Token {
  /// Identifier
  Ident(String)
  /// String literal
  StringLit(String)
  /// Number literal (as string for precision)
  NumberLit(String)
  /// Boolean literal
  BoolLit(Bool)
  /// Null literal
  NullLit
  /// Left brace `{`
  LBrace
  /// Right brace `}`
  RBrace
  /// Left bracket `[`
  LBracket
  /// Right bracket `]`
  RBracket
  /// Left parenthesis `(`
  LParen
  /// Right parenthesis `)`
  RParen
  /// Equals sign `=`
  Equals
  /// Comma `,`
  Comma
  /// Dot `.`
  Dot
  /// Plus `+`
  Plus
  /// Minus `-`
  Minus
  /// Star `*`
  Star
  /// Slash `/`
  Slash
  /// Percent `%`
  Percent
  /// Exclamation `!`
  Bang
  /// Less than `<`
  Lt
  /// Greater than `>`
  Gt
  /// Less than or equal `<=`
  LtEq
  /// Greater than or equal `>=`
  GtEq
  /// Equal `==`
  EqEq
  /// Not equal `!=`
  BangEq
  /// Logical and `&&`
  AndAnd
  /// Logical or `||`
  OrOr
  /// Question mark `?`
  Question
  /// Colon `:`
  Colon
  /// Heredoc start `<<` or `<<-`
  Heredoc(Bool)
  /// Newline
  Newline
  /// End of file
  EOF
} derive(Debug, Eq)

///|
/// Check if token is an operator
pub fn Token::is_operator(self : Token) -> Bool {
  match self {
    Plus
    | Minus
    | Star
    | Slash
    | Percent
    | Bang
    | Lt
    | Gt
    | LtEq
    | GtEq
    | EqEq
    | BangEq
    | AndAnd
    | OrOr
    | Question
    | Colon => true
    _ => false
  }
}

///|
/// Check if token is a literal
pub fn Token::is_literal(self : Token) -> Bool {
  match self {
    Ident(_) | StringLit(_) | NumberLit(_) | BoolLit(_) | NullLit => true
    _ => false
  }
}

///|
/// Check if token is a delimiter
pub fn Token::is_delimiter(self : Token) -> Bool {
  match self {
    LBrace | RBrace | LBracket | RBracket | LParen | RParen => true
    _ => false
  }
}

///|
/// Get operator precedence (higher number = higher precedence)
pub fn Token::precedence(self : Token) -> Int {
  match self {
    OrOr => 1
    AndAnd => 2
    EqEq | BangEq => 3
    Lt | Gt | LtEq | GtEq => 4
    Plus | Minus => 5
    Star | Slash | Percent => 6
    _ => 0
  }
}
