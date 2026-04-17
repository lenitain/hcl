///|
/// HCL CLI Tool - converts HCL to JSON
/// Run with `moon run cmd/main` from the project root.

/// Convert HCL string to JSON string
fn hcl_to_json_string(hcl_content : String, pretty : Bool) -> String {
  match @hcl.parse(hcl_content) {
    Ok(body) => {
      if pretty {
        @hcl.body_to_json_pretty(body)
      } else {
        @hcl.body_to_json(body)
      }
    }
    Err(e) => {
      "Error: " + e.message()
    }
  }
}

/// Main entry point
fn main {
  // For now, we'll use a simple example
  // In a real implementation, we would read from stdin or files
  let example_hcl = "name = \"test\"\nvalue = 42"
  let json = hcl_to_json_string(example_hcl, false)
  println(json)
}
