///|
/// HCL AST visitor - mutable traversal
/// Based on hcl-rs visit_mut.rs design

///|
/// Visitor trait for mutable traversal of HCL AST
pub(open) trait VisitMut {
  visit_body_mut(Self, Body) -> Unit
  visit_body_item_mut(Self, BodyItem) -> Unit
  visit_attr_mut(Self, Attr) -> Unit
  visit_block_mut(Self, Block) -> Unit
  visit_value_mut(Self, HCLValue) -> Unit
  visit_expr_mut(Self, Expression) -> Unit
  visit_object_key_mut(Self, ObjectKey) -> Unit
  visit_traversal_mut(Self, Traversal) -> Unit
  visit_traversal_operator_mut(Self, TraversalOperator) -> Unit
  visit_func_call_mut(Self, FuncCall) -> Unit
  visit_conditional_mut(Self, Conditional) -> Unit
  visit_operation_mut(Self, Operation) -> Unit
  visit_binary_op_mut(Self, BinaryOp) -> Unit
  visit_unary_op_mut(Self, UnaryOp) -> Unit
  visit_for_expr_mut(Self, ForExpr) -> Unit
  visit_template_expr_mut(Self, TemplateExpr) -> Unit
  visit_heredoc_mut(Self, Heredoc) -> Unit
  visit_decorated_expr_mut(Self, Decorated[Expression]) -> Unit
}

///|
/// Default body visitor mutably
pub fn[V : VisitMut] visit_body_mut_default(v : V, body : Body) -> Unit {
  for item in body.get_items() {
    v.visit_body_item_mut(item)
  }
}

///|
/// Default body item visitor mutably
pub fn[V : VisitMut] visit_body_item_mut_default(
  v : V,
  item : BodyItem,
) -> Unit {
  match item {
    Attribute(attr) => v.visit_attr_mut(attr)
    Block(block) => v.visit_block_mut(block)
  }
}

///|
/// Default attr visitor mutably
pub fn[V : VisitMut] visit_attr_mut_default(v : V, attr : Attr) -> Unit {
  v.visit_value_mut(attr.get_value())
}

///|
/// Default block visitor mutably
pub fn[V : VisitMut] visit_block_mut_default(v : V, block : Block) -> Unit {
  v.visit_body_mut(block.get_body())
}

///|
/// Default value visitor mutably
pub fn[V : VisitMut] visit_value_mut_default(v : V, value : HCLValue) -> Unit {
  match value {
    Null(_) => ()
    Bool(_, _) => ()
    Number(_, _) => ()
    String(_, _) => ()
    Array(arr, _) =>
      for elem in arr {
        v.visit_value_mut(elem)
      }
    Object(obj, _) =>
      for _k, val in obj {
        v.visit_value_mut(val)
      }
  }
}

///|
/// Default expression visitor mutably
pub fn[V : VisitMut] visit_expr_mut_default(v : V, expr : Expression) -> Unit {
  match expr {
    ExprNull => ()
    ExprBool(_) => ()
    ExprInt(_) => ()
    ExprInt64(_) => ()
    ExprFloat(_) => ()
    ExprString(_) => ()
    ExprArray(arr) =>
      for elem in arr {
        v.visit_expr_mut(elem)
      }
    ExprObject(obj) =>
      for pair in obj {
        let (key, val) = pair
        v.visit_object_key_mut(key)
        v.visit_expr_mut(val)
      }
    ExprTemplate(tmpl) => v.visit_template_expr_mut(tmpl)
    ExprVariable(_) => ()
    ExprTraversal(trav) => v.visit_traversal_mut(trav)
    ExprFuncCall(call) => v.visit_func_call_mut(call)
    ExprParenthesis(inner) => v.visit_expr_mut(inner)
    ExprConditional(cond) => v.visit_conditional_mut(cond)
    ExprOperation(op) => v.visit_operation_mut(op)
    ExprFor(for_expr) => v.visit_for_expr_mut(for_expr)
  }
}

///|
/// Default object key visitor mutably
pub fn[V : VisitMut] visit_object_key_mut_default(
  v : V,
  key : ObjectKey,
) -> Unit {
  match key {
    Identifier(_) => ()
    Expression(expr) => v.visit_expr_mut(expr)
  }
}

///|
/// Default traversal visitor mutably
pub fn[V : VisitMut] visit_traversal_mut_default(
  v : V,
  trav : Traversal,
) -> Unit {
  v.visit_expr_mut(trav.base)
  for op in trav.operators {
    v.visit_traversal_operator_mut(op)
  }
}

///|
/// Default traversal operator visitor mutably
pub fn[V : VisitMut] visit_traversal_operator_mut_default(
  v : V,
  op : TraversalOperator,
) -> Unit {
  match op {
    Attr(_) => ()
    Index(expr) => v.visit_expr_mut(expr)
  }
}

///|
/// Default function call visitor mutably
pub fn[V : VisitMut] visit_func_call_mut_default(
  v : V,
  call : FuncCall,
) -> Unit {
  for arg in call.args {
    v.visit_expr_mut(arg)
  }
}

///|
/// Default conditional visitor mutably
pub fn[V : VisitMut] visit_conditional_mut_default(
  v : V,
  cond : Conditional,
) -> Unit {
  v.visit_expr_mut(cond.condition)
  v.visit_expr_mut(cond.true_expr)
  v.visit_expr_mut(cond.false_expr)
}

///|
/// Default operation visitor mutably
pub fn[V : VisitMut] visit_operation_mut_default(v : V, op : Operation) -> Unit {
  match op {
    Binary(binop) => v.visit_binary_op_mut(binop)
    Unary(unop) => v.visit_unary_op_mut(unop)
  }
}

///|
/// Default binary op visitor mutably
pub fn[V : VisitMut] visit_binary_op_mut_default(
  v : V,
  binop : BinaryOp,
) -> Unit {
  v.visit_expr_mut(binop.left)
  v.visit_expr_mut(binop.right)
}

///|
/// Default unary op visitor mutably
pub fn[V : VisitMut] visit_unary_op_mut_default(v : V, unop : UnaryOp) -> Unit {
  v.visit_expr_mut(unop.operand)
}

///|
/// Default for expression visitor mutably
pub fn[V : VisitMut] visit_for_expr_mut_default(
  v : V,
  for_expr : ForExpr,
) -> Unit {
  match for_expr {
    List(list) => {
      v.visit_expr_mut(list.collection)
      v.visit_expr_mut(list.value_expr)
      match list.filter {
        Some(f) => v.visit_expr_mut(f)
        None => ()
      }
    }
    Object(obj) => {
      v.visit_expr_mut(obj.collection)
      v.visit_expr_mut(obj.key_expr)
      v.visit_expr_mut(obj.value_expr)
      match obj.filter {
        Some(f) => v.visit_expr_mut(f)
        None => ()
      }
    }
  }
}

///|
/// Default template expression visitor mutably
pub fn[V : VisitMut] visit_template_expr_mut_default(
  v : V,
  tmpl : TemplateExpr,
) -> Unit {
  match tmpl {
    Heredoc(h) => v.visit_heredoc_mut(h)
    InterpolatedString(_) => ()
  }
}

///|
/// Default heredoc visitor mutably (no-op)
pub fn[V : VisitMut] visit_heredoc_mut_default(
  _v : V,
  _heredoc : Heredoc,
) -> Unit {
  ()
}

///|
/// Default decorated expression visitor mutably
pub fn[V : VisitMut] visit_decorated_expr_mut_default(
  v : V,
  de : Decorated[Expression],
) -> Unit {
  v.visit_expr_mut(de.get_value())
}
