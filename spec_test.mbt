///|
/// Spec Tests - HCL compliance tests from hcl-rs specsuite

///|
/// Convert Body to HCLValue for evaluation.
/// Blocks with labels are nested: multiple blocks of same type
/// are grouped under type name with labels as keys.
fn body_to_value(body : Body) -> HCLValue {
  let result : Map[String, HCLValue] = {}
  let block_groups : Map[String, Map[String, HCLValue]] = {}

  for item in body.get_items() {
    match item {
      Attribute(attr) => result[attr.get_key()] = attr.get_value()
      Block(block) => {
        let labels = block.get_labels()
        let block_value = body_to_value(block.get_body())
        if labels.length() > 0 {
          let type_name = block.get_type_name()
          let label = labels[0]
          match block_groups.get(type_name) {
            Some(group) => group[label] = block_value
            None => {
              let group : Map[String, HCLValue] = {}
              group[label] = block_value
              block_groups[type_name] = group
            }
          }
        } else {
          result[block.get_type_name()] = block_value
        }
      }
    }
  }

  for type_name, group in block_groups {
    result[type_name] = Object(group, Decor::empty())
  }

  Object(result, Decor::empty())
}

///|
/// Parse HCL, convert body to value, and evaluate expressions
fn eval_body(input : String) -> HCLResult[HCLValue] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      eval_expr(value, {}, builtin_functions())
    }
    Err(e) => Err(e)
  }
}

///|
/// Spec test: operators - equality
test "spec operators equality" {
  let input = "equality \"==\" {\n  exactly = \"a\" == \"a\"\n  not     = \"a\" == \"b\"\n  type_mismatch_number = \"1\" == 1\n  type_mismatch_bool   = \"true\" == true\n}\n\nequality \"!=\" {\n  exactly = \"a\" != \"a\"\n  not     = \"a\" != \"b\"\n  type_mismatch_number = \"1\" != 1\n  type_mismatch_bool   = \"true\" != true\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let eq = obj.get("equality").unwrap()
          match eq {
            Object(eq_obj, _) => {
              let eq_eq = eq_obj.get("==").unwrap()
              match eq_eq {
                Object(m, _) => {
                  assert_true(
                    m.get("exactly").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("not").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("type_mismatch_number").unwrap() ==
                    Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("type_mismatch_bool").unwrap() ==
                    Bool(false, Decor::empty()),
                  )
                }
                _ => panic()
              }
              let neq = eq_obj.get("!=").unwrap()
              match neq {
                Object(m, _) => {
                  assert_true(
                    m.get("exactly").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("not").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("type_mismatch_number").unwrap() ==
                    Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("type_mismatch_bool").unwrap() ==
                    Bool(true, Decor::empty()),
                  )
                }
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
/// Spec test: operators - inequality
test "spec operators inequality" {
  let input = "inequality \"<\" {\n  lt = 1 < 2\n  gt = 2 < 1\n  eq = 1 < 1\n}\n\ninequality \"<=\" {\n  lt = 1 <= 2\n  gt = 2 <= 1\n  eq = 1 <= 1\n}\n\ninequality \">\" {\n  lt = 1 > 2\n  gt = 2 > 1\n  eq = 1 > 1\n}\n\ninequality \">=\" {\n  lt = 1 >= 2\n  gt = 2 >= 1\n  eq = 1 >= 1\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let ineq = obj.get("inequality").unwrap()
          match ineq {
            Object(ineq_obj, _) => {
              let lt_val = ineq_obj.get("<").unwrap()
              match lt_val {
                Object(m, _) => {
                  assert_true(
                    m.get("lt").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("gt").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("eq").unwrap() == Bool(false, Decor::empty()),
                  )
                }
                _ => panic()
              }
              let lte_val = ineq_obj.get("<=").unwrap()
              match lte_val {
                Object(m, _) => {
                  assert_true(
                    m.get("lt").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("gt").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("eq").unwrap() == Bool(true, Decor::empty()),
                  )
                }
                _ => panic()
              }
              let gt_val = ineq_obj.get(">").unwrap()
              match gt_val {
                Object(m, _) => {
                  assert_true(
                    m.get("lt").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("gt").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("eq").unwrap() == Bool(false, Decor::empty()),
                  )
                }
                _ => panic()
              }
              let gte_val = ineq_obj.get(">=").unwrap()
              match gte_val {
                Object(m, _) => {
                  assert_true(
                    m.get("lt").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("gt").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("eq").unwrap() == Bool(true, Decor::empty()),
                  )
                }
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
/// Spec test: operators - arithmetic
test "spec operators arithmetic" {
  let input = "arithmetic {\n  add      = 2 + 3.5\n  add_big  = 3.14159265358979323846264338327950288419716939937510582097494459 + 1\n  sub      = 3.5 - 2\n  sub_neg  = 2 - 3.5\n  mul      = 2 * 4.5\n  div      = 1 / 10\n  mod      = 11 % 5\n  mod_frac = 11 % 5.1\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let arith = obj.get("arithmetic").unwrap()
          match arith {
            Object(m, _) => {
              assert_true(
                m.get("add").unwrap() ==
                Number(Number::from_finite_f64(5.5), Decor::empty()),
              )
              assert_true(
                m.get("sub").unwrap() ==
                Number(Number::from_finite_f64(1.5), Decor::empty()),
              )
              assert_true(
                m.get("sub_neg").unwrap() ==
                Number(Number::from_finite_f64(-1.5), Decor::empty()),
              )
              assert_true(
                m.get("mul").unwrap() ==
                Number(Number::from_finite_f64(9.0), Decor::empty()),
              )
              assert_true(
                m.get("mod").unwrap() ==
                Number(Number::from_int(1), Decor::empty()),
              )
              match m.get("add_big").unwrap() {
                Number(n, _) =>
                  assert_true(n.as_float() > 4.0 && n.as_float() < 5.0)
                _ => panic()
              }
              match m.get("div").unwrap() {
                Number(n, _) =>
                  assert_true(n.as_float() > 0.09 && n.as_float() < 0.11)
                _ => panic()
              }
              match m.get("mod_frac").unwrap() {
                Number(n, _) =>
                  assert_true(n.as_float() > 0.7 && n.as_float() < 0.9)
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
/// Spec test: operators - logical binary
test "spec operators logical binary" {
  let input = "logical_binary \"&&\" {\n  tt = true && true\n  ft = false && true\n  tf = true && false\n  ff = false && false\n}\n\nlogical_binary \"||\" {\n  tt = true || true\n  ft = false || true\n  tf = true || false\n  ff = false || false\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let log_bin = obj.get("logical_binary").unwrap()
          match log_bin {
            Object(log_bin_obj, _) => {
              let and_val = log_bin_obj.get("&&").unwrap()
              match and_val {
                Object(m, _) => {
                  assert_true(
                    m.get("tt").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("ft").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("tf").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(
                    m.get("ff").unwrap() == Bool(false, Decor::empty()),
                  )
                }
                _ => panic()
              }
              let or_val = log_bin_obj.get("||").unwrap()
              match or_val {
                Object(m, _) => {
                  assert_true(
                    m.get("tt").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("ft").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("tf").unwrap() == Bool(true, Decor::empty()),
                  )
                  assert_true(
                    m.get("ff").unwrap() == Bool(false, Decor::empty()),
                  )
                }
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
/// Spec test: operators - logical unary and conditional
test "spec operators conditional" {
  let input = "logical_unary \"!\" {\n  t = !true\n  f = !false\n}\n\nconditional \"regular\" {\n  t = true ? \"a\" : \"b\"\n  f = false ? \"a\" : \"b\"\n}\n\nconditional \"newline\" {\n  t = [\n    true\n    ? \"a\"\n    : \"b\"\n  ]\n  f = [\n    false\n    ? \"a\"\n    : \"b\"\n  ]\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let log_un = obj.get("logical_unary").unwrap()
          match log_un {
            Object(log_un_obj, _) => {
              let not_val = log_un_obj.get("!").unwrap()
              match not_val {
                Object(m, _) => {
                  assert_true(
                    m.get("t").unwrap() == Bool(false, Decor::empty()),
                  )
                  assert_true(m.get("f").unwrap() == Bool(true, Decor::empty()))
                }
                _ => panic()
              }
            }
            _ => panic()
          }
          let cond = obj.get("conditional").unwrap()
          match cond {
            Object(cond_obj, _) => {
              let reg = cond_obj.get("regular").unwrap()
              match reg {
                Object(m, _) => {
                  assert_true(
                    m.get("t").unwrap() == String("a", Decor::empty()),
                  )
                  assert_true(
                    m.get("f").unwrap() == String("b", Decor::empty()),
                  )
                }
                _ => panic()
              }
              let nl = cond_obj.get("newline").unwrap()
              match nl {
                Object(m, _) => {
                  assert_true(
                    m.get("t").unwrap() ==
                    Array([String("a", Decor::empty())], Decor::empty()),
                  )
                  assert_true(
                    m.get("f").unwrap() ==
                    Array([String("b", Decor::empty())], Decor::empty()),
                  )
                }
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
/// Spec test: heredoc basic (non-strip)
test "spec heredoc normal" {
  let input = "normal {\n  basic = <<EOT\nFoo\nBar\nBaz\nEOT\n\n  indented = <<EOT\n    Foo\n    Bar\n    Baz\n  EOT\n\n  indented_more = <<EOT\n    Foo\n      Bar\n    Baz\n  EOT\n\n  newlines_between = <<EOT\nFoo\n\nBar\n\nBaz\nEOT\n\n  indented_newlines_between = <<EOT\n    Foo\n\n    Bar\n\n    Baz\n  EOT\n\n  marker_at_suffix = <<EOT\n    NOT EOT\n  EOT\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let normal = obj.get("normal").unwrap()
          match normal {
            Object(m, _) => {
              assert_true(
                m.get("basic").unwrap() ==
                String("Foo\nBar\nBaz\n", Decor::empty()),
              )
              assert_true(
                m.get("indented").unwrap() ==
                String("    Foo\n    Bar\n    Baz\n", Decor::empty()),
              )
              assert_true(
                m.get("indented_more").unwrap() ==
                String("    Foo\n      Bar\n    Baz\n", Decor::empty()),
              )
              assert_true(
                m.get("newlines_between").unwrap() ==
                String("Foo\n\nBar\n\nBaz\n", Decor::empty()),
              )
              assert_true(
                m.get("marker_at_suffix").unwrap() ==
                String("    NOT EOT\n", Decor::empty()),
              )
              match m.get("indented_newlines_between").unwrap() {
                String(s, _) => {
                  assert_true(s.contains("Foo"))
                  assert_true(s.contains("Bar"))
                  assert_true(s.contains("Baz"))
                }
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
/// Spec test: heredoc with indent strip
test "spec heredoc indent" {
  let input = "indent {\n  basic = <<-EOT\nFoo\nBar\nBaz\nEOT\n\n  indented = <<-EOT\n    Foo\n    Bar\n    Baz\n  EOT\n\n  indented_more = <<-EOT\n    Foo\n      Bar\n    Baz\n  EOT\n\n  indented_less = <<-EOT\n    Foo\n  Bar\n    Baz\n  EOT\n\n  newlines_between = <<-EOT\nFoo\n\nBar\n\nBaz\nEOT\n\n  indented_newlines_between = <<-EOT\n    Foo\n\n    Bar\n\n    Baz\n  EOT\n}"
  let result = eval_body(input)
  match result {
    Ok(value) =>
      match value {
        Object(obj, _) => {
          let indent = obj.get("indent").unwrap()
          match indent {
            Object(m, _) => {
              assert_true(
                m.get("basic").unwrap() ==
                String("Foo\nBar\nBaz\n", Decor::empty()),
              )
              assert_true(
                m.get("indented").unwrap() ==
                String("Foo\nBar\nBaz\n", Decor::empty()),
              )
              assert_true(
                m.get("indented_more").unwrap() ==
                String("Foo\n  Bar\nBaz\n", Decor::empty()),
              )
              assert_true(
                m.get("indented_less").unwrap() ==
                String("  Foo\nBar\n  Baz\n", Decor::empty()),
              )
              assert_true(
                m.get("newlines_between").unwrap() ==
                String("Foo\n\nBar\n\nBaz\n", Decor::empty()),
              )
              match m.get("indented_newlines_between").unwrap() {
                String(s, _) => {
                  assert_true(s.contains("Foo"))
                  assert_true(s.contains("Bar"))
                  assert_true(s.contains("Baz"))
                }
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}
