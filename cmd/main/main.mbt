///|
/// HCL CLI Tool - converts HCL to JSON
/// Run with `moon run cmd/main` from the project root.
/// 
/// Usage: moon run cmd/main [FILE]
/// 
/// Options can be set via environment variables:
///   HCL2JSON_PRETTY=1    Pretty-print JSON output
///   HCL2JSON_SIMPLIFY=1  Simplify constant expressions

///|
/// Convert HCL string to JSON string
fn hcl_to_json_string(
  hcl_content : String,
  pretty : Bool,
  simplify : Bool,
) -> String {
  match @hcl.parse(hcl_content) {
    Ok(body) =>
      if simplify {
        let simplified = @hcl.simplify_body(body)
        if pretty {
          @hcl.body_to_json_pretty(simplified)
        } else {
          @hcl.body_to_json(simplified)
        }
      } else if pretty {
        @hcl.body_to_json_pretty(body)
      } else {
        @hcl.body_to_json(body)
      }
    Err(e) => "Error: " + e.message()
  }
}

///|
/// Get example HCL
fn get_example_hcl() -> String {
  "name = \"hcl2json\"\nversion = \"1.0.0\"\nfeatures = [\"parse\", \"format\", \"convert\"]\n\nserver {\n  host = \"localhost\"\n  port = 8080\n}"
}

///|
/// Main entry point
fn main {
  let pretty = match @sys.get_env_var("HCL2JSON_PRETTY") {
    Some("1") => true
    Some("true") => true
    _ => false
  }

  let simplify = match @sys.get_env_var("HCL2JSON_SIMPLIFY") {
    Some("1") => true
    Some("true") => true
    _ => false
  }

  let file_path = @sys.get_env_var("HCL2JSON_FILE")

  match file_path {
    Some(path) => {
      // Read from file
      let content = @fs.read_file_to_string(path) catch {
        _ => {
          println("Error: Failed to read file: " + path)
          return
        }
      }
      let json = hcl_to_json_string(content, pretty, simplify)
      println(json)
    }
    None => {
      // Use example HCL
      let example_hcl = get_example_hcl()
      let json = hcl_to_json_string(example_hcl, pretty, simplify)
      println(json)
    }
  }
}
