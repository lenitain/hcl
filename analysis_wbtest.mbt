///|
/// Whitebox tests for static analysis API - direct expression construction

///|
test "collect_variables_from_expr_direct" {
  let var_expr = ExprVariable({ name: "myvar" })
  let vars = collect_variables_from_expr(var_expr)
  assert_eq(vars.length(), 1)
  assert_eq(vars[0], "myvar")
}

///|
test "collect_functions_from_expr_direct" {
  let call = FuncCall::builder("strlen").arg(ExprString("hello")).build()
  let func_expr = ExprFuncCall(call)
  let funcs = collect_functions_from_expr(func_expr)
  assert_eq(funcs.length(), 1)
  assert_eq(funcs[0], "strlen")
}

///|
test "collect_traversals_from_expr_direct" {
  let trav = Traversal::builder(ExprVariable({ name: "base" }))
    .attr("field")
    .build()
  let trav_expr = ExprTraversal(trav)
  let travs = collect_traversals_from_expr(trav_expr)
  assert_eq(travs.length(), 1)
  assert_eq(travs[0], "base")
}

///|
test "collect_variables_from_binary_op" {
  let left = ExprVariable({ name: "x" })
  let right = ExprVariable({ name: "y" })
  let binop = BinaryOp::{ left, op: Plus, right }
  let expr = ExprOperation(Binary(binop))
  let vars = collect_variables_from_expr(expr)
  assert_eq(vars.length(), 2)
  assert_eq(vars[0], "x")
  assert_eq(vars[1], "y")
}

///|
test "collect_functions_nested_expr" {
  let inner_call = FuncCall::builder("inner").arg(ExprInt(1)).build()
  let outer_call = FuncCall::builder("outer")
    .arg(ExprFuncCall(inner_call))
    .build()
  let expr = ExprFuncCall(outer_call)
  let funcs = collect_functions_from_expr(expr)
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0], "inner")
  assert_eq(funcs[1], "outer")
}

///|
test "collect_traversals_from_array" {
  let trav1 = Traversal::builder(ExprVariable({ name: "a" })).attr("x").build()
  let trav2 = Traversal::builder(ExprVariable({ name: "b" })).attr("y").build()
  let arr = ExprArray([ExprTraversal(trav1), ExprTraversal(trav2)])
  let travs = collect_traversals_from_expr(arr)
  assert_eq(travs.length(), 2)
  assert_eq(travs[0], "a")
  assert_eq(travs[1], "b")
}
