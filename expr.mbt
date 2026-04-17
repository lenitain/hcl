///|
/// HCL Expression types - represents the expression sub-language
/// Based on hcl-rs design: https://github.com/nickelchenwealth/hcl-rs

///|
/// Object key type - can be identifier or expression
pub(all) enum ObjectKey {
  /// Unquoted identifier used as object key
  Identifier(String)
  /// Any valid HCL expression can be an object key
  Expression(Expression)
} derive(Eq)

///|
/// Object type for expressions (preserves insertion order via array of pairs)
pub type ExprObject = Array[(ObjectKey, Expression)]

///|
/// Represents an HCL expression
pub(all) enum Expression {
  /// Null value
  ExprNull
  /// Boolean value
  ExprBool(Bool)
  /// Number (int)
  ExprInt(Int)
  /// 64-bit integer
  ExprInt64(Int64)
  /// Floating point number
  ExprFloat(Double)
  /// String without template interpolations
  ExprString(String)
  /// Array of expressions
  ExprArray(Array[Expression])
  /// Object (key-value pairs)
  ExprObject(ExprObject)
  /// Template expression (string with interpolations or heredoc)
  ExprTemplate(TemplateExpr)
  /// Variable reference
  ExprVariable(Variable)
  /// Property/element traversal
  ExprTraversal(Traversal)
  /// Function call
  ExprFuncCall(FuncCall)
  /// Parenthesized expression
  ExprParenthesis(Expression)
  /// Conditional expression (cond ? true_expr : false_expr)
  ExprConditional(Conditional)
  /// Binary or unary operation
  ExprOperation(Operation)
  /// For expression (list/object comprehension)
  ExprFor(ForExpr)
} derive(Eq)

///|
/// Template expression (heredoc or interpolated string)
pub(all) enum TemplateExpr {
  /// Heredoc template
  Heredoc(Heredoc)
  /// Interpolated string template
  InterpolatedString(String)
} derive(Eq)

///|
/// Heredoc template
pub(all) struct Heredoc {
  /// Delimiter (e.g., "EOF")
  delimiter : String
  /// Template content
  content : String
  /// Strip indentation mode
  strip_mode : HeredocStripMode
} derive(Eq)

///|
/// Heredoc strip mode
pub(all) enum HeredocStripMode {
  /// No stripping
  NoStrip
  /// Strip leading whitespace (<<-EOF)
  StripMode
} derive(Eq)

///|
/// Variable reference
pub(all) struct Variable {
  /// Variable name
  name : String
} derive(Eq)

///|
/// Traversal (property/element access)
pub(all) struct Traversal {
  /// Base expression
  base : Expression
  /// Traversal operators
  operators : Array[TraversalOperator]
} derive(Eq)

///|
/// Traversal operator
pub(all) enum TraversalOperator {
  /// Attribute access (obj.attr)
  Attr(String)
  /// Index access (obj[index])
  Index(Expression)
} derive(Eq)

///|
/// Function call
pub(all) struct FuncCall {
  /// Function name
  name : String
  /// Arguments
  args : Array[Expression]
} derive(Eq)

///|
/// Conditional expression (cond ? true_expr : false_expr)
pub(all) struct Conditional {
  /// Condition expression
  condition : Expression
  /// True branch expression
  true_expr : Expression
  /// False branch expression
  false_expr : Expression
} derive(Eq)

///|
/// Operation (binary or unary)
pub(all) enum Operation {
  /// Binary operation (left op right)
  Binary(BinaryOp)
  /// Unary operation (op operand)
  Unary(UnaryOp)
} derive(Eq)

///|
/// Binary operation
pub(all) struct BinaryOp {
  /// Left operand
  left : Expression
  /// Operator
  op : BinaryOperator
  /// Right operand
  right : Expression
} derive(Eq)

///|
/// Binary operator
pub(all) enum BinaryOperator {
  /// Addition (+)
  Plus
  /// Subtraction (-)
  Minus
  /// Multiplication (*)
  Mul
  /// Division (/)
  Div
  /// Modulo (%)
  Mod
  /// Equality (==)
  Eq
  /// Inequality (!=)
  Neq
  /// Less than (<)
  Lt
  /// Greater than (>)
  Gt
  /// Less than or equal (<=)
  Lte
  /// Greater than or equal (>=)
  Gte
  /// Logical AND (&&)
  And
  /// Logical OR (||)
  Or
} derive(Eq)

///|
/// Unary operation
pub(all) struct UnaryOp {
  /// Operator
  op : UnaryOperator
  /// Operand
  operand : Expression
} derive(Eq)

///|
/// Unary operator
pub(all) enum UnaryOperator {
  /// Negation (-)
  Negate
  /// Logical NOT (!)
  Not
} derive(Eq)

///|
/// For expression (list/object comprehension)
pub(all) enum ForExpr {
  /// List comprehension: [for x in list: expr]
  List(ForListExpr)
  /// Object comprehension: {for k, v in obj: k => v}
  Object(ForObjectExpr)
} derive(Eq)

///|
/// List comprehension
pub(all) struct ForListExpr {
  /// Loop variable name
  var_name : String
  /// Collection expression
  collection : Expression
  /// Value expression
  value_expr : Expression
  /// Optional filter expression
  filter : Expression?
} derive(Eq)

///|
/// Object comprehension
pub(all) struct ForObjectExpr {
  /// Key variable name
  key_var : String
  /// Value variable name
  value_var : String
  /// Collection expression
  collection : Expression
  /// Key expression
  key_expr : Expression
  /// Value expression
  value_expr : Expression
  /// Optional filter expression
  filter : Expression?
} derive(Eq)

///|
/// Convert ObjectKey to string representation
pub fn ObjectKey::to_string(self : ObjectKey) -> String {
  match self {
    Identifier(name) => name
    Expression(expr) => expr_to_string(expr)
  }
}

///|
/// Convert Expression to string representation
pub fn expr_to_string(expr : Expression) -> String {
  match expr {
    ExprNull => "null"
    ExprBool(b) => if b { "true" } else { "false" }
    ExprInt(i) => i.to_string()
    ExprInt64(i) => i.to_string()
    ExprFloat(f) => f.to_string()
    ExprString(s) => "\"" + s + "\""
    ExprArray(arr) => {
      let items = arr.map(expr_to_string)
      "[" + items.join(", ") + "]"
    }
    ExprObject(obj) =>
      if obj.is_empty() {
        "{}"
      } else {
        let items = obj.map(fn(pair) {
          let (k, v) = pair
          ObjectKey::to_string(k) + " = " + expr_to_string(v)
        })
        "{ " + items.join(", ") + " }"
      }
    ExprTemplate(_) => "<template>"
    ExprVariable(v) => v.name
    ExprTraversal(t) => {
      let mut result = expr_to_string(t.base)
      for op in t.operators {
        match op {
          Attr(name) => result = result + "." + name
          Index(idx) => result = result + "[" + expr_to_string(idx) + "]"
        }
      }
      result
    }
    ExprFuncCall(f) =>
      f.name + "(" + f.args.map(expr_to_string).join(", ") + ")"
    ExprParenthesis(e) => "(" + expr_to_string(e) + ")"
    ExprConditional(c) =>
      expr_to_string(c.condition) +
      " ? " +
      expr_to_string(c.true_expr) +
      " : " +
      expr_to_string(c.false_expr)
    ExprOperation(op) => op_to_string(op)
    ExprFor(f) => for_expr_to_string(f)
  }
}

///|
/// Convert Operation to string
fn op_to_string(op : Operation) -> String {
  match op {
    Binary(binop) => {
      let op_str = match binop.op {
        Plus => "+"
        Minus => "-"
        Mul => "*"
        Div => "/"
        Mod => "%"
        Eq => "=="
        Neq => "!="
        Lt => "<"
        Gt => ">"
        Lte => "<="
        Gte => ">="
        And => "&&"
        Or => "||"
      }
      expr_to_string(binop.left) +
      " " +
      op_str +
      " " +
      expr_to_string(binop.right)
    }
    Unary(uop) => {
      let op_str = match uop.op {
        Negate => "-"
        Not => "!"
      }
      op_str + expr_to_string(uop.operand)
    }
  }
}

///|
/// Convert ForExpr to string
fn for_expr_to_string(expr : ForExpr) -> String {
  match expr {
    List(list) => {
      let mut result = "[for " +
        list.var_name +
        " in " +
        expr_to_string(list.collection) +
        ": " +
        expr_to_string(list.value_expr)
      match list.filter {
        Some(f) => result = result + " if " + expr_to_string(f)
        None => ()
      }
      result + "]"
    }
    Object(obj) => {
      let mut result = "{for " +
        obj.key_var +
        ", " +
        obj.value_var +
        " in " +
        expr_to_string(obj.collection) +
        ": " +
        expr_to_string(obj.key_expr) +
        " => " +
        expr_to_string(obj.value_expr)
      match obj.filter {
        Some(f) => result = result + " if " + expr_to_string(f)
        None => ()
      }
      result + "}"
    }
  }
}
