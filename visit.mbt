///|
/// HCL AST visitor - immutable traversal
/// Based on hcl-rs visit.rs design
///
/// Design: Visit trait defines leaf handlers. Helper functions implement
/// default recursive traversal. Users can override any visit method.

///|
/// Visitor trait for immutable traversal of HCL AST
/// Users implement this to customize behavior when visiting AST nodes.
pub(open) trait Visit {
  visit_body(Self, Body) -> Unit
  visit_body_item(Self, BodyItem) -> Unit
  visit_attr(Self, Attr) -> Unit
  visit_block(Self, Block) -> Unit
  visit_value(Self, HCLValue) -> Unit
  visit_expr(Self, Expression) -> Unit
  visit_object_key(Self, ObjectKey) -> Unit
  visit_traversal(Self, Traversal) -> Unit
  visit_traversal_operator(Self, TraversalOperator) -> Unit
  visit_func_call(Self, FuncCall) -> Unit
  visit_conditional(Self, Conditional) -> Unit
  visit_operation(Self, Operation) -> Unit
  visit_binary_op(Self, BinaryOp) -> Unit
  visit_unary_op(Self, UnaryOp) -> Unit
  visit_for_expr(Self, ForExpr) -> Unit
  visit_template_expr(Self, TemplateExpr) -> Unit
  visit_heredoc(Self, Heredoc) -> Unit
  visit_decorated_expr(Self, Decorated[Expression]) -> Unit
}

///|
/// Default body visitor - iterates over all items
pub fn[V : Visit] visit_body_default(v : V, body : Body) -> Unit {
  for item in body.get_items() {
    v.visit_body_item(item)
  }
}

///|
/// Default body item visitor - dispatches to attr or block
pub fn[V : Visit] visit_body_item_default(v : V, item : BodyItem) -> Unit {
  match item {
    Attribute(attr) => v.visit_attr(attr)
    Block(block) => v.visit_block(block)
  }
}

///|
/// Default attr visitor - visits value
pub fn[V : Visit] visit_attr_default(v : V, attr : Attr) -> Unit {
  v.visit_expr(attr.get_value())
}

///|
/// Default block visitor - visits body
pub fn[V : Visit] visit_block_default(v : V, block : Block) -> Unit {
  v.visit_body(block.get_body())
}

///|
/// Default value visitor - dispatches based on variant
pub fn[V : Visit] visit_value_default(v : V, value : HCLValue) -> Unit {
  match value {
    Null(_) => ()
    Bool(_, _) => ()
    Number(_, _) => ()
    String(_, _) => ()
    Array(arr, _) =>
      for elem in arr {
        v.visit_value(elem)
      }
    Object(obj, _) =>
      for _k, val in obj {
        v.visit_value(val)
      }
    Unknown(_) => ()
  }
}

///|
/// Default expression visitor - dispatches based on variant
pub fn[V : Visit] visit_expr_default(v : V, expr : Expression) -> Unit {
  match expr {
    ExprNull => ()
    ExprBool(_) => ()
    ExprInt(_) => ()
    ExprInt64(_) => ()
    ExprFloat(_) => ()
    ExprString(_) => ()
    ExprArray(arr) =>
      for elem in arr {
        v.visit_expr(elem)
      }
    ExprObject(obj) =>
      for pair in obj {
        let (key, val) = pair
        v.visit_object_key(key)
        v.visit_expr(val)
      }
    ExprTemplate(tmpl) => v.visit_template_expr(tmpl)
    ExprVariable(_) => ()
    ExprTraversal(trav) => v.visit_traversal(trav)
    ExprFuncCall(call) => v.visit_func_call(call)
    ExprParenthesis(inner) => v.visit_expr(inner)
    ExprConditional(cond) => v.visit_conditional(cond)
    ExprOperation(op) => v.visit_operation(op)
    ExprFor(for_expr) => v.visit_for_expr(for_expr)
    ExprUnknown => ()
  }
}

///|
/// Default object key visitor
pub fn[V : Visit] visit_object_key_default(v : V, key : ObjectKey) -> Unit {
  match key {
    Identifier(_) => ()
    Expression(expr) => v.visit_expr(expr)
  }
}

///|
/// Default traversal visitor
pub fn[V : Visit] visit_traversal_default(v : V, trav : Traversal) -> Unit {
  v.visit_expr(trav.base)
  for op in trav.operators {
    v.visit_traversal_operator(op)
  }
}

///|
/// Default traversal operator visitor
pub fn[V : Visit] visit_traversal_operator_default(
  v : V,
  op : TraversalOperator,
) -> Unit {
  match op {
    Attr(_) => ()
    Index(expr) => v.visit_expr(expr)
    Splat => ()
  }
}

///|
/// Default function call visitor
pub fn[V : Visit] visit_func_call_default(v : V, call : FuncCall) -> Unit {
  for arg in call.args {
    v.visit_expr(arg)
  }
}

///|
/// Default conditional visitor
pub fn[V : Visit] visit_conditional_default(v : V, cond : Conditional) -> Unit {
  v.visit_expr(cond.condition)
  v.visit_expr(cond.true_expr)
  v.visit_expr(cond.false_expr)
}

///|
/// Default operation visitor
pub fn[V : Visit] visit_operation_default(v : V, op : Operation) -> Unit {
  match op {
    Binary(binop) => v.visit_binary_op(binop)
    Unary(unop) => v.visit_unary_op(unop)
  }
}

///|
/// Default binary op visitor
pub fn[V : Visit] visit_binary_op_default(v : V, binop : BinaryOp) -> Unit {
  v.visit_expr(binop.left)
  v.visit_expr(binop.right)
}

///|
/// Default unary op visitor
pub fn[V : Visit] visit_unary_op_default(v : V, unop : UnaryOp) -> Unit {
  v.visit_expr(unop.operand)
}

///|
/// Default for expression visitor
pub fn[V : Visit] visit_for_expr_default(v : V, for_expr : ForExpr) -> Unit {
  match for_expr {
    List(list) => {
      v.visit_expr(list.collection)
      v.visit_expr(list.value_expr)
      match list.filter {
        Some(f) => v.visit_expr(f)
        None => ()
      }
    }
    Object(obj) => {
      v.visit_expr(obj.collection)
      v.visit_expr(obj.key_expr)
      v.visit_expr(obj.value_expr)
      match obj.filter {
        Some(f) => v.visit_expr(f)
        None => ()
      }
    }
  }
}

///|
/// Default template expression visitor
pub fn[V : Visit] visit_template_expr_default(
  v : V,
  tmpl : TemplateExpr,
) -> Unit {
  match tmpl {
    Heredoc(h) => v.visit_heredoc(h)
    InterpolatedString(_) => ()
  }
}

///|
/// Default heredoc visitor (no-op)
pub fn[V] visit_heredoc_default(_v : V, _heredoc : Heredoc) -> Unit {
  ()
}

///|
/// Default decorated expression visitor
pub fn[V : Visit] visit_decorated_expr_default(
  v : V,
  de : Decorated[Expression],
) -> Unit {
  v.visit_expr(de.get_value())
}
