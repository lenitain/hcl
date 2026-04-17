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
          assert_true(attr.get_value() == String("John", Decor::empty()))
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
            Array(arr, _) => assert_eq(arr.length(), 3)
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
        Attribute(attr) => assert_true(attr.get_value() == Null(Decor::empty()))
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
          assert_true(
            attr.get_value() == String("Hello World\n", Decor::empty()),
          )
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
            attr.get_value() ==
            String("line 1\nline 2\nline 3\n", Decor::empty()),
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
          assert_true(
            attr.get_value() == String("indented\ncontent\n", Decor::empty()),
          )
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
              assert_true(
                attr.get_value() == String("Allow all\n", Decor::empty()),
              )
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
          assert_true(
            attr.get_value() == String("custom delimiter\n", Decor::empty()),
          )
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
          assert_true(attr.get_value() == Int(255, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(255, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(255, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(0xDead, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(63, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(63, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(63, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(10, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(10, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(10, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(0, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(0, Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == Int(0, Decor::empty()))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape 4-digit lowercase" {
  let input = "value = \"\\u0041\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          assert_true(attr.get_value() == String("A", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("J", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("\u{ff}", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("A", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("A", Decor::empty()))
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
          assert_true(attr.get_value() == String("\u{1f600}", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("Hello", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("Hello", Decor::empty()))
        _ => panic()
      }
    Err(_) => panic()
  }
}

///|
test "parse unicode escape invalid missing digits" {
  let input = "value = \"\\u004\""
  let result = parse(input)
  assert_true(result is Err(_))
}

///|
test "parse unicode escape invalid empty bracket" {
  let input = "value = \"\\u{}\""
  let result = parse(input)
  assert_true(result is Err(_))
}

///|
test "parse unicode escape invalid too many digits" {
  let input = "value = \"\\u{1234567}\""
  let result = parse(input)
  assert_true(result is Err(_))
}

///|
test "parse unicode escape invalid out of range" {
  let input = "value = \"\\u{110000}\""
  let result = parse(input)
  assert_true(result is Err(_))
}

///|
test "parse unicode escape zero" {
  let input = "value = \"\\u0000\""
  let result = parse(input)
  match result {
    Ok(body) =>
      match body.get_items()[0] {
        Attribute(attr) =>
          assert_true(attr.get_value() == String("\u{0}", Decor::empty()))
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
          assert_true(attr.get_value() == String("\u{ffff}", Decor::empty()))
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
          assert_true(attr.get_value() == String("\u{10ffff}", Decor::empty()))
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
        Attribute(attr) =>
          assert_true(attr.get_value() == String("\u{1}", Decor::empty()))
        _ => panic()
      }
    Err(_) => panic()
  }
}
