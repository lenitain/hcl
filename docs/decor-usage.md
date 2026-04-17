# Decor Usage Guide

The decor system preserves whitespace and comments through parse-modify-serialize
round-trips. This is useful for tools that need to edit HCL files without losing
user formatting.

## Core Types

### `Decor`

Stores prefix and suffix whitespace/comments around a syntactic element.

```moonbit
// Create decor with prefix comment
let decor = Decor::new(Some("// comment\n"), Some("\n"))

// Empty decor (no whitespace/comments)
let empty = Decor::empty()

// Build incrementally
let decor = Decor::empty()
  .set_prefix("// header\n")
  .set_suffix("\n")

// Read decor
decor.get_prefix()  // Some("// header\n")
decor.get_suffix()  // Some("\n")
decor.clear()       // Removes all decor
```

### `Decorated[T]`

Wraps a value with its decor. Used for keys, labels, and type names.

```moonbit
// Create decorated string
let key = Decorated::new("name", Decor::new(Some("  "), None))

// Bare value (no decor)
let key = Decorated::bare("name")

// Access
key.get_value()   // "name"
key.get_decor()   // Decor with prefix "  "
```

### `HCLValue`

Every variant carries a `Decor`:

```moonbit
// Create values with decor
let val = HCLValue::Int(42, Decor::new(Some("// answer\n"), None))

// Convenience constructors use empty decor
let val = HCLValue::int(42)
let val = HCLValue::string("hello")
let val = HCLValue::bool(true)

// Get/set decor on any value
val.get_decor()
val.set_decor(new_decor)
```

## Parse-Modify-Serialize Round-Trip

### Basic Round-Trip

Parse HCL, modify a value, serialize back with all comments preserved:

```moonbit
let input = """
// Server configuration
host = "localhost"  # default host
port = 8080         # default port
"""

// 1. Parse
let body = hcl.parse(input).unwrap()

// 2. Modify - change host value
let host_attr = body.find_attr("host").unwrap()
let new_host = HCLValue::string("0.0.0.0")
  .set_decor(host_attr.get_value().get_decor())
// Body is immutable, so build a new one
let new_body = hcl.Body::new()
  .add_attr("host", new_host)
  .add_attr("port", body.find_attr("port").unwrap().get_value())

// 3. Serialize - comments are preserved
let output = hcl.format_body_with_decor(new_body)
```

### Preserving Comments on Attributes

Comments before an attribute are stored as the attribute's `prefix` decor:

```moonbit
let input = """
# This is the server host
host = "localhost"
"""

let body = hcl.parse(input).unwrap()
let attr = body.find_attr("host").unwrap()

// The comment is in the attribute's prefix
attr.get_decor().get_prefix()
// => Some("# This is the server host\n")
```

### Preserving Inline Comments

Inline comments after a value are stored as the value's `suffix` decor:

```moonbit
let input = "port = 8080 # default"

let body = hcl.parse(input).unwrap()
let attr = body.find_attr("port").unwrap()

// Inline comment is in the value's suffix
attr.get_value().get_decor().get_suffix()
// => Some(" # default")
```

### Preserving Block Comments

Comments before a block are stored as the block's `prefix` decor:

```moonbit
let input = """
// Provision an EC2 instance
resource "aws_instance" "web" {
  ami = "ami-123"
}
"""

let body = hcl.parse(input).unwrap()
let block = body.find_block("resource").unwrap()

block.get_decor().get_prefix()
// => Some("// Provision an EC2 instance\n")
```

## API Reference

### Decor Methods

| Method | Description |
|--------|-------------|
| `Decor::new(prefix, suffix)` | Create with prefix and suffix |
| `Decor::empty()` | Create empty decor |
| `decor.get_prefix()` | Get prefix string |
| `decor.get_suffix()` | Get suffix string |
| `decor.set_prefix(s)` | Return new decor with prefix |
| `decor.set_suffix(s)` | Return new decor with suffix |
| `decor.clear()` | Return empty decor |

### Decorated[T] Methods

| Method | Description |
|--------|-------------|
| `Decorated::new(value, decor)` | Create decorated value |
| `Decorated::bare(value)` | Create with empty decor |
| `d.get_value()` | Get inner value |
| `d.get_decor()` | Get decor |
| `d.set_decor(decor)` | Return with new decor |

### HCLValue Decor Methods

| Method | Description |
|--------|-------------|
| `val.get_decor()` | Get decor from any value |
| `val.set_decor(decor)` | Return value with new decor |
| `HCLValue::int(i)` | Create Int with empty decor |
| `HCLValue::string(s)` | Create String with empty decor |
| `HCLValue::bool(b)` | Create Bool with empty decor |

### Body/Attr/Block Decor Methods

| Method | Description |
|--------|-------------|
| `body.get_decor()` | Get body decor |
| `Body::with_decor(items, decor)` | Create body with decor |
| `attr.get_decor()` | Get attribute decor |
| `attr.get_decorated_key()` | Get key as Decorated[String] |
| `Attr::with_decor(key, value, decor)` | Create attr with decor |
| `block.get_decor()` | Get block decor |
| `block.get_decorated_type_name()` | Get type name as Decorated[String] |
| `block.get_decorated_labels()` | Get labels as Array[Decorated[String]] |
| `Block::with_decor(type_name, labels, body, decor)` | Create block with decor |

### Serialization Functions

| Function | Description |
|----------|-------------|
| `format_body_with_decor(body)` | Serialize body preserving decor |
| `format_value_with_decor(value)` | Serialize value preserving decor |
| `format_attr_with_decor(attr)` | Serialize attribute preserving decor |

## Common Patterns

### Updating a Single Attribute

```moonbit
fn update_attr(body : Body, key : String, new_value : HCLValue) -> Body {
  let items = []
  for item in body.get_items() {
    match item {
      Attribute(attr) if attr.get_key() == key => {
        // Preserve original decor on the new value
        let decorated_val = new_value.set_decor(attr.get_value().get_decor())
        items.push(Attribute(Attr::with_decor(
          attr.get_decorated_key(),
          decorated_val,
          attr.get_decor(),
        )))
      }
      other => items.push(other)
    }
  }
  Body::with_decor(items, body.get_decor())
}
```

### Adding a New Attribute with Comment

```moonbit
fn add_attr_with_comment(body : Body, key : String, value : HCLValue, comment : String) -> Body {
  let attr = Attr::with_decor(
    Decorated::bare(key),
    value,
    Decor::new(Some("// " + comment + "\n"), None),
  )
  let items = body.get_items()
  items.push(Attribute(attr))
  Body::with_decor(items, body.get_decor())
}
```

### Stripping All Comments

```moonbit
fn strip_decor(body : Body) -> Body {
  // Re-parse or manually clear decor on all elements
  let items = body.get_items().map(fn(item) {
    match item {
      Attribute(attr) => Attribute(Attr::with_decor(
        Decorated::bare(attr.get_decorated_key().get_value()),
        attr.get_value().set_decor(Decor::empty()),
        Decor::empty(),
      ))
      Block(block) => Block(Block::new(
        block.get_type_name(),
        block.get_labels(),
        strip_decor(block.get_body()),
      ))
    }
  })
  Body::with_decor(items, Decor::empty())
}
```
