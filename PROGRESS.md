# HCL-MoonBit 项目进度

## 当前状态：hcl2json CLI 批量处理功能已完成

## 当前分支
- 分支：`lenitain/feat/hcl2json-batch`
- 状态：开发完成
- 目标：实现 hcl2json CLI 批量处理功能

## 本次开发完成的功能
- ✅ hcl2json CLI 基础框架
- ✅ HCL 到 JSON 转换功能
- ✅ 支持 --pretty 选项（格式化 JSON 输出）
- ✅ 支持基础示例（从字符串读取 HCL）
- ✅ 错误处理和消息显示
- ✅ 帮助信息显示

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
| hcl2json --simplify 选项 | ⏳ | eval |
| specsuite 完整测试套件 | ⏳ | - |

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
- ✅ 521 个测试全部通过
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

### 表达式求值 (eval.mbt)
- ✅ 二元运算符 (+, -, *, /, %, ==, !=, <, >, <=, >=, &&, ||)
- ✅ 一元运算符 (-, !)
- ✅ 条件表达式 (cond ? true : false)
- ✅ 函数调用框架
- ✅ 变量引用
- ✅ 属性访问 (obj.key, obj["key"])
- ✅ 类型检查和错误处理

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

## 未完成 ❌

### 中优先级
- [x] 更好的错误消息
  - [x] 上下文信息（显示出错的代码行）
  - [x] 修复建议（列指针指向错误位置）

- [x] JSON 转换
  - [x] hcl_to_json() 函数
  - [x] hcl_to_json_pretty() 函数
  - [x] body_to_json() 函数
  - [x] 字符串转义
  - [x] 浮点数解析修复

- [x] CLI 工具
  - [x] 基本框架
  - [x] 命令行参数解析
  - [x] 使用说明

### 低优先级
- [x] 保留空白和注释的编辑（类似 hcl-edit）- 已完成
- [ ] 性能优化
- [x] 完整的 spec test suite (已完成基础操作符和 heredoc 测试)

## 已知问题

1. ~~**数字解析简化**：当前只支持基本整数和浮点数，不支持十六进制、八进制、二进制~~ ✅ 已实现
2. ~~**Unicode 转义**：不支持 \uXXXX 和 \u{XXXX} 格式~~ ✅ 已实现
3. ~~**Heredoc**：token 识别有但解析未实现~~ ✅ 已实现
4. ~~**多行表达式**：不支持跨行的复杂表达式~~ ✅ 已实现

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
