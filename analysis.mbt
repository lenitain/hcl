///|
/// Static analysis API for HCL ASTs
/// Collects information from expressions and bodies without evaluating them.

///|
/// Helper: add to array if not already present
fn add_unique(arr : Array[String], name : String) -> Unit {
  if !arr.contains(name) {
    arr.push(name)
  }
}

///|
/// Helper: sort array of strings (selection sort for determinism)
fn sort_strings(arr : Array[String]) -> Array[String] {
  let result = arr.copy()
  let n = result.length()
  for i = 0; i < n - 1; i = i + 1 {
    let mut min_idx = i
    for j = i + 1; j < n; j = j + 1 {
      if result[j] < result[min_idx] {
        min_idx = j
      }
    }
    if min_idx != i {
      let tmp = result[i]
      result[i] = result[min_idx]
      result[min_idx] = tmp
    }
  }
  result
}

///|
/// Collector for variable names from ExprVariable nodes
priv struct VariableCollector {
  names : Array[String]
}

///|
impl Visit for VariableCollector with visit_body(self, body) {
  visit_body_default(self, body)
}

///|
impl Visit for VariableCollector with visit_body_item(self, item) {
  visit_body_item_default(self, item)
}

///|
impl Visit for VariableCollector with visit_attr(self, attr) {
  visit_attr_default(self, attr)
}

///|
impl Visit for VariableCollector with visit_block(self, block) {
  visit_block_default(self, block)
}

///|
impl Visit for VariableCollector with visit_value(self, value) {
  visit_value_default(self, value)
}

///|
impl Visit for VariableCollector with visit_expr(self, expr) {
  match expr {
    ExprVariable(v) => add_unique(self.names, v.name)
    _ => visit_expr_default(self, expr)
  }
}

///|
impl Visit for VariableCollector with visit_object_key(self, key) {
  visit_object_key_default(self, key)
}

///|
impl Visit for VariableCollector with visit_traversal(self, trav) {
  visit_traversal_default(self, trav)
}

///|
impl Visit for VariableCollector with visit_traversal_operator(self, op) {
  visit_traversal_operator_default(self, op)
}

///|
impl Visit for VariableCollector with visit_func_call(self, call) {
  visit_func_call_default(self, call)
}

///|
impl Visit for VariableCollector with visit_conditional(self, cond) {
  visit_conditional_default(self, cond)
}

///|
impl Visit for VariableCollector with visit_operation(self, op) {
  visit_operation_default(self, op)
}

///|
impl Visit for VariableCollector with visit_binary_op(self, binop) {
  visit_binary_op_default(self, binop)
}

///|
impl Visit for VariableCollector with visit_unary_op(self, unop) {
  visit_unary_op_default(self, unop)
}

///|
impl Visit for VariableCollector with visit_for_expr(self, for_expr) {
  visit_for_expr_default(self, for_expr)
}

///|
impl Visit for VariableCollector with visit_template_expr(self, tmpl) {
  visit_template_expr_default(self, tmpl)
}

///|
impl Visit for VariableCollector with visit_heredoc(self, heredoc) {
  visit_heredoc_default(self, heredoc)
}

///|
impl Visit for VariableCollector with visit_decorated_expr(self, de) {
  visit_decorated_expr_default(self, de)
}

///|
/// Collector for function names from ExprFuncCall nodes
priv struct FunctionCollector {
  names : Array[String]
}

///|
impl Visit for FunctionCollector with visit_body(self, body) {
  visit_body_default(self, body)
}

///|
impl Visit for FunctionCollector with visit_body_item(self, item) {
  visit_body_item_default(self, item)
}

///|
impl Visit for FunctionCollector with visit_attr(self, attr) {
  visit_attr_default(self, attr)
}

///|
impl Visit for FunctionCollector with visit_block(self, block) {
  visit_block_default(self, block)
}

///|
impl Visit for FunctionCollector with visit_value(self, value) {
  visit_value_default(self, value)
}

///|
impl Visit for FunctionCollector with visit_expr(self, expr) {
  match expr {
    ExprFuncCall(call) => {
      add_unique(self.names, call.name)
      for arg in call.args {
        self.visit_expr(arg)
      }
    }
    _ => visit_expr_default(self, expr)
  }
}

///|
impl Visit for FunctionCollector with visit_object_key(self, key) {
  visit_object_key_default(self, key)
}

///|
impl Visit for FunctionCollector with visit_traversal(self, trav) {
  visit_traversal_default(self, trav)
}

///|
impl Visit for FunctionCollector with visit_traversal_operator(self, op) {
  visit_traversal_operator_default(self, op)
}

///|
impl Visit for FunctionCollector with visit_func_call(self, call) {
  visit_func_call_default(self, call)
}

///|
impl Visit for FunctionCollector with visit_conditional(self, cond) {
  visit_conditional_default(self, cond)
}

///|
impl Visit for FunctionCollector with visit_operation(self, op) {
  visit_operation_default(self, op)
}

///|
impl Visit for FunctionCollector with visit_binary_op(self, binop) {
  visit_binary_op_default(self, binop)
}

///|
impl Visit for FunctionCollector with visit_unary_op(self, unop) {
  visit_unary_op_default(self, unop)
}

///|
impl Visit for FunctionCollector with visit_for_expr(self, for_expr) {
  visit_for_expr_default(self, for_expr)
}

///|
impl Visit for FunctionCollector with visit_template_expr(self, tmpl) {
  visit_template_expr_default(self, tmpl)
}

///|
impl Visit for FunctionCollector with visit_heredoc(self, heredoc) {
  visit_heredoc_default(self, heredoc)
}

///|
impl Visit for FunctionCollector with visit_decorated_expr(self, de) {
  visit_decorated_expr_default(self, de)
}

///|
/// Collector for traversal root variable names (from ExprTraversal where base is ExprVariable)
priv struct TraversalCollector {
  names : Array[String]
}

///|
impl Visit for TraversalCollector with visit_body(self, body) {
  visit_body_default(self, body)
}

///|
impl Visit for TraversalCollector with visit_body_item(self, item) {
  visit_body_item_default(self, item)
}

///|
impl Visit for TraversalCollector with visit_attr(self, attr) {
  visit_attr_default(self, attr)
}

///|
impl Visit for TraversalCollector with visit_block(self, block) {
  visit_block_default(self, block)
}

///|
impl Visit for TraversalCollector with visit_value(self, value) {
  visit_value_default(self, value)
}

///|
impl Visit for TraversalCollector with visit_expr(self, expr) {
  match expr {
    ExprTraversal(trav) =>
      match trav.base {
        ExprVariable(v) => add_unique(self.names, v.name)
        _ => visit_traversal_default(self, trav)
      }
    _ => visit_expr_default(self, expr)
  }
}

///|
impl Visit for TraversalCollector with visit_object_key(self, key) {
  visit_object_key_default(self, key)
}

///|
impl Visit for TraversalCollector with visit_traversal(self, trav) {
  visit_traversal_default(self, trav)
}

///|
impl Visit for TraversalCollector with visit_traversal_operator(self, op) {
  visit_traversal_operator_default(self, op)
}

///|
impl Visit for TraversalCollector with visit_func_call(self, call) {
  visit_func_call_default(self, call)
}

///|
impl Visit for TraversalCollector with visit_conditional(self, cond) {
  visit_conditional_default(self, cond)
}

///|
impl Visit for TraversalCollector with visit_operation(self, op) {
  visit_operation_default(self, op)
}

///|
impl Visit for TraversalCollector with visit_binary_op(self, binop) {
  visit_binary_op_default(self, binop)
}

///|
impl Visit for TraversalCollector with visit_unary_op(self, unop) {
  visit_unary_op_default(self, unop)
}

///|
impl Visit for TraversalCollector with visit_for_expr(self, for_expr) {
  visit_for_expr_default(self, for_expr)
}

///|
impl Visit for TraversalCollector with visit_template_expr(self, tmpl) {
  visit_template_expr_default(self, tmpl)
}

///|
impl Visit for TraversalCollector with visit_heredoc(self, heredoc) {
  visit_heredoc_default(self, heredoc)
}

///|
impl Visit for TraversalCollector with visit_decorated_expr(self, de) {
  visit_decorated_expr_default(self, de)
}

///|
/// Collect all unique variable names referenced in the body (from ExprVariable nodes)
pub fn collect_variables(body : Body) -> Array[String] {
  let collector : VariableCollector = { names: [] }
  Visit::visit_body(collector, body)
  sort_strings(collector.names)
}

///|
/// Collect all unique function names called in the body (from ExprFuncCall nodes)
pub fn collect_functions(body : Body) -> Array[String] {
  let collector : FunctionCollector = { names: [] }
  Visit::visit_body(collector, body)
  sort_strings(collector.names)
}

///|
/// Collect all unique traversal root variable names (from ExprTraversal where base is ExprVariable)
pub fn collect_traversals(body : Body) -> Array[String] {
  let collector : TraversalCollector = { names: [] }
  Visit::visit_body(collector, body)
  sort_strings(collector.names)
}

///|
/// Collect all unique variable names from a single expression
pub fn collect_variables_from_expr(expr : Expression) -> Array[String] {
  let collector : VariableCollector = { names: [] }
  collector.visit_expr(expr)
  sort_strings(collector.names)
}

///|
/// Collect all unique function names from a single expression
pub fn collect_functions_from_expr(expr : Expression) -> Array[String] {
  let collector : FunctionCollector = { names: [] }
  collector.visit_expr(expr)
  sort_strings(collector.names)
}

///|
/// Collect all unique traversal root variable names from a single expression
pub fn collect_traversals_from_expr(expr : Expression) -> Array[String] {
  let collector : TraversalCollector = { names: [] }
  collector.visit_expr(expr)
  sort_strings(collector.names)
}
