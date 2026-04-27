# HCL-MoonBit 项目进度

## 当前状态：隐式类型转换 (Implicit Type Conversion) 进行中

## 当前分支
- 分支：`lenitain/feat/implicit-type-conversion`
- 状态：开发中
- 目标：隐式类型转换（P0 #2）

## 本次开发完成的任务
- ✅ `HCLValue::type_name()` 方法 — 获取值类型名称字符串
- ✅ `string_to_bool` — 字符串转布尔值（"true"/"1" → true, "false"/"0" → false）
- ✅ `string_to_number` — 字符串转数字（支持整数、浮点数、正负号）
- ✅ `number_to_string` — 数字转字符串
- ✅ `bool_to_string` — 布尔值转字符串
- ✅ `try_convert` — 统一类型转换入口（pub fn）
- ✅ 所有 588 个测试通过
- ✅ moon check: 0 errors
- ✅ moon fmt: 通过
- ✅ `HCLValue::Unknown(Decor)` 变体
- ✅ `Expression::ExprUnknown` 变体
- ✅ `expr_to_hcl_value` / `hcl_value_to_expression` 桥接 Unknown
- ✅ 序列化输出 `"unknown"`（非 `"null"`）
- ✅ JSON 输出 `"null"`（JSON 无 unknown 概念）
- ✅ Eval 传播：binary/unary/conditional 遇 Unknown 返回 Unknown
- ✅ Schema 验证：Unknown 通过所有 schema
- ✅ `tostring(unknown)` 返回 `"unknown"`
- ✅ 所有 588 个测试通过（相比之前增加 18 个）
- ✅ moon check: 0 errors
- ✅ moon fmt: 通过

## 警告统计
- 25 警告（主要是 trait impl 的 unused_value，这些是 MoonBit trait 系统的正常警告）

## 设计要点
- 参考 hcl-rs 的 hcl2json CLI 设计
- 适配 MoonBit 语言特性（有限的文件 I/O 支持）
- 支持基本 HCL 到 JSON 转换
- 支持格式化 JSON 输出（--pretty 选项）
- 错误处理和用户友好的消息显示

## 重构计划

按 hcl-rs 方案重写核心类型，优先级：

### 第一阶段：核心类型
| 任务 | 状态 | 依赖 |
|------|------|------|
| Expression 独立枚举 | ✅ 完成 | - |
| Value 统一 Number 类型 | ✅ 完成 | - |
| Identifier 类型 | ✅ 完成 | - |
| ObjectKey 类型 | ✅ 已包含 | Expression |

### 第二阶段：表达式类型
| 任务 | 状态 | 依赖 |
|------|------|------|
| Traversal 类型 + TraversalBuilder | ✅ 完成 | Expression |
| FuncCall 类型 + FuncCallBuilder | ✅ 完成 | Expression |
| FuncDef 参数类型验证 | ⏭️ 跳过 | FuncCall |
| Conditional 类型 | ✅ 已包含 | Expression |
| ForExpr 类型 | ✅ 已包含 | Expression |
| Operation 类型 | ✅ 已包含 | Expression |
| Parenthesis 支持 | ✅ 已包含 | Expression |
| ExprUnknown 类型 | ✅ 完成 | Expression |

### 第三阶段：Builder 模式
| 任务 | 状态 | 依赖 |
|------|------|------|
| BodyBuilder | ✅ 已有 | - |
| BlockBuilder | ✅ 已有 | - |
| TraversalBuilder | ✅ 完成 | Traversal |
| FuncCallBuilder | ✅ 完成 | FuncCall |

### 第四阶段：数据结构增强
| 任务 | 状态 | 依赖 |
|------|------|------|
| Map 类型 (IndexMap 替代) | ✅ 完成 | - |
| 格式化器配置 (dense/compact) | ✅ 完成 | - |
| prefer_ident_keys 选项 | ✅ 完成 | - |

### 第五阶段：高级功能
| 任务 | 状态 | 依赖 |
|------|------|------|
| hcl-edit (visit/visit_mut) | ✅ 完成 | Expression |
| Decorated\<Expression\> 包装 | ✅ 完成 | Decor |
| hcl2json CLI 批量处理 | ✅ 完成 | - |
| hcl2json glob 模式 | ⏳ | - |
| hcl2json --simplify 选项 | ✅ 完成 | eval |
| specsuite 完整测试套件 | 🔄 进行中 | - |

### 第六阶段：适配
| 任务 | 状态 | 依赖 |
|------|------|------|
| 适配 parser | ⏳ | 以上全部 |
| 适配 eval | ⏳ | 以上全部 |
| 适配 template | ⏳ | 以上全部 |

## 已完成 ✅

### 核心数据结构
- `value.mbt` - HCLValue 枚举（Null, Bool, Number, String, Array, Object）
- `body.mbt` - Body, BodyItem, Attr, Block 结构体
- `token.mbt` - Token 枚举（所有 token 类型）
- `error.mbt` - HCLError 和 HCLResult 类型
- `number.mbt` - Number 类型（PosInt/NegInt/Float 内部表示）
- `ident.mbt` - Ident 类型（标识符验证和构造）
- `object.mbt` - HCLObject 类型别名 + HCLObjectBuilder（新增）
- `object_wbtest.mbt` - HCLObject 白盒测试（新增）

### 词法分析器 (lexer.mbt)
- ✅ 基础 token 识别
- ✅ 字符串字面量（带转义序列）
- ✅ 数字字面量（整数、浮点数、十六进制0x、八进制0o、二进制0b、科学计数法）
- ✅ 标识符和关键字（true, false, null, for, in, if）
- ✅ 行注释 (//)
- ✅ 块注释 (/* */)
- ✅ Unicode 支持（使用 UInt16）
- ✅ 所有运算符和分隔符
- ✅ Heredoc 完整解析（delimiter、content、strip）

### 解析器 (parser.mbt)
- ✅ 解析属性 (key = value)
- ✅ 解析块 (type labels { body })
- ✅ 解析对象 ({ key = value })
- ✅ 解析数组 ([values])
- ✅ 解析嵌套结构
- ✅ 解析字符串、数字、布尔值、null
- ✅ 错误定位（行号、列号）
- ✅ 二元运算符表达式（+, -, *, /, %, ==, !=, <, >, <=, >=, &&, ||）
- ✅ 条件表达式 (cond ? true : false)
- ✅ Heredoc 解析（<<EOF, <<-EOF，自定义 delimiter）

### 序列化框架
- `ser.mbt` - 序列化（to_hcl_* 函数）
- `de.mbt` - 反序列化（from_hcl_* 函数）
- ✅ HCLValue 到字符串
- ✅ Body 到字符串
- ✅ 字符串转义

### 序列化 Derive 支持
- `trait.mbt` - ToHCL/FromHCL trait 定义
- `builder.mbt` - Builder 模式辅助函数
- ✅ ToHCL trait（to_hcl_value 方法）
- ✅ FromHCL trait（from_hcl_value 方法）
- ✅ 基础类型自动实现（Int, Double, String, Bool 等）
- ✅ Array/Option 泛型实现
- ✅ Builder 模式（ObjectBuilder, ArrayBuilder）
- ✅ derive 白盒测试覆盖

### 测试
- ✅ 588 个测试全部通过
- 覆盖：属性解析、块解析、嵌套块、数组、对象、布尔值、null、注释
- 覆盖：表达式求值、条件表达式、函数调用、变量引用、属性访问
- 覆盖：模板系统（字符串插值、条件指令、for循环、heredoc）
- 覆盖：for表达式（列表推导、对象推导、条件过滤）
- 覆盖：Schema验证（类型检查、必填字段、自定义验证器、集成测试）
- 覆盖：Heredoc 解析（基本、多行、strip、自定义 delimiter）
- 覆盖：JSON 转换（基本、嵌套、转义、错误处理）
- 覆盖：序列化 derive（ToHCL trait、FromHCL trait、Builder 模式、Option/Array 泛型）
- 覆盖：内置函数（数字、集合、字符串、类型转换，共45个函数）
- 覆盖：Spec 测试（操作符、heredoc、多行表达式）
- 覆盖：Decor 系统（解析保留注释/空白、序列化输出装饰、集成测试）
- 覆盖：hcl2json CLI 基础功能（HCL 到 JSON 转换、格式化输出）
- 覆盖：simplify 功能（二元运算、比较、条件、一元运算、数组、嵌套表达式）
- 覆盖：Unknown 值（HCLValue::Unknown、Expression::ExprUnknown、桥接函数、工厂函数）

### 表达式求值 (eval.mbt)
- ✅ 二元运算符 (+, -, *, /, %, ==, !=, <, >, <=, >=, &&, ||)
- ✅ 一元运算符 (-, !)
- ✅ 条件表达式 (cond ? true : false)
- ✅ 函数调用框架
- ✅ 变量引用
- ✅ 属性访问 (obj.key, obj["key"])
- ✅ 类型检查和错误处理
- ✅ 类型转换辅助函数（string_to_bool, string_to_number, try_convert）

### 模板系统 (template.mbt)
- ✅ 字符串插值 (${expr})
- ✅ 模板指令 (%{if}, %{for})
- ✅ Heredoc (<<EOF, <<-EOF)
- ✅ 嵌套条件和循环
- ✅ 变量替换
- ✅ 类型转换（HCLValue 到字符串）

### for 表达式 (parser.mbt + eval.mbt)
- ✅ 列表推导 [for x in list: expr]
- ✅ 对象推导 {for k, v in obj: k => v}
- ✅ 条件过滤 if condition
- ✅ 嵌套 for 表达式
- ✅ 二元运算符表达式支持（新增）

### 内置函数 (funcs.mbt) - 新增
- ✅ 数字函数 (abs, ceil, floor, log, max, min, parseint, pow, signum)
- ✅ 集合函数 (length, keys, values, contains, flatten, merge, reverse, distinct, sort, slice, element)
- ✅ 字符串函数 (chomp, indent, join, lower, upper, replace, split, strrev, substr, trim, trimprefix, trimsuffix, trimspace, format, formatlist)
- ✅ 类型转换函数 (tobool, tonumber, tolist, tomap, toset, tostring)
- ✅ 通过 builtin_functions() 获取所有内置函数

### 多行表达式 (parser.mbt) - 新增
- ✅ 条件表达式支持换行 (true ? "a" : "b")
- ✅ 二元运算符支持换行 (1 + 2)
- ✅ 数组内表达式支持换行

### Schema 验证 (schema.mbt)
- ✅ 类型检查（TypeSchema 枚举）
- ✅ 必填字段验证（FieldSchema.required）
- ✅ 自定义验证器（Validator 类型）
- ✅ 路径跟踪错误消息（$.user.name）
- ✅ 集成到反序列化（from_hcl_with_schema）

## 待实现：对标完整 HCL 规范的缺口

综合评估：整体约 55% 完整度。核心解析/求值/序列化已可用，但缺以下关键功能。

### 🔴 P0：生产环境必备

| # | 功能 | 说明 | 影响 |
|---|------|------|------|
| 1 | **未知值 (Unknown values)** | ✅ 已完成。`HCLValue::Unknown(Decor)` + `Expression::ExprUnknown` + 桥接函数。Unknown 通过所有 schema 验证 + tostring 返回 "unknown"。 | Terraform 兼容性已可用 |
| 2 | **隐式类型转换** | 🔄 辅助函数已实现（string_to_bool, string_to_number, try_convert），待集成到 eval_binary/eval_eq 等 | 现有 `.tf` 文件大量依赖隐式转换 |
| 3 | **JSON 语法解析** | `json.mbt` 只有 HCL→JSON 序列化，没有 JSON→HCL body 解析。HCL spec 定义了一套 JSON 等效语法。 | 无法读取 `terraform.tfvars.json` |
| 4 | **模板 else 子句** | `%{if cond}...%{else}...%{endif}` 未实现，`template.mbt` 只处理 if/endif。 | 大量 Terraform 模板不可用 |
| 5 | **表达式类型安全重构** | ✅ 已完成 | 架构缺陷修复 |

### 🟡 P1：重要但可暂缓

| # | 功能 | 说明 |
|---|------|------|
| 6 | **Splat 运算符** | `list.*.attr` 和 `list[*].attr` 无法解析。`parser.mbt:776-840` 处理 `.` 和 `[` 但无 `*` 支持。 |
| 7 | **模板 Strip markers** | `${~ expr ~}` 去除相邻空白未实现。 |
| 8 | **Unicode 标识符** | `ident.mbt:11` 注明不支持 XID_Start/XID_Continue，只支持 ASCII。 |
| 9 | **Schema 驱动的 body 提取** | 现有 schema 只做 value 类型校验，没有 body 结构提取（类似 `.hcldec` 的功能：根据 schema 把 body 解析成结构化的 attribute map + block sequence）。 |

### 🟢 P2：锦上添花

| # | 功能 | 说明 |
|---|------|------|
| 10 | **源位置保留在 AST 中** | Body/Attr/Block/HCLValue 只有 Decor（注释/空白），没有 source span。错误定位有但不够精确。 |
| 11 | **UTF-8 BOM 拒绝 + UTF-8 验证** | Lexer 不做 BOM 检查和 UTF-8 合法性验证。 |
| 12 | **类型统一 (Type unification)** | 条件表达式、函数返回值等需要 unification lattice 找到共同类型。 |
| 13 | **函数参数定义系统** | `funcs.mbt` 用裸 closure `(Array[HCLValue]) -> Result`，缺少 formal param spec（位置/variadic、类型约束、null 接受标志）。 |
| 14 | **静态分析 API** | 没有 `visit.mbt` 之外的静态分析工具（list/map/call/traversal 分析）。 |

### 优先级排序（建议下次迭代顺序）

```
迭代 1 (P0):  表达式类型安全重构 (#5) → ✅ 已完成
迭代 2 (P0):  未知值 Unknown (#1) → ✅ 已完成
迭代 3 (P0):  模板 else (#4) → 影响面广
迭代 4 (P0):  隐式类型转换 (#2) → 关系到所有表达式求值
迭代 5 (P0):  JSON 语法解析 (#3) → 独立模块，可并行
迭代 6 (P1):  Splat (#6) + Strip markers (#7) + Unicode ident (#8)
迭代 7 (P1):  Schema body 提取 (#9)
迭代 8 (P2):  剩余功能
```

### 实现建议

**关于 #5（表达式类型安全重构）**：
✅ 已完成。当前 parser 产出 `Expression` enum 的直接实例（如 `ExprFuncCall`），而非 tagged Object。
主要改动：
1. `parser.mbt` 的表达式解析分支返回 `Expression` 而非 `HCLValue`
2. `eval.mbt` 从 string-match 改为 pattern match on enum
3. `visit.mbt` 的 Expression visitor 现在通过 `visit_attr_default` → `visit_expr` 路径真实工作
4. `Attr.value` 类型从 `HCLValue` 改为 `Expression`
5. 桥接函数 `expr_to_hcl_value` / `hcl_value_to_expression` 保证序列化层兼容

共修改 23 个文件，-949 行（代码量显著减少）。

## 已知问题

1. ~~**数字解析简化**：当前只支持基本整数和浮点数，不支持十六进制、八进制、二进制~~ ✅ 已实现
2. ~~**Unicode 转义**：不支持 \uXXXX 和 \u{XXXX} 格式~~ ✅ 已实现
3. ~~**Heredoc**：token 识别有但解析未实现~~ ✅ 已实现
4. ~~**多行表达式**：不支持跨行的复杂表达式~~ ✅ 已实现

---

## 单一库目标：缺失项和改进

**目标**：让 MoonBit 开发者只需要 `import "hcl"` 就能完成所有 HCL 工作。

### 当前已具备的核心能力 ✅

| 模块 | 功能 | 状态 |
|------|------|------|
| 解析 | `parse(String) -> HCLResult[Body]` | ✅ |
| 序列化 | `to_hcl_body`, `to_hcl_value`, `Formatter` | ✅ |
| 反序列化 | `from_hcl_body`, `from_hcl_with_schema` | ✅ |
| Trait 系统 | `ToHCL`, `FromHCL` | ✅ |
| 表达式求值 | `eval_binary/unary`, 45 个内置函数 | ✅ |
| Schema 验证 | `TypeSchema`, `FieldSchema`, `validate` | ✅ |
| JSON 转换 | `hcl_to_json`, `body_to_json_pretty` | ✅ |
| Decor 系统 | `Decor`, `Decorated[T]` | ✅ |
| Visit 遍历 | `Visit`, `VisitMut` | ✅ |
| 模板 | `TemplateExpr`, heredoc, 插值 | ✅ |
| CLI | hcl2json, --pretty, --simplify, --validate, --format | ✅ |

### 必须改进项 ❌

#### 1. API 不统一 - `hcl.mbt` 需要 central re-export ⚠️ MoonBit 限制

**问题**：`hcl.mbt` 基本是空的，开发者不知道该从哪个模块 import 什么

**状态**：MoonBit 限制 ⚠️

MoonBit 的 flat package 系统不支持 intra-package re-exports。
尝试 `pub fn parse = parser::parse` 会导致 "duplicate definition" 错误，
因为所有模块共享同一个命名空间。

**解决方案**：已实现 ✅

MoonBit 的 flat package 系统已经达到了目标！当 `cmd/main/moon.pkg` 执行
`import "hcl" @hcl` 后，所有公共 API 都可通过 `@hcl.XXX` 访问。

`cmd/main/main.mbt` 已经展示了这一点：
```moonbit
@hcl.parse(hcl_content)
@hcl.simplify_body(body)
@hcl.body_to_json_pretty(body)
```

所有 548 个测试通过，API 已可通过 `import "hcl"` 完整访问。

#### 2. `escape_hcl_string` 缺少模板标记转义 ✅ 已完成

**问题**：没有转义 `${` 和 `%{}`，这些是 HCL 的模板标记

**对比 hcl-rs**：`escape_markers()` 函数转义 `${` → `$${`

**解决方案**：已在 `ser.mbt` 的 `escape_hcl_string` 中实现 (lines 271-286)

#### 3. `simplify_body` 需要公开为公共 API ✅ 已完成

**问题**：`simplify_body` 只在 CLI 内部使用

**解决方案**：已在 `eval.mbt` 中添加 `pub fn simplify_body` (line 548)

#### 4. Map 顺序保证

**问题**：`HCLObject = Map[String, HCLValue]` - HCL 规范要求属性保持定义顺序

**解决方案**：确认 MoonBit `Map` 是否保证插入顺序；如不保证，需改用 `Array[(String, HCLValue)]`

#### 5. CLI 改进

| 功能 | 状态 | 优先级 |
|------|------|--------|
| stdin 支持 | ❌ | 高 (MoonBit 无 stdin API) |
| glob 模式 | ❌ | 中 (MoonBit 无 glob 库) |
| `hcl format` 命令 | ✅ | 中 |
| `--validate` 选项 | ✅ | 中 |
| CLI 参数解析 | ✅ | 高 |

### 代码质量警告 ⚠️ → ✅ 已修复

**已修复的警告**：

| 警告类型 | 修复前 | 修复方式 |
|----------|--------|----------|
| [0020] deprecated: use `x is Some(_)` instead | ~23 | `x.is_some()` → `x is Some(_)` |
| [0057] missing_pattern_payload (Some) | 2 | `attr is Some` → `attr is Some(_)` |
| [0053] unused_trait_bound | 2 | 移除未使用的 trait bound |
| [0002] unused_variable | 6 | 使用 `_` 前缀或移除未使用的变量 |

**剩余警告**（MoonBit 语言限制或 trait 系统正常警告）：

| 警告类型 | 数量 | 说明 |
|----------|------|------|
| [0001] unused_value | ~20 | trait impl 警告（MoonBit trait 系统正常行为） |
| [0071] core_package_not_imported | 5 | `@math` 包使用警告（编译正常） |

### 与 hcl-rs 功能对比

| 功能 | hcl-rs | MoonBit HCL | 差异来源 |
|------|--------|-------------|----------|
| Serde 集成 | `#[derive(Serialize, Deserialize)]` | 手动 trait | **语言因素** |
| Span 字节偏移 | ✅ | ❌ | 语言因素 |
| Formatted<T> 精确回环 | ✅ | ❌ | 语言因素 |
| winnow 组合子 | ✅ | ❌ | **生态因素**（无等价库） |
| perf feature | ✅ | ❌ | 生态因素 |
| indexmap/vecmap | ✅ | ❌ | **生态因素** |
| benchmarks | ✅ | ❌ | 生态因素 |

### 结论

**"单一库"目标核心功能已实现** ✅

所有高优先级改进项已完成：
1. ✅ API re-exports（MoonBit flat namespace 解决）
2. ✅ `escape_hcl_string` 模板标记转义
3. ✅ `simplify_body` 公共 API
4. ✅ CLI 参数解析（--help, --pretty, --simplify, --file）
5. ✅ `--validate` 选项（验证 HCL 可解析性）
6. ✅ `--format` 选项（输出格式化 HCL）

**当前工作**：修复代码质量警告 (~100 个警告待修复)

剩余中优先级项受 MoonBit 生态限制：
- stdin 支持（MoonBit 无 stdin API）
- glob 模式（MoonBit 无 glob 库）
- Map 顺序：已通过测试验证，MoonBit Map 保持插入顺序

## 从 hcl-rs 学到的坑

1. ✅ **二元运算符优先级** - 需要 pratt parser
2. ✅ **heredoc delimiter prefix matching** - EOF 不能匹配 EOF2
3. ✅ **空表达式 panic** - 需要处理空输入
4. ✅ **Unicode 错误位置** - 用 chars.count() 而不是 bytes
5. ✅ **UTF-16 vs UTF-8** - MoonBit String 内部是 UTF-16

## 下一步计划

### 阶段 1：表达式求值 ✅ 完成
```
1. 创建 eval.mbt ✅
2. 实现基本运算符 ✅
3. 实现条件表达式 ✅
4. 实现函数调用框架 ✅
5. 实现变量引用 ✅
6. 实现属性访问 ✅
```

### 阶段 2：模板系统 ✅ 完成
```
1. 创建 template.mbt ✅
2. 实现字符串插值 (${expr}) ✅
3. 实现 heredoc (<<EOF, <<-EOF) ✅
4. 实现模板指令 (%{if}, %{for}) ✅
```

### 阶段 3：for 表达式 ✅ 完成
```
1. 扩展 parser 支持 for ✅
2. 实现列表推导 [for x in list: expr] ✅
3. 实现对象推导 {for k, v in obj: k => v} ✅
4. 实现条件过滤 if condition ✅
```

### 阶段 4：增强功能 ✅ Schema 验证完成
```
1. Schema 验证 ✅
   - 类型检查 ✅
   - 必填字段 ✅
   - 自定义验证器 ✅
   - 路径跟踪错误 ✅
2. 更好的错误消息 ✅
3. JSON 转换 ✅
4. CLI 工具 ✅
```

### 阶段 5：高级功能（部分完成）
```
1. 保留空白和注释的编辑（类似 hcl-edit）✅
   - Decor 和 Decorated 类型 ✅
   - Body/Attr/Block 装饰支持 ✅
   - HCLValue 装饰支持 ✅
   - 解析器收集空白和注释 ✅
   - 序列化器输出装饰 ✅
2. 性能优化
3. 完整的 spec test suite
4. 更多 CLI 功能（文件读取、批量处理）
5. 序列化 derive 支持 ✅
   - ToHCL trait ✅
   - FromHCL trait ✅
   - Builder 模式 ✅
   - 基础类型自动实现 ✅
   - Array/Option 泛型实现 ✅
```

## 文件结构

```
hcl/
├── moon.mod.json      # 包配置
├── README.mbt.md      # 文档
├── PROGRESS.md        # 本文件
├── body.mbt           # Body/Block/Attr 结构
├── de.mbt             # 反序列化
├── error.mbt          # 错误类型
├── eval.mbt           # 表达式求值
├── eval_test.mbt      # 基础表达式求值测试
├── expr_test.mbt      # 表达式测试（条件、函数、变量、属性）
├── for_test.mbt       # for 表达式测试
├── funcs.mbt          # 内置函数（新增）
├── funcs_test.mbt     # 内置函数测试（新增）
├── hcl.mbt            # 主入口
├── hcl_test.mbt       # 基础测试
├── json.mbt           # JSON 转换
├── json_test.mbt      # JSON 测试
├── lexer.mbt          # 词法分析器
├── multiline_test.mbt # 多行表达式测试（新增）
├── parser.mbt         # 解析器
├── schema.mbt         # Schema验证
├── schema_test.mbt    # Schema测试
├── ser.mbt            # 序列化
├── spec_test.mbt      # Spec 测试（新增）
├── template.mbt       # 模板系统
├── template_test.mbt  # 模板测试
├── token.mbt          # Token 类型
├── value.mbt          # HCLValue 类型
├── error_test.mbt     # 错误消息测试
├── trait.mbt          # ToHCL/FromHCL trait 定义
├── builder.mbt        # Builder 模式辅助函数
├── trait_wbtest.mbt   # trait 白盒测试
├── builder_wbtest.mbt # builder 白盒测试
├── derive_wbtest.mbt  # derive 白盒测试
├── decor.mbt          # Decor/Decorated 类型（新增）
├── decor_test.mbt     # Decor 单元测试（新增）
├── decor_wbtest.mbt   # Decor 白盒测试（新增）
├── parser_decor_test.mbt # 解析器装饰集成测试（新增）
├── visit.mbt           # AST 不可变遍历（新增）
├── visit_mut.mbt       # AST 可变遍历（新增）
├── visit_test.mbt      # 遍历测试（新增）
├── decorated_expr.mbt  # Decorated[Expression] 辅助函数（新增）
├── decorated_expr_test.mbt # Decorated[Expression] 测试（新增）
└── cmd/
    └── main/
        ├── main.mbt   # CLI 入口
        └── moon.pkg   # CLI 包配置
```

## 参考资料

- hcl-rs 源码：`/home/pilot/.projects/hcl-rs/`
- HCL 规范：https://github.com/hashicorp/hcl/blob/main/spec.md
- MoonBit 文档：https://docs.moonbitlang.com
