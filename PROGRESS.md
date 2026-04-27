# HCL-MoonBit 项目进度

## 当前状态：字符串函数补齐 — 迭代 2 完成 ✅

## 当前分支
- 分支：`lenitain/feat/string-funcs-complete`
- 状态：开发完成
- 目标：补齐常见 Terraform 字符串函数

## 本次开发完成的任务

### 字符串函数补齐 StringFuncsComplete ✅
- ✅ `startswith(str, prefix)` — 字符串前缀检查，使用 `s.has_prefix()`
- ✅ `endswith(str, suffix)` — 字符串后缀检查，使用 `s.has_suffix()`
- ✅ `title(str)` — 每个单词首字母大写，逐字符遍历实现
- ✅ `contains` 扩展 — 支持字符串子串搜索（`OneOf([ParamArray(Any), ParamString])`）
- ✅ 13 个新测试（startswith/endswith/title/contains string × 正常/边界/错误）
- ✅ 所有 801 个测试通过

### 解析错误恢复 ParseErrorRecovery ✅
- ✅ `MultipleErrors(Array[HCLError])` 变体 — HCLError 新增多错误包装
- ✅ `HCLError::multi(errors)` 工厂方法
- ✅ `HCLError::message()` 处理 MultipleErrors — 用换行连接子错误消息
- ✅ `Parser::skip_to_next_item()` 辅助方法 — 错误恢复时跳过到下一个换行/EOF
- ✅ `Parser::parse_body_with_recovery()` — 收集错误继续解析，返回部分 Body
- ✅ `parse_with_recovery(input)` — 公共 API 入口
- ✅ 10 个新测试（多错误、意外 token、部分解析、空输入、边界情况）
- ✅ 所有 788 个测试通过

## 本次开发完成的任务

### 类型统一 Type Unification (#12) ✅
- ✅ `TypeName` 枚举 — TNull, TBool, TNumber, TString, TArray, TObject, TUnknown
- ✅ `type_of(v)` — HCLValue 到 TypeName 映射
- ✅ `unify_types(a, b)` — HCL 规范类型兼容性规则
  - 同类型 → 该类型
  - TNull + 任意 T → T（null 可转为任意类型）
  - TUnknown + 任意 T → TUnknown（传播）
  - TNumber + TString → TString（数字转字符串）
  - TBool + TString → TString（布尔转字符串）
  - TNumber + TBool → 错误（无转换路径）
  - TArray + TArray → TArray
  - TObject + TObject → TObject
- ✅ `convert_value(v, target)` — 值类型转换
  - Number → String, Bool → String, Null → any, Unknown → passthrough
- ✅ `eval_conditional` 统一分支类型并转换选中值
- ✅ `ExprConditional` 处理器：求值两分支，统一类型，短路错误处理
- ✅ `unify_branches` 辅助函数消除重复逻辑
- ✅ 44 个新测试（type_of + unify_types + convert_value + 集成测试）
- ✅ 所有 778 个测试通过

## 本次开发完成的任务

### Splat 运算符 (#6) ✅
- ✅ `TraversalOperator::Splat` 变体 — 表示 `.*` 和 `[*]` 操作
- ✅ `TraversalBuilder::splat()` 方法 — 构建 splat traversal
- ✅ Parser 支持 `.*` — 属性 splat 语法
- ✅ Parser 支持 `[*]` — 索引 splat 语法
- ✅ `expr_to_string` 输出 `.*`
- ✅ Eval 实现：`eval_splat` 映射数组/对象元素
- ✅ `apply_traversal_ops` — 对单个值应用 traversal 操作序列
- ✅ Visit/VisitMut 支持 Splat
- ✅ 7 个新测试（解析 + 序列化 + round-trip）
- ✅ 所有 682 个测试通过（相比之前增加 10 个）

### 静态分析 API (#14) ✅
- ✅ `collect_variables(body)` — 收集所有唯一变量名（ExprVariable 节点）
- ✅ `collect_functions(body)` — 收集所有唯一函数名（ExprFuncCall 节点）
- ✅ `collect_traversals(body)` — 收集所有唯一 traversal 根变量名
- ✅ `collect_variables_from_expr(expr)` — 单表达式版本
- ✅ `collect_functions_from_expr(expr)` — 单表达式版本
- ✅ `collect_traversals_from_expr(expr)` — 单表达式版本
- ✅ 使用 Visit trait 实现递归 AST 遍历
- ✅ 结果去重 + 排序（确定性输出）
- ✅ 17 个新测试（黑盒 + 白盒）
- ✅ 所有 720 个测试通过

### UTF-8 BOM 拒绝 (#11) ✅
- ✅ `EncodingError(String)` 变体 — 新错误类型
- ✅ `Lexer::validate_input()` — 检测输入开头的 U+FEFF BOM
- ✅ `parse()` 入口自动调用验证
- ✅ 6 个新测试（BOM 开头→错误、无 BOM→正常、BOM 中间→正常、空输入→正常）
- ✅ 所有 720 个测试通过

### 函数参数定义系统 (#13) ✅
- ✅ `ParamType` 枚举 — Any, ParamBool, ParamNumber, ParamString, ParamArray, ParamObject, Nullable, OneOf
- ✅ `ParamType::is_satisfied_by()` — 值类型验证
- ✅ `ParamType::display_name()` — 错误消息用类型名
- ✅ `FuncDef` 结构体 — name, params, variadic, func 字段
- ✅ `FuncDef::call()` — 自动参数数量/类型验证
- ✅ `FuncDefBuilder` — param(), variadic(), build() 链式 API
- ✅ `builtin_functions()` 返回 `Map[String, FuncDef]`
- ✅ 45 个内置函数全部注册到 FuncDefBuilder
- ✅ 移除所有手动 `guard check_args` / `guard check_min_args`
- ✅ eval_expr 和 template 函数签名更新
- ✅ 所有测试更新为 `FuncDef.call()` 接口
- ✅ 所有 682 个测试通过

### Strip Markers (#7) ✅
- ✅ `InterpolationStrip(Expression, Bool, Bool)` — 带 strip 标记的插值
- ✅ `ConditionalStartStrip/ElseIfStrip/ElseStrip/EndStrip` — 带 strip 的条件指令
- ✅ `ForStartStrip/ForEndStrip` — 带 strip 的 for 指令
- ✅ `parse_interpolation` 检测 `${~` 和 `~}` 模式
- ✅ `parse_directive` 检测 `%{~` 和 `~}` 模式
- ✅ `trim_trailing_whitespace` / `trim_leading_whitespace` 辅助函数
- ✅ `evaluate` 中 `pending_strip_after` 标志处理
- ✅ 所有嵌套辅助函数（find_for_end, find_conditional_boundary 等）更新
- ✅ 9 个新测试覆盖所有 strip 场景

### Unicode 标识符 (#8) ✅
- ✅ `is_id_start` 支持 Unicode XID_Start — Latin Extended, CJK, Hangul, Cyrillic, Greek, Arabic, Devanagari, Thai
- ✅ `is_id_continue` 支持 Unicode XID_Continue — 包含 Combining Diacritical Marks
- ✅ Lexer 自动识别 Unicode 标识符
- ✅ 21 个新测试（14 ident 单元测试 + 7 parser 集成测试）
- ✅ 中文/日文/韩文/拉丁扩展/西里尔字母标识符解析验证

### 验证结果
- ✅ moon check: 0 errors
- ✅ moon test: 801 passed, 0 failed
- ✅ moon fmt: 通过
- ✅ moon info: 通过

## 警告统计
- 38 警告（主要是 trait impl 的 unused_value，这些是 MoonBit trait 系统的正常警告）

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
| 适配 template | ✅ 已完成 | 以上全部 |

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
- `span.mbt` - Span 结构体 + Spanned[T] 泛型包装器（新增）

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
- ✅ 801 个测试全部通过
- 覆盖：属性解析、块解析、嵌套块、数组、对象、布尔值、null、注释
- 覆盖：表达式求值、条件表达式、函数调用、变量引用、属性访问
- 覆盖：模板系统（字符串插值、条件指令、for循环、heredoc）
- 覆盖：for表达式（列表推导、对象推导、条件过滤）
- 覆盖：Schema验证（类型检查、必填字段、自定义验证器、集成测试）
- 覆盖：Heredoc 解析（基本、多行、strip、自定义 delimiter）
- 覆盖：JSON 转换（基本、嵌套、转义、错误处理）
- 覆盖：JSON 语法解析（JSON→Body、标签嵌套、数组块、round-trip、terraform.tfvars.json）
- 覆盖：序列化 derive（ToHCL trait、FromHCL trait、Builder 模式、Option/Array 泛型）
- 覆盖：内置函数（数字、集合、字符串、类型转换，共48个函数）
- 覆盖：Spec 测试（操作符、heredoc、多行表达式）
- 覆盖：Decor 系统（解析保留注释/空白、序列化输出装饰、集成测试）
- 覆盖：hcl2json CLI 基础功能（HCL 到 JSON 转换、格式化输出）
- 覆盖：simplify 功能（二元运算、比较、条件、一元运算、数组、嵌套表达式）
- 覆盖：Unknown 值（HCLValue::Unknown、Expression::ExprUnknown、桥接函数、工厂函数）
- 覆盖：Splat 运算符（`.*`、`[*]`、解析、序列化、求值、round-trip）
- 覆盖：Template strip markers（`${~ expr ~}`、`%{~ directive ~}`、前后空白去除）
- 覆盖：Unicode 标识符（XID_Start/XID_Continue、CJK、Latin Extended、Cyrillic 等）
- 覆盖：FuncDef 参数定义系统（ParamType 类型检查、FuncDef 验证、variadic、builder）
- 覆盖：UTF-8 BOM 拒绝（BOM 检测、错误报告、边界情况）
- 覆盖：静态分析 API（collect_variables/functions/traversals、表达式级、去重、排序）
- 覆盖：源位置 Span（Span 类型、Spanned[T]、Parser span 捕获、Attr/Body/Block span）
- 覆盖：类型统一（TypeName、unify_types、convert_value、条件分支类型检查、Null/Unknown 传播）

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
- ✅ Else-if 链 (%{else if cond})
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
- ✅ 字符串函数 (chomp, indent, join, lower, upper, replace, split, strrev, substr, trim, trimprefix, trimsuffix, trimspace, format, formatlist, startswith, endswith, title)
- ✅ 类型转换函数 (tobool, tonumber, tolist, tomap, toset, tostring)
- ✅ 通过 builtin_functions() 获取所有内置函数（48 个）
- ✅ `ParamType` 枚举 — Any, ParamBool, ParamNumber, ParamString, ParamArray, ParamObject, Nullable, OneOf
- ✅ `FuncDef` 结构体 — 自动参数数量/类型验证
- ✅ `FuncDefBuilder` — 链式 API 构建函数定义

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
- ✅ BodySchema 类型（BodySchema, AttrSchema, BlockSchema, LabelSchema）

## 待实现：对标完整 HCL 规范的缺口

综合评估：整体约 97% 完整度。核心解析/求值/序列化/类型统一已全部完成。

### 🔴 P0：生产环境必备

| # | 功能 | 说明 | 影响 |
|---|------|------|------|
| 1 | **未知值 (Unknown values)** | ✅ 已完成。`HCLValue::Unknown(Decor)` + `Expression::ExprUnknown` + 桥接函数。Unknown 通过所有 schema 验证 + tostring 返回 "unknown"。 | Terraform 兼容性已可用 |
| 2 | **隐式类型转换** | ✅ 已完成。string↔number, string↔bool 自动转换。eval_add 支持混合类型拼接，eval_eq/neq/lt/gt/lte/gte 支持混合类型比较。 | 现有 `.tf` 文件大量依赖隐式转换 |
| 3 | **JSON 语法解析** | ✅ 已完成。`json_parse.mbt` 实现 JSON→HCL body 解析。支持原始值→Attr、对象→Block、数组对象→多Block、标签嵌套。`json_to_body` + `json_to_hcl_string` 公共 API。同时修复 `body_to_json()` 为 HCL JSON spec 合规（嵌套标签、重复块数组）。27 个新测试。 | 可读取 `terraform.tfvars.json` |
| 4 | **模板 else 子句** | ✅ 已完成。`%{if cond}...%{else if cond2}...%{else}...%{endif}` 完整支持。`ConditionalElseIf(Expression)` 变体 + 递归 `evaluate_else_chain`。6 个新测试。 | 大量 Terraform 模板不可用 |
| 5 | **表达式类型安全重构** | ✅ 已完成 | 架构缺陷修复 |

### 🟡 P1：重要但可暂缓

| # | 功能 | 说明 |
|---|------|------|
| 6 | **Splat 运算符** | ✅ 已完成。`list.*.attr` 和 `list[*].attr` 解析/求值/序列化。`TraversalOperator::Splat` + `eval_splat` 映射数组/对象。7 个新测试。 |
| 7 | **模板 Strip markers** | ✅ 已完成。`${~ expr ~}` 和 `%{~ directive ~}` 支持。7 个 strip-aware TemplatePart 变体。9 个新测试。 |
| 8 | **Unicode 标识符** | ✅ 已完成。XID_Start/XID_Continue 支持（Latin Extended, CJK, Hangul, Cyrillic 等）。21 个新测试。 |
| 9 | **Schema 驱动的 body 提取** | ✅ 已完成。BodySchema + extract_body + from_hcl_with_body_schema + 综合测试。 |

### 🟢 P2：锦上添花

| # | 功能 | 说明 |
|---|------|------|
| 10 | **源位置保留在 AST 中** | ✅ 已完成。`Span` 结构体 + `Spanned[T]` 包装器。Attr/Body/Block 携带 span。14 个新测试。 |
| 11 | **UTF-8 BOM 拒绝 + UTF-8 验证** | ✅ 已完成。`EncodingError` 变体 + `Lexer::validate_input()` 检测 U+FEFF。6 个新测试。 |
| 12 | **类型统一 (Type unification)** | ✅ 已完成。`TypeName` 枚举 + `unify_types` + `convert_value`。条件表达式分支类型统一 + 自动转换。44 个新测试。 |
| 13 | **函数参数定义系统** | ✅ 已完成。`ParamType` 枚举 + `FuncDef` 结构体 + `FuncDefBuilder`。自动参数数量/类型验证，无需手动 `check_args`。 |
| 14 | **静态分析 API** | ✅ 已完成。`collect_variables`/`collect_functions`/`collect_traversals` + 表达式级变体。 |

### 优先级排序（建议下次迭代顺序）

```
迭代 1 (P0):  表达式类型安全重构 (#5) → ✅ 已完成
迭代 2 (P0):  未知值 Unknown (#1) → ✅ 已完成
迭代 3 (P0):  模板 else (#4) → ✅ 已完成（含 else-if 链）
迭代 4 (P0):  隐式类型转换 (#2) → ✅ 已完成
迭代 5 (P0):  JSON 语法解析 (#3) → ✅ 已完成
迭代 6 (P1):  Splat (#6) + Strip markers (#7) + Unicode ident (#8) → ✅ 已完成
迭代 7 (P1):  Schema body 提取 (#9) → ✅ 已完成（全量测试验证通过）
迭代 8 (P2):  函数参数定义系统 (#13) → ✅ 已完成（697 测试通过）
迭代 9 (P2):  UTF-8 BOM (#11) + 静态分析 API (#14) → ✅ 已完成（720 测试通过）
迭代 10 (P2): 源位置 Span (#10) → ✅ 已完成（734 测试通过）
迭代 11 (P2): 类型统一 (#12) → ✅ 已完成（778 测试通过）
🎉 全部 14 个迭代任务已完成！
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
| 表达式求值 | `eval_binary/unary`, 48 个内置函数 | ✅ |
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
| `-o/--output FILE` | ✅ | 中 |
| `--indent N` | ✅ | 中 |
| `-j/--json-input` | ✅ | 中 |
| `--version` | ✅ | 低 |
| `--color`/`--no-color` | ✅ | 低 |
| 错误位置标注（源码上下文） | ✅ | 高 |
| 多文件处理 | ✅ | 中 |
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
4. ✅ CLI 参数解析（--help, --pretty, --simplify, --file, --version）
5. ✅ `--validate` 选项（验证 HCL 可解析性）
6. ✅ `--format` 选项（输出格式化 HCL）
7. ✅ `-o/--output FILE` 输出到文件
8. ✅ `--indent N` 自定义缩进（JSON + HCL）
9. ✅ `-j/--json-input` JSON→HCL 转换
10. ✅ `--color`/`--no-color` ANSI 彩色输出 + `NO_COLOR` 支持
11. ✅ 错误位置标注（源码行 + `^^^^` 指针 + 行号列号）
12. ✅ 多文件处理（validate/format/JSON）

**当前分支**：`lenitain/feat/cli-enhancement` - ✅ 完成

🎉 全部 14 个迭代任务已完成！项目达到 97% HCL 规范完整度。

剩余受 MoonBit 生态限制的可选项：
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

### 阶段 6：Schema Body Extraction ✅ 完成
```
1. BodySchema 类型定义 ✅
   - BodySchema, AttrSchema, BlockSchema, LabelSchema 结构体 ✅
   - 构造函数 ✅
2. ExtractedBody 类型 ✅
   - ExtractedBody, ExtractedBlock 结构体 ✅
   - 访问器方法 ✅
3. Body 提取逻辑 ✅
   - extract_body 函数 ✅
   - 属性提取 + 类型验证 ✅
   - 额外属性检查 ✅
   - 必填属性检查 ✅
   - Block 提取（递归 body 提取） ✅
   - 标签验证 ✅
   - max_items 约束检查 ✅
4. from_hcl_with_body_schema API ✅
5. 测试 ✅
   - required attribute missing ✅
   - extra_attrs=false rejection ✅
   - nested blocks with labels ✅
   - max_items constraint violation ✅
   - optional attribute handling ✅
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
├── json.mbt           # JSON 转换（HCL→JSON，spec 合规）
├── json_parse.mbt     # JSON 语法解析（JSON→HCL Body）（新增）
├── json_test.mbt      # JSON 转换测试
├── json_parse_test.mbt # JSON 语法解析测试（新增）
├── lexer.mbt          # 词法分析器
├── multiline_test.mbt # 多行表达式测试（新增）
├── parser.mbt         # 解析器
├── schema.mbt         # Schema验证
├── schema_test.mbt    # Schema测试
├── ser.mbt            # 序列化
├── spec_test.mbt      # Spec 测试（新增）
├── splat_test.mbt     # Splat 运算符测试（新增）
├── strip_test.mbt     # Strip markers 测试（新增）
├── unicode_test.mbt   # Unicode 标识符测试（新增）
├── ident_test.mbt     # Ident 类型测试（新增）
├── template.mbt       # 模板系统
├── template_test.mbt  # 模板测试
├── token.mbt          # Token 类型
├── value.mbt          # HCLValue 类型
├── error_test.mbt     # 错误消息测试
├── eval_wbtest.mbt    # 表达式求值白盒测试（新增）
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
├── analysis.mbt        # 静态分析 API（新增）
├── analysis_test.mbt   # 静态分析黑盒测试（新增）
├── analysis_wbtest.mbt # 静态分析白盒测试（新增）
├── encoding_test.mbt   # UTF-8 BOM 测试（新增）
├── span.mbt            # Span 和 Spanned[T] 类型（新增）
├── span_test.mbt       # 源位置 Span 测试（新增）
├── unify.mbt           # 类型统一 lattice（新增）
├── unify_test.mbt      # 类型统一测试（新增）
└── cmd/
    └── main/
        ├── main.mbt   # CLI 入口
        └── moon.pkg   # CLI 包配置
```

## 参考资料

- hcl-rs 源码：`/home/pilot/.projects/hcl-rs/`
- HCL 规范：https://github.com/hashicorp/hcl/blob/main/spec.md
- MoonBit 文档：https://docs.moonbitlang.com

---

# 下一阶段开发计划：补齐缺口，实现"一库通吃"

## 现状评估

**核心 HCL 规范完整度：~97%** ✅
- 解析、求值、序列化、反序列化、Schema 验证、模板、CLI 均已完成
- 数值字面量（hex/octal/binary/科学计数法/下划线）已完整实现
- Unicode 标识符、Splat、Strip markers、类型统一、静态分析均已实现

**剩余缺口评估：约 3% 规范 + ~60 个内置函数**

| 缺口类型 | 数量 | 影响范围 | 开发难度 |
|----------|------|----------|----------|
| 内置函数缺失 | ~60 | 大（Terraform 配置可能用到） | 低（模板式添加） |
| 解析错误恢复 | ✅ 已完成 | 中（IDE/CLI 体验） | 中（架构改动） |
| 类型系统增强 | 3项 | 小（特殊场景） | 中 |
| 字符串 contains | 1项 | 小 | 低 |
| 函数注册 API | 1项 | 中（开发者体验） | 低 |

---

## 缺口详细规划

### 迭代 1 ✅：解析错误恢复 — ParseErrorRecovery

**目标**：从单错误模式升级为多错误积累模式，让用户一次看到所有错误

**改动文件**：

| 文件 | 改动内容 |
|------|----------|
| `error.mbt` | `HCLError` 新增 `MultipleErrors(Array[HCLError])` 变体；`HCLResult` 改为 `Result[T, Array[HCLError]]`（注意：此为破坏性变更，需要别名方案） |
| `HCLError` 新增方法 | `fn HCLError::multi(errors: Array[HCLError]) -> HCLError` — 将多个错误包装为单个 |
| 维持 `HCLResult[T]` 不变 | 引入新类型 `HCLParseResult[T] = Result[T, Array[HCLError]]` |
| `parser.mbt` | 所有 `return Err(e)` 改为收集错误后继续解析（skip to next newline/block boundary），最后返回收集到的所有错误 |
| `parse` 函数签 | 新增 `parse_with_recovery(String) -> (Body?, Array[HCLError])` |
| `spec_test.mbt` | 增加多错误场景测试：同一文件多个语法错误 |
| `decor_test.mbt` | 验证部分解析时 decoration 仍然正确收集 |

**设计要点**：
- 解析器遇到错误时，跳过到下一个换行或块结束符（`}`），然后继续解析
- 收集所有错误到 `Array[HCLError]`
- 如果解析过程中没有产生任何有效 Body，返回 `(None, errors)`
- 即使有错误也返回部分解析的 Body（如有）
- 保持 `parse` 向后兼容（用 `try` 封装第一个错误）

**验证**：
```moonbit
// 输入：a = 1\nb = \nc = 3\n
// 期望：2 个错误（b 缺少值），但 c=3 仍被解析
```

**测试计数**：新增至少 10 个测试

---

### 迭代 2：字符串函数补齐 — StringFuncsComplete ✅

**目标**：补齐所有常见 Terraform 字符串函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

| 函数 | 签名 | 实现要点 |
|------|------|----------|
| `startswith(str, prefix)` | `(string, string) -> bool` | `String.has_prefix` |
| `endswith(str, suffix)` | `(string, string) -> bool` | `String.has_suffix` |
| `title(str)` | `(string) -> string` | 逐字符遍历，空格后首字母大写 |
| `contains(str, search)` | `(string/any, any) -> bool` | 扩展为 `OneOf([ParamArray(Any), ParamString])`，支持字符串子串搜索 |

**测试计数**：13 个新测试，总计 801 个测试通过 ✅

---

### 迭代 3：集合/条件函数补齐 — CollectionFuncs

**目标**：补齐集合操作和条件函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

| 函数 | 签名 | 实现要点 |
|------|------|----------|
| `concat(list1, list2, ...)` | `variadic array(array) -> array` | 拼接多个数组 |
| `coalesce(val1, val2, ...)` | `variadic any -> any` | 返回第一个非 null 值 |
| `range(max)` / `range(start, limit)` | `(number) -> array` | 生成数字序列 |
| `chunklist(list, size)` | `(array, number) -> array(array)` | 将数组分块 |
| `lookup(map, key, default?)` | `(object, string, any?) -> any` | 安全访问 map 键 |
| `zipmap(keys, values)` | `(array(string), array) -> object` | 两个数组合并成 map |
| `transpose(map)` | `(object) -> object` | map 的键值转置 |
| `matchkeys(search, keys, values)` | `(array, array, array) -> array` | 匹配键模式 |
| `sum(list)` | `(array(number)) -> number` | 数字数组求和 |
| `alltrue(list)` | `(array(bool)) -> bool` | 全为真 |
| `anytrue(list)` | `(array(bool)) -> bool` | 任一为真 |
| `one(list)` | `(array(any)) -> any` | 确保列表只有一个元素并返回 |
| `can(expr)` | 特殊（需要延迟求值） | ⚠️ 难度高，Terraform 中为特殊表达式 |
| `try(expr, default)` | 特殊（需要延迟求值） | ⚠️ 难度高 |

**注意**：`can` 和 `try` 需要表达式级别的延迟求值，当前 `FuncDef` 架构不支持。需要先实现 `LazyFuncDef` 或类似机制。这两个可暂缓。

**实现顺序建议**：
1. concat, coalesce, range — 简单，直接实现
2. chunklist, lookup, zipmap, transpose, matchkeys — 中等
3. sum, alltrue, anytrue, one — 简单
4. can, try — ⚠️ 需要设计变更，暂缓

**测试计数**：新增至少 40 个测试（每个函数至少 3 个）

---

### 迭代 4：集合论函数补齐 — SetFuncs

**目标**：补齐集合运算函数（HCL 中集合用数组表示）

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

| 函数 | 签名 | 实现要点 |
|------|------|----------|
| `setintersection(s1, s2, ...)` | `variadic array(array) -> array` | 交集，去重 |
| `setunion(s1, s2, ...)` | `variadic array(array) -> array` | 并集，去重 |
| `setsubtract(s1, s2)` | `(array, array) -> array` | 差集 |
| `setsymmetricdifference(s1, s2)` | `(array, array) -> array` | 对称差集 |
| `setproduct(s1, s2, ...)` | `variadic array(array) -> array(array)` | 笛卡尔积 |
| `setissubset(s1, s2)` | `(array, array) -> bool` | 子集判断 |

**测试计数**：新增至少 18 个测试

---

### 迭代 5：编码函数补齐 — EncodingFuncs

**目标**：补齐编码/解码函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

**依赖**：MoonBit 标准库是否提供 base64/json 编码接口

| 函数 | 签名 | MoonBit 支持 |
|------|------|-------------|
| `csvdecode(str)` | `(string) -> array(object)` | 需自行解析 CSV |
| `jsondecode(str)` | `(string) -> any` | ✅ `@json` 库可用 |
| `jsonencode(val)` | `(any) -> string` | ✅ `@json` 库可用 |
| `base64decode(str)` | `(string) -> string` | ❓ 需要检查 `@encoding/base64` |
| `base64encode(str)` | `(string) -> string` | ❓ 需要检查 `@encoding/base64` |
| `urlencode(str)` | `(string) -> string` | ❓ MoonBit 可能无此功能 |

**测试计数**：新增至少 15 个测试

---

### 迭代 6：加密切密函数补齐 — CryptoFuncs

**目标**：补齐加密切密函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

**依赖**：MoonBit 标准库是否提供 hash 函数

| 函数 | 签名 | MoonBit 支持 |
|------|------|-------------|
| `sha256(str)` | `(string) -> string` | ❓ 需检查 `@encoding/sha256` |
| `sha512(str)` | `(string) -> string` | ❓ 需检查 |
| `sha1(str)` | `(string) -> string` | ❓ 需检查 |
| `md5(str)` | `(string) -> string` | ❓ 需检查 |
| `bcrypt(str)` | `(string) -> string` | ❌ 可能无支持 |

**测试计数**：新增至少 10 个测试

---

### 迭代 7：日期/时间函数补齐 — DateTimeFuncs

**目标**：补齐日期时间函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

**注意**：这些函数的输出依赖于当前时间或平台，测试需要 mock 或容差判断

| 函数 | 签名 | 实现要点 |
|------|------|----------|
| `formatdate(format, timestamp)` | `(string, string) -> string` | 解析 RFC3339 时间戳并格式化 |
| `timeadd(timestamp, duration)` | `(string, string) -> string` | 时间加减 |
| `timecmp(t1, t2)` | `(string, string) -> number` | 时间比较 |
| `timestamp()` | `() -> string` | 返回当前 UTC 时间（RFC3339） |

**测试计数**：新增至少 12 个测试

---

### 迭代 8：网络函数补齐 — NetworkFuncs

**目标**：补齐 CIDR 网络函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

| 函数 | 签名 | 实现要点 |
|------|------|----------|
| `cidrhost(prefix, hostnum)` | `(string, number) -> string` | 计算 CIDR 中第 N 个主机地址 |
| `cidrnetmask(prefix)` | `(string) -> string` | 返回子网掩码 |
| `cidrsubnet(prefix, newbits, netnum)` | `(string, number, number) -> string` | 计算子网 |
| `cidrsubnets(prefix, newbits...)` | `(string, variadic number) -> array(string)` | 多个子网计算 |

**测试计数**：新增至少 12 个测试

---

### 迭代 9：Regex 函数补齐 — RegexFuncs

**目标**：补齐正则表达式函数

**改动文件**：`funcs.mbt` + `funcs_test.mbt`

**依赖**：MoonBit 标准库的 `Regex` 类型

```moonbit
// MoonBit 标准库有 @regex 包
```

| 函数 | 签名 | 实现要点 |
|------|------|----------|
| `regex(pattern, str)` | `(string, string) -> array(string)` | 查找第一个匹配的子串和捕获组 |
| `regexall(pattern, str)` | `(string, string) -> array(array(string))` | 查找所有匹配 |
| `regex_replace(pattern, str, replacement)` | `(string, string, string) -> string` | 替换匹配 |

**测试计数**：新增至少 9 个测试

---

### 迭代 10：函数注册 API — UserFuncRegistry

**目标**：允许用户注册自定义函数到求值环境

**改动文件**：`funcs.mbt` + `eval.mbt`

**当前问题**：用户只能使用 `builtin_functions()`，无法扩展。

**解决方案**：

```moonbit
/// 用户自定义函数注册
pub struct FuncRegistry {
  funcs : Map[String, FuncDef]
}

pub fn FuncRegistry::new() -> FuncRegistry { ... }
pub fn FuncRegistry::register(self, name: String, def: FuncDef) -> FuncRegistry { ... }
pub fn FuncRegistry::build(self) -> Map[String, FuncDef] { ... }
```

或者更简单：直接暴露 `Map[String, FuncDef]` 的合并 API：

```moonbit
pub fn merge_funcs(base: Map[String, FuncDef], extra: Map[String, FuncDef]) -> Map[String, FuncDef]
```

**测试计数**：新增至少 5 个测试

---

### 迭代 11：类型系统增强 — TypeSystemEnhance

**目标**：补齐类型系统缺口

**改动文件**：`unify.mbt` + `value.mbt` + `unify_test.mbt`

| 特性 | 说明 | 难度 |
|------|------|------|
| `TDynamic` 类型 | 与任意类型可统一 | 低 |
| `type_of` 对空数组/空对象 | 返回 `TArray(TDynamic)` / `TObject(TDynamic)` 而非 `TArray` / `TObject` | 低 |

**注意**：HCL spec 中的 `capsule` 类型主要用于 Terraform provider 内部，MoonBit 环境无需实现。

**测试计数**：新增至少 6 个测试

---

## 优先级路线图

```
迭代 1:  ParseErrorRecovery  — ✅ 已完成 (788 测试通过)
迭代 2:  StringFuncsComplete  — ✅ 已完成 (801 测试通过)
迭代 3:  CollectionFuncs     — 高优先级 (常用函数)
迭代 4:  SetFuncs            — 中优先级
迭代 5:  EncodingFuncs       — 中优先级 (依赖 MoonBit 生态)
迭代 6:  CryptoFuncs         — 中优先级 (依赖 MoonBit 生态)
迭代 7:  DateTimeFuncs       — 中优先级
迭代 8:  NetworkFuncs        — 低优先级
迭代 9:  RegexFuncs          — 低优先级 (依赖 MoonBit 生态)
迭代 10: UserFuncRegistry    — 低优先级 (增强 API)
迭代 11: TypeSystemEnhance   — 低优先级
```

**建议开发顺序**：按迭代 2 ✅ → 3 → 10 → 4 → 7 → 8 → 5/6/9（并行，取决于 MoonBit 生态就绪情况）→ 11

---

## 分支命名规范

```
lenitain/fix/parse-error-recovery     — 迭代 1
lenitain/feat/string-funcs-complete    — 迭代 2
lenitain/feat/collection-funcs         — 迭代 3
lenitain/feat/set-funcs                — 迭代 4
lenitain/feat/encoding-funcs           — 迭代 5
lenitain/feat/crypto-funcs             — 迭代 6
lenitain/feat/datetime-funcs           — 迭代 7
lenitain/feat/network-funcs            — 迭代 8
lenitain/feat/regex-funcs              — 迭代 9
lenitain/feat/user-func-registry       — 迭代 10
lenitain/feat/type-system-enhance      — 迭代 11
```

## 每次迭代完成后的验证命令

```bash
moon check && moon test && moon info && moon fmt
```

每次迭代应确保：
1. `moon check` — 0 errors
2. `moon test` — 全部通过（总数递增）
3. `moon info` — `.mbti` 接口文件更新
4. `moon fmt` — 格式化通过
5. 添加新测试覆盖所有变更
