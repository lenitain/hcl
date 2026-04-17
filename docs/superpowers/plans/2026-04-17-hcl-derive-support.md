# HCL 序列化 Derive 支持 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- []`) syntax for tracking.

**Goal:** 为 HCL-MoonBit 库添加 ToHCL/FromHCL trait、Builder 模式和辅助函数，简化用户将 MoonBit 类型与 HCL 格式互转。

**Architecture:** 定义 trait + 提供 builder + 辅助函数 + 预实现常用类型。MoonBit 不支持自定义 derive 宏，因此采用手动 impl + 辅助函数的方式。

**Tech Stack:** MoonBit

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `trait.mbt` | ToHCL/FromHCL trait 定义 + 基本类型预实现 |
| `trait_test.mbt` | trait 测试 |
| `builder.mbt` | BodyBuilder/BlockBuilder 实现 |
| `builder_test.mbt` | builder 测试 |
| `ser.mbt` | 扩展辅助函数 (hcl_int, hcl_str 等) |
| `de.mbt` | 扩展便捷方法 |

---

## Task 1: 定义 ToHCL/FromHCL Trait + 基本类型实现

**Files:**
- Create: `trait.mbt`
- Create: `trait_test.mbt`

- [ ] **Step 1: 创建 trait.mbt，定义 trait 和基本类型实现**

```moonbit
///|
/// ToHCL trait - convert MoonBit types to HCLValue
pub trait ToHCL {
  to_hcl(Self) -> HCLValue
}

///|
/// FromHCL trait - convert HCLValue to MoonBit types
pub trait FromHCL {
  from_hcl(HCLValue) -> HCLResult[Self]
}

///|
/// Convert ToHCL value to HCL string
pub fn to_hcl_string[T : ToHCL](value : T) -> String {
  to_hcl_body(value.to_hcl())
}

///|
/// Parse HCL string and convert to type
pub fn from_hcl_string[T : FromHCL](input : String) -> HCLResult[T] {
  match parse(input) {
    Ok(body) => T::from_hcl(body_to_value(body))
    Err(e) => Err(e)
  }
}

///|
/// Identity: HCLValue -> HCLValue
impl ToHCL for HCLValue {
  to_hcl(self) -> HCLValue { self }
}

impl FromHCL for HCLValue {
  from_hcl(value : HCLValue) -> HCLResult[HCLValue] { Ok(value) }
}

///|
/// Int
impl ToHCL for Int {
  to_hcl(self) -> HCLValue { Int(self) }
}

impl FromHCL for Int {
  from_hcl(value : HCLValue) -> HCLResult[Int] {
    match value {
      Int(i) => Ok(i)
      _ => Err(HCLError::type_mismatch("Int", value_to_type_name(value)))
    }
  }
}

///|
/// Int64
impl ToHCL for Int64 {
  to_hcl(self) -> HCLValue { Int64(self) }
}

impl FromHCL for Int64 {
  from_hcl(value : HCLValue) -> HCLResult[Int64] {
    match value {
      Int64(i) => Ok(i)
      _ => Err(HCLError::type_mismatch("Int64", value_to_type_name(value)))
    }
  }
}

///|
/// Double
impl ToHCL for Double {
  to_hcl(self) -> HCLValue { Float(self) }
}

impl FromHCL for Double {
  from_hcl(value : HCLValue) -> HCLResult[Double] {
    match value {
      Float(f) => Ok(f)
      Int(i) => Ok(i.to_double())
      _ => Err(HCLError::type_mismatch("Float", value_to_type_name(value)))
    }
  }
}

///|
/// Bool
impl ToHCL for Bool {
  to_hcl(self) -> HCLValue { Bool(self) }
}

impl FromHCL for Bool {
  from_hcl(value : HCLValue) -> HCLResult[Bool] {
    match value {
      Bool(b) => Ok(b)
      _ => Err(HCLError::type_mismatch("Bool", value_to_type_name(value)))
    }
  }
}

///|
/// String
impl ToHCL for String {
  to_hcl(self) -> HCLValue { String(self) }
}

impl FromHCL for String {
  from_hcl(value : HCLValue) -> HCLResult[String] {
    match value {
      String(s) => Ok(s)
      _ => Err(HCLError::type_mismatch("String", value_to_type_name(value)))
    }
  }
}

///|
/// Option[T]
impl[T : ToHCL] ToHCL for Option[T] {
  to_hcl(self) -> HCLValue {
    match self {
      Some(v) => v.to_hcl()
      None => Null
    }
  }
}

impl[T : FromHCL] FromHCL for Option[T] {
  from_hcl(value : HCLValue) -> HCLResult[Option[T]] {
    match value {
      Null => Ok(None)
      v => match T::from_hcl(v) {
        Ok(t) => Ok(Some(t))
        Err(e) => Err(e)
      }
    }
  }
}

///|
/// Array[T]
impl[T : ToHCL] ToHCL for Array[T] {
  to_hcl(self) -> HCLValue {
    Array(self.map(fn(v) { v.to_hcl() }))
  }
}

impl[T : FromHCL] FromHCL for Array[T] {
  from_hcl(value : HCLValue) -> HCLResult[Array[T]] {
    match value {
      Array(arr) => {
        let result = []
        for v in arr {
          match T::from_hcl(v) {
            Ok(t) => result.push(t)
            Err(e) => return Err(e)
          }
        }
        Ok(result)
      }
      _ => Err(HCLError::type_mismatch("Array", value_to_type_name(value)))
    }
  }
}

///|
/// Map[String, T]
impl[T : ToHCL] ToHCL for Map[String, T] {
  to_hcl(self) -> HCLValue {
    let obj = {}
    for k, v in self {
      obj[k] = v.to_hcl()
    }
    Object(obj)
  }
}

impl[T : FromHCL] FromHCL for Map[String, T] {
  from_hcl(value : HCLValue) -> HCLResult[Map[String, T]] {
    match value {
      Object(obj) => {
        let result = {}
        for k, v in obj {
          match T::from_hcl(v) {
            Ok(t) => result[k] = t
            Err(e) => return Err(e)
          }
        }
        Ok(result)
      }
      _ => Err(HCLError::type_mismatch("Object", value_to_type_name(value)))
    }
  }
}
```

- [ ] **Step 2: 创建 trait_test.mbt**

```moonbit
test "to_hcl Int" {
  let value = (42 : Int).to_hcl()
  assert_eq(value, Int(42))
}

test "from_hcl Int" {
  let result = Int::from_hcl(Int(42))
  assert_eq(result, Ok(42))
}

test "to_hcl String" {
  let value = "hello".to_hcl()
  assert_eq(value, String("hello"))
}

test "from_hcl String" {
  let result = String::from_hcl(String("hello"))
  assert_eq(result, Ok("hello"))
}

test "to_hcl Bool" {
  let value = true.to_hcl()
  assert_eq(value, Bool(true))
}

test "from_hcl Bool" {
  let result = Bool::from_hcl(Bool(false))
  assert_eq(result, Ok(false))
}

test "to_hcl Double" {
  let value = (3.14 : Double).to_hcl()
  assert_eq(value, Float(3.14))
}

test "from_hcl Double from Float" {
  let result = Double::from_hcl(Float(3.14))
  assert_eq(result, Ok(3.14))
}

test "from_hcl Double from Int" {
  let result = Double::from_hcl(Int(42))
  assert_eq(result, Ok(42.0))
}

test "to_hcl Option Some" {
  let value = Some(42 : Int).to_hcl()
  assert_eq(value, Int(42))
}

test "to_hcl Option None" {
  let value = (None : Option[Int]).to_hcl()
  assert_eq(value, Null)
}

test "from_hcl Option Some" {
  let result = Option[Int]::from_hcl(Int(42))
  assert_eq(result, Ok(Some(42)))
}

test "from_hcl Option None" {
  let result = Option[Int]::from_hcl(Null)
  assert_eq(result, Ok(None))
}

test "to_hcl Array" {
  let value = ([1, 2, 3] : Array[Int]).to_hcl()
  assert_eq(value, Array([Int(1), Int(2), Int(3)]))
}

test "from_hcl Array" {
  let result = Array[Int]::from_hcl(Array([Int(1), Int(2), Int(3)]))
  assert_eq(result, Ok([1, 2, 3]))
}

test "to_hcl Map" {
  let m : Map[String, Int] = { "a": 1, "b": 2 }
  let value = m.to_hcl()
  let expected = Object({ "a": Int(1), "b": Int(2) })
  assert_eq(value, expected)
}

test "from_hcl Map" {
  let input = Object({ "a": Int(1), "b": Int(2) })
  let result = Map[String, Int]::from_hcl(input)
  assert(result is Ok)
  let m = result.unwrap()
  assert_eq(m["a"], 1)
  assert_eq(m["b"], 2)
}

test "from_hcl type mismatch" {
  let result = Int::from_hcl(String("not an int"))
  assert(result is Err)
}

test "roundtrip Int" {
  let original = 42 : Int
  let hcl = original.to_hcl()
  let result = Int::from_hcl(hcl)
  assert_eq(result, Ok(original))
}

test "roundtrip String" {
  let original = "hello world"
  let hcl = original.to_hcl()
  let result = String::from_hcl(hcl)
  assert_eq(result, Ok(original))
}

test "to_hcl_string convenience" {
  let result = to_hcl_string(42 : Int)
  assert_eq(result, "42")
}

test "from_hcl_string convenience" {
  let result : HCLResult[Int] = from_hcl_string("42")
  assert_eq(result, Ok(42))
}
```

- [ ] **Step 3: 运行测试验证**

```bash
moon check && moon test
```

- [ ] **Step 4: 运行 moon info 更新接口**

```bash
moon info && moon fmt
```

- [ ] **Step 5: Commit**

```bash
git add trait.mbt trait_test.mbt
git commit -m "feat: add ToHCL/FromHCL trait with basic type implementations"
```

---

## Task 2: HCLValue 构造辅助函数

**Files:**
- Modify: `ser.mbt` (追加辅助函数)

- [ ] **Step 1: 在 ser.mbt 末尾添加辅助函数**

```moonbit
///|
/// Create Int HCLValue
pub fn hcl_int(v : Int) -> HCLValue { Int(v) }

///|
/// Create Int64 HCLValue
pub fn hcl_int64(v : Int64) -> HCLValue { Int64(v) }

///|
/// Create Float HCLValue
pub fn hcl_float(v : Double) -> HCLValue { Float(v) }

///|
/// Create Bool HCLValue
pub fn hcl_bool(v : Bool) -> HCLValue { Bool(v) }

///|
/// Create String HCLValue
pub fn hcl_str(v : String) -> HCLValue { String(v) }

///|
/// Create Null HCLValue
pub fn hcl_null() -> HCLValue { Null }

///|
/// Create Array HCLValue
pub fn hcl_array(items : Array[HCLValue]) -> HCLValue { Array(items) }

///|
/// Create Object HCLValue
pub fn hcl_object(entries : Map[String, HCLValue]) -> HCLValue { Object(entries) }
```

- [ ] **Step 2: 在 trait_test.mbt 添加测试**

```moonbit
test "hcl_int helper" {
  assert_eq(hcl_int(42), Int(42))
}

test "hcl_str helper" {
  assert_eq(hcl_str("hello"), String("hello"))
}

test "hcl_bool helper" {
  assert_eq(hcl_bool(true), Bool(true))
  assert_eq(hcl_bool(false), Bool(false))
}

test "hcl_null helper" {
  assert_eq(hcl_null(), Null)
}

test "hcl_array helper" {
  let arr = hcl_array([hcl_int(1), hcl_str("two")])
  assert_eq(arr, Array([Int(1), String("two")]))
}

test "hcl_object helper" {
  let obj = hcl_object({ "key": hcl_str("value") })
  assert_eq(obj, Object({ "key": String("value") }))
}
```

- [ ] **Step 3: 运行测试验证**

```bash
moon test
```

- [ ] **Step 4: Commit**

```bash
git add ser.mbt trait_test.mbt
git commit -m "feat: add HCLValue constructor helper functions"
```

---

## Task 3: BodyBuilder / BlockBuilder

**Files:**
- Create: `builder.mbt`
- Create: `builder_test.mbt`

- [ ] **Step 1: 创建 builder.mbt**

```moonbit
///|
/// Builder for Body
pub struct BodyBuilder {
  items : Array[BodyItem]
}

///|
/// Create a new BodyBuilder
pub fn Body::builder() -> BodyBuilder {
  { items: [] }
}

///|
/// Add an attribute with HCLValue
pub fn BodyBuilder::attr(self : BodyBuilder, key : String, value : HCLValue) -> BodyBuilder {
  self.items.push(Attribute({ key, value }))
  self
}

///|
/// Add an attribute from ToHCL value
pub fn BodyBuilder::attr_hcl[T : ToHCL](self : BodyBuilder, key : String, value : T) -> BodyBuilder {
  self.items.push(Attribute({ key, value: value.to_hcl() }))
  self
}

///|
/// Add an attribute conditionally
pub fn BodyBuilder::attr_if(
  self : BodyBuilder,
  key : String,
  value : HCLValue,
  cond : Bool,
) -> BodyBuilder {
  if cond {
    self.items.push(Attribute({ key, value }))
  }
  self
}

///|
/// Add an attribute from Option (skip if None)
pub fn BodyBuilder::attr_option[T : ToHCL](
  self : BodyBuilder,
  key : String,
  value : Option[T],
) -> BodyBuilder {
  match value {
    Some(v) => self.items.push(Attribute({ key, value: v.to_hcl() }))
    None => ()
  }
  self
}

///|
/// Add a block
pub fn BodyBuilder::block(self : BodyBuilder, block : Block) -> BodyBuilder {
  self.items.push(Block(block))
  self
}

///|
/// Build the Body
pub fn BodyBuilder::build(self : BodyBuilder) -> Body {
  { items: self.items }
}

///|
/// Builder for Block
pub struct BlockBuilder {
  type_name : String
  labels : Array[String]
  items : Array[BodyItem]
}

///|
/// Create a new BlockBuilder
pub fn Block::builder(type_name : String) -> BlockBuilder {
  { type_name, labels: [], items: [] }
}

///|
/// Add a label
pub fn BlockBuilder::label(self : BlockBuilder, label : String) -> BlockBuilder {
  self.labels.push(label)
  self
}

///|
/// Add an attribute with HCLValue
pub fn BlockBuilder::attr(self : BlockBuilder, key : String, value : HCLValue) -> BlockBuilder {
  self.items.push(Attribute({ key, value }))
  self
}

///|
/// Add an attribute from ToHCL value
pub fn BlockBuilder::attr_hcl[T : ToHCL](self : BlockBuilder, key : String, value : T) -> BlockBuilder {
  self.items.push(Attribute({ key, value: value.to_hcl() }))
  self
}

///|
/// Add an attribute conditionally
pub fn BlockBuilder::attr_if(
  self : BlockBuilder,
  key : String,
  value : HCLValue,
  cond : Bool,
) -> BlockBuilder {
  if cond {
    self.items.push(Attribute({ key, value }))
  }
  self
}

///|
/// Set the body directly
pub fn BlockBuilder::body(self : BlockBuilder, body : Body) -> BlockBuilder {
  for item in body.get_items() {
    self.items.push(item)
  }
  self
}

///|
/// Build the Block
pub fn BlockBuilder::build(self : BlockBuilder) -> Block {
  { type_name: self.type_name, labels: self.labels, body: { items: self.items } }
}
```

- [ ] **Step 2: 创建 builder_test.mbt**

```moonbit
test "Body::builder basic" {
  let body = Body::builder()
    .attr("name", String("test"))
    .attr("port", Int(8080))
    .build()
  assert_eq(body.len(), 2)
  let name_attr = body.find_attr("name")
  assert(name_attr is Some)
  assert_eq(name_attr.unwrap().get_value(), String("test"))
}

test "Body::builder attr_hcl" {
  let body = Body::builder()
    .attr_hcl("count", 42 : Int)
    .build()
  let attr = body.find_attr("count")
  assert(attr is Some)
  assert_eq(attr.unwrap().get_value(), Int(42))
}

test "Body::builder attr_if true" {
  let body = Body::builder()
    .attr_if("key", String("value"), true)
    .build()
  assert_eq(body.len(), 1)
}

test "Body::builder attr_if false" {
  let body = Body::builder()
    .attr_if("key", String("value"), false)
    .build()
  assert_eq(body.len(), 0)
}

test "Body::builder attr_option Some" {
  let body = Body::builder()
    .attr_option("key", Some("value"))
    .build()
  assert_eq(body.len(), 1)
}

test "Body::builder attr_option None" {
  let body = Body::builder()
    .attr_option("key", (None : Option[String]))
    .build()
  assert_eq(body.len(), 0)
}

test "Body::builder with block" {
  let inner = Block::builder("server")
    .attr("host", String("localhost"))
    .build()
  let body = Body::builder()
    .attr("name", String("app"))
    .block(inner)
    .build()
  assert_eq(body.len(), 2)
}

test "Block::builder basic" {
  let block = Block::builder("resource")
    .label("aws_s3_bucket")
    .label("my_bucket")
    .attr("bucket", String("my-bucket"))
    .build()
  assert_eq(block.get_type_name(), "resource")
  assert_eq(block.get_labels().length(), 2)
  assert_eq(block.get_labels()[0], "aws_s3_bucket")
  assert_eq(block.get_labels()[1], "my_bucket")
  let attr = block.find_attr("bucket")
  assert(attr is Some)
}

test "Block::builder no labels" {
  let block = Block::builder("server")
    .attr("port", Int(8080))
    .build()
  assert_eq(block.get_type_name(), "server")
  assert_eq(block.get_labels().length(), 0)
}

test "builder chain immutable style" {
  let builder = Body::builder()
  let b1 = builder.attr("a", Int(1))
  let b2 = b1.attr("b", Int(2))
  let body = b2.build()
  assert_eq(body.len(), 2)
}
```

- [ ] **Step 3: 运行测试验证**

```bash
moon check && moon test
```

- [ ] **Step 4: 运行 moon info 更新接口**

```bash
moon info && moon fmt
```

- [ ] **Step 5: Commit**

```bash
git add builder.mbt builder_test.mbt
git commit -m "feat: add BodyBuilder and BlockBuilder"
```

---

## Task 4: 集成测试（复杂场景）

**Files:**
- Create: `derive_test.mbt` (或在现有测试文件追加)

- [ ] **Step 1: 创建集成测试**

```moonbit
// 模拟用户自定义结构体的序列化/反序列化

test "custom struct to_hcl via builder" {
  // 模拟: struct Config { host: String, port: Int, debug: Bool }
  let body = Body::builder()
    .attr_hcl("host", "localhost")
    .attr_hcl("port", 8080 : Int)
    .attr_hcl("debug", true)
    .build()
  
  let hcl_str = to_hcl_body(body)
  assert(hcl_str.contains("host"))
  assert(hcl_str.contains("8080"))
  assert(hcl_str.contains("true"))
}

test "nested block serialization" {
  let server_block = Block::builder("server")
    .attr("host", String("localhost"))
    .attr("port", Int(8080))
    .build()
  
  let body = Body::builder()
    .attr("app_name", String("myapp"))
    .block(server_block)
    .build()
  
  let hcl_str = to_hcl_body(body)
  assert(hcl_str.contains("app_name"))
  assert(hcl_str.contains("server"))
  assert(hcl_str.contains("host"))
}

test "to_hcl_string with struct-like usage" {
  // 使用 Map 模拟结构体
  let config : Map[String, HCLValue] = {
    "host": String("localhost"),
    "port": Int(8080),
    "debug": Bool(false)
  }
  let hcl = to_hcl_string(config)
  assert(hcl.contains("host"))
  assert(hcl.contains("8080"))
}

test "from_hcl_string to Map" {
  let input = "host = \"localhost\"\nport = 8080"
  let result : HCLResult[Map[String, HCLValue]] = from_hcl_string(input)
  assert(result is Ok)
  let m = result.unwrap()
  assert_eq(m["host"], String("localhost"))
  assert_eq(m["port"], Int(8080))
}

test "optional fields in builder" {
  let debug : Option[Bool] = None
  let timeout : Option[Int] = Some(30)
  
  let body = Body::builder()
    .attr("host", String("localhost"))
    .attr_option("debug", debug)
    .attr_option("timeout", timeout)
    .build()
  
  assert_eq(body.len(), 2) // debug skipped, host + timeout
  assert(body.find_attr("debug") is None)
  assert(body.find_attr("timeout") is Some)
}

test "complex nested structure" {
  let db_block = Block::builder("database")
    .label("primary")
    .attr("host", String("db.example.com"))
    .attr("port", Int(5432))
    .build()
  
  let cache_block = Block::builder("cache")
    .attr("driver", String("redis"))
    .attr("ttl", Int(3600))
    .build()
  
  let body = Body::builder()
    .attr("app_name", String("myapp"))
    .attr("version", String("1.0.0"))
    .block(db_block)
    .block(cache_block)
    .build()
  
  assert_eq(body.len(), 4)
  let hcl = to_hcl_body(body)
  assert(hcl.contains("database"))
  assert(hcl.contains("cache"))
  assert(hcl.contains("primary"))
}
```

- [ ] **Step 2: 运行所有测试**

```bash
moon test
```

- [ ] **Step 3: 运行 moon info 更新接口**

```bash
moon info && moon fmt
```

- [ ] **Step 4: Commit**

```bash
git add derive_test.mbt
git commit -m "test: add integration tests for serialization derive support"
```

---

## Task 5: 更新 PROGRESS.md 和最终验证

**Files:**
- Modify: `PROGRESS.md`

- [ ] **Step 1: 更新 PROGRESS.md**

将序列化 derive 支持从未完成标记为已完成，更新文件结构。

- [ ] **Step 2: 运行完整验证**

```bash
moon check && moon test && moon info && moon fmt
```

- [ ] **Step 3: Commit**

```bash
git add PROGRESS.md
git commit -m "docs: mark serialization derive support as complete"
```

---

## 最终验证清单

- [ ] `moon check` 通过
- [ ] `moon test` 全部测试通过
- [ ] `moon info` 成功生成
- [ ] `moon fmt` 格式化完成
- [ ] `.mbti` 文件更新正确
- [ ] PROGRESS.md 已更新
