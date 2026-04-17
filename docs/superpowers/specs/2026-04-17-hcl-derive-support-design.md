# HCL 序列化 Derive 支持设计

## 概述

为 HCL-MoonBit 库提供序列化/反序列化 trait 和辅助工具，使用户能够方便地将 MoonBit 类型转换为 HCL 格式，以及从 HCL 格式反序列化为 MoonBit 类型。

## 背景

MoonBit 不支持自定义 derive 宏（只有内置的 Eq, Compare, ToJson, FromJson 等）。因此采用以下策略：
- 定义 `ToHCL` / `FromHCL` trait
- 提供 Builder 模式简化 HCL 构建
- 提供辅助函数减少样板代码
- 为常用类型预实现 trait

## 设计

### 1. ToHCL Trait

```moonbit
trait ToHCL {
  to_hcl(Self) -> HCLValue
}
```

用户实现示例：
```moonbit
struct Server {
  host: String
  port: Int
}

impl ToHCL for Server {
  to_hcl(self) -> HCLValue {
    Object({
      "host": String(self.host),
      "port": Int(self.port)
    })
  }
}
```

### 2. FromHCL Trait

```moonbit
trait FromHCL {
  from_hcl(HCLValue) -> HCLResult[Self]
}
```

用户实现示例：
```moonbit
impl FromHCL for Server {
  from_hcl(value: HCLValue) -> HCLResult[Server] {
    match value {
      Object(obj) => {
        let host = match obj["host"] {
          String(s) => Ok(s)
          v => Err(HCLError::type_mismatch("String", value_to_type_name(v)))
        }
        let port = match obj["port"] {
          Int(i) => Ok(i)
          v => Err(HCLError::type_mismatch("Int", value_to_type_name(v)))
        }
        match (host, port) {
          (Ok(h), Ok(p)) => Ok({ host: h, port: p })
          (Err(e), _) | (_, Err(e)) => Err(e)
        }
      }
      v => Err(HCLError::type_mismatch("Object", value_to_type_name(v)))
    }
  }
}
```

### 3. 便捷函数

```moonbit
// ToHCL -> String
fn to_hcl_string[T : ToHCL](value : T) -> String

// String -> FromHCL
fn from_hcl_string[T : FromHCL](input : String) -> HCLResult[T]
```

### 4. BodyBuilder

```moonbit
pub fn Body::builder() -> BodyBuilder

// BodyBuilder 方法：
//   .attr(key, value) -> BodyBuilder
//   .attr_hcl(key, ToHCL value) -> BodyBuilder
//   .attr_if(key, value, cond) -> BodyBuilder
//   .block(block) -> BodyBuilder
//   .build() -> Body
```

### 5. BlockBuilder

```moonbit
pub fn Block::builder(type_name: String) -> BlockBuilder

// BlockBuilder 方法：
//   .label(label) -> BlockBuilder
//   .attr(key, value) -> BlockBuilder
//   .body(body) -> BlockBuilder
//   .build() -> Block
```

### 6. HCLValue 构造辅助函数

```moonbit
pub fn hcl_int(v: Int) -> HCLValue       // Int(v)
pub fn hcl_int64(v: Int64) -> HCLValue   // Int64(v)
pub fn hcl_float(v: Double) -> HCLValue  // Float(v)
pub fn hcl_bool(v: Bool) -> HCLValue     // Bool(v)
pub fn hcl_str(v: String) -> HCLValue    // String(v)
pub fn hcl_null() -> HCLValue            // Null
pub fn hcl_array(items: Array[HCLValue]) -> HCLValue
pub fn hcl_object(entries: Map[String, HCLValue]) -> HCLValue
```

### 7. 预实现的类型

**ToHCL:**
- Int, Int64, Double, Bool, String
- Array[T] where T: ToHCL
- Map[String, T] where T: ToHCL
- Option[T] where T: ToHCL (None -> Null)
- HCLValue (identity)

**FromHCL:**
- Int, Int64, Double, Bool, String
- Array[T] where T: FromHCL
- Map[String, T] where T: FromHCL
- Option[T] where T: FromHCL (Null -> None)
- HCLValue (identity)

## 文件结构

```
hcl/
├── trait.mbt           # ToHCL / FromHCL trait 定义 + 预实现
├── trait_test.mbt      # trait 测试
├── builder.mbt         # BodyBuilder / BlockBuilder
├── builder_test.mbt    # builder 测试
├── ser.mbt             # 现有序列化（扩展辅助函数）
├── de.mbt              # 现有反序列化（扩展便捷方法）
```

## 测试要求

1. trait 基本类型序列化/反序列化
2. 嵌套结构序列化/反序列化
3. Option 类型处理
4. Builder 链式 API
5. 错误处理（类型不匹配、缺失字段）
6. 往返测试（serialize -> deserialize == original）
