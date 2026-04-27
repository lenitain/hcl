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
          assert_true(attr.get_value() == ExprString("John"))
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
        Attribute(attr) => assert_true(attr.get_value() == ExprNull)
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

///|
test "parse heredoc basic" {
  let input = "text = <<EOF\nHello World\nEOF"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "text")
          assert_true(attr.get_value() == ExprString("Hello World\n"))
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse heredoc multiline" {
  let input = "config = <<EOF\nline 1\nline 2\nline 3\nEOF"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "config")
          assert_true(
            attr.get_value() == ExprString("line 1\nline 2\nline 3\n"),
          )
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse heredoc with strip" {
  let input = "config = <<-EOF\n  indented\n  content\nEOF"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "config")
          // With strip, leading whitespace should be removed
          assert_true(attr.get_value() == ExprString("indented\ncontent\n"))
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse heredoc in block" {
  let input = "resource \"test\" \"example\" {\n  policy = <<EOF\nAllow all\nEOF\n}"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Block(block) => {
          assert_eq(block.get_type_name(), "resource")
          assert_eq(block.get_body().len(), 1)
          match block.get_body().get_items()[0] {
            Attribute(attr) => {
              assert_eq(attr.get_key(), "policy")
              assert_true(attr.get_value() == ExprString("Allow all\n"))
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
test "parse heredoc with custom delimiter" {
  let input = "data = <<MYDELIM\ncustom delimiter\nMYDELIM"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "data")
          assert_true(attr.get_value() == ExprString("custom delimiter\n"))
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse hex number" {
  let input = "value = 0xFF"
  let result = parse(input)
  assert_true(result is Ok(_))
  match result {
    Ok(body) => {
      assert_eq(body.len(), 1)
      match body.get_items()[0] {
        Attribute(attr) => {
          assert_eq(attr.get_key(), "value")
          assert_true(attr.get_value() == ExprInt(255))
        }
        _ => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse hex number uppercase" {
  let input = "value = 0XFF"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(255))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse hex with underscore" {
  let input = "value = 0x_F_F"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(255))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse hex mixed case" {
  let input = "value = 0xDeAd"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(0xDead))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse octal number" {
  let input = "value = 0o77"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(63))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse octal uppercase" {
  let input = "value = 0O77"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(63))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse octal with underscore" {
  let input = "value = 0o7_7"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(63))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse binary number" {
  let input = "value = 0b1010"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(10))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse binary uppercase" {
  let input = "value = 0B1010"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(10))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse binary with underscore" {
  let input = "value = 0b10_10"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(10))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse hex zero" {
  let input = "value = 0x0"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(0))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse octal zero" {
  let input = "value = 0o0"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(0))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse binary zero" {
  let input = "value = 0b0"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprInt(0))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse scientific notation positive exponent" {
  let input = "value = 1e10"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          assert_true(attr.get_value() == ExprFloat(10000000000.0))
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
test "parse scientific notation negative exponent" {
  let input = "value = 2.5e-3"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprFloat(n) => assert_true((n - 0.0025).abs() < 0.000001)
            _ => panic()
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
test "parse scientific notation with decimal" {
  let input = "value = 1.5e2"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          match attr.get_value() {
            ExprFloat(n) => assert_true((n - 150.0).abs() < 0.000001)
            _ => panic()
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
test "parse scientific notation uppercase E" {
  let input = "value = 1E3"
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprFloat(1000.0))
        _ => panic()
      }
    Err(e) => {
      println("Error: " + e.message())
      panic()
    }
  }
}

///|
test "parse unicode escape 4-digit lowercase" {
  let input = "value = \"\\u0041\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("A"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape 4-digit uppercase" {
  let input = "value = \"\\u004A\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("J"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape 4-digit mixed case" {
  let input = "value = \"\\u00fF\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("\u{ff}"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape bracket format" {
  let input = "value = \"\\u{41}\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("A"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape bracket 4-digit" {
  let input = "value = \"\\u{0041}\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("A"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape bracket 5-digit" {
  let input = "value = \"\\u{1F600}\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          assert_true(attr.get_value() == ExprString("\u{1f600}"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape multiple in string" {
  let input = "value = \"\\u0048\\u0065\\u006C\\u006C\\u006F\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("Hello"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape mixed formats" {
  let input = "value = \"\\u0048\\u{65}llo\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("Hello"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape zero" {
  let input = "value = \"\\u0000\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("\u{0}"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape max bmp" {
  let input = "value = \"\\uFFFF\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          assert_true(attr.get_value() == ExprString("\u{ffff}"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape max valid" {
  let input = "value = \"\\u{10FFFF}\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          assert_true(attr.get_value() == ExprString("\u{10ffff}"))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape bracket single digit" {
  let input = "value = \"\\u{1}\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) => assert_true(attr.get_value() == ExprString("\u{1}"))
        _ => panic()
      }
    Err(_) => panic()
  }
}
