# AGENTS.md — HCL for MoonBit

HCL (HashiCorp Configuration Language) parser, formatter, and serialization library.

## Commands

- `moon test` — run tests
- `moon test --update` — update snapshots
- `moon fmt` — format code
- `moon check` — typecheck (pre-commit hook runs this)
- `moon info` — regenerate `.mbti` interface
- `moon coverage analyze > uncovered.log` — find untested lines
- `moon run cmd/main` — run CLI (`-- --help` for options)

After editing, always run: `moon check && moon test && moon info && moon fmt`

## Architecture

Single package at repo root (`moon.pkg` is empty = library).

Pipeline: `lexer.mbt` → `token.mbt` → `parser.mbt` → `body.mbt` / `value.mbt`

- `lexer.mbt` — tokenizer, produces `Token` stream from string input
- `token.mbt` — token enum with operator precedence
- `parser.mbt` — recursive descent parser, entry: `parse(String) -> HCLResult[Body]`
- `body.mbt` — `Body` (top-level), `Attr`, `Block`, `BodyItem` types
- `value.mbt` — `HCLValue` enum (Null/Bool/Int/Int64/Float/String/Array/Object)
- `error.mbt` — `HCLError` enum, `HCLResult[T]` type alias
- `ser.mbt` — serialize MoonBit values → HCL string (`to_hcl_value`, `format_body`)
- `de.mbt` — deserialize HCL string → MoonBit types (`from_hcl_*`)
- `hcl.mbt` — module doc only
- `eval.mbt` — expression evaluation, `simplify_body` function
- `funcs.mbt` — 45 built-in functions

CLI: `cmd/main/main.mbt` — hcl2json with `--help`, `--pretty`, `--simplify`, `--file`

## MoonBit conventions

- Blocks separated by `///|` — order is irrelevant, can process block-by-block
- Blackbox tests: `*_test.mbt`; whitebox tests: `*_wbtest.mbt`
- `.mbti` is generated interface — check its diff to verify visibility changes
- Deprecated blocks → `deprecated.mbt` in each directory

## Gotchas

- `moon.pkg` at root is empty (library). `cmd/main/moon.pkg` has `options("is-main": true)`
- Pre-commit hook (`.githooks/pre-commit`) runs `moon check`. Activate with: `git config core.hooksPath .githooks`
- `HCLResult[T]` is `Result[T, HCLError]` — use this alias, not raw `Result`
- Parser uses immutable-style (`advance` returns new parser). `Lexer` is also value-based
- MoonBit flat package: all modules share namespace, no intra-package re-exports

## Branch naming

Format: `lenitain/feat/<feature-name>` or `lenitain/fix/<bug-name>`

## Reference

- hcl-rs source: `/home/pilot/.projects/hcl-rs/`
- HCL spec: https://github.com/hashicorp/hcl/blob/main/spec.md