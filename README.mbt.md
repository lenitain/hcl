# HCL for MoonBit

HCL (HashiCorp Configuration Language) parser, formatter, and serialization library for MoonBit.

## Features

### Completed

- **Parse HCL syntax** - Parse HCL strings into AST (`Body`, `Block`, `Attr`)
- **Serialize to HCL** - Convert MoonBit types back to HCL strings
- **Deserialize to MoonBit types** - Use `ToHCL`/`FromHCL` traits for type-safe conversion
- **Format HCL** - Proper indentation with configurable `Formatter`
- **Preserve comments and whitespace** - Decor system for parse-modify-serialize cycles
- **Expression evaluation** - Evaluate HCL expressions (`+`, `-`, `*`, `/`, comparisons, etc.)
- **45 built-in functions** - `abs`, `ceil`, `floor`, `keys`, `values`, `length`, `chomp`, `upper`, `lower`, `replace`, `split`, `format`, `tobool`, `tonumber`, `tolist`, `tomap`, and more
- **For expressions** - List comprehension `[for x in list: expr]` and object comprehension `{for k, v in obj: k => v}`
- **Conditional expressions** - `cond ? true_val : false_val`
- **Heredoc support** - `<<EOF`, `<<-EOF` with custom delimiters
- **Template expressions** - String interpolation `${expr}` and template directives `%{if}`, `%{for}`
- **Schema validation** - Type checking, required fields, custom validators
- **JSON conversion** - `hcl_to_json()`, `body_to_json_pretty()`
- **CLI tool** - `moon run cmd/main` provides `hcl2json` with `--pretty`, `--simplify`, `--validate`, `--format`
- **Visit AST** - Immutable (`Visit`) and mutable (`VisitMut`) traversals

### Cannot Be Implemented (MoonBit Language Limitations)

The following features exist in the Rust `hcl-rs` library but **cannot be implemented** in MoonBit due to language limitations:

| Feature | Why Not Possible |
|---------|-----------------|
| **Serde `#[derive(Serialize, Deserialize)]`** | MoonBit has no procedural macros / derive system |
| **Span with byte offsets** | MoonBit AST nodes don't track source span |
| **Formatted\<T\> round-trip** | MoonBit lacks custom formatting traits |
| **winnow combinator parsing** | No parser combinator library exists for MoonBit |
| **perf features / benchmarks** | No benchmarking infrastructure |
| **indexmap/vecmap** | No equivalent crate exists |
| **stdin support** | MoonBit stdlib has no stdin API |
| **glob file patterns** | No glob library for MoonBit |

### MoonBit Ecosystem Limitations

| Feature | Workaround |
|---------|------------|
| stdin input | Use `--file` option to read from file |
| glob patterns | Process files individually in a build script |

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
```

## Installation

```bash
moon add github:lenitain/hcl
```

Or add to your `moon.pkg`:

```json
{
  "dependencies": {
    "hcl": "github:lenitain/hcl"
  }
}
```

## Usage Examples

### Parse and Access Data

```moonbit nocheck
let input = `
// Server configuration
server {
  host = "localhost"
  port = 8080
}

name = "myapp"
version = "1.0.0"
`

let body = hcl.parse(input).unwrap()

// Find block
let server = body.find_block("server").unwrap()
let server_body = server.get_body()
let host = server_body.find_attr("host").unwrap().get_value().as_string()

// Find attribute
let name = body.find_attr("name").unwrap().get_value().as_string()
```

### Serialize to HCL

```moonbit nocheck
let value = hcl.hcl_object([
  ("name", hcl.hcl_str("John")),
  ("age", hcl.hcl_int(30)),
  ("active", hcl.hcl_bool(true)),
])
let hcl_str = hcl.to_hcl_value(value)
// name = "John"
// age = 30
// active = true
```

### Format with Decor Preservation

```moonbit nocheck
let input = "// Configure server\nhost = \"localhost\"\nport = 8080"
let body = hcl.parse(input).unwrap()

// format_body_with_decor preserves comments
let output = hcl.format_body_with_decor(body)
```

### Expression Evaluation

```moonbit nocheck
let vars = {
  "x": hcl.hcl_int(10),
  "y": hcl.hcl_int(3),
}
let funcs = hcl.builtin_functions()

// Evaluate: x + y > 5 ? "yes" : "no"
let expr = hcl.hcl_object([
  ("type", hcl.hcl_str("conditional")),
  ("condition", hcl.hcl_object([
    ("type", hcl.hcl_str("binary_expr")),
    ("op", hcl.hcl_str(">")),
    ("left", hcl.hcl_object([
      ("type", hcl.hcl_str("binary_expr")),
      ("op", hcl.hcl_str("+")),
      ("left", hcl.hcl_str("x")),
      ("right", hcl.hcl_str("y")),
    ])),
    ("right", hcl.hcl_int(5)),
  ])),
  ("true_expr", hcl.hcl_str("yes")),
  ("false_expr", hcl.hcl_str("no")),
])

let result = hcl.eval_expr(expr, vars, funcs)
// Ok(String("yes", ...))
```

### Schema Validation

```moonbit nocheck
let schema = hcl.FieldSchema::new()
  .attr("name", hcl.TypeSchema::String)
  .attr("port", hcl.TypeSchema::Int)
  .required("name")

let body = hcl.parse("port = 8080").unwrap()
let result = hcl.from_hcl_with_schema(body, schema)
// Err(HCLError::missing_required("name"))
```

### CLI Usage

```bash
# Parse and convert to JSON
moon run cmd/main --file config.hcl

# Pretty print JSON
moon run cmd/main --file config.hcl --pretty

# Simplify expressions
moon run cmd/main --file config.hcl --simplify

# Validate HCL (exit code 0 or 1)
moon run cmd/main --file config.hcl --validate

# Format HCL
moon run cmd/main --file config.hcl --format
```

## HCL Syntax Support

### Attributes

```hcl
name = "John"
age = 30
active = true
```

### Blocks

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}
```

### Objects and Arrays

```hcl
config = {
  host = "localhost"
  port = 8080
}

items = ["one", "two", "three"]
```

### Expressions

```hcl
# Arithmetic
count = 1 + 2 * 3

# Conditionals
status = count > 10 ? "high" : "low"

# For expressions
names = [for item in items: item.name]
```

### Heredocs

```hcl
script = <<EOF
#!/bin/bash
echo "Hello"
EOF
```

## API Reference

### Parse

- `hcl.parse(String) -> HCLResult[Body]`

### Serialize

- `hcl.to_hcl_body(Body) -> String`
- `hcl.to_hcl_value(HCLValue) -> String`
- `hcl.format_body(Body) -> String`
- `hcl.format_body_with_decor(Body) -> String`

### Deserialize

- `hcl.from_hcl_body(String) -> HCLResult[Body]`
- `hcl.from_hcl_with_schema(Body, FieldSchema) -> HCLResult[...]`

### JSON

- `hcl.hcl_to_json(String) -> String`
- `hcl.body_to_json(Body) -> String`
- `hcl.body_to_json_pretty(Body) -> String`

### Evaluation

- `hcl.eval_expr(HCLValue, Map[String, HCLValue], Map[String, Fn]) -> HCLResult[HCLValue]`
- `hcl.simplify_body(Body) -> Body`
- `hcl.builtin_functions() -> Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]]`

### Schema

- `hcl.TypeSchema` - Type checking (`String`, `Int`, `Bool`, `Array`, `Object`)
- `hcl.FieldSchema` - Field validation with `required()`, `validator()`
- `hcl.from_hcl_with_schema(Body, FieldSchema) -> HCLResult[T]`

### Decor

- `hcl.Decor` - Whitespace and comment storage
- `hcl.Decorated[T]` - Wrapper that carries decor
- `hcl.format_body_with_decor(Body) -> String`
- `hcl.format_attr_with_decor(Attr) -> String`

### Visit

- `hcl.Visit` trait - Immutable AST traversal
- `hcl.VisitMut` trait - Mutable AST traversal


## License

MIT
