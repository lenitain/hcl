///|
/// Tests for HCL to JSON conversion
test "hcl_to_json basic attribute" {
  let input = "name = \"John\""
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"name\""))
      assert_true(json.contains("\"John\""))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json multiple attributes" {
  let input = "name = \"John\"\nage = 30"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"name\""))
      assert_true(json.contains("\"John\""))
      assert_true(json.contains("\"age\""))
      assert_true(json.contains("30"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json block" {
  let input = "server {\n  host = \"localhost\"\n  port = 8080\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"server\""))
      assert_true(json.contains("\"host\""))
      assert_true(json.contains("\"localhost\""))
      assert_true(json.contains("\"port\""))
      assert_true(json.contains("8080"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json nested blocks" {
  let input = "server {\n  config {\n    timeout = 30\n  }\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"server\""))
      assert_true(json.contains("\"config\""))
      assert_true(json.contains("\"timeout\""))
      assert_true(json.contains("30"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json array" {
  let input = "tags = [\"web\", \"api\"]"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"tags\""))
      assert_true(json.contains("[\"web\",\"api\"]"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json object" {
  let input = "metadata = { version = \"1.0\", author = \"test\" }"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"metadata\""))
      assert_true(json.contains("\"version\""))
      assert_true(json.contains("\"1.0\""))
      assert_true(json.contains("\"author\""))
      assert_true(json.contains("\"test\""))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json boolean values" {
  let input = "enabled = true\ndisabled = false"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"enabled\""))
      assert_true(json.contains("true"))
      assert_true(json.contains("\"disabled\""))
      assert_true(json.contains("false"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json null value" {
  let input = "value = null"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"value\""))
      assert_true(json.contains("null"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json number types" {
  let input = "int_val = 42\nfloat_val = 3.14"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"int_val\""))
      assert_true(json.contains("42"))
      assert_true(json.contains("\"float_val\""))
      assert_true(json.contains("3.14") || json.contains("3.140000"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json_pretty basic" {
  let input = "name = \"John\""
  let result = hcl_to_json_pretty(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"name\""))
      assert_true(json.contains("\"John\""))
      assert_true(json.contains("\n"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json_pretty nested" {
  let input = "server {\n  host = \"localhost\"\n}"
  let result = hcl_to_json_pretty(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"server\""))
      assert_true(json.contains("\"host\""))
      assert_true(json.contains("  "))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json string escaping" {
  let input = "message = \"Hello\\nWorld\""
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"message\""))
      assert_true(json.contains("Hello") && json.contains("World"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json complex nested structure" {
  let input = "server {\n  config {\n    options = [\"opt1\", \"opt2\"]\n  }\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"server\""))
      assert_true(json.contains("\"config\""))
      assert_true(json.contains("\"options\""))
      assert_true(json.contains("[\"opt1\",\"opt2\"]"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json error handling" {
  let input = "name = "
  let result = hcl_to_json(input)
  match result {
    Ok(_) => panic()
    Err(e) => {
      let msg = e.message()
      assert_true(msg.contains("Parse error"))
    }
  }
}

///|
test "hcl_to_json empty input" {
  let input = ""
  let result = hcl_to_json(input)
  match result {
    Ok(json) => assert_eq(json, "{}")
    Err(_) => panic()
  }
}

///|
test "hcl_to_json only whitespace" {
  let input = "   \n  \n  "
  let result = hcl_to_json(input)
  match result {
    Ok(json) => assert_eq(json, "{}")
    Err(_) => panic()
  }
}

///|
test "hcl_to_json block with single label nests" {
  let input = "resource \"aws_instance\" {\n  ami = \"abc\"\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) =>
      assert_eq(json, "{\"resource\":{\"aws_instance\":{\"ami\":\"abc\"}}}")
    Err(_) => panic()
  }
}

///|
test "hcl_to_json block with multiple labels nests deeply" {
  let input = "resource \"aws_instance\" \"web\" {\n  ami = \"abc\"\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) =>
      assert_eq(
        json, "{\"resource\":{\"aws_instance\":{\"web\":{\"ami\":\"abc\"}}}}",
      )
    Err(_) => panic()
  }
}

///|
test "hcl_to_json repeated blocks become array" {
  let input = "resource \"aws_instance\" \"a\" {\n  ami = \"1\"\n}\nresource \"aws_instance\" \"b\" {\n  ami = \"2\"\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"resource\""))
      assert_true(json.contains("[{"))
      assert_true(json.contains("}]"))
      assert_true(json.contains("\"a\""))
      assert_true(json.contains("\"b\""))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json mixed attrs and blocks" {
  let input = "name = \"test\"\nserver {\n  port = 80\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"name\""))
      assert_true(json.contains("\"test\""))
      assert_true(json.contains("\"server\""))
      assert_true(json.contains("\"port\""))
      assert_true(json.contains("80"))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json block without labels" {
  let input = "server {\n  port = 80\n}"
  let result = hcl_to_json(input)
  match result {
    Ok(json) => assert_eq(json, "{\"server\":{\"port\":80}}")
    Err(_) => panic()
  }
}

///|
test "hcl_to_json_pretty block with labels" {
  let input = "resource \"aws_instance\" \"web\" {\n  ami = \"abc\"\n}"
  let result = hcl_to_json_pretty(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"resource\""))
      assert_true(json.contains("\"aws_instance\""))
      assert_true(json.contains("\"web\""))
      assert_true(json.contains("\"ami\""))
    }
    Err(_) => panic()
  }
}

///|
test "hcl_to_json_pretty repeated blocks" {
  let input = "resource \"aws_instance\" \"a\" {\n  ami = \"1\"\n}\nresource \"aws_instance\" \"b\" {\n  ami = \"2\"\n}"
  let result = hcl_to_json_pretty(input)
  match result {
    Ok(json) => {
      assert_true(json.contains("\"resource\""))
      assert_true(json.contains("["))
      assert_true(json.contains("]"))
    }
    Err(_) => panic()
  }
}
