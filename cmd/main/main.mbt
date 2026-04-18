///|
/// HCL CLI Tool - converts HCL to JSON
/// Run with `moon run cmd/main` from the project root.
///
/// Usage: moon run cmd/main [OPTIONS]
///
/// Options:
///   -h, --help         Show this help message
///   -p, --pretty       Pretty-print JSON output
///   -s, --simplify     Simplify constant expressions
///   -f, --file PATH    Read HCL from file (default: use example HCL)

///|
/// Show help message
fn show_help(program_name : String) -> Unit {
  println("HCL CLI Tool - converts HCL to JSON")
  println("")
  println("Usage: " + program_name + " [OPTIONS]")
  println("")
  println("Options:")
  println("  -h, --help         Show this help message")
  println("  -p, --pretty       Pretty-print JSON output")
  println("  -s, --simplify     Simplify constant expressions")
  println("  -f, --file PATH    Read HCL from file (default: use example HCL)")
}

///|
/// Parse CLI arguments
/// Returns (help, pretty, simplify, file_path)
fn parse_args(args : Array[String]) -> (Bool, Bool, Bool, String?) {
  let mut help = false
  let mut pretty = false
  let mut simplify = false
  let mut file_path : String? = None
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      help = true
    } else if arg == "-p" || arg == "--pretty" {
      pretty = true
    } else if arg == "-s" || arg == "--simplify" {
      simplify = true
    } else if arg == "-f" || arg == "--file" {
      if i + 1 < args.length() {
        file_path = Some(args[i + 1])
        i = i + 1
      } else {
        println("Error: -f/--file requires a path argument")
      }
    } else if !arg.has_prefix("-") {
      file_path = Some(arg)
    } else {
      println("Error: Unknown option: " + arg)
    }
    i = i + 1
  }
  (help, pretty, simplify, file_path)
}

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
  let args = @sys.get_cli_args()
  let program_name = if args.length() > 0 { args[0] } else { "hcl" }
  let (help, pretty, simplify, file_path) = parse_args(args)

  if help {
    show_help(program_name)
    return
  }

  match file_path {
    Some(path) => {
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
      let example_hcl = get_example_hcl()
      let json = hcl_to_json_string(example_hcl, pretty, simplify)
      println(json)
    }
  }
}
