///|
/// HCL Template System - handles string interpolation, heredoc, and template directives
/// Implements ${expr}, <<EOF, %{if}, %{for} syntax

///|
/// Template part types
pub(all) enum TemplatePart {
  /// Literal text
  Text(String)
  /// String interpolation ${expr}
  Interpolation(Expression)
  /// Conditional directive %{if cond}
  ConditionalStart(Expression)
  /// Else-if directive %{else if cond}
  ConditionalElseIf(Expression)
  /// Else directive %{else}
  ConditionalElse
  /// End of conditional %{endif}
  ConditionalEnd
  /// For directive %{for var in collection}
  ForStart(String, Expression)
  /// End of for %{endfor}
  ForEnd
  /// String interpolation with strip markers ${~ expr ~}
  InterpolationStrip(Expression, Bool, Bool)
  /// Conditional directive with strip markers %{~ if cond ~}
  ConditionalStartStrip(Expression, Bool, Bool)
  /// Else-if with strip markers %{~ else if cond ~}
  ConditionalElseIfStrip(Expression, Bool, Bool)
  /// Else with strip markers %{~ else ~}
  ConditionalElseStrip(Bool, Bool)
  /// Endif with strip markers %{~ endif ~}
  ConditionalEndStrip(Bool, Bool)
  /// For with strip markers %{~ for var in col ~}
  ForStartStrip(String, Expression, Bool, Bool)
  /// Endfor with strip markers %{~ endfor ~}
  ForEndStrip(Bool, Bool)
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
pub fn substring(s : String, start : Int, end : Int) -> String {
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
        Ok((expr, end_pos, strip_before, strip_after)) => {
          if strip_before || strip_after {
            template.parts.push(
              InterpolationStrip(expr, strip_before, strip_after),
            )
          } else {
            template.parts.push(Interpolation(expr))
          }
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
/// Parse interpolation expression ${expr} or ${~ expr ~}
fn parse_interpolation(
  input : String,
  start : Int,
) -> HCLResult[(Expression, Int, Bool, Bool)] {
  let len = input.length()
  let mut i = start
  let mut strip_before = false
  let mut strip_after = false

  // Check for strip marker after opening ${
  if i < len && input.code_unit_at(i) == '~'.to_int().to_uint16() {
    strip_before = true
    i += 1
  }

  let mut depth = 1
  let expr_start = i

  while i < len && depth > 0 {
    let c = input.code_unit_at(i)

    if c == '{'.to_int().to_uint16() {
      depth += 1
    } else if c == '}'.to_int().to_uint16() {
      depth -= 1
      if depth == 0 {
        // Check for strip marker before closing }
        let mut expr_end = i
        if expr_end > expr_start {
          let last_char = input.code_unit_at(expr_end - 1)
          if last_char == '~'.to_int().to_uint16() {
            strip_after = true
            expr_end -= 1
          }
        }
        // Extract expression
        let expr_str = substring(input, expr_start, expr_end)
        // Parse expression
        match parse_template_expression(expr_str) {
          Ok(expr) => return Ok((expr, i + 1, strip_before, strip_after))
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
/// Parse template directive %{directive} or %{~ directive ~}
fn parse_directive(
  input : String,
  start : Int,
) -> HCLResult[(TemplatePart, Int)] {
  let len = input.length()
  let mut i = start
  let mut strip_before = false
  let mut strip_after = false

  // Check for strip marker after opening %{
  if i < len && input.code_unit_at(i) == '~'.to_int().to_uint16() {
    strip_before = true
    i += 1
  }

  let mut depth = 1
  let content_start = i

  while i < len && depth > 0 {
    let c = input.code_unit_at(i)

    if c == '{'.to_int().to_uint16() {
      depth += 1
    } else if c == '}'.to_int().to_uint16() {
      depth -= 1
      if depth == 0 {
        // Check for strip marker before closing }
        let mut content_end = i
        if content_end > content_start {
          let last_char = input.code_unit_at(content_end - 1)
          if last_char == '~'.to_int().to_uint16() {
            strip_after = true
            content_end -= 1
          }
        }
        // Extract directive content
        let content = substring(input, content_start, content_end)
        // Parse directive with strip info
        match parse_directive_content(content, strip_before, strip_after) {
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
fn parse_directive_content(
  content : String,
  strip_before : Bool,
  strip_after : Bool,
) -> HCLResult[TemplatePart] {
  let trimmed = content.trim().to_string()

  if has_prefix(trimmed, "if ") {
    // %{if cond}
    let cond_str = substring(trimmed, 3, trimmed.length())
    match parse_template_expression(cond_str) {
      Ok(cond) =>
        if strip_before || strip_after {
          Ok(ConditionalStartStrip(cond, strip_before, strip_after))
        } else {
          Ok(ConditionalStart(cond))
        }
      Err(e) => Err(e)
    }
  } else if has_prefix(trimmed, "else if ") {
    // %{else if cond}
    let cond_str = substring(trimmed, 8, trimmed.length())
    match parse_template_expression(cond_str) {
      Ok(cond) =>
        if strip_before || strip_after {
          Ok(ConditionalElseIfStrip(cond, strip_before, strip_after))
        } else {
          Ok(ConditionalElseIf(cond))
        }
      Err(e) => Err(e)
    }
  } else if trimmed == "else" {
    // %{else}
    if strip_before || strip_after {
      Ok(ConditionalElseStrip(strip_before, strip_after))
    } else {
      Ok(ConditionalElse)
    }
  } else if trimmed == "endif" {
    // %{endif}
    if strip_before || strip_after {
      Ok(ConditionalEndStrip(strip_before, strip_after))
    } else {
      Ok(ConditionalEnd)
    }
  } else if has_prefix(trimmed, "for ") {
    // %{for var in collection}
    match parse_for_directive(trimmed) {
      Ok((var_name, collection)) =>
        if strip_before || strip_after {
          Ok(ForStartStrip(var_name, collection, strip_before, strip_after))
        } else {
          Ok(ForStart(var_name, collection))
        }
      Err(e) => Err(e)
    }
  } else if trimmed == "endfor" {
    // %{endfor}
    if strip_before || strip_after {
      Ok(ForEndStrip(strip_before, strip_after))
    } else {
      Ok(ForEnd)
    }
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
fn parse_for_directive(content : String) -> HCLResult[(String, Expression)] {
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
fn parse_template_expression(expr_str : String) -> HCLResult[Expression] {
  let trimmed = expr_str.trim().to_string()

  // Check for string literal
  if has_prefix(trimmed, "\"") && has_suffix(trimmed, "\"") {
    let content = substring(trimmed, 1, trimmed.length() - 1)
    return Ok(ExprString(content))
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
      return Ok(ExprFloat(0.0))
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
      return Ok(ExprInt(if negative { -result } else { result }))
    }
  }

  // Check for boolean
  if trimmed == "true" {
    return Ok(ExprBool(true))
  }
  if trimmed == "false" {
    return Ok(ExprBool(false))
  }

  // Check for null
  if trimmed == "null" {
    return Ok(ExprNull)
  }

  // Variable reference
  Ok(ExprVariable({ name: trimmed }))
}

///|
/// Trim trailing whitespace from string
fn trim_trailing_whitespace(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  let mut end = len
  while end > 0 {
    let c = s.code_unit_at(end - 1)
    if c == ' '.to_int().to_uint16() ||
      c == '\t'.to_int().to_uint16() ||
      c == '\n'.to_int().to_uint16() ||
      c == '\r'.to_int().to_uint16() {
      end = end - 1
    } else {
      break
    }
  }
  substring(s, 0, end)
}

///|
/// Trim leading whitespace from string
fn trim_leading_whitespace(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  let mut start = 0
  while start < len {
    let c = s.code_unit_at(start)
    if c == ' '.to_int().to_uint16() ||
      c == '\t'.to_int().to_uint16() ||
      c == '\n'.to_int().to_uint16() ||
      c == '\r'.to_int().to_uint16() {
      start = start + 1
    } else {
      break
    }
  }
  substring(s, start, len)
}

///|
/// Evaluate template with given context
pub fn Template::evaluate(
  self : Template,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[String] {
  let mut result = ""
  let mut i = 0
  let parts = self.parts
  let mut pending_strip_after = false

  while i < parts.length() {
    let part = parts[i]
    match part {
      Text(text) => {
        let t = if pending_strip_after {
          trim_leading_whitespace(text)
        } else {
          text
        }
        pending_strip_after = false
        result = result + t
        i += 1
      }
      Interpolation(expr) =>
        match eval_expr(expr, variables, functions) {
          Ok(value) => {
            pending_strip_after = false
            result = result + value_to_string(value)
            i += 1
          }
          Err(e) => return Err(e)
        }
      InterpolationStrip(expr, strip_before, strip_after) =>
        match eval_expr(expr, variables, functions) {
          Ok(value) => {
            if strip_before {
              result = trim_trailing_whitespace(result)
            }
            pending_strip_after = strip_after
            result = result + value_to_string(value)
            i += 1
          }
          Err(e) => return Err(e)
        }
      ConditionalStart(condition) =>
        match eval_expr(condition, variables, functions) {
          Ok(cond_value) =>
            match cond_value {
              Bool(b, _) =>
                match find_conditional_boundary(parts, i + 1) {
                  Ok((boundary, has_more)) =>
                    if b {
                      match
                        evaluate_body_range(
                          parts,
                          i + 1,
                          boundary,
                          variables,
                          functions,
                        ) {
                        Ok(body_result) => {
                          result = result + body_result
                          if has_more {
                            match skip_to_conditional_end(parts, boundary) {
                              Ok(end) => i = end + 1
                              Err(e) => return Err(e)
                            }
                          } else {
                            i = boundary + 1
                          }
                        }
                        Err(e) => return Err(e)
                      }
                    } else if has_more {
                      match
                        evaluate_else_chain(
                          parts, boundary, variables, functions,
                        ) {
                        Ok((chain_result, end_pos)) => {
                          result = result + chain_result
                          i = end_pos + 1
                        }
                        Err(e) => return Err(e)
                      }
                    } else {
                      i = boundary + 1
                    }
                  Err(e) => return Err(e)
                }
              _ => return Err(HCLError::type_error("Condition must be boolean"))
            }
          Err(e) => return Err(e)
        }
      ConditionalStartStrip(condition, strip_before, strip_after) =>
        match eval_expr(condition, variables, functions) {
          Ok(cond_value) =>
            match cond_value {
              Bool(b, _) => {
                if strip_before {
                  result = trim_trailing_whitespace(result)
                }
                pending_strip_after = strip_after
                match find_conditional_boundary(parts, i + 1) {
                  Ok((boundary, has_more)) =>
                    if b {
                      match
                        evaluate_body_range(
                          parts,
                          i + 1,
                          boundary,
                          variables,
                          functions,
                        ) {
                        Ok(body_result) => {
                          result = result + body_result
                          if has_more {
                            match skip_to_conditional_end(parts, boundary) {
                              Ok(end) => i = end + 1
                              Err(e) => return Err(e)
                            }
                          } else {
                            i = boundary + 1
                          }
                        }
                        Err(e) => return Err(e)
                      }
                    } else if has_more {
                      match
                        evaluate_else_chain(
                          parts, boundary, variables, functions,
                        ) {
                        Ok((chain_result, end_pos)) => {
                          result = result + chain_result
                          i = end_pos + 1
                        }
                        Err(e) => return Err(e)
                      }
                    } else {
                      i = boundary + 1
                    }
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
              Array(arr, _) =>
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
      ForStartStrip(var_name, collection, strip_before, strip_after) =>
        match eval_expr(collection, variables, functions) {
          Ok(collection_value) =>
            match collection_value {
              Array(arr, _) => {
                if strip_before {
                  result = trim_trailing_whitespace(result)
                }
                pending_strip_after = strip_after
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
              }
              _ =>
                return Err(HCLError::type_error("For collection must be array"))
            }
          Err(e) => return Err(e)
        }
      ConditionalEnd | ForEnd | ConditionalElse | ConditionalElseIf(_) =>
        // These should be handled by their respective start directives
        i += 1
      ConditionalEndStrip(_, _)
      | ForEndStrip(_, _)
      | ConditionalElseStrip(_, _)
      | ConditionalElseIfStrip(_, _, _) => i += 1
    }
  }

  Ok(result)
}

///|
/// Evaluate for loop body
fn evaluate_for_body(
  parts : Array[TemplatePart],
  start : Int,
  var_name : String,
  arr : Array[HCLValue],
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
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

    // Evaluate body using evaluate_body_range for proper nested conditional handling
    match evaluate_body_range(parts, start, end_pos, loop_vars, functions) {
      Ok(body_result) => result = result + body_result
      Err(e) => return Err(e)
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
      ForStart(_, _) | ForStartStrip(_, _, _, _) => depth += 1
      ForEnd | ForEndStrip(_, _) => {
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
/// Find first ConditionalElseIf, ConditionalElse, or ConditionalEnd at depth 0
fn find_conditional_boundary(
  parts : Array[TemplatePart],
  start : Int,
) -> HCLResult[(Int, Bool)] {
  let mut i = start
  let mut depth = 0
  while i < parts.length() {
    let part = parts[i]
    match part {
      ConditionalStart(_) | ConditionalStartStrip(_, _, _) => depth += 1
      ConditionalElseIf(_) | ConditionalElseIfStrip(_, _, _) =>
        if depth == 0 {
          return Ok((i, true))
        }
      ConditionalElse | ConditionalElseStrip(_, _) =>
        if depth == 0 {
          return Ok((i, true))
        }
      ConditionalEnd | ConditionalEndStrip(_, _) => {
        if depth == 0 {
          return Ok((i, false))
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
/// Find ConditionalEnd at depth 0
fn find_conditional_end(
  parts : Array[TemplatePart],
  start : Int,
) -> HCLResult[Int] {
  let mut i = start
  let mut depth = 0
  while i < parts.length() {
    let part = parts[i]
    match part {
      ConditionalStart(_) | ConditionalStartStrip(_, _, _) => depth += 1
      ConditionalEnd | ConditionalEndStrip(_, _) => {
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
/// Skip from a boundary (else-if/else) to the matching ConditionalEnd
fn skip_to_conditional_end(
  parts : Array[TemplatePart],
  boundary : Int,
) -> HCLResult[Int] {
  find_conditional_end(parts, boundary + 1)
}

///|
/// Evaluate an else-if/else chain starting at the given boundary position
fn evaluate_else_chain(
  parts : Array[TemplatePart],
  pos : Int,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[(String, Int)] {
  let part = parts[pos]
  match part {
    ConditionalElseIf(cond_expr) | ConditionalElseIfStrip(cond_expr, _, _) =>
      match eval_expr(cond_expr, variables, functions) {
        Ok(cond_value) =>
          match cond_value {
            Bool(b, _) =>
              match find_conditional_boundary(parts, pos + 1) {
                Ok((next_boundary, has_more)) =>
                  if b {
                    match
                      evaluate_body_range(
                        parts,
                        pos + 1,
                        next_boundary,
                        variables,
                        functions,
                      ) {
                      Ok(body_result) =>
                        if has_more {
                          match skip_to_conditional_end(parts, next_boundary) {
                            Ok(end) => Ok((body_result, end))
                            Err(e) => Err(e)
                          }
                        } else {
                          Ok((body_result, next_boundary))
                        }
                      Err(e) => Err(e)
                    }
                  } else if has_more {
                    evaluate_else_chain(
                      parts, next_boundary, variables, functions,
                    )
                  } else {
                    Ok(("", next_boundary))
                  }
                Err(e) => Err(e)
              }
            _ => Err(HCLError::type_error("Condition must be boolean"))
          }
        Err(e) => Err(e)
      }
    ConditionalElse | ConditionalElseStrip(_, _) =>
      match find_conditional_end(parts, pos + 1) {
        Ok(end) =>
          match evaluate_body_range(parts, pos + 1, end, variables, functions) {
            Ok(body_result) => Ok((body_result, end))
            Err(e) => Err(e)
          }
        Err(e) => Err(e)
      }
    _ => Ok(("", pos))
  }
}

///|
/// Evaluate a range of template parts, handling nested conditionals recursively
fn evaluate_body_range(
  parts : Array[TemplatePart],
  start : Int,
  end : Int,
  variables : Map[String, HCLValue],
  functions : Map[String, FuncDef],
) -> HCLResult[String] {
  let mut result = ""
  let mut i = start
  while i < end {
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
      ConditionalStart(condition) | ConditionalStartStrip(condition, _, _) =>
        match eval_expr(condition, variables, functions) {
          Ok(cond_value) =>
            match cond_value {
              Bool(b, _) =>
                match find_conditional_boundary(parts, i + 1) {
                  Ok((boundary, has_more)) =>
                    if b {
                      match
                        evaluate_body_range(
                          parts,
                          i + 1,
                          boundary,
                          variables,
                          functions,
                        ) {
                        Ok(body_result) => {
                          result = result + body_result
                          i = if has_more {
                            match skip_to_conditional_end(parts, boundary) {
                              Ok(e) => e + 1
                              Err(e) => return Err(e)
                            }
                          } else {
                            boundary + 1
                          }
                        }
                        Err(e) => return Err(e)
                      }
                    } else if has_more {
                      match
                        evaluate_else_chain(
                          parts, boundary, variables, functions,
                        ) {
                        Ok((chain_result, end_pos)) => {
                          result = result + chain_result
                          i = end_pos + 1
                        }
                        Err(e) => return Err(e)
                      }
                    } else {
                      i = boundary + 1
                    }
                  Err(e) => return Err(e)
                }
              _ => return Err(HCLError::type_error("Condition must be boolean"))
            }
          Err(e) => return Err(e)
        }
      _ => {
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
  Ok(result)
}

///|
/// Parse heredoc content
pub fn Template::from_heredoc(
  input : String,
  _delimiter : String,
  strip : Bool,
) -> HCLResult[Template] {
  let processed_input = if strip { strip_heredoc_indent(input) } else { input }

  let template = Template::new()
  let mut i = 0
  let len = processed_input.length()
  let mut text_start = 0

  // Parse content directly (input is already the content between delimiters)
  while i < len {
    let c = processed_input.code_unit_at(i)

    // Handle interpolation in heredoc
    if c == '$'.to_int().to_uint16() &&
      i + 1 < len &&
      processed_input.code_unit_at(i + 1) == '{'.to_int().to_uint16() {
      // Add text before interpolation
      if i > text_start {
        let text = substring(processed_input, text_start, i)
        template.parts.push(Text(text))
      }

      // Parse interpolation
      match parse_interpolation(processed_input, i + 2) {
        Ok((expr, end_pos, strip_before, strip_after)) => {
          if strip_before || strip_after {
            template.parts.push(
              InterpolationStrip(expr, strip_before, strip_after),
            )
          } else {
            template.parts.push(Interpolation(expr))
          }
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
    let text = substring(processed_input, text_start, len)
    template.parts.push(Text(text))
  }

  Ok(template)
}

///|
/// Compute minimum indentation across all lines and strip it
fn strip_heredoc_indent(text : String) -> String {
  let len = text.length()
  if len == 0 {
    return text
  }

  // Pass 1: Find minimum indentation across non-empty lines
  let mut min_indent = -1
  let mut line_indent = 0
  let mut line_has_content = false
  let mut at_line_start = true

  let mut i = 0
  while i < len {
    let c = text.code_unit_at(i)
    if c == '\n'.to_int().to_uint16() {
      if line_has_content {
        if min_indent < 0 || line_indent < min_indent {
          min_indent = line_indent
        }
      }
      line_indent = 0
      line_has_content = false
      at_line_start = true
    } else if at_line_start &&
      (c == ' '.to_int().to_uint16() || c == '\t'.to_int().to_uint16()) {
      line_indent += 1
    } else {
      at_line_start = false
      line_has_content = true
    }
    i += 1
  }
  // Handle last line (no trailing newline)
  if line_has_content {
    if min_indent < 0 || line_indent < min_indent {
      min_indent = line_indent
    }
  }

  if min_indent <= 0 {
    return text
  }

  // Pass 2: Strip min_indent characters from beginning of each line
  let mut result = ""
  let mut chars_stripped = 0
  let mut is_start_of_line = true

  i = 0
  while i < len {
    let c = text.code_unit_at(i)
    if c == '\n'.to_int().to_uint16() {
      result = result + "\n"
      is_start_of_line = true
      chars_stripped = 0
    } else if is_start_of_line &&
      chars_stripped < min_indent &&
      (c == ' '.to_int().to_uint16() || c == '\t'.to_int().to_uint16()) {
      chars_stripped += 1
    } else {
      is_start_of_line = false
      result = result + c.to_int().unsafe_to_char().to_string()
    }
    i += 1
  }

  result
}

///|
/// Convert HCLValue to string
fn value_to_string(value : HCLValue) -> String {
  match value {
    Null(_) => "null"
    Bool(b, _) => bool_to_string(b)
    Number(n, _) => number_to_string(n)
    String(s, _) => s
    Array(_, _) => "[array]"
    Object(_, _) => "[object]"
    Unknown(_) => "(unknown)"
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
  functions : Map[String, FuncDef],
) -> HCLResult[String] {
  match parse_template(input) {
    Ok(template) => template.evaluate(variables, functions)
    Err(e) => Err(e)
  }
}
