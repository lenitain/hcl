///|
/// Tests for static analysis API

///|
test "collect_variables_simple" {
  let body = parse("a = x\nb = y").unwrap()
  let vars = collect_variables(body)
  assert_eq(vars.length(), 2)
  assert_eq(vars[0], "x")
  assert_eq(vars[1], "y")
}

///|
test "collect_variables_nested" {
  let body = parse("outer {\n  inner = a\n  nested {\n    val = b\n  }\n}").unwrap()
  let vars = collect_variables(body)
  assert_eq(vars.length(), 2)
  assert_eq(vars[0], "a")
  assert_eq(vars[1], "b")
}

///|
test "collect_functions" {
  let body = parse("a = upper(\"x\")\nb = lower(\"y\")\nc = upper(\"z\")").unwrap()
  let funcs = collect_functions(body)
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0], "lower")
  assert_eq(funcs[1], "upper")
}

///|
test "collect_traversals" {
  let body = parse("a = obj.key1\nb = obj.key2\nc = other.attr").unwrap()
  let travs = collect_traversals(body)
  assert_eq(travs.length(), 2)
  assert_eq(travs[0], "obj")
  assert_eq(travs[1], "other")
}

///|
test "collect_from_expr" {
  let body = parse("a = myvar").unwrap()
  let item = body.get_items()[0]
  let expr = match item {
    Attribute(attr) => attr.get_value()
    _ => panic()
  }
  let vars = collect_variables_from_expr(expr)
  assert_eq(vars.length(), 1)
  assert_eq(vars[0], "myvar")

  let body2 = parse("a = strlen(\"hello\")").unwrap()
  let item2 = body2.get_items()[0]
  let expr2 = match item2 {
    Attribute(attr) => attr.get_value()
    _ => panic()
  }
  let funcs = collect_functions_from_expr(expr2)
  assert_eq(funcs.length(), 1)
  assert_eq(funcs[0], "strlen")

  let body3 = parse("a = base.field").unwrap()
  let item3 = body3.get_items()[0]
  let expr3 = match item3 {
    Attribute(attr) => attr.get_value()
    _ => panic()
  }
  let travs = collect_traversals_from_expr(expr3)
  assert_eq(travs.length(), 1)
  assert_eq(travs[0], "base")
}

///|
test "no_duplicates" {
  let body = parse("a = x\nb = x\nc = x").unwrap()
  let vars = collect_variables(body)
  assert_eq(vars.length(), 1)
  assert_eq(vars[0], "x")

  let body2 = parse("a = upper(\"a\")\nb = upper(\"b\")\nc = upper(\"c\")").unwrap()
  let funcs = collect_functions(body2)
  assert_eq(funcs.length(), 1)
  assert_eq(funcs[0], "upper")
}

///|
test "empty_body" {
  let body = Body::new()
  assert_eq(collect_variables(body).length(), 0)
  let body2 = Body::new()
  assert_eq(collect_functions(body2).length(), 0)
  let body3 = Body::new()
  assert_eq(collect_traversals(body3).length(), 0)
}

///|
test "nested_function_calls" {
  let body = parse("a = upper(lower(\"x\"))").unwrap()
  let funcs = collect_functions(body)
  assert_eq(funcs.length(), 2)
  assert_eq(funcs[0], "lower")
  assert_eq(funcs[1], "upper")
}

///|
test "mixed_analysis" {
  let body = parse(
    "name = upper(first)\naddr = obj.street\ncount = length(items)",
  ).unwrap()
  let vars = collect_variables(body)
  assert_eq(vars.length(), 3)
  assert_true(vars.contains("first"))
  assert_true(vars.contains("items"))
  assert_true(vars.contains("obj"))

  let funcs = collect_functions(body)
  assert_eq(funcs.length(), 2)
  assert_true(funcs.contains("length"))
  assert_true(funcs.contains("upper"))

  let travs = collect_traversals(body)
  assert_eq(travs.length(), 1)
  assert_true(travs.contains("obj"))
}
