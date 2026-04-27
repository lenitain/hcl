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
} derive(Debug, Eq)

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
  /// Unknown value (Terraform plan-stage)
  ExprUnknown
} derive(Debug, Eq)

///|
/// Template expression (heredoc or interpolated string)
pub(all) enum TemplateExpr {
  /// Heredoc template
  Heredoc(Heredoc)
  /// Interpolated string template
  InterpolatedString(String)
} derive(Debug, Eq)

///|
/// Heredoc template
pub(all) struct Heredoc {
  /// Delimiter (e.g., "EOF")
  delimiter : String
  /// Template content
  content : String
  /// Strip indentation mode
  strip_mode : HeredocStripMode
} derive(Debug, Eq)

///|
/// Heredoc strip mode
pub(all) enum HeredocStripMode {
  /// No stripping
  NoStrip
  /// Strip leading whitespace (<<-EOF)
  StripMode
} derive(Debug, Eq)

///|
/// Variable reference
pub(all) struct Variable {
  /// Variable name
  name : String
} derive(Debug, Eq)

///|
/// Traversal (property/element access)
pub(all) struct Traversal {
  /// Base expression
  base : Expression
  /// Traversal operators
  operators : Array[TraversalOperator]
} derive(Debug, Eq)

///|
/// Traversal operator
pub(all) enum TraversalOperator {
  /// Attribute access (obj.attr)
  Attr(String)
  /// Index access (obj[index])
  Index(Expression)
  /// Splat access (obj.* or obj[*])
  Splat
} derive(Debug, Eq)

///|
/// Builder for constructing Traversal expressions incrementally
pub struct TraversalBuilder {
  base : Expression
  operators : Array[TraversalOperator]
}

///|
/// Create a new TraversalBuilder from a base expression
pub fn TraversalBuilder::new(base : Expression) -> TraversalBuilder {
  { base, operators: [] }
}

///|
/// Add an attribute access operator (.attr)
pub fn TraversalBuilder::attr(
  self : TraversalBuilder,
  name : String,
) -> TraversalBuilder {
  self.operators.push(Attr(name))
  self
}

///|
/// Add an index access operator ([expr])
pub fn TraversalBuilder::index(
  self : TraversalBuilder,
  expr : Expression,
) -> TraversalBuilder {
  self.operators.push(Index(expr))
  self
}

///|
/// Add a splat access operator (.*)
pub fn TraversalBuilder::splat(self : TraversalBuilder) -> TraversalBuilder {
  self.operators.push(Splat)
  self
}

///|
/// Build the Traversal expression
pub fn TraversalBuilder::build(self : TraversalBuilder) -> Traversal {
  { base: self.base, operators: self.operators }
}

///|
/// Create a TraversalBuilder starting from this Traversal
pub fn Traversal::builder(base : Expression) -> TraversalBuilder {
  TraversalBuilder::new(base)
}

///|
/// Function call
pub(all) struct FuncCall {
  /// Function name
  name : String
  /// Arguments
  args : Array[Expression]
} derive(Debug, Eq)

///|
/// Builder for constructing FuncCall expressions incrementally
pub struct FuncCallBuilder {
  name : String
  args : Array[Expression]
}

///|
/// Create a new FuncCallBuilder with a function name
pub fn FuncCallBuilder::new(name : String) -> FuncCallBuilder {
  { name, args: [] }
}

///|
/// Add an argument expression
pub fn FuncCallBuilder::arg(
  self : FuncCallBuilder,
  expr : Expression,
) -> FuncCallBuilder {
  self.args.push(expr)
  self
}

///|
/// Build the FuncCall expression
pub fn FuncCallBuilder::build(self : FuncCallBuilder) -> FuncCall {
  { name: self.name, args: self.args }
}

///|
/// Create a FuncCallBuilder for this function name
pub fn FuncCall::builder(name : String) -> FuncCallBuilder {
  FuncCallBuilder::new(name)
}

///|
/// Conditional expression (cond ? true_expr : false_expr)
pub(all) struct Conditional {
  /// Condition expression
  condition : Expression
  /// True branch expression
  true_expr : Expression
  /// False branch expression
  false_expr : Expression
} derive(Debug, Eq)

///|
/// Operation (binary or unary)
pub(all) enum Operation {
  /// Binary operation (left op right)
  Binary(BinaryOp)
  /// Unary operation (op operand)
  Unary(UnaryOp)
} derive(Debug, Eq)

///|
/// Binary operation
pub(all) struct BinaryOp {
  /// Left operand
  left : Expression
  /// Operator
  op : BinaryOperator
  /// Right operand
  right : Expression
} derive(Debug, Eq)

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
} derive(Debug, Eq)

///|
/// Unary operation
pub(all) struct UnaryOp {
  /// Operator
  op : UnaryOperator
  /// Operand
  operand : Expression
} derive(Debug, Eq)

///|
/// Unary operator
pub(all) enum UnaryOperator {
  /// Negation (-)
  Negate
  /// Logical NOT (!)
  Not
} derive(Debug, Eq)

///|
/// For expression (list/object comprehension)
pub(all) enum ForExpr {
  /// List comprehension: [for x in list: expr]
  List(ForListExpr)
  /// Object comprehension: {for k, v in obj: k => v}
  Object(ForObjectExpr)
} derive(Debug, Eq)

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
} derive(Debug, Eq)

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
} derive(Debug, Eq)

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
          Splat => result = result + ".*"
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
    ExprUnknown => "unknown"
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
/// Convert Expression to HCLValue (bridge for serializers)
pub fn expr_to_hcl_value(expr : Expression) -> HCLValue {
  match expr {
    ExprNull => Null(Decor::empty())
    ExprBool(b) => Bool(b, Decor::empty())
    ExprInt(i) => Number(Number::from_int(i), Decor::empty())
    ExprInt64(i) => Number(Number::from_int64(i), Decor::empty())
    ExprFloat(f) => Number(Number::from_finite_f64(f), Decor::empty())
    ExprString(s) => String(s, Decor::empty())
    ExprArray(arr) => {
      let items = arr.map(expr_to_hcl_value)
      Array(items, Decor::empty())
    }
    ExprObject(obj) => {
      let result = {}
      for pair in obj {
        let (k, v) = pair
        result[ObjectKey::to_string(k)] = expr_to_hcl_value(v)
      }
      Object(result, Decor::empty())
    }
    ExprUnknown => Unknown(Decor::empty())
    _ => String(expr_to_string(expr), Decor::empty())
  }
}

///|
/// Convert HCLValue to Expression
pub fn hcl_value_to_expression(value : HCLValue) -> Expression {
  match value {
    Null(_) => ExprNull
    Bool(b, _) => ExprBool(b)
    Number(n, _) =>
      match n.as_int() {
        Some(i) => ExprInt(i)
        None =>
          match n.as_int64() {
            Some(i64) => ExprInt64(i64)
            None => ExprFloat(n.as_float())
          }
      }
    String(s, _) => ExprString(s)
    Array(arr, _) => ExprArray(arr.map(hcl_value_to_expression))
    Object(obj, _) => {
      let pairs : ExprObject = []
      for k, v in obj {
        pairs.push((ObjectKey::Identifier(k), hcl_value_to_expression(v)))
      }
      ExprObject(pairs)
    }
    Unknown(_) => ExprUnknown
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

///|
/// Create Expression from Int
pub fn expr_int(v : Int) -> Expression {
  ExprInt(v)
}

///|
/// Create Expression from String
pub fn expr_str(v : String) -> Expression {
  ExprString(v)
}

///|
/// Create Expression from Bool
pub fn expr_bool(v : Bool) -> Expression {
  ExprBool(v)
}

///|
/// Null Expression
pub fn expr_null() -> Expression {
  ExprNull
}

///|
/// Create Expression array
pub fn expr_array(items : Array[Expression]) -> Expression {
  ExprArray(items)
}

///|
/// Create Expression from FuncCall
pub fn expr_func_call(fc : FuncCall) -> Expression {
  ExprFuncCall(fc)
}

///|
/// Unknown Expression (Terraform plan-stage)
pub fn expr_unknown() -> Expression {
  ExprUnknown
}
