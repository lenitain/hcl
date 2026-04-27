///|
/// Tests for HCL template system
test "parse simple text template" {
  let input = "Hello, World!"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {}
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Hello, World!")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with interpolation" {
  let input = "Hello, ${name}!"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = { "name": HCLValue::String("Alice", Decor::empty()) }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Hello, Alice!")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with multiple interpolations" {
  let input = "${greeting}, ${name}!"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "greeting": HCLValue::String("Hi", Decor::empty()),
        "name": HCLValue::String("Bob", Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Hi, Bob!")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with number interpolation" {
  let input = "Count: ${count}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "count": HCLValue::Number(Number::from_int(42), Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Count: 42")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with boolean interpolation" {
  let input = "Active: ${active}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = { "active": HCLValue::Bool(true, Decor::empty()) }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Active: true")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with conditional true" {
  let input = "%{if show}Visible%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = { "show": HCLValue::Bool(true, Decor::empty()) }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Visible")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with conditional false" {
  let input = "%{if show}Visible%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = { "show": HCLValue::Bool(false, Decor::empty()) }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with for loop" {
  let input = "%{for item in items}${item} %{endfor}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "items": HCLValue::Array(
          [
            HCLValue::String("a", Decor::empty()),
            HCLValue::String("b", Decor::empty()),
            HCLValue::String("c", Decor::empty()),
          ],
          Decor::empty(),
        ),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "a b c ")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse template with complex structure" {
  let input = "Name: ${name}, Age: ${age}, Active: %{if active}yes%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "name": HCLValue::String("John", Decor::empty()),
        "age": HCLValue::Number(Number::from_int(30), Decor::empty()),
        "active": HCLValue::Bool(true, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Name: John, Age: 30, Active: yes")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "evaluate template directly" {
  let input = "Hello, ${name}!"
  let vars = { "name": HCLValue::String("World", Decor::empty()) }
  let funcs = {}
  match evaluate_template(input, vars, funcs) {
    Ok(result) => assert_eq(result, "Hello, World!")
    Err(_) => panic()
  }
}

///|
test "template with undefined variable" {
  let input = "Hello, ${undefined_var}!"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {}
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(_) => panic()
        Err(_) => () // Expected error
      }
    }
    Err(_) => panic()
  }
}

///|
test "template with nested conditionals" {
  let input = "%{if outer}%{if inner}nested%{endif}%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "outer": HCLValue::Bool(true, Decor::empty()),
        "inner": HCLValue::Bool(true, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "nested")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template with for loop and interpolation" {
  let input = "Items: %{for item in items}${item}, %{endfor}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "items": HCLValue::Array(
          [
            HCLValue::String("x", Decor::empty()),
            HCLValue::String("y", Decor::empty()),
          ],
          Decor::empty(),
        ),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Items: x, y, ")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse heredoc simple" {
  let input = "This is a multi-line\nstring content\n"
  match Template::from_heredoc(input, "EOF", false) {
    Ok(template) => {
      let vars = {}
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) =>
          assert_eq(result, "This is a multi-line\nstring content\n")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse heredoc with interpolation" {
  let input = "Hello ${name}!\nWelcome to ${place}.\n"
  match Template::from_heredoc(input, "EOF", false) {
    Ok(template) => {
      let vars = {
        "name": HCLValue::String("Alice", Decor::empty()),
        "place": HCLValue::String("Wonderland", Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) =>
          assert_eq(result, "Hello Alice!\nWelcome to Wonderland.\n")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|

///|
test "template else true condition" {
  let input = "%{if show}yes%{else}no%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = { "show": HCLValue::Bool(true, Decor::empty()) }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "yes")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else false condition" {
  let input = "%{if show}yes%{else}no%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = { "show": HCLValue::Bool(false, Decor::empty()) }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "no")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else with interpolation" {
  let input = "%{if admin}Welcome ${name}%{else}Access denied%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "admin": HCLValue::Bool(false, Decor::empty()),
        "name": HCLValue::String("Alice", Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Access denied")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else true with interpolation" {
  let input = "%{if admin}Welcome ${name}%{else}Access denied%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "admin": HCLValue::Bool(true, Decor::empty()),
        "name": HCLValue::String("Bob", Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "Welcome Bob")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else in for loop" {
  let input = "%{for item in items}%{if active}${item}%{else}(hidden)%{endif} %{endfor}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "items": HCLValue::Array(
          [
            HCLValue::String("a", Decor::empty()),
            HCLValue::String("b", Decor::empty()),
          ],
          Decor::empty(),
        ),
        "active": HCLValue::Bool(true, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "a b ")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else false in for loop" {
  let input = "%{for item in items}%{if active}${item}%{else}(hidden)%{endif} %{endfor}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "items": HCLValue::Array(
          [
            HCLValue::String("a", Decor::empty()),
            HCLValue::String("b", Decor::empty()),
          ],
          Decor::empty(),
        ),
        "active": HCLValue::Bool(false, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "(hidden) (hidden) ")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else multiple conditionals" {
  let input = "%{if a}first%{else}%{if b}second%{else}third%{endif}%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(false, Decor::empty()),
        "b": HCLValue::Bool(true, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "second")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else multiple conditionals all false" {
  let input = "%{if a}first%{else}%{if b}second%{else}third%{endif}%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(false, Decor::empty()),
        "b": HCLValue::Bool(false, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "third")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "parse heredoc with strip" {
  let input = "  This has leading spaces\n  And more spaces\n"
  match Template::from_heredoc(input, "EOF", true) {
    Ok(template) => {
      let vars = {}
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) =>
          assert_eq(result, "This has leading spaces\nAnd more spaces\n")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else-if first true" {
  let input = "%{if a}A%{else if b}B%{else}C%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(true, Decor::empty()),
        "b": HCLValue::Bool(false, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "A")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else-if second true" {
  let input = "%{if a}A%{else if b}B%{else}C%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(false, Decor::empty()),
        "b": HCLValue::Bool(true, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "B")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else-if all false" {
  let input = "%{if a}A%{else if b}B%{else}C%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(false, Decor::empty()),
        "b": HCLValue::Bool(false, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "C")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else-if chain no else" {
  let input = "%{if a}A%{else if b}B%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(false, Decor::empty()),
        "b": HCLValue::Bool(false, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else-if chain with interpolation" {
  let input = "%{if admin}Admin ${name}%{else if user}User ${name}%{else}Guest%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "admin": HCLValue::Bool(false, Decor::empty()),
        "user": HCLValue::Bool(true, Decor::empty()),
        "name": HCLValue::String("Bob", Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "User Bob")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}

///|
test "template else-if three-way chain" {
  let input = "%{if a}A%{else if b}B%{else if c}C%{else}D%{endif}"
  match Template::from_string(input) {
    Ok(template) => {
      let vars = {
        "a": HCLValue::Bool(false, Decor::empty()),
        "b": HCLValue::Bool(false, Decor::empty()),
        "c": HCLValue::Bool(true, Decor::empty()),
      }
      let funcs = {}
      match template.evaluate(vars, funcs) {
        Ok(result) => assert_eq(result, "C")
        Err(_) => panic()
      }
    }
    Err(_) => panic()
  }
}
