# HCL-MoonBit 项目进度

## 当前状态：更好的错误消息完成 (约 75% 功能覆盖)

## 已完成 ✅

### 核心数据结构
- `value.mbt` - HCLValue 枚举（Null, Bool, Int, Int64, Float, String, Array, Object）
- `body.mbt` - Body, BodyItem, Attr, Block 结构体
- `token.mbt` - Token 枚举（所有 token 类型）
- `error.mbt` - HCLError 和 HCLResult 类型

### 词法分析器 (lexer.mbt)
- ✅ 基础 token 识别
- ✅ 字符串字面量（带转义序列）
- ✅ 数字字面量（整数、浮点数）
- ✅ 标识符和关键字（true, false, null, for, in, if）
- ✅ 行注释 (//)
- ✅ 块注释 (/* */)
- ✅ Unicode 支持（使用 UInt16）
- ✅ 所有运算符和分隔符

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

### 序列化框架
- `ser.mbt` - 序列化（to_hcl_* 函数）
- `de.mbt` - 反序列化（from_hcl_* 函数）
- ✅ HCLValue 到字符串
- ✅ Body 到字符串
- ✅ 字符串转义

### 测试
- ✅ 96 个测试全部通过
- 覆盖：属性解析、块解析、嵌套块、数组、对象、布尔值、null、注释
- 覆盖：表达式求值、条件表达式、函数调用、变量引用、属性访问
- 覆盖：模板系统（字符串插值、条件指令、for循环、heredoc）
- 覆盖：for表达式（列表推导、对象推导、条件过滤）
- 覆盖：Schema验证（类型检查、必填字段、自定义验证器、集成测试）

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

### Schema 验证 (schema.mbt)
- ✅ 类型检查（TypeSchema 枚举）
- ✅ 必填字段验证（FieldSchema.required）
- ✅ 自定义验证器（Validator 类型）
- ✅ 路径跟踪错误消息（$.user.name）
- ✅ 集成到反序列化（from_hcl_with_schema）

## 未完成 ❌

### 中优先级
- [ ] 序列化 derive 支持
  - 需要 MoonBit 编译器支持 derive 宏
  - 或提供手动实现的辅助函数

- [x] 更好的错误消息
  - [x] 上下文信息（显示出错的代码行）
  - [x] 修复建议（列指针指向错误位置）

### 低优先级
- [ ] 保留空白和注释的编辑（类似 hcl-edit）
- [ ] JSON 转换
- [ ] CLI 工具
- [ ] 性能优化
- [ ] 完整的 spec test suite

## 已知问题

1. **数字解析简化**：当前只支持基本整数和浮点数，不支持十六进制、八进制、二进制
2. **Unicode 转义**：不支持 \uXXXX 和 \u{XXXX} 格式
3. **Heredoc**：token 识别有但解析未实现
4. **多行表达式**：不支持跨行的复杂表达式

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
2. 更好的错误消息
3. JSON 转换
4. CLI 工具
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
├── expr_test.mbt      # 表达式测试（条件、函数、变量、属性）
├── for_test.mbt       # for 表达式测试（新增）
├── hcl.mbt            # 主入口
├── lexer.mbt          # 词法分析器
├── parser.mbt         # 解析器
├── schema.mbt         # Schema验证（新增）
├── schema_test.mbt    # Schema测试（新增）
├── ser.mbt            # 序列化
├── template.mbt       # 模板系统
├── template_test.mbt  # 模板测试
├── token.mbt          # Token 类型
├── value.mbt          # HCLValue 类型
├── hcl_test.mbt       # 基础测试
└── eval_test.mbt      # 基础表达式求值测试
```

## 参考资料

- hcl-rs 源码：`/home/pilot/.projects/hcl-rs/`
- HCL 规范：https://github.com/hashicorp/hcl/blob/main/spec.md
- MoonBit 文档：https://docs.moonbitlang.com
