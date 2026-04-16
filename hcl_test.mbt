///|
/// HCL Parser Tests
test "parse simple attribute" {
  let input = "name = \"John\""
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "name")
          assert_true(attr.get_value() == String("John"))
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse multiple attributes" {
  let input = "name = \"John\"\nage = 30"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => assert_eq(body.len(), 2)
    Err(_) => panic()
  }
}

///|
test "parse block" {
  let input = "resource \"aws_instance\" \"example\" {\n  ami = \"ami-123\"\n}"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "resource")
          assert_eq(block.get_labels(), ["aws_instance", "example"])
          assert_eq(block.get_body().len(), 1)
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse nested blocks" {
  let input = "resource \"aws_instance\" \"example\" {\n  ami = \"ami-123\"\n  tags {\n    Name = \"example\"\n  }\n}"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "resource")
          assert_eq(block.get_body().len(), 2)
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse array" {
  let input = "items = [1, 2, 3]"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "items")
          match attr.get_value() {
            Array(arr) => assert_eq(arr.length(), 3)
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
test "parse object" {
  let input = "config = { host = \"localhost\", port = 8080 }"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => assert_eq(body.len(), 1)
    Err(_) => panic()
  }
}

///|
test "parse boolean values" {
  let input = "enabled = true\ndisabled = false"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => assert_eq(body.len(), 2)
    Err(_) => panic()
  }
}

///|
test "parse null value" {
  let input = "value = null"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == Null)
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse with comments" {
  let input = "// This is a comment\nname = \"John\"\n/* Block comment */\nage = 30"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => assert_eq(body.len(), 2)
    Err(_) => panic()
  }
}

///|
test "parse with newlines" {
  let input = "\n\nname = \"John\"\n\nage = 30\n\n"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => assert_eq(body.len(), 2)
    Err(_) => panic()
  }
}
