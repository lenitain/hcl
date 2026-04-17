# Schema 验证实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 HCL 值提供类型检查、必填字段验证和自定义验证器支持

**Architecture:** 创建 `schema.mbt` 定义 Schema 类型（TypeSchema），支持对象/数组/标量类型验证。验证函数返回带路径的错误列表，便于定位问题。

**Tech Stack:** MoonBit, 现有 HCLValue/HCLError 类型

---

## 文件结构

- Create: `schema.mbt` - Schema 类型定义和验证逻辑
- Create: `schema_test.mbt` - Schema 验证测试
- Modify: `error.mbt` - 添加 ValidationError 类型

## 任务分解

### Task 1: 扩展错误类型

**Files:**
- Modify: `error.mbt`

- [ ] **Step 1: 添加 ValidationError**

在 `error.mbt` 的 `HCLError` 枚举中添加：
```
/// Validation error with path
ValidationError(String, String)
```

- [ ] **Step 2: 添加构造函数**

```moonbit
/// Create a validation error
pub fn HCLError::validation_error(path : String, msg : String) -> HCLError {
  ValidationError(path, msg)
}
```

- [ ] **Step 3: 更新 message 方法**

在 `HCLError::message` 中添加：
```
ValidationError(path, msg) =>
  "Validation error at " + path + ": " + msg
```

- [ ] **Step 4: 运行测试验证无破坏**

```bash
moon test
```

- [ ] **Step 5: 提交**

```bash
git add error.mbt
git commit -m "feat: add ValidationError to HCLError"
```

---

### Task 2: 创建 Schema 类型定义

**Files:**
- Create: `schema.mbt`

- [ ] **Step 1: 创建 schema.mbt 骨架**

```moonbit
///|
/// HCL Schema - type definitions for validation

/// Schema for validating HCL values
pub(all) enum TypeSchema {
  /// Any value is accepted
  Any
  /// Null value
  Null
  /// Boolean value
  Bool
  /// Integer value
  Int
  /// 64-bit integer
  Int64
  /// Float value
  Float
  /// Number (int or float)
  Number
  /// String value
  String
  /// Array with element schema
  Array(TypeSchema)
  /// Object with field schemas
  Object(Map[String, FieldSchema])
} derive(Debug, Eq)

/// Schema for an object field
pub struct FieldSchema {
  /// Field type schema
  schema : TypeSchema
  /// Whether field is required
  required : Bool
  /// Optional description
  description : String
} derive(Debug, Eq)
```

- [ ] **Step 2: 添加 FieldSchema 构造函数**

```moonbit
///|
/// Create a required field schema
pub fn FieldSchema::required(schema : TypeSchema) -> FieldSchema {
  { schema, required: true, description: "" }
}

///|
/// Create an optional field schema
pub fn FieldSchema::optional(schema : TypeSchema) -> FieldSchema {
  { schema, required: false, description: "" }
}

///|
/// Create a field schema with description
pub fn FieldSchema::with_description(
  self : FieldSchema,
  desc : String,
) -> FieldSchema {
  { ..self, description: desc }
}
```

- [ ] **Step 3: 添加便捷构造函数**

```moonbit
///|
/// Schema for any value
pub fn TypeSchema::any() -> TypeSchema { Any }

///|
/// Schema for boolean
pub fn TypeSchema::bool() -> TypeSchema { Bool }

///|
/// Schema for integer
pub fn TypeSchema::int() -> TypeSchema { Int }

///|
/// Schema for string
pub fn TypeSchema::string() -> TypeSchema { String }

///|
/// Schema for array
pub fn TypeSchema::array(element : TypeSchema) -> TypeSchema { Array(element) }

///|
/// Schema for object
pub fn TypeSchema::object(fields : Map[String, FieldSchema]) -> TypeSchema {
  Object(fields)
}
```

- [ ] **Step 4: 编译检查**

```bash
moon check
```

- [ ] **Step 5: 提交**

```bash
git add schema.mbt
git commit -m "feat: add TypeSchema and FieldSchema types"
```

---

### Task 3: 实现验证逻辑

**Files:**
- Modify: `schema.mbt`

- [ ] **Step 1: 添加验证函数**

```moonbit
///|
/// Validate a value against a schema
pub fn validate(value : HCLValue, schema : TypeSchema) -> Array[HCLError] {
  validate_at(value, schema, "$")
}

///|
/// Validate with path tracking
fn validate_at(
  value : HCLValue,
  schema : TypeSchema,
  path : String,
) -> Array[HCLError] {
  match schema {
    Any => []
    Null =>
      if value.is_null() { [] }
      else { [HCLError::validation_error(path, "expected null")] }
    Bool =>
      if value.is_bool() { [] }
      else { [HCLError::validation_error(path, "expected bool")] }
    Int =>
      match value {
        Int(_) => []
        _ => [HCLError::validation_error(path, "expected int")]
      }
    Int64 =>
      match value {
        Int64(_) => []
        _ => [HCLError::validation_error(path, "expected int64")]
      }
    Float =>
      match value {
        Float(_) => []
        _ => [HCLError::validation_error(path, "expected float")]
      }
    Number =>
      if value.is_number() { [] }
      else { [HCLError::validation_error(path, "expected number")] }
    String =>
      if value.is_string() { [] }
      else { [HCLError::validation_error(path, "expected string")] }
    Array(elem_schema) =>
      validate_array(value, elem_schema, path)
    Object(field_schemas) =>
      validate_object(value, field_schemas, path)
  }
}
```

- [ ] **Step 2: 实现数组验证**

```moonbit
///|
/// Validate array value
fn validate_array(
  value : HCLValue,
  elem_schema : TypeSchema,
  path : String,
) -> Array[HCLError] {
  match value {
    Array(arr) => {
      let errors = []
      for i in 0..<arr.length() {
        let elem_path = path + "[" + i.to_string() + "]"
        let elem_errors = validate_at(arr[i], elem_schema, elem_path)
        for e in elem_errors {
          errors.push(e)
        }
      }
      errors
    }
    _ => [HCLError::validation_error(path, "expected array")]
  }
}
```

- [ ] **Step 3: 实现对象验证**

```moonbit
///|
/// Validate object value
fn validate_object(
  value : HCLValue,
  field_schemas : Map[String, FieldSchema],
  path : String,
) -> Array[HCLError] {
  match value {
    Object(obj) => {
      let errors = []
      // Check required fields
      for name, field_schema in field_schemas {
        let field_path = path + "." + name
        match obj[name] {
          Some(field_value) => {
            let field_errors = validate_at(
              field_value,
              field_schema.schema,
              field_path,
            )
            for e in field_errors {
              errors.push(e)
            }
          }
          None =>
            if field_schema.required {
              errors.push(
                HCLError::validation_error(field_path, "required field missing"),
              )
            }
        }
      }
      errors
    }
    _ => [HCLError::validation_error(path, "expected object")]
  }
}
```

- [ ] **Step 4: 添加批量验证函数**

```moonbit
///|
/// Validate and return first error, or Ok
pub fn validate_one(
  value : HCLValue,
  schema : TypeSchema,
) -> HCLResult[()] {
  let errors = validate(value, schema)
  if errors.is_empty() {
    Ok(())
  } else {
    Err(errors[0])
  }
}

///|
/// Check if value is valid
pub fn is_valid(value : HCLValue, schema : TypeSchema) -> Bool {
  validate(value, schema).is_empty()
}
```

- [ ] **Step 5: 编译检查**

```bash
moon check
```

- [ ] **Step 6: 提交**

```bash
git add schema.mbt
git commit -m "feat: implement schema validation logic"
```

---

### Task 4: 编写测试

**Files:**
- Create: `schema_test.mbt`

- [ ] **Step 1: 创建测试文件**

```moonbit
///|
/// Schema validation tests

test "validate any schema" {
  let schema = TypeSchema::any()
  assert_true(is_valid(Null, schema))
  assert_true(is_valid(Int(42), schema))
  assert_true(is_valid(String("hello"), schema))
}

test "validate bool schema" {
  let schema = TypeSchema::bool()
  assert_true(is_valid(Bool(true), schema))
  assert_true(is_valid(Bool(false), schema))
  assert_false(is_valid(Int(1), schema))
  assert_false(is_valid(String("true"), schema))
}

test "validate int schema" {
  let schema = TypeSchema::int()
  assert_true(is_valid(Int(42), schema))
  assert_false(is_valid(Int64(42), schema))
  assert_false(is_valid(Float(3.14), schema))
  assert_false(is_valid(String("42"), schema))
}

test "validate string schema" {
  let schema = TypeSchema::string()
  assert_true(is_valid(String("hello"), schema))
  assert_false(is_valid(Int(42), schema))
}

test "validate array schema" {
  let schema = TypeSchema::array(TypeSchema::int())
  assert_true(is_valid(Array([Int(1), Int(2), Int(3)]), schema))
  assert_false(is_valid(Array([Int(1), String("a")]), schema))
  assert_false(is_valid(Int(42), schema))
}

test "validate object schema" {
  let schema = TypeSchema::object({
    "name": FieldSchema::required(TypeSchema::string()),
    "age": FieldSchema::optional(TypeSchema::int()),
  })
  assert_true(is_valid(Object({"name": String("Alice")}), schema))
  assert_true(is_valid(Object({"name": String("Bob"), "age": Int(30)}), schema))
  assert_false(is_valid(Object({}), schema))
  assert_false(is_valid(Object({"name": Int(42)}), schema))
}

test "validate returns error path" {
  let schema = TypeSchema::object({
    "user": FieldSchema::required(TypeSchema::object({
      "name": FieldSchema::required(TypeSchema::string()),
    })),
  })
  let errors = validate(Object({"user": Object({})}), schema)
  assert_eq(errors.length(), 1)
  assert_true(errors[0].message().contains("$.user.name"))
}

test "validate nested array" {
  let schema = TypeSchema::array(TypeSchema::array(TypeSchema::int()))
  let value = Array([Array([Int(1), Int(2)]), Array([Int(3)])])
  assert_true(is_valid(value, schema))
}

test "validate_one returns first error" {
  let schema = TypeSchema::object({
    "a": FieldSchema::required(TypeSchema::int()),
    "b": FieldSchema::required(TypeSchema::string()),
  })
  let result = validate_one(Object({}), schema)
  assert_true(result.is_err())
}
```

- [ ] **Step 2: 运行测试**

```bash
moon test
```

- [ ] **Step 3: 修复问题（如有）**

- [ ] **Step 4: 提交**

```bash
git add schema_test.mbt
git commit -m "test: add schema validation tests"
```

---

### Task 5: 添加自定义验证器支持

**Files:**
- Modify: `schema.mbt`

- [ ] **Step 1: 添加 Validator 类型**

```moonbit
///|
/// Custom validator function type
pub type Validator = (HCLValue, String) -> Array[HCLError]

///|
/// Extended field schema with custom validators
pub struct FieldSchemaEx {
  /// Base field schema
  base : FieldSchema
  /// Custom validators
  validators : Array[Validator]
} derive(Debug, Eq)

///|
/// Create extended field schema
pub fn FieldSchemaEx::new(base : FieldSchema) -> FieldSchemaEx {
  { base, validators: [] }
}

///|
/// Add validator to field schema
pub fn FieldSchemaEx::add_validator(
  self : FieldSchemaEx,
  v : Validator,
) -> FieldSchemaEx {
  let vs = self.validators.copy()
  vs.push(v)
  { ..self, validators: vs }
}
```

- [ ] **Step 2: 添加验证函数扩展**

```moonbit
///|
/// Validate with custom validators
pub fn validate_ex(
  value : HCLValue,
  schema : Map[String, FieldSchemaEx],
) -> Array[HCLError] {
  validate_object_ex(value, schema, "$")
}

///|
/// Validate object with extended field schemas
fn validate_object_ex(
  value : HCLValue,
  field_schemas : Map[String, FieldSchemaEx],
  path : String,
) -> Array[HCLError] {
  match value {
    Object(obj) => {
      let errors = []
      for name, field_schema in field_schemas {
        let field_path = path + "." + name
        match obj[name] {
          Some(field_value) => {
            // Base validation
            let base_errors = validate_at(
              field_value,
              field_schema.base.schema,
              field_path,
            )
            for e in base_errors {
              errors.push(e)
            }
            // Custom validators
            for v in field_schema.validators {
              let custom_errors = v(field_value, field_path)
              for e in custom_errors {
                errors.push(e)
              }
            }
          }
          None =>
            if field_schema.base.required {
              errors.push(
                HCLError::validation_error(field_path, "required field missing"),
              )
            }
        }
      }
      errors
    }
    _ => [HCLError::validation_error(path, "expected object")]
  }
}
```

- [ ] **Step 3: 添加常用验证器**

```moonbit
///|
/// Validator: string not empty
pub fn string_not_empty() -> Validator {
  fn(value, path) {
    match value {
      String(s) if s.is_empty() => [
        HCLError::validation_error(path, "string must not be empty"),
      ]
      _ => []
    }
  }
}

///|
/// Validator: int in range
pub fn int_in_range(min : Int, max : Int) -> Validator {
  fn(value, path) {
    match value {
      Int(i) if i < min || i > max => [
        HCLError::validation_error(
          path,
          "value " + i.to_string() + " not in range [" + min.to_string() + ", " + max.to_string() + "]",
        ),
      ]
      _ => []
    }
  }
}

///|
/// Validator: string matches pattern (simple prefix/suffix check)
pub fn string_starts_with(prefix : String) -> Validator {
  fn(value, path) {
    match value {
      String(s) if !s.starts_with(prefix) => [
        HCLError::validation_error(
          path,
          "string must start with " + prefix,
        ),
      ]
      _ => []
    }
  }
}
```

- [ ] **Step 4: 编译检查**

```bash
moon check
```

- [ ] **Step 5: 提交**

```bash
git add schema.mbt
git commit -m "feat: add custom validator support"
```

---

### Task 6: 自定义验证器测试

**Files:**
- Modify: `schema_test.mbt`

- [ ] **Step 1: 添加测试用例**

```moonbit
test "custom validator - string not empty" {
  let schema = {
    "name": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
      .add_validator(string_not_empty()),
  }
  let errors = validate_ex(Object({"name": String("")}), schema)
  assert_eq(errors.length(), 1)
  assert_true(errors[0].message().contains("must not be empty"))
}

test "custom validator - int in range" {
  let schema = {
    "age": FieldSchemaEx::new(FieldSchema::required(TypeSchema::int()))
      .add_validator(int_in_range(0, 150)),
  }
  assert_eq(validate_ex(Object({"age": Int(25)}), schema).length(), 0)
  assert_eq(validate_ex(Object({"age": Int(-1)}), schema).length(), 1)
  assert_eq(validate_ex(Object({"age": Int(200)}), schema).length(), 1)
}

test "custom validator - string starts with" {
  let schema = {
    "id": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
      .add_validator(string_starts_with("usr_")),
  }
  assert_eq(validate_ex(Object({"id": String("usr_123")}), schema).length(), 0)
  assert_eq(validate_ex(Object({"id": String("abc")}), schema).length(), 1)
}

test "multiple validators" {
  let schema = {
    "name": FieldSchemaEx::new(FieldSchema::required(TypeSchema::string()))
      .add_validator(string_not_empty())
      .add_validator(string_starts_with("A")),
  }
  assert_eq(validate_ex(Object({"name": String("Alice")}), schema).length(), 0)
  assert_eq(validate_ex(Object({"name": String("")}), schema).length(), 2)
}
```

- [ ] **Step 2: 运行测试**

```bash
moon test
```

- [ ] **Step 3: 修复问题（如有）**

- [ ] **Step 4: 提交**

```bash
git add schema_test.mbt
git commit -m "test: add custom validator tests"
```

---

### Task 7: 集成到反序列化

**Files:**
- Modify: `de.mbt`

- [ ] **Step 1: 添加带验证的反序列化函数**

```moonbit
///|
/// Deserialize HCL with schema validation
pub fn from_hcl_with_schema(
  input : String,
  schema : TypeSchema,
) -> HCLResult[HCLValue] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      let errors = validate(value, schema)
      if errors.is_empty() {
        Ok(value)
      } else {
        Err(errors[0])
      }
    }
    Err(e) => Err(e)
  }
}

///|
/// Deserialize HCL with schema, return all errors
pub fn from_hcl_with_schema_full(
  input : String,
  schema : TypeSchema,
) -> Result[HCLValue, Array[HCLError]] {
  match parse(input) {
    Ok(body) => {
      let value = body_to_value(body)
      let errors = validate(value, schema)
      if errors.is_empty() {
        Ok(value)
      } else {
        Err(errors)
      }
    }
    Err(e) => Err([e])
  }
}
```

- [ ] **Step 2: 编译检查**

```bash
moon check
```

- [ ] **Step 3: 提交**

```bash
git add de.mbt
git commit -m "feat: integrate schema validation with deserialization"
```

---

### Task 8: 集成测试

**Files:**
- Modify: `schema_test.mbt`

- [ ] **Step 1: 添加端到端测试**

```moonbit
test "from_hcl_with_schema - valid config" {
  let hcl = `
    server {
      host = "localhost"
      port = 8080
    }
  `
  let schema = TypeSchema::object({
    "server": FieldSchema::required(TypeSchema::object({
      "host": FieldSchema::required(TypeSchema::string()),
      "port": FieldSchema::required(TypeSchema::int()),
    })),
  })
  let result = from_hcl_with_schema(hcl, schema)
  assert_true(result.is_ok())
}

test "from_hcl_with_schema - invalid config" {
  let hcl = `
    server {
      host = "localhost"
    }
  `
  let schema = TypeSchema::object({
    "server": FieldSchema::required(TypeSchema::object({
      "host": FieldSchema::required(TypeSchema::string()),
      "port": FieldSchema::required(TypeSchema::int()),
    })),
  })
  let result = from_hcl_with_schema(hcl, schema)
  assert_true(result.is_err())
}

test "from_hcl_with_schema_full - multiple errors" {
  let hcl = `
    config {
    }
  `
  let schema = TypeSchema::object({
    "config": FieldSchema::required(TypeSchema::object({
      "name": FieldSchema::required(TypeSchema::string()),
      "value": FieldSchema::required(TypeSchema::int()),
    })),
  })
  let result = from_hcl_with_schema_full(hcl, schema)
  match result {
    Err(errors) => assert_eq(errors.length(), 2)
    _ => assert_true(false)
  }
}
```

- [ ] **Step 2: 运行所有测试**

```bash
moon test
```

- [ ] **Step 3: 运行完整验证**

```bash
moon check && moon test && moon info && moon fmt
```

- [ ] **Step 4: 提交**

```bash
git add schema_test.mbt
git commit -m "test: add integration tests for schema validation"
```

---

## 验证清单

- [ ] 所有测试通过 (`moon test`)
- [ ] 类型检查通过 (`moon check`)
- [ ] 接口文件更新 (`moon info`)
- [ ] 代码格式化 (`moon fmt`)
- [ ] 测试覆盖核心功能

## 参考资料

- 现有类型：`value.mbt`, `body.mbt`, `error.mbt`
- 反序列化：`de.mbt`
- HCL 规范：https://github.com/hashicorp/hcl/blob/main/spec.md
