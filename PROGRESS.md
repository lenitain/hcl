# HCL-MoonBit 项目进度

## 当前状态：阶段7进行中 - 改为 flat package 风格

**变更**: 用户要求保持 flat package 风格（所有模块共享命名空间），已执行以下操作：

1. 将 lexer/ 目录的文件移到根目录（lexer.mbt, token.mbt, error.mbt）
2. 删除 lexer/ 目录
3. 更新 moon.work 移除 lexer 成员
4. 更新 moon.pkg 移除 import
5. 更新 moon.mod.json 移除 lexer 依赖
6. 移除所有代码中的 @lexer. 前缀引用
7. 为 cmd/main 添加 moon.mod.json

**结果**: 编译通过，测试全部通过 (566/566)

## 文件结构（当前 - flat package 风格）

```
hcl/
├── moon.work              # workspace 定义 (e2e, cmd/main, .)
├── e2e/                   # 端到端测试
│   ├── moon.mod.json
│   ├── moon.pkg
│   └── e2e_test.mbt
├── cmd/main/              # CLI 入口
│   ├── moon.mod.json
│   ├── moon.pkg
│   └── main.mbt
├── moon.mod.json          # 根包配置
├── moon.pkg               # 空（flat package）
├── lexer.mbt              # Lexer 结构 (从 lexer/ 移回根目录)
├── token.mbt              # Token 类型 (从 lexer/ 移回根目录)
├── error.mbt              # HCLError, HCLResult (从 lexer/ 移回根目录)
├── body.mbt               # Body/Block/Attr 结构
├── de.mbt                 # 反序列化
├── eval.mbt               # 表达式求值
├── funcs.mbt              # 内置函数
├── hcl.mbt                # 主入口
├── json.mbt               # JSON 转换
├── parser.mbt             # 解析器
├── schema.mbt             # Schema 验证
├── ser.mbt                # 序列化
├── template.mbt           # 模板系统
├── value.mbt              # HCLValue 类型
├── trait.mbt              # ToHCL/FromHCL trait
├── builder.mbt            # Builder 模式
└── *_test.mbt             # 测试文件
```
hcl/
├── moon.work              # workspace 定义 (lexer, e2e, .)
├── lexer/                 # HCL lexer 子包 (已完成)
│   ├── moon.mod.json
│   ├── moon.pkg
│   ├── lexer.mbt
│   ├── token.mbt
│   └── error.mbt
├── e2e/                   # 端到端测试 (已完成)
│   ├── moon.mod.json
│   ├── moon.pkg
│   ├── e2e_test.mbt
│   └── testdata/
├── cmd/main/              # CLI 入口
├── moon.mod.json          # 根包配置 (deps: lexer)
├── moon.pkg               # 导入 lexer 包
├── body.mbt               # Body/Block/Attr 结构
├── de.mbt                 # 反序列化
├── eval.mbt               # 表达式求值
├── funcs.mbt              # 内置函数
├── hcl.mbt                # 主入口
├── json.mbt               # JSON 转换
├── parser.mbt             # 解析器
├── schema.mbt             # Schema 验证
├── ser.mbt                # 序列化
├── template.mbt           # 模板系统
├── token.mbt              # Token 类型 (已移除，见lexer/)
├── value.mbt              # HCLValue 类型
├── trait.mbt              # ToHCL/FromHCL trait
├── builder.mbt            # Builder 模式
└── *_test.mbt             # 测试文件 (51个文件散落根目录)
```

## 文件结构（目标 - 阶段7完成后）

```
hcl/
├── moon.work              # workspace 定义
├── lexer/                 # HCL lexer 子包 (自包含)
│   ├── moon.mod.json
│   ├── moon.pkg
│   ├── lexer.mbt
│   ├── token.mbt
│   └── error.mbt
├── internal/              # 实现细节
│   ├── moon.mod.json      # name: "lenitain/hcl/internal"
│   ├── moon.pkg
│   ├── parser/            # 解析器
│   │   ├── moon.mod.json
│   │   ├── moon.pkg
│   │   ├── parser.mbt
│   │   └── *_test.mbt
│   ├── eval/              # 表达式求值
│   │   ├── moon.mod.json
│   │   ├── moon.pkg
│   │   ├── eval.mbt
│   │   ├── expr.mbt
│   │   └── *_test.mbt
│   ├── funcs/             # 内置函数
│   │   ├── moon.mod.json
│   │   ├── moon.pkg
│   │   ├── funcs.mbt
│   │   └── *_test.mbt
│   ├── template/          # 模板系统
│   │   ├── moon.mod.json
│   │   ├── moon.pkg
│   │   ├── template.mbt
│   │   └── *_test.mbt
│   ├── value/             # 核心类型
│   │   ├── moon.mod.json
│   │   ├── moon.pkg
│   │   ├── value.mbt
│   │   ├── body.mbt
│   │   ├── decor.mbt
│   │   ├── visit.mbt
│   │   ├── visit_mut.mbt
│   │   └── *_test.mbt
│   └── util/              # 工具模块
│       ├── moon.mod.json
│       ├── moon.pkg
│       ├── number.mbt
│       ├── object.mbt
│       ├── ident.mbt
│       └── *_test.mbt
├── e2e/                   # 端到端测试
│   ├── moon.mod.json
│   ├── moon.pkg
│   ├── e2e_test.mbt
│   └── testdata/
├── cmd/main/              # CLI 入口
├── hcl.mbt                # 主入口 (~100行, re-export API)
├── hcl_test.mbt           # 主集成测试
├── json.mbt               # JSON 转换入口
├── schema.mbt             # Schema 验证入口
├── ser.mbt                # 序列化入口
├── de.mbt                 # 反序列化入口
├── trait.mbt              # ToHCL/FromHCL trait
└── builder.mbt           # Builder 模式
```

## 已完成 ✅

### 核心数据结构
- `value.mbt` - HCLValue 枚举（Null, Bool, Int, Int64, Float, String, Array, Object）
- `body.mbt` - Body, BodyItem, Attr, Block 结构体
- `token.mbt` - Token 枚举（所有 token 类型）
- `error.mbt` - HCLError 和 HCLResult 类型

### 词法分析器 (lexer.mbt)
- ✅ 基础 token 识别
- ✅ 字符串字面量（带转义序列）
- ✅ 数字字面量（整数、浮点数、十六进制0x、八进制0o、二进制0b）
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
- ✅ 289 个测试全部通过
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
- [ ] 保留空白和注释的编辑（类似 hcl-edit）
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

### 阶段 6：项目结构重构（进行中 - 部分完成）

### 阶段 6：项目结构重构 ✅ 已完成

**解决方案**: 让 lexer 包自包含（参考 toml-parser）

#### 6.1 创建 self-contained lexer 包 ✅
```
1. 创建 lexer/ 目录
2. lexer/lexer.mbt - Lexer 结构
3. lexer/token.mbt - Token 枚举 (pub(all))
4. lexer/error.mbt - HCLError, HCLResult (pub(all))
5. lexer/moon.mod.json (name: "lenitain/hcl/lexer")
6. lexer/moon.pkg (empty)
7. 删除根目录的 lexer.mbt, token.mbt, error.mbt
```

#### 6.2 更新根包导入 ✅
- moon.mod.json 添加 deps: "lenitain/hcl/lexer": "0.1.0"
- moon.work 添加 "lexer" 到 members
- 所有 .mbt 文件使用 @lexer.Lexer, @lexer.Token 等

#### 6.3 创建 e2e/ 子包 ✅
```
1. mkdir -p e2e/testdata
2. e2e/moon.mod.json (name: "lenitain/hcl/e2e", deps: lenitain/hcl)
3. e2e/moon.pkg
4. e2e/e2e_test.mbt (placeholder)
```

#### 6.4 验证 ✅
- moon build 成功
- moon test 全部通过 (566/566)
- moon check 通过
- moon fmt 通过

### 阶段 7：根目录清理（TODO）

**目标**: 根目录只保留入口文件，所有实现细节移到 internal/ 子包

**参考**: toml-parser 的 clean 结构：
```
toml-parser/
├── lexer/           # 独立 lexer 包 (已完成)
├── internal/        # internal/tokenize/
│   └── tokenize/    # tokenize.mbt, token.mbt, *_test.mbt
├── e2e/             # 端到端测试 (已完成)
├── parser.mbt       # 入口
├── toml.mbt         # 入口
└── toml_test.mbt    # 主测试
```

**当前根目录问题**: 51个.mbt文件散落，职责不清

**计划**:

#### 7.1 创建 internal/ 包结构
```
1. 创建 internal/ 目录
2. internal/moon.mod.json (name: "lenitain/hcl/internal")
3. internal/moon.pkg
4. 创建 internal/parser/ 子包
   - mkdir internal/parser/
   - mv parser.mbt internal/parser/parser.mbt
   - mv *_test.mbt (parser相关) internal/parser/
   - 创建 internal/parser/moon.mod.json
   - 创建 internal/parser/moon.pkg
5. 创建 internal/eval/ 子包 (表达式求值)
6. 创建 internal/funcs/ 子包 (内置函数)
7. 创建 internal/template/ 子包 (模板系统)
8. 创建 internal/value/ 子包 (HCLValue, Body, Block, Attr)
9. 创建 internal/serde/ 子包 (序列化/反序列化)
10. 创建 internal/util/ 子包 (number, object, ident, decor, etc.)
```

#### 7.2 根目录只保留
```
hcl/
├── hcl.mbt          # 主入口，re-export 所有 public API
├── hcl_test.mbt     # 主集成测试
├── json.mbt         # JSON 转换入口
├── schema.mbt       # Schema 验证入口
├── ser.mbt          # 序列化入口
├── de.mbt           # 反序列化入口
├── trait.mbt        # ToHCL/FromHCL trait
├── builder.mbt      # Builder 模式
├── cmd/main/        # CLI (已有)
├── lexer/           # lexer 包 (已完成)
├── e2e/             # e2e 包 (已完成)
└── internal/        # internal 子包
```

#### 7.3 迁移顺序（避免循环依赖）
```
1. internal/value/ (最底层，无依赖)
   - value.mbt, body.mbt, decor.mbt, visit.mbt, visit_mut.mbt

2. internal/util/ (依赖 value)
   - number.mbt, object.mbt, ident.mbt

3. internal/parser/ (依赖 lexer, value)
   - parser.mbt (改为 @lexer.Lexer, @value.HCLValue)

4. internal/eval/ (依赖 value, parser)
   - eval.mbt, expr.mbt

5. internal/funcs/ (依赖 eval, value)
   - funcs.mbt

6. internal/template/ (依赖 eval, funcs)
   - template.mbt

7. 根目录 hcl.mbt (依赖所有)
   - re-export public API
```

#### 7.4 每步验证
```
1. moon build && moon test
2. 确保无循环依赖
3. 提交每步
```

#### 7.5 预期结果
```
hcl/
├── hcl.mbt          # ~100行，re-export API
├── hcl_test.mbt     # ~500行，集成测试
├── json.mbt         # ~200行
├── schema.mbt       # ~300行
├── ser.mbt          # ~300行
├── de.mbt           # ~200行
├── trait.mbt        # ~200行
├── builder.mbt      # ~100行
├── cmd/main/        # CLI
├── lexer/           # lexer 包
├── e2e/             # e2e 包
└── internal/        # 所有实现细节
    ├── parser/
    ├── eval/
    ├── funcs/
    ├── template/
    ├── value/
    └── util/
```

**关键**: MoonBit 的 `using @package {type X}` 语法允许从子包导入类型，无需在每个文件写 `@package.Type`

### 阶段 1-5：历史进度

参见下方"已完成阶段"记录

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
1. 保留空白和注释的编辑（类似 hcl-edit）
2. 性能优化
3. 更多 CLI 功能（文件读取、批量处理）
4. 序列化 derive 支持 ✅
   - ToHCL trait ✅
   - FromHCL trait ✅
   - Builder 模式 ✅
   - 基础类型自动实现 ✅
   - Array/Option 泛型实现 ✅
5. 官方 spec test suite ✅ (阶段6的一部分)
```

## 文件结构（目标）

```
hcl/
├── moon.work              # workspace 定义
├── lexer/                 # HCL lexer 子包
│   ├── moon.mod.json
│   ├── moon.pkg
│   └── lexer.mbt
├── e2e/                   # 端到端测试（官方测试套件）
│   ├── moon.mod.json
│   ├── moon.pkg
│   ├── e2e_test.mbt
│   └── testdata/          # 官方 HCL 测试用例
│       ├── comments/
│       ├── expressions/
│       └── structure/
├── cmd/main/              # CLI 入口
├── moon.mod.json          # 根包配置
├── moon.pkg
├── body.mbt               # Body/Block/Attr 结构
├── de.mbt                 # 反序列化
├── error.mbt              # 错误类型
├── eval.mbt               # 表达式求值
├── funcs.mbt              # 内置函数
├── hcl.mbt                # 主入口
├── json.mbt               # JSON 转换
├── parser.mbt             # 解析器
├── schema.mbt             # Schema 验证
├── ser.mbt                # 序列化
├── template.mbt           # 模板系统
├── token.mbt              # Token 类型
├── value.mbt              # HCLValue 类型
├── trait.mbt              # ToHCL/FromHCL trait
├── builder.mbt            # Builder 模式
└── *_test.mbt             # 测试文件
```

## 参考资料

- hcl-rs 源码：`/home/lenitain/.projects/hcl-rs/`
- HCL 规范：https://github.com/hashicorp/hcl/blob/main/spec.md
- MoonBit 文档：https://docs.moonbitlang.com
