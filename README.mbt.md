# HCL for MoonBit

[![mooncake](https://img.shields.io/badge/mooncake-lenitain%2Fhcl-blue)](https://mooncakes.io/docs/lenitain/hcl)

HCL (HashiCorp Configuration Language) parser, formatter, and serialization library for MoonBit.

~99% HCL spec complete (CryptoFuncs skipped — MoonBit no crypto lib). 921 tests passing.

## Features

### Core
- **Parse HCL syntax** - Parse HCL strings into AST (`Body`, `Block`, `Attr`)
- **Serialize to HCL** - Convert MoonBit types back to HCL strings
- **Deserialize to MoonBit types** - `ToHCL`/`FromHCL` traits for type-safe conversion
- **Format HCL** - Configurable `Formatter` with proper indentation
- **Preserve comments and whitespace** - Decor system for parse-modify-serialize cycles
- **Source position tracking** - Span info on Attr, Block, Body nodes

### Expressions
- **Binary ops** - `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`
- **Unary ops** - `-`, `!`
- **Conditional** - `cond ? true_val : false_val` (with type unification)
- **For expressions** - List comprehension `[for x in list: expr]`, object comprehension `{for k, v in obj: k => v}`, `if` filter
- **Splat operator** - `list.*.attr`, `list[*].attr`
- **Property access** - `obj.key`, `obj["key"]`, `arr[0]`
- **Function calls** - Full function call framework
- **Parenthesized** - Grouping and precedence override

### Templates
- **String interpolation** - `${expr}`
- **Template directives** - `%{if}`, `%{else if}`, `%{else}`, `%{endif}`, `%{for}`, `%{endfor}`
- **Strip markers** - `${~ expr ~}`, `%{~ directive ~}` for whitespace control
- **Heredoc** - `<<EOF`, `<<-EOF` with custom delimiters

### Built-in Functions (78)
- **Numeric (9)** - `abs`, `ceil`, `floor`, `log`, `max`, `min`, `parseint`, `pow`, `signum`
- **Collection (19)** - `length`, `keys`, `values`, `contains`, `flatten`, `merge`, `reverse`, `distinct`, `sort`, `slice`, `element`, `concat`, `coalesce`, `range`, `chunklist`, `lookup`, `zipmap`, `transpose`, `matchkeys`
- **Aggregation (4)** - `sum`, `alltrue`, `anytrue`, `one`
- **Set (6)** - `setunion`, `setintersection`, `setsubtract`, `setsymmetricdifference`, `setproduct`, `setissubset`
- **String (18)** - `chomp`, `indent`, `join`, `lower`, `upper`, `replace`, `split`, `strrev`, `substr`, `trim`, `trimprefix`, `trimsuffix`, `trimspace`, `format`, `formatlist`, `startswith`, `endswith`, `title`
- **Type conversion (6)** - `tobool`, `tonumber`, `tolist`, `tomap`, `toset`, `tostring`
- **Encoding (6)** - `jsondecode`, `jsonencode`, `base64decode`, `base64encode`, `csvdecode`, `urlencode`
- **DateTime (3)** - `formatdate`, `timeadd`, `timecmp`
- **Network (4)** - `cidrhost`, `cidrnetmask`, `cidrsubnet`, `cidrsubnets`
- **Regex (3)** - `regex`, `regexall`, `regex_replace`

### Types & Validation
- **Schema validation** - `TypeSchema` type checking, required fields, custom validators
- **Body schema extraction** - `BodySchema`/`BlockSchema`/`LabelSchema` for structured body extraction
- **Type unification** - `unify_types`, `convert_value` for implicit type coercion (string↔number↔bool)
- **Unknown values** - `HCLValue::Unknown` for Terraform partial-evaluation compatibility
- **Dynamic types** - `TDynamic` variant in `TypeName`, unifies with any type
- **FuncDef parameter system** - `ParamType` (Any, Bool, Number, String, Array, Object, Nullable, OneOf) with automatic validation

### Identifiers
- **Unicode support** - XID_Start/XID_Continue (CJK, Hangul, Cyrillic, Greek, Arabic, Devanagari, Thai, Latin Extended, etc.)
- **Number literals** - Decimal, hex (`0x`), octal (`0o`), binary (`0b`), scientific notation, float

### JSON
- **HCL→JSON** - `hcl_to_json()`, `body_to_json_pretty()` (spec-compliant, handles nested blocks/labels)
- **JSON→HCL** - `json_parse.mbt` parses `terraform.tfvars.json` into HCL Body

### Analysis & Transformation
- **Static analysis** - `collect_variables`, `collect_functions`, `collect_traversals` on Body or Expression
- **Expression simplification** - `simplify_body` for constant folding at parse time
- **Parse error recovery** - `parse_with_recovery` accumulates multiple errors, returns partial Body
- **FuncRegistry API** - `FuncRegistry` for registering custom functions with built-in merge
- **AST traversal** - Immutable (`Visit`) and mutable (`VisitMut`) visitor pattern
- **Decor system** - `Decor`, `Decorated[T]` for comment/whitespace preservation

### CLI
- **hcl2json** - `moon run cmd/main [OPTIONS] [FILES...]`
  - `--pretty` / `-p` — pretty-print JSON
  - `--simplify` / `-s` — constant folding
  - `--format` / `-F` — output formatted HCL
  - `--validate` / `-v` — validate HCL (exit 0/1)
  - `--json-input` / `-j` — input is JSON, output HCL
  - `--output FILE` / `-o` — write to file
  - `--indent N` — set indent width (default 2)
  - `--version` — print version
  - `--color` / `--no-color` — force color on/off
  - Multi-file: pass multiple paths, combined JSON/format/validate output
  - Colored error output with source context (`line:col`, `^^^^` pointer)

## Official HCL Spec Tests

Includes tests from the [official HCL spec test suite](https://github.com/hashicorp/hcl/tree/main/specsuite/tests).

```bash
moon test -F "spec fixture *"        # all 14 fixture tests
moon test -F "spec fixture comments *"
moon test -F "spec fixture expressions *"
moon test -F "spec fixture structure *"
```

## Quick Start

```moonbit nocheck
import "hcl"

// Parse HCL
let input = "name = \"John\"\nport = 8080"
let body = hcl.parse(input).unwrap()

// Access attributes
let name = body.find_attr("name").unwrap().get_value().as_string()
let port = body.find_attr("port").unwrap().get_value().as_int()

// Serialize back to HCL
let hcl_str = hcl.to_hcl_body(body)

// Convert to JSON
let json_str = hcl.body_to_json_pretty(body)

// Evaluate expressions
let expr = hcl.parse("x = 1 + 2 * 3").unwrap()
let result = hcl.simplify_body(expr)
```

## Installation

```bash
moon add github:lenitain/hcl
```

Or add to `moon.pkg`:

```json
{
  "dependencies": {
    "hcl": "github:lenitain/hcl"
  }
}
```

## HCL Syntax Support

```hcl
# Attributes
name = "John"
count = 1 + 2 * 3
status = count > 10 ? "high" : "low"

# Blocks with labels
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}

# Objects and Arrays
config = { host = "localhost", port = 8080 }
items  = ["one", "two", "three"]

# Heredoc
script = <<EOF
#!/bin/bash
echo "Hello"
EOF

# For expressions
names = [for item in items: item.name]

# Splat
all_names = items.*.name
```

## API Reference

| Category | Functions |
|----------|-----------|
| **Parse** | `parse(String) -> HCLResult[Body]`, `parse_with_recovery(String) -> (Body?, Array[HCLError])` |
| **Serialize** | `to_hcl_body(Body) -> String`, `to_hcl_value(HCLValue) -> String`, `format_body(Body) -> String`, `format_body_with_decor(Body) -> String` |
| **Deserialize** | `from_hcl_body(String) -> HCLResult[Body]`, `from_hcl_with_schema(Body, FieldSchema) -> HCLResult[...]`, `from_hcl_with_body_schema(Body, BodySchema) -> HCLResult[ExtractedBody]` |
| **JSON** | `hcl_to_json(String) -> String`, `body_to_json(Body) -> String`, `body_to_json_pretty(Body) -> String`, `json_to_body(String) -> HCLResult[Body]` |
| **Eval** | `eval_expr(Expression, Map[String, HCLValue], Map[String, FuncDef]) -> HCLResult[HCLValue]`, `eval_expr_with_funcs(Expression, Map[String, HCLValue], Map[String, FuncDef]) -> HCLResult[HCLValue]`, `simplify_body(Body) -> Body`, `builtin_functions() -> Map[String, FuncDef]`, `merge_funcs(Map[...], Map[...]) -> Map[...]` |
| **Schema** | `TypeSchema`, `FieldSchema`, `BodySchema`, `Validator`, `from_hcl_with_schema` |
| **Types** | `TypeName` enum, `unify_types(TypeName, TypeName) -> HCLResult[TypeName]`, `convert_value(HCLValue, TypeName) -> HCLResult[HCLValue]` |
| **Static analysis** | `collect_variables(Body) -> Array[String]`, `collect_functions(Body) -> Array[String]`, `collect_traversals(Body) -> Array[String]` |
| **Ident** | `Ident::new(String) -> HCLResult[Ident]` (validates XID_Start/XID_Continue) |
| **Span** | `Span` struct, `Spanned[T]` wrapper with start/end line+column |
| **FuncDef** | `FuncDefBuilder` for defining functions with typed params, variadic, OneOf |
| **FuncRegistry** | `FuncRegistry::new()`, `with_builtins()`, `register(name, def)`, `merge(other)`, `build()` |
| **Decor** | `Decor`, `Decorated[T]`, `format_body_with_decor`, `format_attr_with_decor` |
| **Visit** | `Visit` trait (immutable), `VisitMut` trait (mutable) |

## License

Apache-2.0 License
