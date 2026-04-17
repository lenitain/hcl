///|
/// Simplify Tests - tests for the simplify_body function
test "simplify binary expressions" {
  let hcl = "sum = 1 + 2\nproduct = 3 * 4"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_eq(json, "{\"sum\":3,\"product\":12}")
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify comparison expressions" {
  let hcl = "lt = 1 < 2\ngt = 3 > 2\neq = 1 == 1"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_eq(json, "{\"lt\":true,\"gt\":true,\"eq\":true}")
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify conditional expressions" {
  let hcl = "result = true ? \"yes\" : \"no\""
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_eq(json, "{\"result\":\"yes\"}")
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify preserves non-constant expressions" {
  let hcl = "var = some_var\nsum = 1 + 2"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      // var should remain as variable reference, sum should be simplified
      assert_true(json.contains("\"sum\":3"))
      assert_true(json.contains("some_var"))
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify nested expressions" {
  let hcl = "nested = (1 + 2) * 3"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_eq(json, "{\"nested\":9}")
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify with blocks" {
  let hcl = "server {\n  port = 80 + 80\n}"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_true(json.contains("\"port\":160"))
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify unary expressions" {
  let hcl = "neg = -5\nnot = !true"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_true(json.contains("\"neg\":-5"))
      assert_true(json.contains("\"not\":false"))
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}

///|
test "simplify array expressions" {
  let hcl = "arr = [1 + 1, 2 * 2, 3 - 1]"
  match @hcl.parse(hcl) {
    Ok(body) => {
      let simplified = @hcl.simplify_body(body)
      let json = @hcl.body_to_json(simplified)
      assert_eq(json, "{\"arr\":[2,4,2]}")
    }
    Err(e) => abort("Parse error: " + e.message())
  }
}
