# 保留空白和注释编辑实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- []`) syntax for tracking.

**Goal:** 实现类似hcl-edit的功能，在解析和修改HCL文档时保留空白和注释

**架构:** 参考hcl-rs的hcl-edit设计，为每个HCL结构添加Decor（前缀和后缀空白/注释），解析时收集这些信息，序列化时输出

**Tech Stack:** MoonBit语言，现有HCL解析器/序列化器

---

## 设计概述

### 核心概念
1. **Decor**: 存储prefix和suffix（空白和注释）
2. **Span**: 位置信息（开始和结束字节偏移）
3. **Decorated[T]**: 包装需要保留格式的值

### 文件结构
- `decor.mbt` - Decor和Decorated类型定义
- `span.mbt` - Span trait和位置信息
- 修改`body.mbt` - Attr/Block/Body添加decor字段
- 修改`value.mbt` - HCLValue添加decor字段
- 修改`parser.mbt` - 解析时收集空白和注释
- 修改`ser.mbt` - 序列化时输出decor

---

## 任务分解

### Task 1: 创建Decor和Decorated类型

**Files:**
- Create: `decor.mbt`
- Create: `decor_test.mbt`

- [ ] **Step 1: 创建decor.mbt文件**

```moonbit
///|
/// 白白和注释装饰器，存储前缀和后缀
pub struct Decor {
  prefix : String?
  suffix : String?
} derive(Debug, Eq)

///|
/// 创建新的Decor
pub fn Decor::new(prefix : String?, suffix : String?) -> Decor {
  { prefix, suffix }
}

///|
/// 创建空Decor
pub fn Decor::empty() -> Decor {
  { prefix: None, suffix: None }
}

///|
/// 设置前缀
pub fn Decor::set_prefix(self : Decor, prefix : String) -> Decor {
  { prefix: Some(prefix), suffix: self.suffix }
}

///|
/// 设置后缀
pub fn Decor::set_suffix(self : Decor, suffix : String) -> Decor {
  { prefix: self.prefix, suffix: Some(suffix) }
}

///|
/// 获取前缀
pub fn Decor::get_prefix(self : Decor) -> String? {
  self.prefix
}

///|
/// 获取后缀
pub fn Decor::get_suffix(self : Decor) -> String? {
  self.suffix
}

///|
/// 清除装饰
pub fn Decor::clear(self : Decor) -> Decor {
  { prefix: None, suffix: None }
}

///|
/// 带装饰的值
pub struct Decorated[T] {
  value : T
  decor : Decor
} derive(Debug, Eq)

///|
/// 创建带装饰的值
pub fn Decorated::new[T](value : T, decor : Decor) -> Decorated[T] {
  { value, decor }
}

///|
/// 创建带空装饰的值
pub fn Decorated::bare[T](value : T) -> Decorated[T] {
  { value, decor: Decor::empty() }
}

///|
/// 获取值
pub fn Decorated::get_value[T](self : Decorated[T]) -> T {
  self.value
}

///|
/// 获取装饰
pub fn Decorated::get_decor[T](self : Decorated[T]) -> Decor {
  self.decor
}

///|
/// 设置装饰
pub fn Decorated::set_decor[T](self : Decorated[T], decor : Decor) -> Decorated[T] {
  { value: self.value, decor }
}
```

- [ ] **Step 2: 创建decor_test.mbt测试文件**

```moonbit
test "Decor basic operations" {
  let decor = Decor::empty()
  assert_eq(decor.get_prefix(), None)
  assert_eq(decor.get_suffix(), None)
  
  let decor2 = decor.set_prefix(" ")
  assert_eq(decor2.get_prefix(), Some(" "))
  
  let decor3 = decor2.set_suffix("\n")
  assert_eq(decor3.get_suffix(), Some("\n"))
}

test "Decorated basic operations" {
  let decorated = Decorated::bare("hello")
  assert_eq(decorated.get_value(), "hello")
  assert_eq(decorated.get_decor().get_prefix(), None)
  
  let decor = Decor::new(Some(" "), Some("\n"))
  let decorated2 = Decorated::new("world", decor)
  assert_eq(decorated2.get_value(), "world")
  assert_eq(decorated2.get_decor().get_prefix(), Some(" "))
}
```

- [ ] **Step 3: 运行测试验证**

```bash
moon test decor_test.mbt
```

- [ ] **Step 4: 提交**

```bash
git add decor.mbt decor_test.mbt
git commit -m "feat: add Decor and Decorated types for whitespace/comment preservation"
```

---

### Task 2: 修改Body结构添加decor支持

**Files:**
- Modify: `body.mbt`
- Create: `body_decor_test.mbt`

- [ ] **Step 1: 修改Attr结构添加decor字段**

```moonbit
///|
/// HCL Attribute - key-value pair with decoration
pub struct Attr {
  key : Decorated[String]
  value : HCLValue
  decor : Decor
} derive(Debug, Eq)
```

- [ ] **Step 2: 修改Block结构添加decor字段**

```moonbit
///|
/// HCL Block - named container with optional labels and decoration
pub struct Block {
  type_name : Decorated[String]
  labels : Array[Decorated[String]]
  body : Body
  decor : Decor
} derive(Debug, Eq)
```

- [ ] **Step 3: 修改Body结构添加decor字段**

```moonbit
///|
/// HCL Body - top-level container for attributes and blocks with decoration
pub struct Body {
  items : Array[BodyItem]
  decor : Decor
} derive(Debug, Eq)
```

- [ ] **Step 4: 更新Attr构造函数**

```moonbit
///|
/// Create a new attribute with decoration
pub fn Attr::new(key : String, value : HCLValue) -> Attr {
  { key: Decorated::bare(key), value, decor: Decor::empty() }
}

///|
/// Create a new attribute with full decoration
pub fn Attr::with_decor(key : Decorated[String], value : HCLValue, decor : Decor) -> Attr {
  { key, value, decor }
}
```

- [ ] **Step 5: 更新Block构造函数**

```moonbit
///|
/// Create a new block with decoration
pub fn Block::new(type_name : String, labels : Array[String], body : Body) -> Block {
  { type_name: Decorated::bare(type_name), labels: labels.map(Decorated::bare), body, decor: Decor::empty() }
}

///|
/// Create a new block with full decoration
pub fn Block::with_decor(type_name : Decorated[String], labels : Array[Decorated[String]], body : Body, decor : Decor) -> Block {
  { type_name, labels, body, decor }
}
```

- [ ] **Step 6: 更新Body构造函数**

```moonbit
///|
/// Create a new empty Body with decoration
pub fn Body::new() -> Body {
  { items: [], decor: Decor::empty() }
}

///|
/// Create a Body from items with decoration
pub fn Body::from_items(items : Array[BodyItem]) -> Body {
  { items, decor: Decor::empty() }
}

///|
/// Create a Body with full decoration
pub fn Body::with_decor(items : Array[BodyItem], decor : Decor) -> Body {
  { items, decor }
}
```

- [ ] **Step 7: 创建body_decor_test.mbt测试**

```moonbit
test "Attr with decoration" {
  let decor = Decor::new(Some(" "), Some("\n"))
  let key_decor = Decor::new(None, Some(" "))
  let key = Decorated::new("name", key_decor)
  let value = HCLValue::String("value")
  
  let attr = Attr::with_decor(key, value, decor)
  assert_eq(attr.key.get_value(), "name")
  assert_eq(attr.key.get_decor().get_suffix(), Some(" "))
  assert_eq(attr.decor.get_prefix(), Some(" "))
}

test "Block with decoration" {
  let decor = Decor::new(Some("\n"), Some("\n"))
  let type_decor = Decor::new(None, Some(" "))
  let type_name = Decorated::new("resource", type_decor)
  let label_decor = Decor::new(Some(" "), Some(" "))
  let labels = [Decorated::new("aws_instance", label_decor)]
  let body = Body::new()
  
  let block = Block::with_decor(type_name, labels, body, decor)
  assert_eq(block.type_name.get_value(), "resource")
  assert_eq(block.labels[0].get_value(), "aws_instance")
  assert_eq(block.labels[0].get_decor().get_prefix(), Some(" "))
}
```

- [ ] **Step 8: 运行测试验证**

```bash
moon test body_decor_test.mbt
```

- [ ] **Step 9: 提交**

```bash
git add body.mbt body_decor_test.mbt
git commit -m "feat: add decor support to Body, Attr, and Block structures"
```

---

### Task 3: 修改HCLValue添加decor支持

**Files:**
- Modify: `value.mbt`
- Create: `value_decor_test.mbt`

- [ ] **Step 1: 修改HCLValue枚举添加decor**

```moonbit
///|
/// HCL value types with decoration
pub(all) enum HCLValue {
  /// Null value with decoration
  Null(Decor)
  /// Boolean value with decoration
  Bool(Bool, Decor)
  /// Integer value with decoration
  Int(Int, Decor)
  /// 64-bit integer value with decoration
  Int64(Int64, Decor)
  /// Floating point value with decoration
  Float(Double, Decor)
  /// String value with decoration
  String(String, Decor)
  /// Array of values with decoration
  Array(Array[HCLValue], Decor)
  /// Object (map of string to value) with decoration
  Object(Map[String, HCLValue], Decor)
} derive(Debug, Eq)
```

- [ ] **Step 2: 更新HCLValue辅助函数**

```moonbit
///|
/// Get decoration from HCLValue
pub fn HCLValue::get_decor(self : HCLValue) -> Decor {
  match self {
    Null(decor) => decor
    Bool(_, decor) => decor
    Int(_, decor) => decor
    Int64(_, decor) => decor
    Float(_, decor) => decor
    String(_, decor) => decor
    Array(_, decor) => decor
    Object(_, decor) => decor
  }
}

///|
/// Set decoration on HCLValue
pub fn HCLValue::set_decor(self : HCLValue, decor : Decor) -> HCLValue {
  match self {
    Null(_) => Null(decor)
    Bool(b, _) => Bool(b, decor)
    Int(i, _) => Int(i, decor)
    Int64(i, _) => Int64(i, decor)
    Float(f, _) => Float(f, decor)
    String(s, _) => String(s, decor)
    Array(a, _) => Array(a, decor)
    Object(o, _) => Object(o, decor)
  }
}
```

- [ ] **Step 3: 更新is_*函数**

```moonbit
///|
/// Check if value is null
pub fn HCLValue::is_null(self : HCLValue) -> Bool {
  match self {
    Null(_) => true
    _ => false
  }
}

///|
/// Check if value is a boolean
pub fn HCLValue::is_bool(self : HCLValue) -> Bool {
  match self {
    Bool(_, _) => true
    _ => false
  }
}
```

- [ ] **Step 4: 更新as_*函数**

```moonbit
///|
/// Get the boolean value, or None if not a bool
pub fn HCLValue::as_bool(self : HCLValue) -> Bool? {
  match self {
    Bool(b, _) => Some(b)
    _ => None
  }
}

///|
/// Get the integer value, or None if not an int
pub fn HCLValue::as_int(self : HCLValue) -> Int? {
  match self {
    Int(i, _) => Some(i)
    _ => None
  }
}
```

- [ ] **Step 5: 创建便利构造函数**

```moonbit
///|
/// Create null value with empty decor
pub fn HCLValue::null() -> HCLValue {
  Null(Decor::empty())
}

///|
/// Create bool value with empty decor
pub fn HCLValue::bool(b : Bool) -> HCLValue {
  Bool(b, Decor::empty())
}

///|
/// Create int value with empty decor
pub fn HCLValue::int(i : Int) -> HCLValue {
  Int(i, Decor::empty())
}

///|
/// Create string value with empty decor
pub fn HCLValue::string(s : String) -> HCLValue {
  String(s, Decor::empty())
}

///|
/// Create array value with empty decor
pub fn HCLValue::array(arr : Array[HCLValue]) -> HCLValue {
  Array(arr, Decor::empty())
}

///|
/// Create object value with empty decor
pub fn HCLValue::object(obj : Map[String, HCLValue]) -> HCLValue {
  Object(obj, Decor::empty())
}
```

- [ ] **Step 6: 更新to_json_string函数**

```moonbit
///|
/// Convert HCLValue to JSON-compatible string representation
pub fn HCLValue::to_json_string(self : HCLValue) -> String {
  match self {
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Int(i, _) => i.to_string()
    Int64(i, _) => i.to_string()
    Float(f, _) => f.to_string()
    String(s, _) => escape_string(s)
    Array(arr, _) =>
      if arr.is_empty() {
        "[]"
      } else {
        let items = arr.map(fn(v) { v.to_json_string() })
        "[" + items.join(", ") + "]"
      }
    Object(obj, _) =>
      if obj.is_empty() {
        "{}"
      } else {
        let items = []
        for k, v in obj {
          items.push(escape_string(k) + ": " + v.to_json_string())
        }
        "{" + items.join(", ") + "}"
      }
  }
}
```

- [ ] **Step 7: 创建value_decor_test.mbt测试**

```moonbit
test "HCLValue decoration" {
  let value = HCLValue::string("hello")
  assert_eq(value.get_decor().get_prefix(), None)
  
  let decor = Decor::new(Some(" "), Some("\n"))
  let value2 = value.set_decor(decor)
  assert_eq(value2.get_decor().get_prefix(), Some(" "))
  assert_eq(value2.as_string(), Some("hello"))
}

test "HCLValue convenience constructors" {
  let null_val = HCLValue::null()
  assert(null_val.is_null())
  assert_eq(null_val.get_decor().get_prefix(), None)
  
  let bool_val = HCLValue::bool(true)
  assert(bool_val.is_bool())
  assert_eq(bool_val.as_bool(), Some(true))
}
```

- [ ] **Step 8: 运行测试验证**

```bash
moon test value_decor_test.mbt
```

- [ ] **Step 9: 提交**

```bash
git add value.mbt value_decor_test.mbt
git commit -m "feat: add decor support to HCLValue enum"
```

---

### Task 4: 更新解析器收集空白和注释

**Files:**
- Modify: `lexer.mbt`
- Modify: `parser.mbt`
- Create: `parser_decor_test.mbt`

- [ ] **Step 1: 修改Lexer添加空白和注释收集**

```moonbit
///|
/// 扩展Token类型包含空白和注释
pub(all) enum Token {
  // ... existing tokens ...
  /// 空白字符
  Whitespace(String)
  /// 行注释
  LineComment(String)
  /// 块注释
  BlockComment(String)
  /// 新行
  Newline
} derive(Debug, Eq)
```

- [ ] **Step 2: 修改Lexer跳过空白但保留信息**

```moonbit
///|
/// 跳过空白但返回空白信息
pub fn Lexer::skip_whitespace_with_info(mut self : Lexer) -> (Lexer, String?) {
  let mut whitespace = ""
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if ch.is_whitespace() {
      whitespace = whitespace + ch.to_string()
      self.pos = self.pos + 1
    } else {
      break
    }
  }
  if whitespace == "" {
    (self, None)
  } else {
    (self, Some(whitespace))
  }
}
```

- [ ] **Step 3: 修改Lexer收集注释**

```moonbit
///|
/// 收集注释
pub fn Lexer::collect_comment(mut self : Lexer) -> (Lexer, String?) {
  if self.pos >= self.input.length() {
    return (self, None)
  }
  
  let ch = self.input[self.pos]
  if ch == '/' && self.pos + 1 < self.input.length() {
    let next_ch = self.input[self.pos + 1]
    if next_ch == '/' {
      // 行注释
      let start = self.pos
      self.pos = self.pos + 2
      while self.pos < self.input.length() && self.input[self.pos] != '\n' {
        self.pos = self.pos + 1
      }
      let comment = self.input[start:self.pos]
      return (self, Some(comment))
    } else if next_ch == '*' {
      // 块注释
      let start = self.pos
      self.pos = self.pos + 2
      while self.pos + 1 < self.input.length() {
        if self.input[self.pos] == '*' && self.input[self.pos + 1] == '/' {
          self.pos = self.pos + 2
          break
        }
        self.pos = self.pos + 1
      }
      let comment = self.input[start:self.pos]
      return (self, Some(comment))
    }
  }
  (self, None)
}
```

- [ ] **Step 4: 修改Parser收集decor**

```moonbit
///|
/// 解析前收集空白和注释
pub fn Parser::collect_prefix(mut self : Parser) -> (Parser, Decor) {
  let mut prefix = ""
  
  // 收集空白
  let (lexer, whitespace) = self.lexer.skip_whitespace_with_info()
  self.lexer = lexer
  if let Some(ws) = whitespace {
    prefix = prefix + ws
  }
  
  // 收集注释
  let (lexer, comment) = self.lexer.collect_comment()
  self.lexer = lexer
  if let Some(c) = comment {
    prefix = prefix + c
  }
  
  // 再次收集空白（注释后的空白）
  let (lexer, whitespace2) = self.lexer.skip_whitespace_with_info()
  self.lexer = lexer
  if let Some(ws) = whitespace2 {
    prefix = prefix + ws
  }
  
  if prefix == "" {
    (self, Decor::empty())
  } else {
    (self, Decor::new(Some(prefix), None))
  }
}
```

- [ ] **Step 5: 修改解析属性函数**

```moonbit
///|
/// 解析属性，收集decor
pub fn Parser::parse_attr_with_decor(mut self : Parser) -> HCLResult[(Parser, Attr)] {
  // 收集前缀
  let (parser, prefix_decor) = self.collect_prefix()
  self = parser
  
  // 解析键
  let (parser, key_token) = self.expect_identifier()
  self = parser
  let key = key_token.to_string()
  
  // 收集键后的空白
  let (parser, key_suffix) = self.collect_suffix()
  self = parser
  let key_decorated = Decorated::new(key, Decor::new(None, key_suffix.get_prefix()))
  
  // 解析等号
  let (parser, _) = self.expect_equal()
  self = parser
  
  // 收集等号后的空白
  let (parser, equal_suffix) = self.collect_suffix()
  self = parser
  
  // 解析值
  let (parser, value) = self.parse_expression()
  self = parser
  
  // 收集后缀
  let (parser, suffix_decor) = self.collect_suffix()
  self = parser
  
  let decor = Decor::new(prefix_decor.get_prefix(), suffix_decor.get_prefix())
  let attr = Attr::with_decor(key_decorated, value, decor)
  
  Ok((parser, attr))
}
```

- [ ] **Step 6: 创建parser_decor_test.mbt测试**

```moonbit
test "parse attribute with leading comment" {
  let input = "// This is a comment\nname = \"value\""
  let result = parse(input)
  assert(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert(attr.is_some())
  assert(attr.unwrap().decor.get_prefix().is_some())
}

test "parse attribute with trailing comment" {
  let input = "name = \"value\" // trailing comment"
  let result = parse(input)
  assert(result.is_ok())
  let body = result.unwrap()
  let attr = body.find_attr("name")
  assert(attr.is_some())
  assert(attr.unwrap().decor.get_suffix().is_some())
}

test "parse block with comments" {
  let input = "// Block comment\nresource \"aws_instance\" \"example\" {\n  // Inside block\n  ami = \"ami-123\"\n}"
  let result = parse(input)
  assert(result.is_ok())
  let body = result.unwrap()
  let block = body.find_block("resource")
  assert(block.is_some())
  assert(block.unwrap().decor.get_prefix().is_some())
}
```

- [ ] **Step 7: 运行测试验证**

```bash
moon test parser_decor_test.mbt
```

- [ ] **Step 8: 提交**

```bash
git add lexer.mbt parser.mbt parser_decor_test.mbt
git commit -m "feat: update parser to collect whitespace and comments as decor"
```

---

### Task 5: 更新序列化器输出decor

**Files:**
- Modify: `ser.mbt`
- Create: `ser_decor_test.mbt`

- [ ] **Step 1: 修改format_body函数输出decor**

```moonbit
///|
/// 格式化Body，包含decor
pub fn format_body_with_decor(body : Body) -> String {
  let mut result = ""
  
  // 输出前缀decor
  if let Some(prefix) = body.decor.get_prefix() {
    result = result + prefix
  }
  
  // 输出items
  for item in body.get_items() {
    result = result + format_body_item_with_decor(item)
  }
  
  // 输出后缀decor
  if let Some(suffix) = body.decor.get_suffix() {
    result = result + suffix
  }
  
  result
}
```

- [ ] **Step 2: 修改format_attr函数输出decor**

```moonbit
///|
/// 格式化属性，包含decor
pub fn format_attr_with_decor(attr : Attr) -> String {
  let mut result = ""
  
  // 输出前缀decor
  if let Some(prefix) = attr.decor.get_prefix() {
    result = result + prefix
  }
  
  // 输出键（包含键的decor）
  let key_decor = attr.key.get_decor()
  if let Some(key_prefix) = key_decor.get_prefix() {
    result = result + key_prefix
  }
  result = result + attr.key.get_value()
  if let Some(key_suffix) = key_decor.get_suffix() {
    result = result + key_suffix
  }
  
  // 输出等号
  result = result + " = "
  
  // 输出值（包含值的decor）
  result = result + format_value_with_decor(attr.value)
  
  // 输出后缀decor
  if let Some(suffix) = attr.decor.get_suffix() {
    result = result + suffix
  }
  
  result
}
```

- [ ] **Step 3: 修改format_value函数输出decor**

```moonbit
///|
/// 格式化值，包含decor
pub fn format_value_with_decor(value : HCLValue) -> String {
  let mut result = ""
  
  // 输出前缀decor
  if let Some(prefix) = value.get_decor().get_prefix() {
    result = result + prefix
  }
  
  // 输出值内容
  result = result + format_value_content(value)
  
  // 输出后缀decor
  if let Some(suffix) = value.get_decor().get_suffix() {
    result = result + suffix
  }
  
  result
}

///|
/// 格式化值内容（不包含decor）
pub fn format_value_content(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(b, _) => if b { "true" } else { "false" }
    Int(i, _) => i.to_string()
    Int64(i, _) => i.to_string()
    Float(f, _) => f.to_string()
    String(s, _) => "\"" + escape_string(s) + "\""
    Array(arr, _) => format_array_content(arr)
    Object(obj, _) => format_object_content(obj)
  }
}
```

- [ ] **Step 4: 创建ser_decor_test.mbt测试**

```moonbit
test "format attribute with decor" {
  let key = Decorated::new("name", Decor::new(None, Some(" ")))
  let value = HCLValue::string("value")
  let decor = Decor::new(Some("// comment\n"), Some("\n"))
  let attr = Attr::with_decor(key, value, decor)
  
  let result = format_attr_with_decor(attr)
  assert(result.contains("// comment"))
  assert(result.contains("name = \"value\""))
}

test "format body with decor" {
  let items = [
    Attribute(Attr::new("name", HCLValue::string("value")))
  ]
  let decor = Decor::new(Some("# Header\n"), Some("\n# Footer\n"))
  let body = Body::with_decor(items, decor)
  
  let result = format_body_with_decor(body)
  assert(result.contains("# Header"))
  assert(result.contains("# Footer"))
}
```

- [ ] **Step 5: 运行测试验证**

```bash
moon test ser_decor_test.mbt
```

- [ ] **Step 6: 提交**

```bash
git add ser.mbt ser_decor_test.mbt
git commit -m "feat: update serializer to output decor (whitespace and comments)"
```

---

### Task 6: 更新现有测试和添加集成测试

**Files:**
- Modify: `hcl_test.mbt`
- Create: `integration_decor_test.mbt`

- [ ] **Step 1: 更新现有测试使用新API**

```moonbit
// 更新测试使用HCLValue::string()而不是直接构造String(s, Decor::empty())
```

- [ ] **Step 2: 创建集成测试**

```moonbit
test "roundtrip with comments" {
  let input = "// Header comment\nname = \"value\" // trailing\n\n// Block comment\nresource \"aws\" \"example\" {\n  ami = \"ami-123\"\n}"
  
  // 解析
  let result = parse(input)
  assert(result.is_ok())
  let body = result.unwrap()
  
  // 序列化
  let output = format_body_with_decor(body)
  
  // 验证注释保留
  assert(output.contains("// Header comment"))
  assert(output.contains("// trailing"))
  assert(output.contains("// Block comment"))
}

test "modify and preserve decor" {
  let input = "// Comment\nname = \"old\""
  
  // 解析
  let body = parse(input).unwrap()
  let attr = body.find_attr("name").unwrap()
  
  // 修改值
  let new_value = HCLValue::string("new")
  let new_attr = Attr::with_decor(attr.key, new_value, attr.decor)
  
  // 创建新body
  let new_body = Body::with_decor([Attribute(new_attr)], body.decor)
  
  // 序列化
  let output = format_body_with_decor(new_body)
  
  // 验证注释保留，值更新
  assert(output.contains("// Comment"))
  assert(output.contains("\"new\""))
}
```

- [ ] **Step 3: 运行所有测试**

```bash
moon test
```

- [ ] **Step 4: 提交**

```bash
git add hcl_test.mbt integration_decor_test.mbt
git commit -m "test: update existing tests and add integration tests for decor"
```

---

### Task 7: 更新文档和清理

**Files:**
- Modify: `README.mbt.md`
- Modify: `PROGRESS.md`
- Create: `docs/decor-usage.md`

- [ ] **Step 1: 更新README添加decor功能说明**

```moonbit
// 在README中添加新功能说明
```

- [ ] **Step 2: 更新PROGRESS.md记录进度**

```moonbit
// 更新进度文档
```

- [ ] **Step 3: 创建使用文档**

```moonbit
// 创建decor使用示例文档
```

- [ ] **Step 4: 运行完整测试套件**

```bash
moon test
```

- [ ] **Step 5: 提交**

```bash
git add README.mbt.md PROGRESS.md docs/decor-usage.md
git commit -m "docs: update documentation for decor feature"
```

---

## 执行说明

1. 使用subagent-driven方式执行每个任务
2. 每个任务完成后进行spec compliance review和code quality review
3. 严格测试，确保现有功能不被破坏
4. 参考hcl-rs的hcl-edit设计，但适配MoonBit语言特性

## 参考

- hcl-rs hcl-edit: `/home/pilot/.projects/hcl-rs/crates/hcl-edit/`
- 核心概念: `Decor`, `Decorated[T]`, `Span`
- 关键文件: `repr.rs`, `structure/attribute.rs`, `structure/block.rs`
