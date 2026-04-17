///|
/// TraversalBuilder whitebox tests
test "TraversalBuilder attr builds dot traversal" {
  let expr = ExprVariable({ name: "obj" })
  let traversal = TraversalBuilder::new(expr).attr("name").build()
  assert_true(traversal.operators.length() == 1)
  match traversal.operators[0] {
    Attr(name) => assert_true(name == "name")
    _ => panic()
  }
}

///|
test "TraversalBuilder index builds bracket traversal" {
  let expr = ExprVariable({ name: "items" })
  let traversal = TraversalBuilder::new(expr).index(ExprInt(0)).build()
  assert_true(traversal.operators.length() == 1)
  match traversal.operators[0] {
    Index(i) =>
      match i {
        ExprInt(v) => assert_true(v == 0)
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "TraversalBuilder chains attr and index" {
  let expr = ExprVariable({ name: "var" })
  let traversal = TraversalBuilder::new(expr)
    .attr("name")
    .index(ExprInt(0))
    .attr("sub")
    .build()
  assert_true(traversal.operators.length() == 3)
  match traversal.operators[0] {
    Attr(name) => assert_true(name == "name")
    _ => panic()
  }
  match traversal.operators[1] {
    Index(_) => ()
    _ => panic()
  }
  match traversal.operators[2] {
    Attr(name) => assert_true(name == "sub")
    _ => panic()
  }
}

///|
test "Traversal::builder factory method" {
  let traversal = Traversal::builder(ExprVariable({ name: "obj" }))
    .attr("key")
    .build()
  assert_true(traversal.operators.length() == 1)
  assert_true(traversal.base == ExprVariable({ name: "obj" }))
}

///|
test "TraversalBuilder expr_to_string config.db.host" {
  let traversal = TraversalBuilder::new(ExprVariable({ name: "config" }))
    .attr("db")
    .attr("host")
    .build()
  assert_true(expr_to_string(ExprTraversal(traversal)) == "config.db.host")
}

///|
test "TraversalBuilder expr_to_string var.name[0]" {
  let traversal = TraversalBuilder::new(ExprVariable({ name: "var" }))
    .attr("name")
    .index(ExprInt(0))
    .build()
  assert_true(expr_to_string(ExprTraversal(traversal)) == "var.name[0]")
}

///|
test "TraversalBuilder empty operators" {
  let expr = ExprVariable({ name: "x" })
  let traversal = TraversalBuilder::new(expr).build()
  assert_true(traversal.operators.is_empty())
  assert_true(traversal.base == ExprVariable({ name: "x" }))
}

///|
test "TraversalBuilder with string index" {
  let expr = ExprVariable({ name: "obj" })
  let traversal = TraversalBuilder::new(expr).index(ExprString("key")).build()
  assert_true(traversal.operators.length() == 1)
  match traversal.operators[0] {
    Index(i) =>
      match i {
        ExprString(s) => assert_true(s == "key")
        _ => panic()
      }
    _ => panic()
  }
}

///|
test "TraversalBuilder with variable index" {
  let expr = ExprVariable({ name: "arr" })
  let traversal = TraversalBuilder::new(expr)
    .index(ExprVariable({ name: "i" }))
    .build()
  assert_true(traversal.operators.length() == 1)
  match traversal.operators[0] {
    Index(_) => ()
    _ => panic()
  }
}

///|
test "TraversalBuilder multiple index access" {
  let traversal = TraversalBuilder::new(ExprVariable({ name: "matrix" }))
    .index(ExprInt(0))
    .index(ExprInt(1))
    .build()
  assert_true(traversal.operators.length() == 2)
  assert_true(expr_to_string(ExprTraversal(traversal)) == "matrix[0][1]")
}

///|
test "TraversalBuilder complex chain" {
  let traversal = TraversalBuilder::new(ExprVariable({ name: "var" }))
    .attr("list")
    .index(ExprInt(0))
    .attr("nested")
    .index(ExprString("key"))
    .build()
  assert_true(traversal.operators.length() == 4)
  assert_true(
    expr_to_string(ExprTraversal(traversal)) == "var.list[0].nested[\"key\"]",
  )
}

///|
test "Traversal equality" {
  let a = TraversalBuilder::new(ExprVariable({ name: "x" })).attr("y").build()
  let b = TraversalBuilder::new(ExprVariable({ name: "x" })).attr("y").build()
  assert_true(a == b)
}

///|
test "Traversal inequality" {
  let a = TraversalBuilder::new(ExprVariable({ name: "x" })).attr("y").build()
  let b = TraversalBuilder::new(ExprVariable({ name: "x" })).attr("z").build()
  assert_true(a != b)
}

///|
/// FuncCallBuilder whitebox tests
test "FuncCallBuilder basic no args" {
  let fc = FuncCallBuilder::new("empty").build()
  assert_true(fc.name == "empty")
  assert_true(fc.args.is_empty())
}

///|
test "FuncCallBuilder single arg" {
  let fc = FuncCallBuilder::new("negate").arg(ExprInt(42)).build()
  assert_true(fc.name == "negate")
  assert_true(fc.args.length() == 1)
  match fc.args[0] {
    ExprInt(v) => assert_true(v == 42)
    _ => panic()
  }
}

///|
test "FuncCallBuilder multiple args" {
  let fc = FuncCallBuilder::new("add").arg(ExprInt(1)).arg(ExprInt(2)).build()
  assert_true(fc.args.length() == 2)
}

///|
test "FuncCall::builder factory" {
  let fc = FuncCall::builder("length")
    .arg(ExprArray([ExprInt(1), ExprInt(2), ExprInt(3)]))
    .build()
  assert_true(fc.name == "length")
  assert_true(fc.args.length() == 1)
}

///|
test "FuncCallBuilder expr_to_string no args" {
  let fc = FuncCallBuilder::new("empty").build()
  assert_true(expr_to_string(ExprFuncCall(fc)) == "empty()")
}

///|
test "FuncCallBuilder expr_to_string one arg" {
  let fc = FuncCallBuilder::new("abs").arg(ExprInt(-5)).build()
  assert_true(expr_to_string(ExprFuncCall(fc)) == "abs(-5)")
}

///|
test "FuncCallBuilder expr_to_string two args" {
  let fc = FuncCallBuilder::new("max").arg(ExprInt(1)).arg(ExprInt(2)).build()
  assert_true(expr_to_string(ExprFuncCall(fc)) == "max(1, 2)")
}

///|
test "FuncCallBuilder with string args" {
  let fc = FuncCallBuilder::new("concat")
    .arg(ExprString("hello"))
    .arg(ExprString("world"))
    .build()
  assert_true(
    expr_to_string(ExprFuncCall(fc)) == "concat(\"hello\", \"world\")",
  )
}

///|
test "FuncCallBuilder with variable args" {
  let fc = FuncCallBuilder::new("merge")
    .arg(ExprVariable({ name: "obj1" }))
    .arg(ExprVariable({ name: "obj2" }))
    .build()
  assert_true(expr_to_string(ExprFuncCall(fc)) == "merge(obj1, obj2)")
}

///|
test "FuncCallBuilder nested function call" {
  let inner = FuncCallBuilder::new("inner").arg(ExprInt(1)).build()
  let outer = FuncCallBuilder::new("outer").arg(ExprFuncCall(inner)).build()
  assert_true(expr_to_string(ExprFuncCall(outer)) == "outer(inner(1))")
}

///|
test "FuncCall equality" {
  let a = FuncCall::builder("f").arg(ExprInt(1)).build()
  let b = FuncCall::builder("f").arg(ExprInt(1)).build()
  assert_true(a == b)
}

///|
test "FuncCall inequality" {
  let a = FuncCall::builder("f").arg(ExprInt(1)).build()
  let b = FuncCall::builder("g").arg(ExprInt(1)).build()
  assert_true(a != b)
}
