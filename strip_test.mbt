///|
/// Template strip marker tests
test "parse strip marker interpolation" {
  let template = Template::from_string("hello ${~ name ~} world").unwrap()
  assert_eq(template.parts.length(), 3)
}

///|
test "strip before removes trailing whitespace" {
  let template = Template::from_string("hello  ${~ name}").unwrap()
  let vars = { "name": HCLValue::String("world", Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "helloworld")
    Err(_) => panic()
  }
}

///|
test "strip after removes leading whitespace" {
  let template = Template::from_string("${name ~}  world").unwrap()
  let vars = { "name": HCLValue::String("hello", Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "helloworld")
    Err(_) => panic()
  }
}

///|
test "strip both sides" {
  let template = Template::from_string("hello  ${~ name ~}  world").unwrap()
  let vars = { "name": HCLValue::String("X", Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "helloXworld")
    Err(_) => panic()
  }
}

///|
test "strip before with newlines" {
  let template = Template::from_string("hello\n  ${~ name}").unwrap()
  let vars = { "name": HCLValue::String("world", Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "helloworld")
    Err(_) => panic()
  }
}

///|
test "strip after with newlines" {
  let template = Template::from_string("${name ~}\n  world").unwrap()
  let vars = { "name": HCLValue::String("hello", Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "helloworld")
    Err(_) => panic()
  }
}

///|
test "strip directive conditional" {
  let template = Template::from_string("%{~ if show ~}visible%{~ endif ~}").unwrap()
  let vars = { "show": HCLValue::Bool(true, Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "visible")
    Err(_) => panic()
  }
}

///|
test "strip interpolation no whitespace" {
  let template = Template::from_string("${~ name ~}").unwrap()
  let vars = { "name": HCLValue::String("hello", Decor::empty()) }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "hello")
    Err(_) => panic()
  }
}

///|
test "strip multiple interpolations" {
  let template = Template::from_string("a  ${~ x ~}  b  ${~ y ~}  c").unwrap()
  let vars = {
    "x": HCLValue::String("X", Decor::empty()),
    "y": HCLValue::String("Y", Decor::empty()),
  }
  let funcs = {}
  match template.evaluate(vars, funcs) {
    Ok(result) => assert_eq(result, "aXbYc")
    Err(_) => panic()
  }
}
