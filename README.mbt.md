# HCL

HCL parser, formatter, and serialization library for MoonBit.

## Features

- Parse HCL syntax
- Serialize/deserialize to/from MoonBit types
- Format HCL with proper indentation
- Preserve whitespace and comments through parse-modify-serialize cycles
- Terraform-compatible

## Installation

```bash
moon add hcl
```

## Usage

### Parse HCL

```moonbit nocheck
let input = "name = \"John\"\nport = 8080"
let result = hcl.parse(input)
match result {
  Ok(body) => {
    println("Parsed successfully!")
  }
  Err(e) => {
    println("Error: " + e.message())
  }
}
```

### Parse HCL Attributes

```moonbit nocheck
let input = "host = \"localhost\"\nport = 8080"
let result = hcl.parse(input)
match result {
  Ok(body) => {
    for item in body.get_items() {
      match item {
        Attribute(attr) => {
          println(attr.get_key() + " = " + attr.get_value().to_json_string())
        }
        Block(block) => {
          println("Block: " + block.get_type_name())
        }
      }
    }
  }
  Err(e) => println("Error: " + e.message())
}
```

### Parse HCL Blocks

```moonbit nocheck
let input = "resource \"aws_instance\" \"example\" {\n  ami = \"ami-123\"\n  instance_type = \"t2.micro\"\n}"
let result = hcl.parse(input)
match result {
  Ok(body) => {
    for item in body.get_items() {
      match item {
        Block(block) => {
          println("Block type: " + block.get_type_name())
          println("Labels: " + block.get_labels().join(", "))
        }
        _ => ()
      }
    }
  }
  Err(e) => println("Error: " + e.message())
}
```

### Serialize to HCL

```moonbit nocheck
let value = hcl.HCLValue::Object({
  "name": hcl.HCLValue::String("John"),
  "age": hcl.HCLValue::Int(30),
  "active": hcl.HCLValue::Bool(true)
})
let hcl_str = hcl.to_hcl_value(value)
println(hcl_str)
```

### Check if HCL is Valid

```moonbit nocheck
let valid = "name = \"John\""
let invalid = "name = John" // missing quotes

println("Valid: " + hcl.is_valid_hcl(valid).to_string())
println("Invalid: " + hcl.is_valid_hcl(invalid).to_string())
```

### Preserve Comments and Whitespace (Decor)

The decor system preserves whitespace and comments through parse-modify-serialize
round-trips. Every `HCLValue`, `Body`, `Attr`, and `Block` carries a `Decor` with
`prefix` and `suffix` fields that store surrounding whitespace and comments.

```moonbit nocheck
let input = "// Configure server\nhost = \"localhost\"\nport = 8080"
let result = hcl.parse(input)
match result {
  Ok(body) => {
    // Comments are preserved in decor
    let attr = body.find_attr("host")
    match attr {
      Some(a) => {
        let prefix = a.get_decor().get_prefix()
        // prefix contains "// Configure server\n"
        println("Has comment: " + prefix.is_some().to_string())
      }
      None => ()
    }

    // Serialize back preserves comments
    let output = hcl.format_body_with_decor(body)
    println(output)
  }
  Err(e) => println("Error: " + e.message())
}
```

See [docs/decor-usage.md](docs/decor-usage.md) for detailed examples.

## HCL Syntax

HCL (HashiCorp Configuration Language) is a structured configuration language. Here are the basic constructs:

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

### Objects

```hcl
config = {
  host = "localhost"
  port = 8080
}
```

### Arrays

```hcl
items = ["one", "two", "three"]
numbers = [1, 2, 3, 4, 5]
```

### Comments

```hcl
// Line comment
/* Block comment */
```

## License

MIT
