///|
/// Tests for JSON to HCL Body parser
test "json_to_body primitive string" {
  let input = "{\"name\": \"John\"}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "name")
          match attr.get_value() {
            ExprString(s) => assert_eq(s, "John")
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body primitive int" {
  let input = "{\"age\": 30}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "age")
          match attr.get_value() {
            ExprInt(i) => assert_eq(i, 30)
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body primitive float" {
  let input = "{\"score\": 3.14}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "score")
          match attr.get_value() {
            ExprFloat(f) => assert_true(f > 3.13 && f < 3.15)
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body primitive bool" {
  let input = "{\"enabled\": true}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "enabled")
          match attr.get_value() {
            ExprBool(b) => assert_true(b)
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body primitive null" {
  let input = "{\"value\": null}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "value")
          match attr.get_value() {
            ExprNull => ()
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body object to block" {
  let input = "{\"server\": {\"host\": \"localhost\", \"port\": 8080}}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "server")
          assert_true(block.get_labels().is_empty())
          let inner = block.get_body().get_items()
          assert_eq(inner.length(), 2)
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body nested object to block with label" {
  let input = "{\"variable\": {\"region\": {\"default\": \"us-east-1\"}}}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "variable")
          let labels = block.get_labels()
          assert_eq(labels.length(), 1)
          assert_eq(labels[0], "region")
          let inner = block.get_body().get_items()
          assert_eq(inner.length(), 1)
          match inner[0] {
            Attribute(attr) => {
              assert_eq(attr.get_key(), "default")
              match attr.get_value() {
                ExprString(s) => assert_eq(s, "us-east-1")
                _ => panic()
              }
            }
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body array of objects to multiple blocks" {
  let input = "{\"rule\": [{\"action\": \"allow\"}, {\"action\": \"deny\"}]}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 2)
      match items[0] {
        Block(block) => assert_eq(block.get_type_name(), "rule")
        _ => panic()
      }
      match items[1] {
        Block(block) => assert_eq(block.get_type_name(), "rule")
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body array of primitives to attr" {
  let input = "{\"tags\": [\"web\", \"api\", \"prod\"]}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "tags")
          match attr.get_value() {
            ExprArray(arr) => assert_eq(arr.length(), 3)
            _ => panic()
          }
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body terraform tfvars style" {
  let input = "{\"variable\": {\"region\": {\"default\": \"us-east-1\", \"description\": \"AWS region\"}}}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "variable")
          let labels = block.get_labels()
          assert_eq(labels.length(), 1)
          assert_eq(labels[0], "region")
          let inner = block.get_body().get_items()
          assert_eq(inner.length(), 2)
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body error invalid json" {
  let input = "{invalid}"
  match json_to_body(input) {
    Ok(_) => panic()
    Err(e) => {
      let msg = e.message()
      assert_true(msg.contains("JSON parse error"))
    }
  }
}

///|
test "json_to_body error top-level not object" {
  let input = "[1, 2, 3]"
  match json_to_body(input) {
    Ok(_) => panic()
    Err(e) => {
      let msg = e.message()
      assert_true(msg.contains("top-level JSON must be an object"))
    }
  }
}

///|
test "json_to_hcl_string basic" {
  let input = "{\"name\": \"John\", \"age\": 30}"
  match json_to_hcl_string(input) {
    Ok(hcl) => {
      assert_true(hcl.contains("name = \"John\""))
      assert_true(hcl.contains("age = 30"))
    }
    Err(_) => panic()
  }
}

///|
test "json_to_hcl_string block" {
  let input = "{\"server\": {\"host\": \"localhost\"}}"
  match json_to_hcl_string(input) {
    Ok(hcl) => {
      assert_true(hcl.contains("server"))
      assert_true(hcl.contains("host"))
      assert_true(hcl.contains("localhost"))
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body empty object" {
  let input = "{}"
  match json_to_body(input) {
    Ok(body) => assert_true(body.is_empty())
    Err(_) => panic()
  }
}

///|
test "json_to_body string escape" {
  let input = "{\"msg\": \"hello\\nworld\"}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      match items[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprString(s) => assert_true(s.contains("\n"))
            _ => panic()
          }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body unicode escape" {
  let input = "{\"char\": \"\\u0041\"}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      match items[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprString(s) => assert_eq(s, "A")
            _ => panic()
          }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body negative number" {
  let input = "{\"val\": -42}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      match items[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprInt(i) => assert_eq(i, -42)
            _ => panic()
          }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body scientific notation" {
  let input = "{\"val\": 1.5e2}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      match items[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprFloat(f) => assert_true(f > 149.0 && f < 151.0)
            _ => panic()
          }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body multiple attributes and blocks" {
  let input = "{\"name\": \"test\", \"config\": {\"debug\": true}, \"tags\": [\"a\", \"b\"]}"
  match json_to_body(input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 3)
    }
    Err(_) => panic()
  }
}

///|
test "json round-trip: json_to_body then format_body" {
  let json_input = "{\"name\": \"John\", \"age\": 30, \"active\": true}"
  match json_to_body(json_input) {
    Ok(body) => {
      let hcl = format_body(body)
      match parse(hcl) {
        Ok(body2) => {
          let name = body2.find_attr("name")
          assert_true(name is Some(_))
        }
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json round-trip: block with label" {
  let json_input = "{\"variable\": {\"region\": {\"default\": \"us-east-1\"}}}"
  match json_to_body(json_input) {
    Ok(body) => {
      let hcl = format_body(body)
      match parse(hcl) {
        Ok(body2) => {
          let blocks = body2.find_blocks("variable")
          assert_eq(blocks.length(), 1)
          assert_eq(blocks[0].get_labels(), ["region"])
        }
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body deeply nested labels" {
  let json_input = "{\"a\": {\"b\": {\"c\": {\"d\": \"value\"}}}}"
  match json_to_body(json_input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "a")
          assert_eq(block.get_labels(), ["b", "c"])
          let inner = block.get_body().find_attr("d")
          assert_true(inner is Some(_))
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body empty array" {
  let json_input = "{\"items\": []}"
  match json_to_body(json_input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprArray(arr) => assert_eq(arr.length(), 0)
            _ => panic()
          }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body mixed array (not all objects)" {
  let json_input = "{\"data\": [1, \"two\", true, null]}"
  match json_to_body(json_input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 1)
      match items[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprArray(arr) => assert_eq(arr.length(), 4)
            _ => panic()
          }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "json_to_hcl_string resource block" {
  let json_input = "{\"resource\": {\"aws_instance\": {\"web\": {\"ami\": \"abc-123\", \"instance_type\": \"t2.micro\"}}}}"
  match json_to_hcl_string(json_input) {
    Ok(hcl) => {
      assert_true(hcl.contains("resource"))
      assert_true(hcl.contains("aws_instance"))
      assert_true(hcl.contains("web"))
      assert_true(hcl.contains("ami"))
      assert_true(hcl.contains("abc-123"))
    }
    Err(_) => panic()
  }
}

///|
test "json_to_body terraform full tfvars" {
  let json_input = "{\"instance_type\": \"t2.micro\", \"instance_count\": 3, \"tags\": {\"Name\": \"test\", \"Environment\": \"dev\"}}"
  match json_to_body(json_input) {
    Ok(body) => {
      let items = body.get_items()
      assert_eq(items.length(), 3)
      // instance_type is an attribute
      let it = body.find_attr("instance_type")
      assert_true(it is Some(_))
      // tags is a block (object value → block)
      let blocks = body.find_blocks("tags")
      assert_eq(blocks.length(), 1)
    }
    Err(_) => panic()
  }
}
