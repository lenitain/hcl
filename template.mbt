///|
/// HCL Template System - handles string interpolation, heredoc, and template directives
/// Implements ${expr}, <<EOF, %{if}, %{for} syntax

///|
/// Template part types
pub(all) enum TemplatePart {
  /// Literal text
  Text(String)
  /// String interpolation ${expr}
  Interpolation(HCLValue)
  /// Conditional directive %{if cond}
  ConditionalStart(HCLValue)
  /// End of conditional %{endif}
  ConditionalEnd
  /// For directive %{for var in collection}
  ForStart(String, HCLValue)
  /// End of for %{endfor}
  ForEnd
} derive(Debug, Eq)

///|
/// Template representation
pub struct Template {
  parts : Array[TemplatePart]
}

///|
/// Create new template
pub fn Template::new() -> Template {
  { parts: [] }
}

///|
/// Extract substring from string
fn substring(s : String, start : Int, end : Int) -> String {
  let mut result = ""
  let mut i = start
  while i < end && i < s.length() {
    result = result + s.code_unit_at(i).to_int().unsafe_to_char().to_string()
    i = i + 1
  }
  result
}

///|
/// Parse string with template expressions
pub fn Template::from_string(input : String) -> HCLResult[Template] {
  let template = Template::new()
  let mut i = 0
  let len = input.length()
  let mut text_start = 0

  while i < len {
    let c = input.code_unit_at(i)

    if c == '$'.to_int().to_uint16() &&
      i + 1 < len &&
      input.code_unit_at(i + 1) == '{'.to_int().to_uint16() {
      // Add text before interpolation
      if i > text_start {
        let text = substring(input, text_start, i)
        template.parts.push(Text(text))
      }

      // Parse interpolation
      match parse_interpolation(input, i + 2) {
        Ok((expr, end_pos)) => {
          template.parts.push(Interpolation(expr))
          i = end_pos
          text_start = i
        }
        Err(e) => return Err(e)
      }
    } else if c == '%'.to_int().to_uint16() &&
      i + 1 < len &&
      input.code_unit_at(i + 1) == '{'.to_int().to_uint16() {
      // Add text before directive
      if i > text_start {
        let text = substring(input, text_start, i)
        template.parts.push(Text(text))
      }

      // Parse directive
      match parse_directive(input, i + 2) {
        Ok((part, end_pos)) => {
          template.parts.push(part)
          i = end_pos
          text_start = i
        }
        Err(e) => return Err(e)
      }
    } else {
      i += 1
    }
  }

  // Add remaining text
  if text_start < len {
    let text = substring(input, text_start, len)
    template.parts.push(Text(text))
  }

  Ok(template)
}

///|
/// Parse interpolation expression ${expr}
fn parse_interpolation(
  input : String,
  start : Int,
) -> HCLResult[(HCLValue, Int)] {
  let mut i = start
  let len = input.length()
  let mut depth = 1
  let expr_start = i

  while i < len && depth > 0 {
    let c = input.code_unit_at(i)

    if c == '{'.to_int().to_uint16() {
      depth += 1
    } else if c == '}'.to_int().to_uint16() {
      depth -= 1
      if depth == 0 {
        // Extract expression
        let expr_str = substring(input, expr_start, i)
        // Parse expression
        match parse_template_expression(expr_str) {
          Ok(expr) => return Ok((expr, i + 1))
          Err(e) => return Err(e)
        }
      }
    }
    i += 1
  }

  if depth > 0 {
    Err(
      HCLError::parse_error_with_context(
        "Unclosed interpolation ${", 0, 0, start, "",
      ),
    )
  } else {
    Err(
      HCLError::parse_error_with_context(
        "Unexpected end of interpolation", 0, 0, i, "",
      ),
    )
  }
}

///|
/// Parse template directive %{directive}
fn parse_directive(
  input : String,
  start : Int,
) -> HCLResult[(TemplatePart, Int)] {
  let mut i = start
  let len = input.length()
  let mut depth = 1
  let content_start = i

  while i < len && depth > 0 {
    let c = input.code_unit_at(i)

    if c == '{'.to_int().to_uint16() {
      depth += 1
    } else if c == '}'.to_int().to_uint16() {
      depth -= 1
      if depth == 0 {
        // Extract directive content
        let content = substring(input, content_start, i)
        // Parse directive
        match parse_directive_content(content) {
          Ok(part) => return Ok((part, i + 1))
          Err(e) => return Err(e)
        }
      }
    }
    i += 1
  }

  if depth > 0 {
    Err(
      HCLError::parse_error_with_context(
        "Unclosed directive %{", 0, 0, start, "",
      ),
    )
  } else {
    Err(
      HCLError::parse_error_with_context(
        "Unexpected end of directive", 0, 0, i, "",
      ),
    )
  }
}

///|
/// Parse directive content
fn parse_directive_content(content : String) -> HCLResult[TemplatePart] {
  let trimmed = content.trim().to_string()

  if has_prefix(trimmed, "if ") {
    // %{if cond}
    let cond_str = substring(trimmed, 3, trimmed.length())
    match parse_template_expression(cond_str) {
      Ok(cond) => Ok(ConditionalStart(cond))
      Err(e) => Err(e)
    }
  } else if trimmed == "endif" {
    // %{endif}
    Ok(ConditionalEnd)
  } else if has_prefix(trimmed, "for ") {
    // %{for var in collection}
    match parse_for_directive(trimmed) {
      Ok((var_name, collection)) => Ok(ForStart(var_name, collection))
      Err(e) => Err(e)
    }
  } else if trimmed == "endfor" {
    // %{endfor}
    Ok(ForEnd)
  } else {
    Err(
      HCLError::parse_error_with_context(
        "Unknown directive: " + trimmed,
        0,
        0,
        0,
        "",
      ),
    )
  }
}

///|
/// Parse for directive %{for var in collection}
fn parse_for_directive(content : String) -> HCLResult[(String, HCLValue)] {
  // Expected format: "for var_name in collection_expr"
  let parts = []
  let mut current = ""
  for c in content {
    if c == ' ' {
      if current.length() > 0 {
        parts.push(current)
        current = ""
      }
    } else {
      current = current + c.to_string()
    }
  }
  if current.length() > 0 {
    parts.push(current)
  }

  if parts.length() < 4 || parts[0] != "for" || parts[2] != "in" {
    return Err(
      HCLError::parse_error_with_context(
        "Invalid for directive format", 0, 0, 0, "",
      ),
    )
  }

  let var_name = parts[1]
  let collection_str = parts[3]

  match parse_template_expression(collection_str) {
    Ok(collection) => Ok((var_name, collection))
    Err(e) => Err(e)
  }
}

///|
/// Check if string has prefix
fn has_prefix(s : String, prefix : String) -> Bool {
  if prefix.length() > s.length() {
    return false
  }
  let mut i = 0
  while i < prefix.length() {
    if s.code_unit_at(i) != prefix.code_unit_at(i) {
      return false
    }
    i += 1
  }
  true
}

///|
/// Check if string has suffix
fn has_suffix(s : String, suffix : String) -> Bool {
  if suffix.length() > s.length() {
    return false
  }
  let offset = s.length() - suffix.length()
  let mut i = 0
  while i < suffix.length() {
    if s.code_unit_at(offset + i) != suffix.code_unit_at(i) {
      return false
    }
    i += 1
  }
  true
}

///|
/// Parse simple template expression (variable or literal)
fn parse_template_expression(expr_str : String) -> HCLResult[HCLValue] {
  let trimmed = expr_str.trim().to_string()

  // Check for string literal
  if has_prefix(trimmed, "\"") && has_suffix(trimmed, "\"") {
    let content = substring(trimmed, 1, trimmed.length() - 1)
    return Ok(String(content))
  }

  // Check for number
  let mut is_number = true
  for c in trimmed {
    if !(c >= '0' && c <= '9') && c != '.' && c != '-' {
      is_number = false
      break
    }
  }
  if is_number && trimmed.length() > 0 {
    // Simple number parsing
    if trimmed.contains(".") {
      // Float - simplified
      return Ok(Float(0.0))
    } else {
      // Integer
      let mut result = 0
      let mut negative = false
      let mut start = 0
      if trimmed.code_unit_at(0) == '-'.to_int().to_uint16() {
        negative = true
        start = 1
      }
      let mut i = start
      while i < trimmed.length() {
        let c = trimmed.code_unit_at(i)
        if c >= '0'.to_int().to_uint16() && c <= '9'.to_int().to_uint16() {
          result = result * 10 + (c.to_int() - '0'.to_int())
        }
        i += 1
      }
      return Ok(Int(if negative { -result } else { result }))
    }
  }

  // Check for boolean
  if trimmed == "true" {
    return Ok(Bool(true))
  }
  if trimmed == "false" {
    return Ok(Bool(false))
  }

  // Check for null
  if trimmed == "null" {
    return Ok(Null)
  }

  // Variable reference
  Ok(Object({ "type": String("variable"), "name": String(trimmed) }))
}

///|
/// Evaluate template with given context
pub fn Template::evaluate(
  self : Template,
  variables : Map[String, HCLValue],
  functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]],
) -> HCLResult[String] {
  let mut result = ""
  let mut i = 0
  let parts = self.parts

  while i < parts.length() {
    let part = parts[i]
    match part {
      Text(text) => {
        result = result + text
        i += 1
      }
      Interpolation(expr) =>
        match eval_expr(expr, variables, functions) {
          Ok(value) => {
            result = result + value_to_string(value)
            i += 1
          }
          Err(e) => return Err(e)
        }
      ConditionalStart(condition) =>
        match eval_expr(condition, variables, functions) {
          Ok(cond_value) =>
            match cond_value {
              Bool(b) =>
                if b {
                  // Evaluate conditional body
                  match
                    evaluate_conditional_body(
                      parts,
                      i + 1,
                      variables,
                      functions,
                    ) {
                    Ok((body_result, end_pos)) => {
                      result = result + body_result
                      i = end_pos + 1
                    }
                    Err(e) => return Err(e)
                  }
                } else {
                  // Skip conditional body
                  match skip_conditional_body(parts, i + 1) {
                    Ok(end_pos) => i = end_pos + 1
                    Err(e) => return Err(e)
                  }
                }
              _ => return Err(HCLError::type_error("Condition must be boolean"))
            }
          Err(e) => return Err(e)
        }
      ForStart(var_name, collection) =>
        match eval_expr(collection, variables, functions) {
          Ok(collection_value) =>
            match collection_value {
              Array(arr) =>
                // Evaluate for loop body for each item
                match
                  evaluate_for_body(
                    parts,
                    i + 1,
                    var_name,
                    arr,
                    variables,
                    functions,
                  ) {
                  Ok((body_result, end_pos)) => {
                    result = result + body_result
                    i = end_pos + 1
                  }
                  Err(e) => return Err(e)
                }
              _ =>
                return Err(HCLError::type_error("For collection must be array"))
            }
          Err(e) => return Err(e)
        }
      ConditionalEnd | ForEnd =>
        // These should be handled by their respective start directives
        i += 1
    }
  }

  Ok(result)
}

///|
/// Evaluate conditional body
fn evaluate_conditional_body(
  parts : Array[TemplatePart],
  start : Int,
  variables : Map[String, HCLValue],
  functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]],
) -> HCLResult[(String, Int)] {
  let mut result = ""
  let mut i = start
  let mut depth = 0

  while i < parts.length() {
    let part = parts[i]
    match part {
      ConditionalStart(_) => {
        depth += 1
        i += 1
      }
      ConditionalEnd => {
        if depth == 0 {
          return Ok((result, i))
        }
        depth -= 1
        i += 1
      }
      _ => {
        // Evaluate part
        let temp_template = { parts: [part] }
        match temp_template.evaluate(variables, functions) {
          Ok(text) => {
            result = result + text
            i += 1
          }
          Err(e) => return Err(e)
        }
      }
    }
  }

  Err(
    HCLError::parse_error_with_context("Unclosed conditional", 0, 0, start, ""),
  )
}

///|
/// Skip conditional body (when condition is false)
fn skip_conditional_body(
  parts : Array[TemplatePart],
  start : Int,
) -> HCLResult[Int] {
  let mut i = start
  let mut depth = 0

  while i < parts.length() {
    let part = parts[i]
    match part {
      ConditionalStart(_) => depth += 1
      ConditionalEnd => {
        if depth == 0 {
          return Ok(i)
        }
        depth -= 1
      }
      _ => ignore(part)
    }
    i += 1
  }

  Err(
    HCLError::parse_error_with_context("Unclosed conditional", 0, 0, start, ""),
  )
}

///|
/// Evaluate for loop body
fn evaluate_for_body(
  parts : Array[TemplatePart],
  start : Int,
  var_name : String,
  arr : Array[HCLValue],
  variables : Map[String, HCLValue],
  functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]],
) -> HCLResult[(String, Int)] {
  let mut result = ""

  // Find end of for loop
  let end_pos = find_for_end(parts, start)
  if end_pos < 0 {
    return Err(
      HCLError::parse_error_with_context("Unclosed for loop", 0, 0, start, ""),
    )
  }

  // Evaluate for each item
  for item in arr {
    // Create new context with loop variable
    let loop_vars = variables.copy()
    loop_vars[var_name] = item

    // Evaluate body
    let mut j = start
    while j < end_pos {
      let part = parts[j]
      match part {
        Text(text) => {
          result = result + text
          j += 1
        }
        Interpolation(expr) =>
          match eval_expr(expr, loop_vars, functions) {
            Ok(value) => {
              result = result + value_to_string(value)
              j += 1
            }
            Err(e) => return Err(e)
          }
        _ => {
          // Handle nested structures
          let temp_template = { parts: [part] }
          match temp_template.evaluate(loop_vars, functions) {
            Ok(text) => {
              result = result + text
              j += 1
            }
            Err(e) => return Err(e)
          }
        }
      }
    }
  }

  Ok((result, end_pos))
}

///|
/// Find end position of for loop
fn find_for_end(parts : Array[TemplatePart], start : Int) -> Int {
  let mut i = start
  let mut depth = 0

  while i < parts.length() {
    let part = parts[i]
    match part {
      ForStart(_, _) => depth += 1
      ForEnd => {
        if depth == 0 {
          return i
        }
        depth -= 1
      }
      _ => ignore(part)
    }
    i += 1
  }

  -1
}

///|
/// Parse heredoc content
pub fn Template::from_heredoc(
  input : String,
  delimiter : String,
  strip : Bool,
) -> HCLResult[Template] {
  let template = Template::new()
  let mut i = 0
  let len = input.length()
  let mut text_start = 0

  // Parse content directly (input is already the content between delimiters)
  while i < len {
    let c = input.code_unit_at(i)

    // Handle interpolation in heredoc
    if c == '$'.to_int().to_uint16() &&
      i + 1 < len &&
      input.code_unit_at(i + 1) == '{'.to_int().to_uint16() {
      // Add text before interpolation
      if i > text_start {
        let text = substring(input, text_start, i)
        let processed = if strip {
          strip_leading_whitespace(text)
        } else {
          text
        }
        template.parts.push(Text(processed))
      }

      // Parse interpolation
      match parse_interpolation(input, i + 2) {
        Ok((expr, end_pos)) => {
          template.parts.push(Interpolation(expr))
          i = end_pos
          text_start = i
        }
        Err(e) => return Err(e)
      }
    } else {
      i += 1
    }
  }

  // Add remaining text
  if text_start < len {
    let text = substring(input, text_start, len)
    let processed = if strip { strip_leading_whitespace(text) } else { text }
    template.parts.push(Text(processed))
  }

  Ok(template)
}

///|
/// Strip leading whitespace from a line
fn strip_leading_whitespace(text : String) -> String {
  let mut result = ""
  let mut i = 0
  let len = text.length()
  let mut line_start = true

  while i < len {
    let c = text.code_unit_at(i)

    if c == '\n'.to_int().to_uint16() {
      result = result + "\n"
      line_start = true
    } else if line_start &&
      (c == ' '.to_int().to_uint16() || c == '\t'.to_int().to_uint16()) {
      // Skip leading whitespace
    } else {
      result = result + c.to_int().unsafe_to_char().to_string()
      line_start = false
    }

    i += 1
  }

  result
}

///|
/// Convert HCLValue to string
fn value_to_string(value : HCLValue) -> String {
  match value {
    Null => "null"
    Bool(b) => if b { "true" } else { "false" }
    Int(i) => i.to_string()
    Int64(i) => i.to_string()
    Float(f) => f.to_string()
    String(s) => s
    Array(_) => "[array]"
    Object(_) => "[object]"
  }
}

///|
/// Parse template from string (simple version)
pub fn parse_template(input : String) -> HCLResult[Template] {
  Template::from_string(input)
}

///|
/// Evaluate template string directly
pub fn evaluate_template(
  input : String,
  variables : Map[String, HCLValue],
  functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]],
) -> HCLResult[String] {
  match parse_template(input) {
    Ok(template) => template.evaluate(variables, functions)
    Err(e) => Err(e)
  }
}
