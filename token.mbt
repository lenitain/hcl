///|
/// HCL Token types
pub(all) enum Token {
  Ident(String)
  StringLit(String)
  NumberLit(String)
  BoolLit(Bool)
  NullLit
  LBrace
  RBrace
  LBracket
  RBracket
  LParen
  RParen
  Equals
  Comma
  Dot
  Plus
  Minus
  Star
  Slash
  Percent
  Bang
  Lt
  Gt
  LtEq
  GtEq
  EqEq
  BangEq
  AndAnd
  OrOr
  Question
  Colon
  FatArrow
  Heredoc(Bool)
  HeredocLit(String, String, Bool)
  Newline
  EOF
  For
  In
  If
} derive(Debug, Eq)

///|
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
pub fn Token::is_literal(self : Token) -> Bool {
  match self {
    Ident(_) | StringLit(_) | NumberLit(_) | BoolLit(_) | NullLit => true
    _ => false
  }
}

///|
pub fn Token::is_delimiter(self : Token) -> Bool {
  match self {
    LBrace | RBrace | LBracket | RBracket | LParen | RParen => true
    _ => false
  }
}

///|
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
