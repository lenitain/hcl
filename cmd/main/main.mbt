///|
/// HCL CLI Tool - converts HCL to JSON, formats HCL, validates HCL
/// Run with `moon run cmd/main` from the project root.

///|
/// Read version from moon.mod.json with fallback
fn get_version() -> String {
  let fallback = "0.1.2"
  let content = @fs.read_file_to_string("moon.mod.json") catch { _ => return fallback }
  match content.split_once("\"version\": \"") {
    Some((_, after)) => {
      match after.split_once("\"") {
        Some((ver, _)) => ver.to_string()
        None => fallback
      }
    }
    None => fallback
  }
}

///|
struct CliConfig {
  help : Bool
  version : Bool
  pretty : Bool
  simplify : Bool
  format : Bool
  validate : Bool
  json_input : Bool
  output_file : String?
  indent : Int
  force_color : Bool
  no_color : Bool
  file_paths : Array[String]
}

///|
fn repeat_str(s : String, n : Int) -> String {
  let mut result = ""
  for _ in 0..<n {
    result = result + s
  }
  result
}

///|
fn should_use_color(no_color : Bool, force_color : Bool) -> Bool {
  if no_color {
    false
  } else if force_color {
    true
  } else {
    @env.get_env_var("NO_COLOR") == None
  }
}

///|
fn show_help(program_name : String) -> Unit {
  println("HCL CLI v" + get_version() + " - Convert, format, and validate HCL")
  println("")
  println("Usage: " + program_name + " [OPTIONS] [FILES...]")
  println("")
  println("Options:")
  println("  -h, --help         Show this help message")
  println("  --version          Show version")
  println("  -p, --pretty       Pretty-print JSON output")
  println("  -s, --simplify     Simplify constant expressions")
  println("  -f, --file PATH    Read HCL from file")
  println("  -F, --format       Output formatted HCL instead of JSON")
  println("  -v, --validate     Validate HCL and exit with code 0 or 1")
  println(
    "  -j, --json-input   Input is JSON, output as HCL (implies --format)",
  )
  println("  -o, --output FILE  Write output to file")
  println("  --indent N         Indent width (default 2)")
  println("  --color            Force enable ANSI color output")
  println("  --no-color         Disable ANSI color output")
}

///|
fn parse_int(s : String) -> Int {
  let mut n = 0
  for c in s {
    n = n * 10 + (c.to_int() - 48)
  }
  n
}

///|
fn get_line(input : String, line_num : Int) -> String {
  let mut i = 1
  for line in input.split("\n") {
    if i == line_num {
      return line.to_string()
    }
    i = i + 1
  }
  ""
}

///|
fn parse_args(args : Array[String]) -> CliConfig {
  let mut help = false
  let mut version = false
  let mut pretty = false
  let mut simplify = false
  let mut format = false
  let mut validate = false
  let mut json_input = false
  let mut output_file : String? = None
  let mut indent = 2
  let mut force_color = false
  let mut no_color = false
  let file_paths : Array[String] = []
  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
      help = true
    } else if arg == "--version" {
      version = true
    } else if arg == "-p" || arg == "--pretty" {
      pretty = true
    } else if arg == "-s" || arg == "--simplify" {
      simplify = true
    } else if arg == "-F" || arg == "--format" {
      format = true
    } else if arg == "-v" || arg == "--validate" {
      validate = true
    } else if arg == "-j" || arg == "--json-input" {
      json_input = true
    } else if arg == "--color" {
      force_color = true
    } else if arg == "--no-color" {
      no_color = true
    } else if arg == "-f" || arg == "--file" {
      if i + 1 < args.length() {
        file_paths.push(args[i + 1])
        i = i + 1
      } else {
        println("Error: -f/--file requires a path argument")
      }
    } else if arg == "-o" || arg == "--output" {
      if i + 1 < args.length() {
        output_file = Some(args[i + 1])
        i = i + 1
      } else {
        println("Error: -o/--output requires a path argument")
      }
    } else if arg == "--indent" {
      if i + 1 < args.length() {
        indent = parse_int(args[i + 1])
        i = i + 1
      } else {
        println("Error: --indent requires a number argument")
      }
    } else if !arg.has_prefix("-") {
      file_paths.push(arg)
    } else {
      println("Error: Unknown option: " + arg)
    }
    i = i + 1
  }
  {
    help,
    version,
    pretty,
    simplify,
    format,
    validate,
    json_input,
    output_file,
    indent,
    force_color,
    no_color,
    file_paths,
  }
}

///|
fn format_error(
  err : @hcl.HCLError,
  input : String,
  use_color : Bool,
) -> String {
  match err {
    ParseError(msg, line, col, _, _) => {
      let line_str = if line > 0 { get_line(input, line) } else { "" }
      let header = if use_color {
        "\u001b[31;1mError at line " +
        line.to_string() +
        ", column " +
        col.to_string() +
        " (ParseError):\u001b[0m"
      } else {
        "Error at line " +
        line.to_string() +
        ", column " +
        col.to_string() +
        " (ParseError):"
      }
      let pointer = if col > 0 && line_str.length() > 0 {
        "  | " + repeat_str(" ", col - 1) + "^"
      } else {
        ""
      }
      header + "\n  | " + line_str + "\n" + pointer + "\n  | " + msg
    }
    _ => {
      let msg = err.message()
      if use_color {
        "\u001b[31;1mError:\u001b[0m " + msg
      } else {
        "Error: " + msg
      }
    }
  }
}

///|
fn process_file(config : CliConfig, path : String, use_color : Bool) -> String? {
  let input = @fs.read_file_to_string(path) catch {
    _ => {
      let err_msg = if use_color {
        "\u001b[31;1mError:\u001b[0m Failed to read file: " + path
      } else {
        "Error: Failed to read file: " + path
      }
      println(err_msg)
      return None
    }
  }

  let body = if config.json_input {
    match @hcl.json_to_body(input) {
      Ok(b) => b
      Err(e) => {
        println(format_error(e, input, use_color))
        return None
      }
    }
  } else {
    match @hcl.parse(input) {
      Ok(b) => b
      Err(e) => {
        println(format_error(e, input, use_color))
        return None
      }
    }
  }

  let processed_body = if config.simplify {
    @hcl.simplify_body(body)
  } else {
    body
  }

  let is_format_mode = config.json_input || config.format

  let output = if is_format_mode {
    if config.indent == 2 {
      @hcl.to_hcl_body(processed_body)
    } else {
      @hcl.Formatter::new()
      .set_indent(repeat_str(" ", config.indent))
      .format_body(processed_body)
    }
  } else if config.pretty {
    @hcl.body_to_json_pretty(processed_body, indent=config.indent)
  } else {
    @hcl.body_to_json(processed_body)
  }

  Some(output)
}

///|
fn main {
  let args = @sys.get_cli_args()
  let program_name = if args.length() > 0 { args[0] } else { "hcl" }
  let config = parse_args(args)

  if config.help {
    show_help(program_name)
    @sys.exit(0)
  }

  if config.version {
    println("hcl-moonbit v" + get_version())
    @sys.exit(0)
  }

  let use_color = should_use_color(config.no_color, config.force_color)
  let file_paths = config.file_paths

  if file_paths.is_empty() {
    let err = if use_color {
      "\u001b[31;1mError:\u001b[0m No input files specified"
    } else {
      "Error: No input files specified"
    }
    println(err)
    println("Usage: " + program_name + " [OPTIONS] [FILES...]")
    println("Use --help for more information")
    @sys.exit(1)
  }

  if file_paths.length() > 1 && config.output_file != None {
    let err = if use_color {
      "\u001b[31;1mError:\u001b[0m --output cannot be used with multiple input files"
    } else {
      "Error: --output cannot be used with multiple input files"
    }
    println(err)
    @sys.exit(1)
  }

  if config.validate {
    let mut failures = 0
    for path in file_paths {
      let input = @fs.read_file_to_string(path) catch {
        _ => {
          let err = if use_color {
            "\u001b[31;1mError:\u001b[0m Failed to read file: " + path
          } else {
            "Error: Failed to read file: " + path
          }
          println(err)
          failures = failures + 1
          continue
        }
      }
      let parse_result = if config.json_input {
        @hcl.json_to_body(input)
      } else {
        @hcl.parse(input)
      }
      match parse_result {
        Ok(_) =>
          if use_color {
            println("\u001b[32mValid HCL\u001b[0m: " + path)
          } else {
            println("Valid HCL: " + path)
          }
        Err(e) => {
          println(format_error(e, input, use_color))
          failures = failures + 1
        }
      }
    }
    @sys.exit(failures)
  }

  let results : Array[(String, String)] = []

  for path in file_paths {
    match process_file(config, path, use_color) {
      Some(output) => results.push((path, output))
      None => @sys.exit(1)
    }
  }

  let combined = if file_paths.length() == 1 {
    results[0].1
  } else if config.json_input || config.format {
    results.map(fn(p) { "/* file: " + p.0 + " */\n" + p.1 }).join("\n\n")
  } else {
    let parts = results.map(fn(p) { "\"" + p.0 + "\": " + p.1 })
    "{\n" + parts.map(fn(s) { "  " + s }).join(",\n") + "\n}"
  }

  match config.output_file {
    Some(path) =>
      @fs.write_string_to_file(path, combined) catch {
        _ => {
          let err = if use_color {
            "\u001b[31;1mError:\u001b[0m Failed to write to file: " + path
          } else {
            "Error: Failed to write to file: " + path
          }
          println(err)
          @sys.exit(1)
        }
      }
    None => println(combined)
  }
}
