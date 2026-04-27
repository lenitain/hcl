///|
/// Parameter type hint for function argument validation
pub(all) enum ParamType {
  /// Accepts any type
  Any
  /// Boolean value
  ParamBool
  /// Numeric value
  ParamNumber
  /// String value
  ParamString
  /// Array with element type hint
  ParamArray(ParamType)
  /// Object with value type hint
  ParamObject(ParamType)
  /// Nullable version of inner type
  Nullable(ParamType)
  /// Union of multiple types
  OneOf(Array[ParamType])
} derive(Debug, Eq)

///|
/// Check if a value satisfies this parameter type
pub fn ParamType::is_satisfied_by(self : ParamType, value : HCLValue) -> Bool {
  match self {
    Any => true
    ParamBool => value.is_bool()
    ParamNumber => value.is_number()
    ParamString => value.is_string()
    ParamArray(elem) =>
      match value {
        Array(arr, _) => arr.all(fn(v) { elem.is_satisfied_by(v) })
        _ => false
      }
    ParamObject(val_type) =>
      match value {
        Object(o, _) => {
          for _, v in o {
            if not(val_type.is_satisfied_by(v)) {
              return false
            }
          }
          true
        }
        _ => false
      }
    Nullable(inner) =>
      match value {
        Null(_) => true
        _ => inner.is_satisfied_by(value)
      }
    OneOf(types) => types.any(fn(t) { t.is_satisfied_by(value) })
  }
}

///|
/// Get display name for ParamType (for error messages)
pub fn ParamType::display_name(self : ParamType) -> String {
  match self {
    Any => "any"
    ParamBool => "bool"
    ParamNumber => "number"
    ParamString => "string"
    ParamArray(elem) => "array(" + elem.display_name() + ")"
    ParamObject(val_type) => "object(" + val_type.display_name() + ")"
    Nullable(inner) => inner.display_name() + "?"
    OneOf(_) => "oneof"
  }
}

///|
/// Function definition with parameter specifications
pub struct FuncDef {
  name : String
  params : Array[ParamType]
  variadic : ParamType?
  func : (Array[HCLValue]) -> HCLResult[HCLValue]
}

///|
/// Call function with argument validation
pub fn FuncDef::call(
  self : FuncDef,
  args : Array[HCLValue],
) -> HCLResult[HCLValue] {
  let params_len = self.params.length()
  let args_len = args.length()

  // Too few args
  if args_len < params_len {
    return Err(
      HCLError::invalid_value(
        self.name +
        "() expects at least " +
        params_len.to_string() +
        " argument(s), got " +
        args_len.to_string(),
      ),
    )
  }

  // Too many args without variadic
  if not(self.variadic is Some(_)) && args_len > params_len {
    return Err(
      HCLError::invalid_value(
        self.name +
        "() expects at most " +
        params_len.to_string() +
        " argument(s), got " +
        args_len.to_string(),
      ),
    )
  }

  // Type-check positional args
  for i in 0..<params_len {
    if not(self.params[i].is_satisfied_by(args[i])) {
      return Err(
        HCLError::type_error(
          self.name +
          "() argument " +
          (i + 1).to_string() +
          " expects " +
          self.params[i].display_name() +
          ", got " +
          args[i].type_name(),
        ),
      )
    }
  }

  // Type-check variadic args
  match self.variadic {
    Some(var_type) =>
      for i in params_len..<args_len {
        if not(var_type.is_satisfied_by(args[i])) {
          return Err(
            HCLError::type_error(
              self.name +
              "() variadic argument " +
              (i + 1).to_string() +
              " expects " +
              var_type.display_name() +
              ", got " +
              args[i].type_name(),
            ),
          )
        }
      }
    None => ()
  }

  (self.func)(args)
}

///|
/// Create a FuncDefBuilder
pub fn FuncDef::builder() -> FuncDefBuilder {
  FuncDefBuilder::new()
}

///|
/// Builder for FuncDef
pub struct FuncDefBuilder {
  params : Array[ParamType]
  variadic : ParamType?
} derive(Debug, Eq)

///|
/// Create new FuncDefBuilder
pub fn FuncDefBuilder::new() -> FuncDefBuilder {
  { params: [], variadic: None }
}

///|
/// Add a positional parameter
pub fn FuncDefBuilder::param(
  self : FuncDefBuilder,
  ptype : ParamType,
) -> FuncDefBuilder {
  self.params.push(ptype)
  self
}

///|
/// Set variadic parameter type
pub fn FuncDefBuilder::variadic(
  self : FuncDefBuilder,
  vtype : ParamType,
) -> FuncDefBuilder {
  { params: self.params, variadic: Some(vtype) }
}

///|
/// Build FuncDef with name and function body
pub fn FuncDefBuilder::build(
  self : FuncDefBuilder,
  name : String,
  func : (Array[HCLValue]) -> HCLResult[HCLValue],
) -> FuncDef {
  { name, params: self.params, variadic: self.variadic, func }
}

///|
/// HCL Built-in Functions
/// Standard library of functions available during expression evaluation

///|
/// Get all built-in functions
pub fn builtin_functions() -> Map[String, FuncDef] {
  let funcs = {}

  // Numeric functions
  funcs["abs"] = FuncDef::builder().param(ParamNumber).build("abs", fn_abs)
  funcs["ceil"] = FuncDef::builder().param(ParamNumber).build("ceil", fn_ceil)
  funcs["floor"] = FuncDef::builder()
    .param(ParamNumber)
    .build("floor", fn_floor)
  funcs["log"] = FuncDef::builder()
    .param(ParamNumber)
    .param(ParamNumber)
    .build("log", fn_log)
  funcs["max"] = FuncDef::builder()
    .param(ParamNumber)
    .variadic(ParamNumber)
    .build("max", fn_max)
  funcs["min"] = FuncDef::builder()
    .param(ParamNumber)
    .variadic(ParamNumber)
    .build("min", fn_min)
  funcs["parseint"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamNumber)
    .build("parseint", fn_parseint)
  funcs["pow"] = FuncDef::builder()
    .param(ParamNumber)
    .param(ParamNumber)
    .build("pow", fn_pow)
  funcs["signum"] = FuncDef::builder()
    .param(ParamNumber)
    .build("signum", fn_signum)

  // Collection functions
  funcs["length"] = FuncDef::builder()
    .param(OneOf([ParamArray(Any), ParamObject(Any), ParamString]))
    .build("length", fn_length)
  funcs["keys"] = FuncDef::builder()
    .param(ParamObject(Any))
    .build("keys", fn_keys)
  funcs["values"] = FuncDef::builder()
    .param(ParamObject(Any))
    .build("values", fn_values)
  funcs["contains"] = FuncDef::builder()
    .param(OneOf([ParamArray(Any), ParamString]))
    .param(Any)
    .build("contains", fn_contains)
  funcs["flatten"] = FuncDef::builder()
    .param(ParamArray(Any))
    .build("flatten", fn_flatten)
  funcs["merge"] = FuncDef::builder()
    .variadic(ParamObject(Any))
    .build("merge", fn_merge)
  funcs["reverse"] = FuncDef::builder()
    .param(OneOf([ParamArray(Any), ParamString]))
    .build("reverse", fn_reverse)
  funcs["distinct"] = FuncDef::builder()
    .param(ParamArray(Any))
    .build("distinct", fn_distinct)
  funcs["sort"] = FuncDef::builder()
    .param(ParamArray(Any))
    .build("sort", fn_sort)
  funcs["slice"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamNumber)
    .param(ParamNumber)
    .build("slice", fn_slice)
  funcs["element"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamNumber)
    .build("element", fn_element)
  funcs["concat"] = FuncDef::builder()
    .variadic(ParamArray(Any))
    .build("concat", fn_concat)
  funcs["coalesce"] = FuncDef::builder()
    .variadic(Any)
    .build("coalesce", fn_coalesce)
  funcs["range"] = FuncDef::builder()
    .variadic(ParamNumber)
    .build("range", fn_range)
  funcs["chunklist"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamNumber)
    .build("chunklist", fn_chunklist)
  funcs["lookup"] = FuncDef::builder()
    .param(ParamObject(Any))
    .param(ParamString)
    .variadic(Any)
    .build("lookup", fn_lookup)
  funcs["zipmap"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("zipmap", fn_zipmap)
  funcs["transpose"] = FuncDef::builder()
    .param(ParamObject(Any))
    .build("transpose", fn_transpose)
  funcs["matchkeys"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("matchkeys", fn_matchkeys)
  funcs["sum"] = FuncDef::builder()
    .param(ParamArray(ParamNumber))
    .build("sum", fn_sum)
  funcs["alltrue"] = FuncDef::builder()
    .param(ParamArray(ParamBool))
    .build("alltrue", fn_alltrue)
  funcs["anytrue"] = FuncDef::builder()
    .param(ParamArray(ParamBool))
    .build("anytrue", fn_anytrue)
  funcs["one"] = FuncDef::builder().param(ParamArray(Any)).build("one", fn_one)
  funcs["setunion"] = FuncDef::builder()
    .variadic(ParamArray(Any))
    .build("setunion", fn_setunion)
  funcs["setintersection"] = FuncDef::builder()
    .variadic(ParamArray(Any))
    .build("setintersection", fn_setintersection)
  funcs["setsubtract"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("setsubtract", fn_setsubtract)
  funcs["setsymmetricdifference"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("setsymmetricdifference", fn_setsymmetricdifference)
  funcs["setproduct"] = FuncDef::builder()
    .variadic(ParamArray(Any))
    .build("setproduct", fn_setproduct)
  funcs["setissubset"] = FuncDef::builder()
    .param(ParamArray(Any))
    .param(ParamArray(Any))
    .build("setissubset", fn_setissubset)

  // String functions
  funcs["chomp"] = FuncDef::builder()
    .param(ParamString)
    .build("chomp", fn_chomp)
  funcs["indent"] = FuncDef::builder()
    .param(ParamNumber)
    .param(ParamString)
    .build("indent", fn_indent)
  funcs["join"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamArray(ParamString))
    .build("join", fn_join)
  funcs["lower"] = FuncDef::builder()
    .param(ParamString)
    .build("lower", fn_lower)
  funcs["upper"] = FuncDef::builder()
    .param(ParamString)
    .build("upper", fn_upper)
  funcs["replace"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .param(ParamString)
    .build("replace", fn_replace)
  funcs["split"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("split", fn_split)
  funcs["strrev"] = FuncDef::builder()
    .param(ParamString)
    .build("strrev", fn_strrev)
  funcs["substr"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamNumber)
    .param(ParamNumber)
    .build("substr", fn_substr)
  funcs["trim"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("trim", fn_trim)
  funcs["trimprefix"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("trimprefix", fn_trimprefix)
  funcs["trimsuffix"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("trimsuffix", fn_trimsuffix)
  funcs["trimspace"] = FuncDef::builder()
    .param(ParamString)
    .build("trimspace", fn_trimspace)
  funcs["format"] = FuncDef::builder()
    .param(ParamString)
    .variadic(Any)
    .build("format", fn_format)
  funcs["formatlist"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamArray(Any))
    .build("formatlist", fn_formatlist)
  funcs["startswith"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("startswith", fn_startswith)
  funcs["endswith"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("endswith", fn_endswith)
  funcs["title"] = FuncDef::builder()
    .param(ParamString)
    .build("title", fn_title)

  // Type conversion functions
  funcs["tobool"] = FuncDef::builder()
    .param(OneOf([ParamBool, ParamString, ParamNumber]))
    .build("tobool", fn_tobool)
  funcs["tonumber"] = FuncDef::builder()
    .param(OneOf([ParamNumber, ParamString, ParamBool]))
    .build("tonumber", fn_tonumber)
  funcs["tolist"] = FuncDef::builder().param(Any).build("tolist", fn_tolist)
  funcs["tomap"] = FuncDef::builder()
    .param(ParamObject(Any))
    .build("tomap", fn_tomap)
  funcs["toset"] = FuncDef::builder().param(Any).build("toset", fn_toset)
  funcs["tostring"] = FuncDef::builder()
    .param(Any)
    .build("tostring", fn_tostring)

  // Encoding functions
  funcs["jsondecode"] = FuncDef::builder()
    .param(ParamString)
    .build("jsondecode", fn_jsondecode)
  funcs["jsonencode"] = FuncDef::builder()
    .param(Any)
    .build("jsonencode", fn_jsonencode)
  funcs["base64decode"] = FuncDef::builder()
    .param(ParamString)
    .build("base64decode", fn_base64decode)
  funcs["base64encode"] = FuncDef::builder()
    .param(ParamString)
    .build("base64encode", fn_base64encode)
  funcs["csvdecode"] = FuncDef::builder()
    .param(ParamString)
    .build("csvdecode", fn_csvdecode)
  funcs["urlencode"] = FuncDef::builder()
    .param(ParamString)
    .build("urlencode", fn_urlencode)

  // Date/time functions
  funcs["formatdate"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("formatdate", fn_formatdate)
  funcs["timeadd"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("timeadd", fn_timeadd)
  funcs["timecmp"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamString)
    .build("timecmp", fn_timecmp)

  funcs["cidrhost"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamNumber)
    .build("cidrhost", fn_cidrhost)
  funcs["cidrnetmask"] = FuncDef::builder()
    .param(ParamString)
    .build("cidrnetmask", fn_cidrnetmask)
  funcs["cidrsubnet"] = FuncDef::builder()
    .param(ParamString)
    .param(ParamNumber)
    .param(ParamNumber)
    .build("cidrsubnet", fn_cidrsubnet)
  funcs["cidrsubnets"] = FuncDef::builder()
    .param(ParamString)
    .variadic(ParamNumber)
    .build("cidrsubnets", fn_cidrsubnets)

  funcs
}

///|
/// Registry for managing custom and builtin functions
pub struct FuncRegistry {
  funcs : Map[String, FuncDef]
}

///|
/// Create an empty FuncRegistry
pub fn FuncRegistry::new() -> FuncRegistry {
  { funcs: Map::new() }
}

///|
/// Create a FuncRegistry pre-loaded with all builtin functions
pub fn FuncRegistry::with_builtins() -> FuncRegistry {
  { funcs: builtin_functions() }
}

///|
/// Register a single function definition (fluent API, returns self)
pub fn FuncRegistry::register(
  self : FuncRegistry,
  name : String,
  def : FuncDef,
) -> FuncRegistry {
  self.funcs[name] = def
  self
}

///|
/// Merge another Map[String, FuncDef] into this registry
pub fn FuncRegistry::merge(
  self : FuncRegistry,
  other : Map[String, FuncDef],
) -> FuncRegistry {
  for entry in other {
    let (k, v) = entry
    self.funcs[k] = v
  }
  self
}

///|
/// Build and return the final Map[String, FuncDef]
pub fn FuncRegistry::build(self : FuncRegistry) -> Map[String, FuncDef] {
  self.funcs
}

///|
/// Merge two function maps, extra overrides base on conflict
pub fn merge_funcs(
  base : Map[String, FuncDef],
  extra : Map[String, FuncDef],
) -> Map[String, FuncDef] {
  let result = Map::new()
  for entry in base {
    let (k, v) = entry
    result[k] = v
  }
  for entry in extra {
    let (k, v) = entry
    result[k] = v
  }
  result
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
  match to_double(args[0]) {
    Ok(f) => Ok(Number(Number::from_int(f.ceil().to_int()), Decor::empty()))
    Err(e) => Err(e)
  }
}

///|
/// floor(num) - Returns largest integer <= num
fn fn_floor(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match to_double(args[0]) {
    Ok(f) => Ok(Number(Number::from_int(f.floor().to_int()), Decor::empty()))
    Err(e) => Err(e)
  }
}

///|
/// log(num, base) - Returns log of num with given base
fn fn_log(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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
/// contains(str, substr) - Returns true if string contains substring
fn fn_contains(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      for item in arr {
        if item == args[1] {
          return Ok(Bool(true, Decor::empty()))
        }
      }
      Ok(Bool(false, Decor::empty()))
    }
    String(s, _) =>
      match args[1] {
        String(sub, _) => Ok(Bool(s.contains(sub), Decor::empty()))
        _ =>
          Err(
            HCLError::type_error(
              "contains() string search requires a string substring",
            ),
          )
      }
    _ => Err(HCLError::type_error("contains() requires an array or string"))
  }
}

///|
/// flatten(list) - Flattens nested list
fn fn_flatten(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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

///|
/// concat(list1, list2, ...) - Concatenate multiple arrays
fn fn_concat(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let result = []
  for arg in args {
    match arg {
      Array(arr, _) =>
        for item in arr {
          result.push(item)
        }
      _ => return Err(HCLError::type_error("concat() requires arrays"))
    }
  }
  Ok(Array(result, Decor::empty()))
}

///|
/// coalesce(val1, val2, ...) - Return first non-null value
fn fn_coalesce(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  for arg in args {
    match arg {
      Null(_) => continue
      _ => return Ok(arg)
    }
  }
  Ok(Null(Decor::empty()))
}

///|
/// range(max) or range(start, limit) - Generate number sequence
fn fn_range(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let (start, limit) = match args.length() {
    1 =>
      match args[0] {
        Number(n, _) =>
          match n.as_int() {
            Some(v) => (0, v)
            None =>
              return Err(HCLError::type_error("range() requires integers"))
          }
        _ => return Err(HCLError::type_error("range() requires numbers"))
      }
    2 =>
      match (args[0], args[1]) {
        (Number(n1, _), Number(n2, _)) =>
          match (n1.as_int(), n2.as_int()) {
            (Some(a), Some(b)) => (a, b)
            _ => return Err(HCLError::type_error("range() requires integers"))
          }
        _ => return Err(HCLError::type_error("range() requires numbers"))
      }
    _ =>
      return Err(HCLError::invalid_value("range() requires 1 or 2 arguments"))
  }
  let result = []
  let mut i = start
  while i < limit {
    result.push(Number(Number::from_int(i), Decor::empty()))
    i = i + 1
  }
  Ok(Array(result, Decor::empty()))
}

///|
/// chunklist(list, size) - Split array into chunks
fn fn_chunklist(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (Array(arr, _), Number(n, _)) =>
      match n.as_int() {
        Some(size) => {
          if size <= 0 {
            return Err(
              HCLError::invalid_value("chunklist() size must be positive"),
            )
          }
          let result = []
          let mut chunk = []
          for item in arr {
            chunk.push(item)
            if chunk.length() == size {
              result.push(Array(chunk, Decor::empty()))
              chunk = []
            }
          }
          if chunk.length() > 0 {
            result.push(Array(chunk, Decor::empty()))
          }
          Ok(Array(result, Decor::empty()))
        }
        None => Err(HCLError::type_error("chunklist() size must be integer"))
      }
    _ => Err(HCLError::type_error("chunklist() requires (array, number)"))
  }
}

///|
/// lookup(map, key, default?) - Safe map key access
fn fn_lookup(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (Object(o, _), String(key, _)) => {
      for k, v in o {
        if k == key {
          return Ok(v)
        }
      }
      if args.length() == 3 {
        return Ok(args[2])
      }
      Err(HCLError::invalid_value("lookup() key not found: " + key))
    }
    _ => Err(HCLError::type_error("lookup() requires (object, string)"))
  }
}

///|
/// zipmap(keys, values) - Merge two arrays into map
fn fn_zipmap(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (Array(keys_arr, _), Array(values_arr, _)) => {
      let map : Map[String, HCLValue] = {}
      let keys_len = keys_arr.length()
      let values_len = values_arr.length()
      let len = if keys_len < values_len { keys_len } else { values_len }
      let mut i = 0
      while i < len {
        match keys_arr[i] {
          String(key, _) => map[key] = values_arr[i]
          _ => return Err(HCLError::type_error("zipmap() keys must be strings"))
        }
        i = i + 1
      }
      Ok(Object(map, Decor::empty()))
    }
    _ => Err(HCLError::type_error("zipmap() requires (array, array)"))
  }
}

///|
/// transpose(map) - Transpose map keys/values
fn fn_transpose(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Object(o, _) => {
      let result : Map[String, HCLValue] = {}
      for k, v in o {
        match v {
          Array(arr, _) =>
            for item in arr {
              match item {
                String(s, _) =>
                  match result.get(s) {
                    Some(Array(existing, _)) => {
                      existing.push(String(k, Decor::empty()))
                      result[s] = Array(existing, Decor::empty())
                    }
                    None =>
                      result[s] = Array(
                        [String(k, Decor::empty())],
                        Decor::empty(),
                      )
                    _ =>
                      return Err(
                        HCLError::invalid_value("transpose() internal error"),
                      )
                  }
                _ =>
                  return Err(
                    HCLError::type_error(
                      "transpose() values must be arrays of strings",
                    ),
                  )
              }
            }
          _ =>
            return Err(
              HCLError::type_error("transpose() values must be arrays"),
            )
        }
      }
      Ok(Object(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("transpose() requires an object"))
  }
}

///|
/// matchkeys(search, keys, values) - Match key patterns
fn fn_matchkeys(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1], args[2]) {
    (Array(search_arr, _), Array(keys_arr, _), Array(values_arr, _)) => {
      let result = []
      for search_item in search_arr {
        let mut i = 0
        while i < keys_arr.length() && i < values_arr.length() {
          if keys_arr[i] == search_item {
            result.push(values_arr[i])
            break
          }
          i = i + 1
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("matchkeys() requires (array, array, array)"))
  }
}

///|
/// sum(list) - Sum numeric array
fn fn_sum(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      let mut total = 0.0
      for item in arr {
        match item {
          Number(n, _) => total = total + n.as_float()
          _ => return Err(HCLError::type_error("sum() requires numeric array"))
        }
      }
      Ok(Number(Number::from_finite_f64(total), Decor::empty()))
    }
    _ => Err(HCLError::type_error("sum() requires an array"))
  }
}

///|
/// alltrue(list) - All values true
fn fn_alltrue(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      for item in arr {
        match item {
          Bool(false, _) => return Ok(Bool(false, Decor::empty()))
          Bool(true, _) => continue
          _ => return Err(HCLError::type_error("alltrue() requires bool array"))
        }
      }
      Ok(Bool(true, Decor::empty()))
    }
    _ => Err(HCLError::type_error("alltrue() requires an array"))
  }
}

///|
/// anytrue(list) - Any value true
fn fn_anytrue(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) => {
      for item in arr {
        match item {
          Bool(true, _) => return Ok(Bool(true, Decor::empty()))
          Bool(false, _) => continue
          _ => return Err(HCLError::type_error("anytrue() requires bool array"))
        }
      }
      Ok(Bool(false, Decor::empty()))
    }
    _ => Err(HCLError::type_error("anytrue() requires an array"))
  }
}

///|
/// one(list) - Ensure single element and return it
fn fn_one(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(arr, _) =>
      if arr.length() == 1 {
        Ok(arr[0])
      } else if arr.length() == 0 {
        Err(
          HCLError::invalid_value("one() requires exactly one element, got 0"),
        )
      } else {
        Err(
          HCLError::invalid_value(
            "one() requires exactly one element, got " +
            arr.length().to_string(),
          ),
        )
      }
    _ => Err(HCLError::type_error("one() requires an array"))
  }
}

///|
/// setunion(s1, s2, ...) - Returns deduplicated union of all arrays
fn fn_setunion(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let result = []
  let seen = Set::new()
  for arg in args {
    match arg {
      Array(arr, _) =>
        for item in arr {
          let key = item.to_json_string()
          if !seen.contains(key) {
            seen.add(key)
            result.push(item)
          }
        }
      _ => return Err(HCLError::type_error("setunion() requires arrays"))
    }
  }
  Ok(Array(result, Decor::empty()))
}

///|
/// setintersection(s1, s2, ...) - Returns items present in ALL arrays
fn fn_setintersection(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  if args.length() == 0 {
    return Ok(Array([], Decor::empty()))
  }
  match args[0] {
    Array(first, _) => {
      let seen = Set::new()
      let result = []
      for item in first {
        let key = item.to_json_string()
        if seen.contains(key) {
          continue
        }
        seen.add(key)
        let mut in_all = true
        for i in 1..<args.length() {
          match args[i] {
            Array(arr, _) => {
              let mut found = false
              for other in arr {
                if other.to_json_string() == key {
                  found = true
                  break
                }
              }
              if !found {
                in_all = false
                break
              }
            }
            _ =>
              return Err(
                HCLError::type_error("setintersection() requires arrays"),
              )
          }
        }
        if in_all {
          result.push(item)
        }
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("setintersection() requires arrays"))
  }
}

///|
/// setsubtract(s1, s2) - Returns items in s1 NOT in s2
fn fn_setsubtract(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(s1, _) =>
      match args[1] {
        Array(s2, _) => {
          let s2_keys = Set::new()
          for item in s2 {
            s2_keys.add(item.to_json_string())
          }
          let seen = Set::new()
          let result = []
          for item in s1 {
            let key = item.to_json_string()
            if !s2_keys.contains(key) && !seen.contains(key) {
              seen.add(key)
              result.push(item)
            }
          }
          Ok(Array(result, Decor::empty()))
        }
        _ => Err(HCLError::type_error("setsubtract() requires arrays"))
      }
    _ => Err(HCLError::type_error("setsubtract() requires arrays"))
  }
}

///|
/// setsymmetricdifference(s1, s2) - Returns items in s1 or s2 but not both
fn fn_setsymmetricdifference(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(s1, _) =>
      match args[1] {
        Array(s2, _) => {
          let s1_keys = Set::new()
          for item in s1 {
            s1_keys.add(item.to_json_string())
          }
          let s2_keys = Set::new()
          for item in s2 {
            s2_keys.add(item.to_json_string())
          }
          let seen = Set::new()
          let result = []
          for item in s1 {
            let key = item.to_json_string()
            if !s2_keys.contains(key) && !seen.contains(key) {
              seen.add(key)
              result.push(item)
            }
          }
          for item in s2 {
            let key = item.to_json_string()
            if !s1_keys.contains(key) && !seen.contains(key) {
              seen.add(key)
              result.push(item)
            }
          }
          Ok(Array(result, Decor::empty()))
        }
        _ =>
          Err(HCLError::type_error("setsymmetricdifference() requires arrays"))
      }
    _ => Err(HCLError::type_error("setsymmetricdifference() requires arrays"))
  }
}

///|
/// setproduct(s1, s2, ...) - Returns cartesian product of all arrays
fn fn_setproduct(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let mut results : Array[Array[HCLValue]] = [[]]
  for arg in args {
    match arg {
      Array(arr, _) => {
        let new_results : Array[Array[HCLValue]] = []
        for partial in results {
          for item in arr {
            let extended : Array[HCLValue] = []
            for elem in partial {
              extended.push(elem)
            }
            extended.push(item)
            new_results.push(extended)
          }
        }
        results = new_results
      }
      _ => return Err(HCLError::type_error("setproduct() requires arrays"))
    }
  }
  let out = []
  for r in results {
    out.push(HCLValue::Array(r, Decor::empty()))
  }
  Ok(HCLValue::Array(out, Decor::empty()))
}

///|
/// setissubset(s1, s2) - Returns true if all items in s1 exist in s2
fn fn_setissubset(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(s1, _) =>
      match args[1] {
        Array(s2, _) => {
          let s2_keys = Set::new()
          for item in s2 {
            s2_keys.add(item.to_json_string())
          }
          for item in s1 {
            if not(s2_keys.contains(item.to_json_string())) {
              return Ok(HCLValue::Bool(false, Decor::empty()))
            }
          }
          Ok(HCLValue::Bool(true, Decor::empty()))
        }
        _ => Err(HCLError::type_error("setissubset() requires arrays"))
      }
    _ => Err(HCLError::type_error("setissubset() requires arrays"))
  }
}

///| =========================================================================
/// String Functions

///| =========================================================================

///|
/// chomp(str) - Removes trailing newline
fn fn_chomp(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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
  match args[0] {
    String(s, _) => Ok(String(s.to_lower(), Decor::empty()))
    _ => Err(HCLError::type_error("lower() requires a string"))
  }
}

///|
/// upper(str) - Converts to uppercase
fn fn_upper(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => Ok(String(s.to_upper(), Decor::empty()))
    _ => Err(HCLError::type_error("upper() requires a string"))
  }
}

///|
/// replace(str, pattern, replacement) - Replaces all occurrences
fn fn_replace(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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
  match args[0] {
    String(s, _) => Ok(String(s.trim().to_string(), Decor::empty()))
    _ => Err(HCLError::type_error("trimspace() requires a string"))
  }
}

///|
/// format(pattern, args...) - Formats string with arguments
fn fn_format(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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

///|
/// startswith(str, prefix) - Returns true if str starts with prefix
fn fn_startswith(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (String(s, _), String(prefix, _)) =>
      Ok(Bool(s.has_prefix(prefix), Decor::empty()))
    _ => Err(HCLError::type_error("startswith() requires (string, string)"))
  }
}

///|
/// endswith(str, suffix) - Returns true if str ends with suffix
fn fn_endswith(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (String(s, _), String(suffix, _)) =>
      Ok(Bool(s.has_suffix(suffix), Decor::empty()))
    _ => Err(HCLError::type_error("endswith() requires (string, string)"))
  }
}

///|
/// title(str) - Capitalizes first letter of each word
fn fn_title(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => {
      let chars = s.to_array()
      let result = []
      let mut prev_was_space = true
      for c in chars {
        if c == ' ' {
          result.push(c)
          prev_was_space = true
        } else if prev_was_space {
          let upper = c.to_string().to_upper()
          result.push(upper.to_array()[0])
          prev_was_space = false
        } else {
          let lower = c.to_string().to_lower()
          result.push(lower.to_array()[0])
          prev_was_space = false
        }
      }
      Ok(String(String::from_array(result), Decor::empty()))
    }
    _ => Err(HCLError::type_error("title() requires a string"))
  }
}

///| =========================================================================
/// Type Conversion Functions

///| =========================================================================

///|
/// tobool(val) - Converts to boolean
fn fn_tobool(args : Array[HCLValue]) -> HCLResult[HCLValue] {
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
  match args[0] {
    Array(a, _) => Ok(Array(a, Decor::empty()))
    _ => Ok(Array([args[0]], Decor::empty()))
  }
}

///|
/// tomap(val) - Converts to map
fn fn_tomap(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Object(o, _) => Ok(Object(o, Decor::empty()))
    _ => Err(HCLError::type_error("tomap() requires an object"))
  }
}

///|
/// toset(val) - Converts to set (as distinct list)
fn fn_toset(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    Array(_, _) => fn_distinct(args)
    _ => Ok(Array([args[0]], Decor::empty()))
  }
}

///|
/// tostring(val) - Converts to string
fn fn_tostring(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => Ok(String(s, Decor::empty()))
    Number(n, _) => Ok(String(n.to_string(), Decor::empty()))
    Bool(b, _) => Ok(String(if b { "true" } else { "false" }, Decor::empty()))
    Null(_) => Ok(String("null", Decor::empty()))
    Unknown(_) => Ok(String("unknown", Decor::empty()))
    _ => Ok(String(args[0].to_json_string(), Decor::empty()))
  }
}

///| =========================================================================
/// Encoding Functions

///| =========================================================================

///|
/// Convert a parsed Json value to HCLValue recursively
fn json_to_hcl_value(j : Json) -> HCLValue {
  match j {
    _ if j.as_null() is Some(_) => Null(Decor::empty())
    _ if j.as_bool() is Some(b) => Bool(b, Decor::empty())
    _ if j.as_number() is Some(n) =>
      Number(Number::from_finite_f64(n), Decor::empty())
    _ if j.as_string() is Some(s) => String(s, Decor::empty())
    _ if j.as_array() is Some(arr) => {
      let result = []
      for item in arr {
        result.push(json_to_hcl_value(item))
      }
      Array(result, Decor::empty())
    }
    _ if j.as_object() is Some(obj) => {
      let result : Map[String, HCLValue] = {}
      for k, v in obj {
        result[k] = json_to_hcl_value(v)
      }
      Object(result, Decor::empty())
    }
    _ => Null(Decor::empty())
  }
}

///|
/// Convert HCLValue to Json recursively
fn hcl_value_to_json(v : HCLValue) -> Json {
  match v {
    Null(_) => Json::null()
    Bool(b, _) => Json::boolean(b)
    Number(n, _) => Json::number(n.as_float())
    String(s, _) => Json::string(s)
    Array(arr, _) => {
      let result : Array[Json] = []
      for item in arr {
        result.push(hcl_value_to_json(item))
      }
      Json::array(result)
    }
    Object(obj, _) => {
      let result : Map[String, Json] = {}
      for k, v in obj {
        result[k] = hcl_value_to_json(v)
      }
      Json::object(result)
    }
    _ => Json::null()
  }
}

///|
/// jsondecode(str) - Decode JSON string to HCL value
fn fn_jsondecode(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) =>
      try {
        let j = @json.parse(s)
        Ok(json_to_hcl_value(j))
      } catch {
        e =>
          Err(
            HCLError::invalid_value(
              "jsondecode() parse error: " + e.to_string(),
            ),
          )
      }
    _ => Err(HCLError::type_error("jsondecode() requires a string"))
  }
}

///|
/// jsonencode(val) - Encode HCL value to JSON string
fn fn_jsonencode(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  let j = hcl_value_to_json(args[0])
  Ok(String(j.stringify(), Decor::empty()))
}

///|
/// base64decode(str) - Decode base64 string
fn fn_base64decode(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) =>
      try {
        let bytes = @encoding/base64.decode(s)
        Ok(String(@encoding/utf8.decode(bytes), Decor::empty()))
      } catch {
        _ => Err(HCLError::invalid_value("base64decode() invalid base64 input"))
      }
    _ => Err(HCLError::type_error("base64decode() requires a string"))
  }
}

///|
/// base64encode(str) - Encode string to base64
fn fn_base64encode(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => {
      let bytes = @encoding/utf8.encode(s)
      Ok(String(@encoding/base64.encode(bytes), Decor::empty()))
    }
    _ => Err(HCLError::type_error("base64encode() requires a string"))
  }
}

///|
/// csvdecode(str) - Decode CSV string to array of objects
fn fn_csvdecode(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => {
      let lines : Array[String] = []
      for part in s.split("\n") {
        lines.push(part.to_string())
      }
      if lines.is_empty() {
        return Ok(Array([], Decor::empty()))
      }
      let headers = csv_parse_line(lines[0])
      if headers.is_empty() {
        return Ok(Array([], Decor::empty()))
      }
      let result = []
      for i in 1..<lines.length() {
        let line = lines[i]
        if line.trim().to_string().is_empty() {
          continue
        }
        let fields = csv_parse_line(line)
        let obj : Map[String, HCLValue] = {}
        for j in 0..<headers.length() {
          if j < fields.length() {
            obj[headers[j]] = String(fields[j], Decor::empty())
          } else {
            obj[headers[j]] = String("", Decor::empty())
          }
        }
        result.push(HCLValue::Object(obj, Decor::empty()))
      }
      Ok(Array(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("csvdecode() requires a string"))
  }
}

///|
/// Parse a single CSV line, handling quoted fields
fn csv_parse_line(line : String) -> Array[String] {
  let result = []
  let mut current = ""
  let mut in_quotes = false
  let mut i = 0
  let len = line.length()
  while i < len {
    let c = char_at(line, i)
    if in_quotes {
      if c == "\"" {
        if i + 1 < len && char_at(line, i + 1) == "\"" {
          current = current + "\""
          i = i + 2
        } else {
          in_quotes = false
          i = i + 1
        }
      } else {
        current = current + c
        i = i + 1
      }
    } else if c == "\"" && current.is_empty() {
      in_quotes = true
      i = i + 1
    } else if c == "," {
      result.push(current)
      current = ""
      i = i + 1
    } else {
      current = current + c
      i = i + 1
    }
  }
  result.push(current)
  result
}

///|
/// urlencode(str) - URL percent-encode a string
fn fn_urlencode(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => {
      let hex = "0123456789ABCDEF"
      let mut result = ""
      for c in s {
        let code = c.to_int()
        if (code >= 65 && code <= 90) ||
          (code >= 97 && code <= 122) ||
          (code >= 48 && code <= 57) ||
          c == '-' ||
          c == '_' ||
          c == '.' ||
          c == '~' {
          result = result + c.to_string()
        } else if c == ' ' {
          result = result + "+"
        } else {
          let hi = code / 16
          let lo = code % 16
          result = result + "%" + char_at(hex, hi) + char_at(hex, lo)
        }
      }
      Ok(String(result, Decor::empty()))
    }
    _ => Err(HCLError::type_error("urlencode() requires a string"))
  }
}

///| =========================================================================
/// Date/Time Helpers

///| =========================================================================

///|
/// Strip timezone suffix from RFC3339 string
fn strip_rfc3339_tz(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  let mut t_pos = -1
  let mut i = 0
  while i < len {
    if s.code_unit_at(i) == 'T'.to_int().to_uint16() {
      t_pos = i
      break
    }
    i = i + 1
  }
  if t_pos < 0 {
    return s
  }
  let after_t = t_pos + 1
  i = after_t + 8
  while i < len {
    let ch = s.code_unit_at(i)
    if ch == 'Z'.to_int().to_uint16() ||
      ch == '+'.to_int().to_uint16() ||
      ch == '-'.to_int().to_uint16() {
      return substring(s, 0, i)
    }
    i = i + 1
  }
  s
}

///|
/// Parse RFC3339 timestamp string to PlainDateTime
fn parse_rfc3339(s : String) -> @time.PlainDateTime raise {
  let cleaned = strip_rfc3339_tz(s)
  @time.PlainDateTime::from_string(cleaned)
}

///|
/// Format PlainDateTime as RFC3339 UTC string
fn format_rfc3339(dt : @time.PlainDateTime) -> String {
  dt.to_string() + "Z"
}

///|
/// Pad integer to specified width with leading zeros
fn pad_int(n : Int, width : Int) -> String {
  let s = n.to_string()
  let pad = width - s.length()
  if pad <= 0 {
    return s
  }
  let buf = StringBuilder::new(size_hint=width)
  let mut j = 0
  while j < pad {
    buf.write_char('0')
    j = j + 1
  }
  buf.write_string(s)
  buf.to_string()
}

///|
/// Apply date format tokens to PlainDateTime
fn apply_date_format(fmt : String, dt : @time.PlainDateTime) -> String {
  let buf = StringBuilder::new(size_hint=fmt.length())
  let len = fmt.length()
  let mut i = 0
  while i < len {
    let remaining = len - i
    if fmt.code_unit_at(i) == '\''.to_int().to_uint16() {
      i = i + 1
      while i < len && fmt.code_unit_at(i) != '\''.to_int().to_uint16() {
        buf.write_char(fmt.code_unit_at(i).to_int().unsafe_to_char())
        i = i + 1
      }
      i = i + 1
    } else if remaining >= 4 && substring(fmt, i, i + 4) == "YYYY" {
      buf.write_string(pad_int(dt.year(), 4))
      i = i + 4
    } else if remaining >= 2 && substring(fmt, i, i + 2) == "YY" {
      buf.write_string(pad_int(dt.year() % 100, 2))
      i = i + 2
    } else if remaining >= 2 && substring(fmt, i, i + 2) == "MM" {
      buf.write_string(pad_int(dt.month(), 2))
      i = i + 2
    } else if remaining >= 2 && substring(fmt, i, i + 2) == "DD" {
      buf.write_string(pad_int(dt.day(), 2))
      i = i + 2
    } else if remaining >= 2 && substring(fmt, i, i + 2) == "hh" {
      buf.write_string(pad_int(dt.hour(), 2))
      i = i + 2
    } else if remaining >= 2 && substring(fmt, i, i + 2) == "mm" {
      buf.write_string(pad_int(dt.minute(), 2))
      i = i + 2
    } else if remaining >= 2 && substring(fmt, i, i + 2) == "ss" {
      buf.write_string(pad_int(dt.second(), 2))
      i = i + 2
    } else if fmt.code_unit_at(i) == 'Z'.to_int().to_uint16() {
      buf.write_char('Z')
      i = i + 1
    } else {
      buf.write_char(fmt.code_unit_at(i).to_int().unsafe_to_char())
      i = i + 1
    }
  }
  buf.to_string()
}

///| =========================================================================
/// Date/Time Functions

///| =========================================================================

///|
/// formatdate(format, timestamp) - Format a timestamp string
fn fn_formatdate(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (String(fmt, _), String(ts, _)) =>
      try {
        let dt = parse_rfc3339(ts)
        Ok(String(apply_date_format(fmt, dt), Decor::empty()))
      } catch {
        _ =>
          Err(HCLError::invalid_value("formatdate: invalid RFC3339 timestamp"))
      }
    _ =>
      Err(HCLError::invalid_value("formatdate: both arguments must be strings"))
  }
}

///|
/// Convert HCL duration "1h30m5s" to ISO 8601 "PT1H30M5S"
fn hcl_duration_to_iso(s : String) -> String {
  if s.is_empty() {
    return "PT0S"
  }
  let buf = StringBuilder::new(size_hint=s.length() + 2)
  buf.write_char('P')
  buf.write_char('T')
  let len = s.length()
  let mut i = 0
  if i < len && s.code_unit_at(i) == '-'.to_int().to_uint16() {
    buf.write_char('-')
    i = i + 1
  }
  while i < len {
    let ch = s.code_unit_at(i)
    if ch == 'h'.to_int().to_uint16() {
      buf.write_char('H')
      i = i + 1
    } else if ch == 'm'.to_int().to_uint16() {
      buf.write_char('M')
      i = i + 1
    } else if ch == 's'.to_int().to_uint16() {
      buf.write_char('S')
      i = i + 1
    } else {
      buf.write_char(ch.to_int().unsafe_to_char())
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// timeadd(timestamp, duration) - Add duration to timestamp
fn fn_timeadd(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (String(ts, _), String(dur_str, _)) =>
      try {
        let dt = parse_rfc3339(ts)
        let iso_dur = hcl_duration_to_iso(dur_str)
        let dur = @time.Duration::from_string(iso_dur)
        let result = dt.add_duration(dur)
        Ok(String(format_rfc3339(result), Decor::empty()))
      } catch {
        _ =>
          Err(HCLError::invalid_value("timeadd: invalid timestamp or duration"))
      }
    _ => Err(HCLError::invalid_value("timeadd: both arguments must be strings"))
  }
}

///|
/// timecmp(t1, t2) - Compare two timestamps
fn fn_timecmp(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (String(t1, _), String(t2, _)) =>
      try {
        let dt1 = parse_rfc3339(t1)
        let dt2 = parse_rfc3339(t2)
        let s1 = dt1.to_unix_second()
        let s2 = dt2.to_unix_second()
        let cmp = if s1 < s2 { -1 } else if s1 > s2 { 1 } else { 0 }
        Ok(Number(Number::from_int(cmp), Decor::empty()))
      } catch {
        _ => Err(HCLError::invalid_value("timecmp: invalid timestamp"))
      }
    _ => Err(HCLError::invalid_value("timecmp: both arguments must be strings"))
  }
}

///| =========================================================================
/// Network Functions (CIDR)

///| =========================================================================

///|
fn find_char(s : String, ch : Char, start : Int) -> Int {
  let len = s.length()
  let mut i = start
  while i < len {
    if s.code_unit_at(i) == ch.to_int().to_uint16() {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn ip_to_int(ip : String) -> HCLResult[Int] {
  let d1 = find_char(ip, '.', 0)
  if d1 < 0 {
    return Err(HCLError::invalid_value("invalid IPv4 address: " + ip))
  }
  let d2 = find_char(ip, '.', d1 + 1)
  if d2 < 0 {
    return Err(HCLError::invalid_value("invalid IPv4 address: " + ip))
  }
  let d3 = find_char(ip, '.', d2 + 1)
  if d3 < 0 {
    return Err(HCLError::invalid_value("invalid IPv4 address: " + ip))
  }
  let s0 = substring(ip, 0, d1)
  let s1 = substring(ip, d1 + 1, d2)
  let s2 = substring(ip, d2 + 1, d3)
  let s3 = substring(ip, d3 + 1, ip.length())
  match
    (
      parse_int_with_base(s0, 10),
      parse_int_with_base(s1, 10),
      parse_int_with_base(s2, 10),
      parse_int_with_base(s3, 10),
    ) {
    (Ok(a), Ok(b), Ok(c), Ok(d)) =>
      if a < 0 ||
        a > 255 ||
        b < 0 ||
        b > 255 ||
        c < 0 ||
        c > 255 ||
        d < 0 ||
        d > 255 {
        Err(HCLError::invalid_value("IPv4 octet out of range: " + ip))
      } else {
        Ok((a << 24) | (b << 16) | (c << 8) | d)
      }
    _ => Err(HCLError::invalid_value("invalid IPv4 address: " + ip))
  }
}

///|
fn int_to_ip(n : Int) -> String {
  let a = (n >> 24) & 0xFF
  let b = (n >> 16) & 0xFF
  let c = (n >> 8) & 0xFF
  let d = n & 0xFF
  a.to_string() +
  "." +
  b.to_string() +
  "." +
  c.to_string() +
  "." +
  d.to_string()
}

///|
fn parse_cidr(cidr : String) -> HCLResult[(Int, Int)] {
  let slash = find_char(cidr, '/', 0)
  if slash < 0 {
    return Err(HCLError::invalid_value("invalid CIDR: " + cidr))
  }
  let ip_str = substring(cidr, 0, slash)
  let prefix_str = substring(cidr, slash + 1, cidr.length())
  match (ip_to_int(ip_str), parse_int_with_base(prefix_str, 10)) {
    (Ok(ip_int), Ok(prefix)) =>
      if prefix < 0 || prefix > 32 {
        Err(HCLError::invalid_value("CIDR prefix out of range: " + cidr))
      } else {
        Ok((ip_int, prefix))
      }
    _ => Err(HCLError::invalid_value("invalid CIDR: " + cidr))
  }
}

///|
fn prefix_to_mask(prefix : Int) -> Int {
  if prefix == 0 {
    0
  } else if prefix == 32 {
    -1
  } else {
    -1 << (32 - prefix)
  }
}

///|
fn fn_cidrhost(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1]) {
    (String(cidr, _), Number(hostnum_n, _)) =>
      match (parse_cidr(cidr), hostnum_n.as_int()) {
        (Ok((ip_int, prefix_len)), Some(hostnum)) => {
          let mask = prefix_to_mask(prefix_len)
          let base = ip_int & mask
          let host_bits = 32 - prefix_len
          let max_hosts = if host_bits == 32 { -1 } else { 1 << host_bits }
          if hostnum < -max_hosts || hostnum >= max_hosts {
            return Err(
              HCLError::invalid_value("cidrhost: host number out of range"),
            )
          }
          let ip = if hostnum >= 0 {
            base + hostnum
          } else {
            base + max_hosts + hostnum
          }
          Ok(String(int_to_ip(ip), Decor::empty()))
        }
        (Err(e), _) => Err(e)
        (_, None) =>
          Err(HCLError::type_error("cidrhost: hostnum must be an integer"))
      }
    _ => Err(HCLError::type_error("cidrhost: expected (string, number)"))
  }
}

///|
fn fn_cidrnetmask(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(s, _) => {
      let prefix_str = if s.length() > 0 &&
        s.code_unit_at(0) == '/'.to_int().to_uint16() {
        substring(s, 1, s.length())
      } else {
        s
      }
      match parse_int_with_base(prefix_str, 10) {
        Ok(prefix) =>
          if prefix < 0 || prefix > 32 {
            Err(
              HCLError::invalid_value("cidrnetmask: prefix out of range 0-32"),
            )
          } else {
            Ok(String(int_to_ip(prefix_to_mask(prefix)), Decor::empty()))
          }
        Err(_) => Err(HCLError::invalid_value("cidrnetmask: invalid prefix"))
      }
    }
    _ => Err(HCLError::type_error("cidrnetmask: expected string"))
  }
}

///|
fn fn_cidrsubnet(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match (args[0], args[1], args[2]) {
    (String(cidr, _), Number(newbits_n, _), Number(netnum_n, _)) =>
      match (parse_cidr(cidr), newbits_n.as_int(), netnum_n.as_int()) {
        (Ok((ip_int, prefix_len)), Some(newbits), Some(netnum)) => {
          let new_prefix = prefix_len + newbits
          if new_prefix < 0 || new_prefix > 32 {
            return Err(
              HCLError::invalid_value("cidrsubnet: new prefix out of range"),
            )
          }
          if newbits <= 0 {
            return Err(
              HCLError::invalid_value("cidrsubnet: newbits must be positive"),
            )
          }
          let max_subnets = 1 << newbits
          if netnum < 0 || netnum >= max_subnets {
            return Err(
              HCLError::invalid_value("cidrsubnet: netnum out of range"),
            )
          }
          let mask = prefix_to_mask(prefix_len)
          let base = ip_int & mask
          let shift = 32 - new_prefix
          let subnet_ip = base | (netnum << shift)
          Ok(
            String(
              int_to_ip(subnet_ip) + "/" + new_prefix.to_string(),
              Decor::empty(),
            ),
          )
        }
        (Err(e), _, _) => Err(e)
        (_, None, _) =>
          Err(HCLError::type_error("cidrsubnet: newbits must be an integer"))
        (_, _, None) =>
          Err(HCLError::type_error("cidrsubnet: netnum must be an integer"))
      }
    _ =>
      Err(HCLError::type_error("cidrsubnet: expected (string, number, number)"))
  }
}

///|
fn fn_cidrsubnets(args : Array[HCLValue]) -> HCLResult[HCLValue] {
  match args[0] {
    String(cidr, _) =>
      match parse_cidr(cidr) {
        Ok((ip_int, prefix_len)) => {
          let results : Array[HCLValue] = Array::new()
          let mask = prefix_to_mask(prefix_len)
          let base = ip_int & mask
          let mut current_base = base
          let total_host_bits = 32 - prefix_len
          let total_hosts = if total_host_bits == 32 {
            -1
          } else {
            1 << total_host_bits
          }
          let end_addr = base + total_hosts
          for i in 1..<args.length() {
            match args[i] {
              Number(newbits_n, _) =>
                match newbits_n.as_int() {
                  Some(newbits) => {
                    if newbits <= 0 {
                      return Err(
                        HCLError::invalid_value(
                          "cidrsubnets: newbits must be positive",
                        ),
                      )
                    }
                    let new_prefix = prefix_len + newbits
                    if new_prefix > 32 {
                      return Err(
                        HCLError::invalid_value(
                          "cidrsubnets: resulting prefix out of range",
                        ),
                      )
                    }
                    let subnet_host_bits = 32 - new_prefix
                    let subnet_size = if subnet_host_bits == 32 {
                      -1
                    } else {
                      1 << subnet_host_bits
                    }
                    if current_base + subnet_size > end_addr {
                      return Err(
                        HCLError::invalid_value(
                          "cidrsubnets: not enough address space",
                        ),
                      )
                    }
                    results.push(
                      String(
                        int_to_ip(current_base) + "/" + new_prefix.to_string(),
                        Decor::empty(),
                      ),
                    )
                    current_base = current_base + subnet_size
                  }
                  None =>
                    return Err(
                      HCLError::type_error(
                        "cidrsubnets: newbits must be an integer",
                      ),
                    )
                }
              _ =>
                return Err(
                  HCLError::type_error("cidrsubnets: newbits must be a number"),
                )
            }
          }
          Ok(Array(results, Decor::empty()))
        }
        Err(e) => Err(e)
      }
    _ =>
      Err(HCLError::type_error("cidrsubnets: first argument must be a string"))
  }
}
