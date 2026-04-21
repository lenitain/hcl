///|
/// HCL Built-in Functions
/// Standard library of functions available during expression evaluation

///|
/// Get all built-in functions
pub fn builtin_functions() -> Map[
  String,
  (Array[HCLValue]) -> HCLResult[HCLValue],
] {
  let funcs = {}

  // Numeric functions
  funcs["abs"] = fn_abs
  funcs["ceil"] = fn_ceil
  funcs["floor"] = fn_floor
  funcs["log"] = fn_log
  funcs["max"] = fn_max
  funcs["min"] = fn_min
  funcs["parseint"] = fn_parseint
  funcs["pow"] = fn_pow
  funcs["signum"] = fn_signum

  // Collection functions
  funcs["length"] = fn_length
  funcs["keys"] = fn_keys
  funcs["values"] = fn_values
  funcs["contains"] = fn_contains
  funcs["flatten"] = fn_flatten
  funcs["merge"] = fn_merge
  funcs["reverse"] = fn_reverse
  funcs["distinct"] = fn_distinct
  funcs["sort"] = fn_sort
  funcs["slice"] = fn_slice
  funcs["element"] = fn_element

  // String functions
  funcs["chomp"] = fn_chomp
  funcs["indent"] = fn_indent
  funcs["join"] = fn_join
  funcs["lower"] = fn_lower
  funcs["upper"] = fn_upper
  funcs["replace"] = fn_replace
  funcs["split"] = fn_split
  funcs["strrev"] = fn_strrev
  funcs["substr"] = fn_substr
  funcs["trim"] = fn_trim
  funcs["trimprefix"] = fn_trimprefix
  funcs["trimsuffix"] = fn_trimsuffix
  funcs["trimspace"] = fn_trimspace
  funcs["format"] = fn_format
  funcs["formatlist"] = fn_formatlist

  // Type conversion functions
  funcs["tobool"] = fn_tobool
  funcs["tonumber"] = fn_tonumber
  funcs["tolist"] = fn_tolist
  funcs["tomap"] = fn_tomap
  funcs["toset"] = fn_toset
  funcs["tostring"] = fn_tostring

  funcs
}

///|
/// Convert HCLValue to Double for numeric operations
fn to_double(val : HCLValue) -> HCLResult[Double] {
  match val {
    Number(n, _) => Ok(n.as_float())
    _ => Err(HCLError::type_error("Expected number"))
  }
}

///|
/// Check argument count
fn check_args(
  args : Array[HCLValue],
  expected : Int,
  name : String,
) -> HCLResult[Unit] {
  if args.length() != expected {
    Err(
      HCLError::invalid_value(
        name +
        "() expects " +
        expected.to_string() +
        " argument(s), got " +
        args.length().to_string(),
      ),
    )
  } else {
    Ok(())
  }
}

///|
/// Check minimum argument count
fn check_min_args(
  args : Array[HCLValue],
  min : Int,
  name : String,
) -> HCLResult[Unit] {
  if args.length() < min {
    Err(
      HCLError::invalid_value(
        name +
        "() expects at least " +
        min.to_string() +
        " argument(s), got " +
        args.length().to_string(),
      ),
    )
  } else {
    Ok(())
  }
}

///|
/// Get char at index as String
fn char_at(s : String, idx : Int) -> String {
  s.code_unit_at(idx).to_int().unsafe_to_char().to_string()
}

///|
/// Parse integer from string with base (like parser.mbt)
fn parse_int_with_base(s : String, base : Int) -> HCLResult[Int] {
  let mut result = 0
  let mut negative = false
  let mut started = false

  for c in s {
    if !started && c == '-' {
      negative = true
    } else if c == '_' {
      // skip underscores
    } else {
      started = true
      let digit = if c >= '0' && c <= '9' {
        c.to_int() - '0'.to_int()
      } else if c >= 'a' && c <= 'f' {
        c.to_int() - 'a'.to_int() + 10
      } else if c >= 'A' && c <= 'F' {
        c.to_int() - 'A'.to_int() + 10
      } else {
        return Err(HCLError::invalid_value("Invalid digit"))
      }
      if digit >= base || digit < 0 {
        return Err(
          HCLError::invalid_value(
            "Digit out of range for base " + base.to_string(),
          ),
        )
      }
      result = result * base + digit
    }
  }

  if !started {
    return Err(HCLError::invalid_value("Empty number string"))
  }

  if negative {
    Ok(-result)
  } else {
    Ok(result)
  }
}

///|
/// Parse double from string
fn parse_double(s : String) -> HCLResult[Double] {
  let mut result = 0.0
  let mut decimal_place = 1.0
  let mut in_decimal = false
  let mut negative = false
  let mut started = false

  for c in s {
    if !started && c == '-' {
      negative = true
    } else if c == '.' {
      in_decimal = true
      started = true
    } else if c == '_' {
      // skip underscores
    } else if c >= '0' && c <= '9' {
      started = true
      if in_decimal {
        decimal_place = decimal_place * 10.0
        result = result +
          (c.to_int() - '0'.to_int()).to_double() / decimal_place
      } else {
        result = result * 10.0 + (c.to_int() - '0'.to_int()).to_double()
      }
    } else {
      return Err(HCLError::invalid_value("Invalid character in number"))
    }
  }

  if !started {
    return Err(HCLError::invalid_value("Empty number string"))
  }

  if negative {
    Ok(-result)
  } else {
    Ok(result)
  }
}

///| =========================================================================
/// Numeric Functions

///| =========================================================================

///|
/// abs(num) - Returns absolute value
fn fn_abs(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "abs") is Ok(_)
  match args[0] {
    Number(n, _) => {
      let f = n.as_float()
      Ok(Number(Number::from_finite_f64(f.abs()), Decor::empty()))
    }
    _ => Err(HCLError::type_error("abs() requires a number"))
  }
}

///|
/// ceil(num) - Returns smallest integer >= num
fn fn_ceil(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "ceil") is Ok(_)
  match to_double(args[0]) {
    Ok(f) => Ok(Number(Number::from_int(f.ceil().to_int()), Decor::empty()))
    Err(e) => Err(e)
  }
}

///|
/// floor(num) - Returns largest integer <= num
fn fn_floor(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "floor") is Ok(_)
  match to_double(args[0]) {
    Ok(f) => Ok(Number(Number::from_int(f.floor().to_int()), Decor::empty()))
    Err(e) => Err(e)
  }
}

///|
/// log(num, base) - Returns log of num with given base
fn fn_log(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "log") is Ok(_)
  match (to_double(args[0]), to_double(args[1])) {
    (Ok(num), Ok(base)) =>
      if base <= 0.0 || base == 1.0 {
        Err(HCLError::invalid_value("log() base must be positive and not 1"))
      } else if num <= 0.0 {
        Err(HCLError::invalid_value("log() number must be positive"))
      } else {
        // log_base(num) = ln(num) / ln(base)
        let result = @math.ln(num) / @math.ln(base)
        Ok(Number(Number::from_finite_f64(result), Decor::empty()))
      }
    (Err(e), _) => Err(e)
    (_, Err(e)) => Err(e)
  }
}

///|
/// max(num1, num2, ...) - Returns largest number
fn fn_max(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_min_args(args, 1, "max") is Ok(_)
  let mut best = args[0]
  for i in 1..<args.length() {
    match (to_double(best), to_double(args[i])) {
      (Ok(b), Ok(v)) => if v > b { best = args[i] }
      (Err(e), _) => return Err(e)
      (_, Err(e)) => return Err(e)
    }
  }
  Ok(best)
}

///|
/// min(num1, num2, ...) - Returns smallest number
fn fn_min(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_min_args(args, 1, "min") is Ok(_)
  let mut best = args[0]
  for i in 1..<args.length() {
    match (to_double(best), to_double(args[i])) {
      (Ok(b), Ok(v)) => if v < b { best = args[i] }
      (Err(e), _) => return Err(e)
      (_, Err(e)) => return Err(e)
    }
  }
  Ok(best)
}

///|
/// parseint(str, base) - Parses string as integer with given base
fn fn_parseint(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "parseint") is Ok(_)
  match (args[0], args[1]) {
    (String(s, _), Number(n, _)) =>
      match n.as_int() {
        Some(base) =>
          match parse_int_with_base(s, base) {
            Ok(i) => Ok(Number(Number::from_int(i), Decor::empty()))
            Err(e) => Err(e)
          }
        None => Err(HCLError::type_error("parseint() base must be integer"))
      }
    _ => Err(HCLError::type_error("parseint() expects (string, number)"))
  }
}

///|
/// pow(num, power) - Returns num raised to power
fn fn_pow(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "pow") is Ok(_)
  match (to_double(args[0]), to_double(args[1])) {
    (Ok(base), Ok(exp)) =>
      Ok(Number(Number::from_finite_f64(@math.pow(base, exp)), Decor::empty()))
    (Err(e), _) => Err(e)
    (_, Err(e)) => Err(e)
  }
}

///|
/// signum(num) - Returns -1, 0, or 1
fn fn_signum(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "signum") is Ok(_)
  match args[0] {
    Number(n, _) => {
      let f = n.as_float()
      if f < 0.0 {
        Ok(Number(Number::from_int(-1), Decor::empty()))
      } else if f > 0.0 {
        Ok(Number(Number::from_int(1), Decor::empty()))
      } else {
        Ok(Number(Number::from_int(0), Decor::empty()))
      }
    }
    _ => Err(HCLError::type_error("signum() requires a number"))
  }
}

///| =========================================================================
/// Collection Functions

///| =========================================================================

///|
/// length(collection) - Returns length of list, map, or string
fn fn_length(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "length") is Ok(_)
  match args[0] {
    Array(a, _) => Ok(Number(Number::from_int(a.length()), Decor::empty()))
    Object(o, _) => Ok(Number(Number::from_int(o.length()), Decor::empty()))
    String(s, _) => Ok(Number(Number::from_int(s.length()), Decor::empty()))
    _ => Err(HCLError::type_error("length() requires array, object, or string"))
  }
}

///|
/// keys(map) - Returns list of keys from map
fn fn_keys(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "keys") is Ok(_)
  match args[0] {
    Object(o, _) => {
      let result = []
      for k, _ in o {
        result.push(String(k, Decor::empty()))
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("keys() requires an object"))
  }
}

///|
/// values(map) - Returns list of values from map
fn fn_values(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "values") is Ok(_)
  match args[0] {
    Object(o, _) => {
      let result = []
      for _, v in o {
        result.push(v)
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("values() requires an object"))
  }
}

///|
/// contains(list, element) - Returns true if list contains element
fn fn_contains(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "contains") is Ok(_)
  match args[0] {
    Array(arr, _) => {
      for item in arr {
        if item == args[1] {
          return Ok(Bool(true, Decor::empty()))
        }
      }
      Ok(Bool(false, Decor::empty()))
    }
    _ => Err(HCLError::type_error("contains() requires an array"))
  }
}

///|
/// flatten(list) - Flattens nested list
fn fn_flatten(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "flatten") is Ok(_)
  match args[0] {
    Array(arr, _) => {
      let result = []
      flatten_recursive(arr, result)
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("flatten() requires an array"))
  }
}

///|
fn flatten_recursive(arr : Array[HCLValue], result : Array[HCLValue]) -> Unit {
  for item in arr {
    match item {
      Array(inner, _) => flatten_recursive(inner, result)
      _ => result.push(item)
    }
  }
}

///|
/// merge(map1, map2, ...) - Merges multiple maps
fn fn_merge(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_min_args(args, 1, "merge") is Ok(_)
  let result = {}
  for arg in args {
    match arg {
      Object(o, _) =>
        for k, v in o {
          result[k] = v
        }
      _ => return Err(HCLError::type_error("merge() requires objects"))
    }
  }
  Ok(Object(result, Decor::empty()))
}

///|
/// reverse(list) - Reverses a list
fn fn_reverse(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "reverse") is Ok(_)
  match args[0] {
    Array(arr, _) => {
      let result = []
      let mut i = arr.length() - 1
      while i >= 0 {
        result.push(arr[i])
        i = i - 1
      }
      Ok(Array(result, Decor::empty()))
    }
    String(s, _) => {
      let mut result = ""
      let mut i = s.length() - 1
      while i >= 0 {
        result = result + char_at(s, i)
        i = i - 1
      }
      Ok(String(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("reverse() requires an array or string"))
  }
}

///|
/// distinct(list) - Returns list with duplicates removed
fn fn_distinct(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "distinct") is Ok(_)
  match args[0] {
    Array(arr, _) => {
      let result = []
      let seen = Set::new()
      for item in arr {
        let key = item.to_json_string()
        if !seen.contains(key) {
          seen.add(key)
          result.push(item)
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("distinct() requires an array"))
  }
}

///|
/// sort(list) - Sorts a list
fn fn_sort(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "sort") is Ok(_)
  match args[0] {
    Array(arr, _) => {
      let result = arr.copy()
      result.sort_by(fn(a, b) {
        match (a, b) {
          (Number(a, _), Number(b, _)) => a.compare(b)
          (String(a, _), String(b, _)) => a.compare(b)
          _ => 0
        }
      })
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("sort() requires an array"))
  }
}

///|
/// slice(list, from, to) - Returns slice of list
fn fn_slice(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 3, "slice") is Ok(_)
  match (args[0], args[1], args[2]) {
    (Array(arr, _), Number(from_n, _), Number(to_n, _)) =>
      match (from_n.as_int(), to_n.as_int()) {
        (Some(from), Some(to)) => {
          if from < 0 || to > arr.length() || from > to {
            return Err(HCLError::invalid_value("slice() indices out of bounds"))
          }
          let result = []
          for i in from..<to {
            result.push(arr[i])
          }
          Ok(Array(result, Decor::empty()))
        }
        _ => Err(HCLError::type_error("slice() indices must be integers"))
      }
    _ => Err(HCLError::type_error("slice() requires (array, int, int)"))
  }
}

///|
/// element(list, index) - Returns element at index (wraps around)
fn fn_element(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "element") is Ok(_)
  match (args[0], args[1]) {
    (Array(arr, _), Number(idx_n, _)) =>
      match idx_n.as_int() {
        Some(idx) => {
          if arr.length() == 0 {
            return Err(
              HCLError::invalid_value("element() called on empty list"),
            )
          }
          let wrapped = (idx % arr.length() + arr.length()) % arr.length()
          Ok(arr[wrapped])
        }
        None => Err(HCLError::type_error("element() index must be integer"))
      }
    _ => Err(HCLError::type_error("element() requires (array, int)"))
  }
}

///| =========================================================================
/// String Functions

///| =========================================================================

///|
/// chomp(str) - Removes trailing newline
fn fn_chomp(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "chomp") is Ok(_)
  match args[0] {
    String(s, _) => {
      let len = s.length()
      let result = if len >= 2 &&
        char_at(s, len - 2) == "\r" &&
        char_at(s, len - 1) == "\n" {
        substring(s, 0, len - 2)
      } else if len >= 1 && char_at(s, len - 1) == "\n" {
        substring(s, 0, len - 1)
      } else if len >= 1 && char_at(s, len - 1) == "\r" {
        substring(s, 0, len - 1)
      } else {
        s
      }
      Ok(String(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("chomp() requires a string"))
  }
}

///|
/// indent(spaces, str) - Indents each line
fn fn_indent(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "indent") is Ok(_)
  match (args[0], args[1]) {
    (Number(spaces_n, _), String(s, _)) =>
      match spaces_n.as_int() {
        Some(spaces) => {
          let pad = " ".repeat(spaces)
          let lines = s.split("\n")
          let result = []
          for line in lines {
            result.push(pad + line.to_string())
          }
          Ok(String(result.join("\n"), Decor::empty()))
        }
        None => Err(HCLError::type_error("indent() spaces must be integer"))
      }
    _ => Err(HCLError::type_error("indent() requires (int, string)"))
  }
}

///|
/// join(separator, list) - Joins list elements with separator
fn fn_join(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "join") is Ok(_)
  match (args[0], args[1]) {
    (String(sep, _), Array(arr, _)) => {
      let parts = []
      for item in arr {
        match item {
          String(s, _) => parts.push(s)
          _ =>
            return Err(HCLError::type_error("join() requires string elements"))
        }
      }
      Ok(String(parts.join(sep), Decor::empty()))
    }
    _ => Err(HCLError::type_error("join() requires (string, array)"))
  }
}

///|
/// lower(str) - Converts to lowercase
fn fn_lower(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "lower") is Ok(_)
  match args[0] {
    String(s, _) => Ok(String(s.to_lower(), Decor::empty()))
    _ => Err(HCLError::type_error("lower() requires a string"))
  }
}

///|
/// upper(str) - Converts to uppercase
fn fn_upper(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "upper") is Ok(_)
  match args[0] {
    String(s, _) => Ok(String(s.to_upper(), Decor::empty()))
    _ => Err(HCLError::type_error("upper() requires a string"))
  }
}

///|
/// replace(str, pattern, replacement) - Replaces all occurrences
fn fn_replace(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 3, "replace") is Ok(_)
  match (args[0], args[1], args[2]) {
    (String(s, _), String(pattern, _), String(replacement, _)) =>
      Ok(String(s.replace(old=pattern, new=replacement), Decor::empty()))
    _ =>
      Err(HCLError::type_error("replace() requires (string, string, string)"))
  }
}

///|
/// split(separator, str) - Splits string by separator
fn fn_split(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "split") is Ok(_)
  match (args[0], args[1]) {
    (String(sep, _), String(s, _)) => {
      let parts = s.split(sep)
      let result = []
      for part in parts {
        result.push(String(part.to_string(), Decor::empty()))
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("split() requires (string, string)"))
  }
}

///|
/// strrev(str) - Reverses a string
fn fn_strrev(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "strrev") is Ok(_)
  match args[0] {
    String(s, _) => {
      let mut result = ""
      let mut i = s.length() - 1
      while i >= 0 {
        result = result + char_at(s, i)
        i = i - 1
      }
      Ok(String(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("strrev() requires a string"))
  }
}

///|
/// substr(str, offset, length) - Returns substring
fn fn_substr(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 3, "substr") is Ok(_)
  match (args[0], args[1], args[2]) {
    (String(s, _), Number(offset_n, _), Number(length_n, _)) =>
      match (offset_n.as_int(), length_n.as_int()) {
        (Some(offset), Some(length)) => {
          if offset < 0 || offset > s.length() {
            return Err(HCLError::invalid_value("substr() offset out of bounds"))
          }
          let end = if offset + length > s.length() {
            s.length()
          } else {
            offset + length
          }
          Ok(String(substring(s, offset, end), Decor::empty()))
        }
        _ => Err(HCLError::type_error("substr() indices must be integers"))
      }
    _ => Err(HCLError::type_error("substr() requires (string, int, int)"))
  }
}

///|
/// trim(str, cutset) - Trims characters from both ends
fn fn_trim(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "trim") is Ok(_)
  match (args[0], args[1]) {
    (String(s, _), String(cutset, _)) => {
      let mut start = 0
      let mut end = s.length()
      while start < end && cutset.contains(char_at(s, start)) {
        start = start + 1
      }
      while end > start && cutset.contains(char_at(s, end - 1)) {
        end = end - 1
      }
      Ok(String(substring(s, start, end), Decor::empty()))
    }
    _ => Err(HCLError::type_error("trim() requires (string, string)"))
  }
}

///|
/// trimprefix(str, prefix) - Trims prefix
fn fn_trimprefix(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "trimprefix") is Ok(_)
  match (args[0], args[1]) {
    (String(s, _), String(prefix, _)) =>
      if s.has_prefix(prefix) {
        Ok(String(substring(s, prefix.length(), s.length()), Decor::empty()))
      } else {
        Ok(String(s, Decor::empty()))
      }
    _ => Err(HCLError::type_error("trimprefix() requires (string, string)"))
  }
}

///|
/// trimsuffix(str, suffix) - Trims suffix
fn fn_trimsuffix(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "trimsuffix") is Ok(_)
  match (args[0], args[1]) {
    (String(s, _), String(suffix, _)) =>
      if s.has_suffix(suffix) {
        Ok(
          String(substring(s, 0, s.length() - suffix.length()), Decor::empty()),
        )
      } else {
        Ok(String(s, Decor::empty()))
      }
    _ => Err(HCLError::type_error("trimsuffix() requires (string, string)"))
  }
}

///|
/// trimspace(str) - Trims whitespace
fn fn_trimspace(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "trimspace") is Ok(_)
  match args[0] {
    String(s, _) => Ok(String(s.trim().to_string(), Decor::empty()))
    _ => Err(HCLError::type_error("trimspace() requires a string"))
  }
}

///|
/// format(pattern, args...) - Formats string with arguments
fn fn_format(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_min_args(args, 1, "format") is Ok(_)
  match args[0] {
    String(pattern, _) => {
      let mut result = ""
      let mut i = 0
      let mut arg_idx = 1
      while i < pattern.length() {
        let c = char_at(pattern, i)
        if c == "%" && i + 1 < pattern.length() {
          let next = char_at(pattern, i + 1)
          if next == "%" {
            result = result + "%"
            i = i + 2
          } else if next == "s" || next == "d" || next == "f" || next == "v" {
            if arg_idx >= args.length() {
              return Err(
                HCLError::invalid_value("format() not enough arguments"),
              )
            }
            let formatted = match args[arg_idx] {
              String(s, _) => s
              Number(n, _) => n.to_string()
              Bool(b, _) => if b { "true" } else { "false" }
              Null(_) => "null"
              _ => args[arg_idx].to_json_string()
            }
            result = result + formatted
            arg_idx = arg_idx + 1
            i = i + 2
          } else {
            result = result + c
            i = i + 1
          }
        } else {
          result = result + c
          i = i + 1
        }
      }
      Ok(String(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("format() first argument must be string"))
  }
}

///|
/// formatlist(pattern, list) - Formats each element of list
fn fn_formatlist(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 2, "formatlist") is Ok(_)
  match (args[0], args[1]) {
    (String(pattern, _), Array(arr, _)) => {
      let result = []
      for item in arr {
        let formatted = fn_format([String(pattern, Decor::empty()), item])
        match formatted {
          Ok(v) => result.push(v)
          Err(e) => return Err(e)
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("formatlist() requires (string, array)"))
  }
}

///| =========================================================================
/// Type Conversion Functions

///| =========================================================================

///|
/// tobool(val) - Converts to boolean
fn fn_tobool(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "tobool") is Ok(_)
  match args[0] {
    Bool(b, _) => Ok(Bool(b, Decor::empty()))
    String(s, _) => {
      let lower = s.to_lower()
      if lower == "true" {
        Ok(Bool(true, Decor::empty()))
      } else if lower == "false" {
        Ok(Bool(false, Decor::empty()))
      } else {
        Err(HCLError::invalid_value("Cannot convert '" + s + "' to bool"))
      }
    }
    Number(n, _) => {
      let f = n.as_float()
      Ok(Bool(f != 0.0, Decor::empty()))
    }
    _ => Err(HCLError::type_error("tobool() cannot convert this type"))
  }
}

///|
/// tonumber(val) - Converts to number
fn fn_tonumber(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "tonumber") is Ok(_)
  match args[0] {
    Number(_, _) => Ok(args[0])
    String(s, _) => {
      // Check if it looks like a float
      let mut is_float = false
      for c in s {
        if c == '.' || c == 'e' || c == 'E' {
          is_float = true
          break
        }
      }
      if is_float {
        match parse_double(s) {
          Ok(f) => Ok(Number(Number::from_finite_f64(f), Decor::empty()))
          Err(e) => Err(e)
        }
      } else {
        match parse_int_with_base(s, 10) {
          Ok(i) => Ok(Number(Number::from_int(i), Decor::empty()))
          Err(e) => Err(e)
        }
      }
    }
    Bool(b, _) =>
      Ok(Number(Number::from_int(if b { 1 } else { 0 }), Decor::empty()))
    _ => Err(HCLError::type_error("tonumber() cannot convert this type"))
  }
}

///|
/// tolist(val) - Converts to list
fn fn_tolist(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "tolist") is Ok(_)
  match args[0] {
    Array(a, _) => Ok(Array(a, Decor::empty()))
    _ => Ok(Array([args[0]], Decor::empty()))
  }
}

///|
/// tomap(val) - Converts to map
fn fn_tomap(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "tomap") is Ok(_)
  match args[0] {
    Object(o, _) => Ok(Object(o, Decor::empty()))
    _ => Err(HCLError::type_error("tomap() requires an object"))
  }
}

///|
/// toset(val) - Converts to set (as distinct list)
fn fn_toset(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "toset") is Ok(_)
  match args[0] {
    Array(_, _) => fn_distinct(args)
    _ => Ok(Array([args[0]], Decor::empty()))
  }
}

///|
/// tostring(val) - Converts to string
fn fn_tostring(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  guard check_args(args, 1, "tostring") is Ok(_)
  match args[0] {
    String(s, _) => Ok(String(s, Decor::empty()))
    Number(n, _) => Ok(String(n.to_string(), Decor::empty()))
    Bool(b, _) => Ok(String(if b { "true" } else { "false" }, Decor::empty()))
    Null(_) => Ok(String("null", Decor::empty()))
    _ => Ok(String(args[0].to_json_string(), Decor::empty()))
  }
}
