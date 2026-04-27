# 迭代 12 开发计划：RegexFuncs + TypeSystemEnhance

## 目标
补齐剩余可实现的内置函数（regex）并增强类型系统。

## 分支
`lenitain/feat/regex-and-type-enhance`

## 任务拆分

### Task 1: Regex 函数 — RegexFuncs (funcs.mbt + funcs_test.mbt)
依赖: MoonBit core `@string.Regex`（已内置，无需新增依赖）

| 函数 | 签名 | 实现 |
|------|------|------|
| `regex(pattern, str)` | `(string, string) -> array(string)` | `Regex::unsafe_from_string` + `execute`，返回 `[full, group0, group1, ...]` |
| `regexall(pattern, str)` | `(string, string) -> array(array(string))` | `Regex::find` 迭代，每个 match 展开 groups |
| `regex_replace(pattern, str, repl)` | `(string, string, string) -> string` | `Regex::replace_by`，repl 中 `$N` 替换为 group |

关键点:
- `StringView` → `String` 需 `.to_string()`
- `MatchResult::content()` 完整匹配，`group(i)` 捕获组
- `regex_replace` 解析 `$N` 占位符
- 无效 regex pattern → `HCLError::invalid_value`

测试: 9 个（regex 3 + regexall 3 + regex_replace 3）

### Task 2: TypeSystemEnhance (unify.mbt + unify_test.mbt)
- `TypeName` 新增 `TDynamic` 变体
- `type_of` 空数组→`TArray(TDynamic)`，空对象→`TObject(TDynamic)`
- `unify_types`: TDynamic + X → Ok(X)

测试: 6 个

### Task 3: 跳过 CryptoFuncs
MoonBit 无 SHA/MD5 crypto 模块。

### Task 4: 更新 PROGRESS.md

## 验证
```bash
moon check && moon test && moon info && moon fmt
```
