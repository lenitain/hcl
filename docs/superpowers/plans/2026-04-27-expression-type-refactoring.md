# Expression Type Safety Refactoring Implementation Plan

> **For agentic workers:** Execute tasks sequentially. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make parser produce `Expression` enum values instead of tagged `HCLValue::Object`, and make eval pattern-match on `Expression` enum.

**Architecture:** The `Expression` enum already exists in `expr.mbt` with 15 variants covering all expression types. Currently parser ignores it and encodes expressions as tagged `HCLValue::Object` maps. This refactoring connects parser → Expression → eval → visitors → serializers through the typed enum.

**Tech Stack:** MoonBit, Flat package (all modules share namespace)

**Files modified (24 total):**
- Core: `body.mbt`, `expr.mbt`, `parser.mbt`, `eval.mbt`
- Visitors: `visit.mbt`, `visit_mut.mbt`
- Serializers: `ser.mbt`, `json.mbt`, `de.mbt`
- Dependents: `template.mbt`, `schema.mbt`, `decorated_expr.mbt`, `funcs.mbt`, `object.mbt`, `trait.mbt`, `builder.mbt`
- Tests (10 files): `expr_test.mbt`, `eval_test.mbt`, `for_test.mbt`, `spec_test.mbt`, `simplify_test.mbt`, `funcs_test.mbt`, `schema_test.mbt`, `template_test.mbt`, `derive_wbtest.mbt`, `formatter_test.mbt`, `ser_decor_test.mbt`, `integration_decor_test.mbt`, `body_decor_test.mbt`, `value_decor_test.mbt`, `object_wbtest.mbt`, etc.

---

### Task 1: Bridge - expr_to_hcl_value + Attr.value type change

**Files:** `expr.mbt`, `body.mbt`

- [ ] **1.1 Add `expr_to_hcl_value` to `expr.mbt`**

Add function that converts Expression → HCLValue (literal variants only):

```moonbit
pub fn expr_to_hcl_value(expr : Expression) -> HCLValue {
  match expr {
    ExprNull => Null(Decor::empty())
    ExprBool(b) => Bool(b, Decor::empty())
    ExprInt(i) => Number(Number::from_int(i), Decor::empty())
    ExprInt64(i) => Number(Number::from_int64(i), Decor::empty())
    ExprFloat(f) => Number(Number::from_finite_f64(f), Decor::empty())
    ExprString(s) => String(s, Decor::empty())
    ExprArray(arr) => {
      let items = arr.map(expr_to_hcl_value)
      Array(items, Decor::empty())
    }
    ExprObject(obj) => {
      let result = {}
      for pair in obj {
        let (k, v) = pair
        result[ObjectKey::to_string(k)] = expr_to_hcl_value(v)
      }
      Object(result, Decor::empty())
    }
    // Non-literal expressions - used for eval, converted when resolved
    ExprTemplate(_) | ExprVariable(_) | ExprTraversal(_) | ExprFuncCall(_) | 
    ExprParenthesis(_) | ExprConditional(_) | ExprOperation(_) | ExprFor(_) => 
      Null(Decor::empty()) // fallback, shouldn't occur in serialization path
  }
}
```

Also add `expression_to_hcl_object` helper for HCLObjectBuilder compatibility:

```moonbit
pub fn expr_to_hcl_object(obj : ExprObject) -> HCLObject {
  let result = {}
  for pair in obj {
    let (k, v) = pair
    result[ObjectKey::to_string(k)] = expr_to_hcl_value(v)
  }
  result
}
```

- [ ] **1.2 Change Attr.value to Expression in `body.mbt`**

```moonbit
struct Attr {
  key : Decorated[String]
  value : Expression
  decor : Decor
}
```

Update all methods:
- `Attr::new(key, value)` — value is now Expression
- `Attr::with_decor(key, value, decor)` — same
- `Attr::get_value(self) -> Expression` — returns Expression
- `Body::add_attr(self, key, value)` — value is Expression

- [ ] **1.3 Update `decorated_expr.mbt`** - no changes needed (works with Expression already)

- [ ] **1.4 Run moon check to verify compilation**

---

### Task 2: Parser produces Expression

**Files:** `parser.mbt`

- [ ] **2.1 Change `parse_value` return type**

```moonbit
fn Parser::parse_value(self : Parser) -> HCLResult[(Expression, Parser)]
```

- [ ] **2.2 Update `parse_primary` return type**

Return `Expression` for all literals:
- `StringLit(s)` → `ExprString(s)` 
- `BoolLit(b)` → `ExprBool(b)`
- `NullLit` → `ExprNull`
- `NumberLit(n)` → parse as `ExprInt` or `ExprFloat`
- `LBracket` → `parse_array` returns `ExprArray`
- `LBrace` → `parse_object` returns `ExprObject`
- `LParen` → returns inner Expression (no wrapper)
- `Minus` → parse as `ExprOperation(UnaryOp(UnaryOperator::Negate, operand))`
- `Bang` → `ExprOperation(UnaryOp(UnaryOperator::Not, operand))`
- `Ident(name)` → check for function call parens, else `ExprVariable`

- [ ] **2.3 Update expression construct functions**

- `parse_ident_expr`: Return `ExprVariable({ name })` (with traversal check)
- `parse_function_call`: Return `ExprFuncCall({ name, args })`
- `parse_property_access`: Return `ExprTraversal` wrapping the base + operators
- `parse_binary_expr`: Return `ExprOperation(BinaryOp({ left, op, right }))`
- `parse_conditional_expr`: Return `ExprConditional({ condition, true_expr, false_expr })`
- `parse_for_expr`: Return `ExprFor(List(...))` or `ExprFor(Object(...))`
- `parse_not`: Return `ExprOperation(UnaryOp(Not, operand))`
- `parse_negative`: Return `ExprOperation(UnaryOp(Negate, Number))`

- [ ] **2.4 Get binary operator from token**

Remove `op_str` string approach, use BinaryOperator enum:
```moonbit
fn token_to_binary_op(token : Token) -> BinaryOperator? {
  match token {
    Plus => Some(Plus)
    Minus => Some(Minus)
    Star => Some(Mul)
    Slash => Some(Div)
    Percent => Some(Mod)
    EqEq => Some(Eq)
    BangEq => Some(Neq)
    Lt => Some(Lt)
    Gt => Some(Gt)
    LtEq => Some(Lte)
    GtEq => Some(Gte)
    AndAnd => Some(And)
    OrOr => Some(Or)
    _ => None
  }
}
```

- [ ] **2.5 Simplify `parse_negative`**

Instead of trying to negate the Number, produce `UnaryOp(Negate, operand)` — let eval handle it. Remove the special-case Number handling.

- [ ] **2.6 Update `parse_array`**

Return `ExprArray` instead of HCLValue::Array.

- [ ] **2.7 Update `parse_object`**

Return `ExprObject` — but wait, current parse_object uses `Map[String, HCLValue]`. Now we need `ExprObject = Array[(ObjectKey, Expression)]`.

The current parse_object builds `obj[key] = value` where key is String and value is HCLValue. Change to build an `Array[(ObjectKey, Expression)]`.

```moonbit
let obj = [] // Array[(ObjectKey, Expression)]
// ...
let key = match parser.current {
  StringLit(s) => ObjectKey::Identifier(s) // actually Identifier only takes String currently
  Ident(s) => ObjectKey::Identifier(s)
}
// ...
obj.push((key, value))
// ...
ExprObject(obj)
```

Wait, `ObjectKey::Identifier(String)` already exists. So for object keys, we use `Identifier(s)`. Good.

- [ ] **2.8 Run moon check to verify**

---

### Task 3: Eval pattern-matches on Expression

**Files:** `eval.mbt`

- [ ] **3.1 Change `eval_expr` signature**

```moonbit
pub fn eval_expr(
  expr : Expression,
  variables : Map[String, HCLValue],
  functions : Map[String, (Array[HCLValue]) -> HCLResult[HCLValue]],
) -> HCLResult[HCLValue]
```

- [ ] **3.2 Replace string-based dispatch with pattern matching**

```moonbit
match expr {
  ExprNull => Ok(Null(Decor::empty()))
  ExprBool(b) => Ok(Bool(b, Decor::empty()))
  ExprInt(i) => Ok(Number(Number::from_int(i), Decor::empty()))
  ExprInt64(i) => Ok(Number(Number::from_int64(i), Decor::empty()))
  ExprFloat(f) => Ok(Number(Number::from_finite_f64(f), Decor::empty()))
  ExprString(s) => Ok(String(s, Decor::empty()))
  ExprArray(arr) => evaluate_array(arr, variables, functions)
  ExprObject(obj) => evaluate_object(obj, variables, functions)
  ExprTemplate(tmpl) => evaluate_template(tmpl, variables, functions)
  ExprVariable(var) => evaluate_variable(var, variables)
  ExprTraversal(trav) => evaluate_traversal(trav, variables, functions)
  ExprFuncCall(fc) => evaluate_func_call(fc, variables, functions)
  ExprParenthesis(inner) => eval_expr(inner, variables, functions)
  ExprConditional(cond) => evaluate_conditional(cond, variables, functions)
  ExprOperation(op) => evaluate_operation(op, variables, functions)
  ExprFor(for_expr) => evaluate_for(for_expr, variables, functions)
}
```

- [ ] **3.3 Update helper functions**

- `evaluate_binary(left, op, right)` — directly use BinaryOperator enum
- `evaluate_unary(op, operand)` — directly use UnaryOperator enum
- All helpers take Expression and return HCLResult[HCLValue]

- [ ] **3.4 Update `simplify_value`**

Change to work on Expression:
```moonbit
fn simplify_expression(expr : Expression) -> Expression {
  match expr {
    ExprOperation(_) | ExprConditional(_) =>
      match eval_expr_simple(expr) {
        Ok(value) => hcl_value_to_expression(value)
        Err(_) => expr
      }
    ExprArray(arr) => ExprArray(arr.map(simplify_expression))
    ExprObject(obj) => {
      let simplified = obj.map(fn((k, v)) { (k, simplify_expression(v)) })
      ExprObject(simplified)
    }
    _ => expr
  }
}
```

Wait, but simplify_body iterates over Attr values and calls simplify_value. If Attr.value is now Expression, simplify needs to work on Expression too.

Actually let's keep a single `simplify_value` that works on **Expression**:

```moonbit
fn simplify_value(expr : Expression) -> Expression {
  match expr {
    // Expressions that can be evaluated at simplify time
    ExprOperation(_) | ExprConditional(_) => {
      match eval_expr_simple(expr) {
        Ok(value) => hcl_value_to_expression(value)
        Err(_) => expr
      }
    }
    ExprArray(arr) => ExprArray(arr.map(simplify_value))
    ExprObject(obj) => {
      let simplified = obj.map(fn((k, v)) { (k, simplify_value(v)) })
      ExprObject(simplified)
    }
    _ => expr
  }
}
```

And need `hcl_value_to_expression`:

```moonbit
fn hcl_value_to_expression(value : HCLValue) -> Expression {
  match value {
    Null(_) => ExprNull
    Bool(b, _) => ExprBool(b)
    Number(n, _) => {
      match n.as_int() {
        Some(i) => ExprInt(i)
        None => {
          match n.as_int64() {
            Some(i64) => ExprInt64(i64)
            None => ExprFloat(n.as_float())
          }
        }
      }
    }
    String(s, _) => ExprString(s)
    Array(arr, _) => ExprArray(arr.map(hcl_value_to_expression))
    Object(obj, _) => {
      let pairs = []
      for k, v in obj {
        pairs.push((ObjectKey::Identifier(k), hcl_value_to_expression(v)))
      }
      ExprObject(pairs)
    }
  }
}
```

- [ ] **3.5 Change `simplify_body` to work with Expression-based Attr**

Call `simplify_value(attr.get_value())` (now returns Expression) and create new Attr with simplified Expression value.

- [ ] **3.6 Run moon check**

---

### Task 4: Bridge - serializers and visitors

**Files:** `ser.mbt`, `json.mbt`, `de.mbt`, `visit.mbt`, `visit_mut.mbt`

- [ ] **4.1 Update `ser.mbt`**

In `format_attr_with_decor`, change `format_value_with_decor(attr.value)` to `format_value_with_decor(expr_to_hcl_value(attr.value))`.

In `format_body`, same change for `attr.get_value()`.

In `Formatter::format_body_impl`, same bridge.

- [ ] **4.2 Update `json.mbt`**

In `body_to_json` and `body_to_json_pretty_impl`, change `attr.get_value()` to `expr_to_hcl_value(attr.get_value())`.

- [ ] **4.3 Update `de.mbt`**

In `body_to_value`, change `attr.get_value()` to `expr_to_hcl_value(attr.get_value())`.

- [ ] **4.4 Update `visit.mbt`**

In `visit_attr_default`, change `v.visit_value(attr.get_value())` to work with the bridge:
```moonbit
pub fn[V : Visit] visit_attr_default(v : V, attr : Attr) -> Unit {
  v.visit_expr(attr.get_value())
}
```

This now calls visit_expr instead of visit_value! The visitor pattern changes from HCLValue dispatch to Expression dispatch.

- [ ] **4.5 Update `visit_mut.mbt`**

Same as visit.mbt:
```moonbit
pub fn[V : VisitMut] visit_attr_mut_default(v : V, attr : Attr) -> Unit {
  v.visit_expr_mut(attr.get_value())
}
```

- [ ] **4.6 Run moon check**

---

### Task 5: Dependent modules

**Files:** `template.mbt`, `funcs.mbt`, `object.mbt`, `trait.mbt`, `builder.mbt`, `schema.mbt`

- [ ] **5.1 Update `template.mbt`**

`parse_template_expression` currently creates `Object({"type": String("variable", _), ...})`. Change to produce `ExprVariable`:

```moonbit
// Old:
Object({"type": String("variable", _), "name": String(trimmed, _)}, _)
// New:
ExprVariable({ name: trimmed })
```

Also `Interpolation(HCLValue)` → `Interpolation(Expression)` in TemplatePart:
```moonbit
enum TemplatePart {
  Text(String)
  Interpolation(Expression)  // was HCLValue
  ConditionalStart(Expression)  // was HCLValue
  ConditionalElse
  ConditionalEnd
  ForStart(String, Expression)  // was HCLValue as second
  ForEnd
}
```

In `Template::evaluate`, change `eval_expr(expr, ...)` calls to pass Expression directly (it now takes Expression).

In `value_to_string`, since template evaluation returns HCLValue (eval output), keep as is.

- [ ] **5.2 Update `funcs.mbt`**

Funcs work with HCLValue (they receive evaluated values from eval_expr). No changes needed - eval_expr still returns HCLValue.

Check: `funcs.mbt` functions take `Array[HCLValue]` and return `HCLResult[HCLValue]`. This is correct because functions operate on *evaluated* values.

- [ ] **5.3 Update `object.mbt`**

HCLObjectBuilder methods build HCLObject/HCLValue. If there's integration with expression types, need conversion. Check if any methods take/return Expression.

- [ ] **5.4 Update `trait.mbt`**

ToHCL/FromHCL traits use HCLValue. No changes needed - they work with the bridge.

- [ ] **5.5 Update `builder.mbt`**

Builder pattern for HCLObject uses HCLValue. No changes needed.

- [ ] **5.6 Update `schema.mbt`**

Schema validation works on HCLValue. In `from_hcl_with_schema`, `body_to_value` already converts Body → HCLValue (via bridge now). No changes needed.

- [ ] **5.7 Run moon check**

---

### Task 6: Tests

- [ ] **6.1 Run all tests** to see what breaks
- [ ] **6.2 Fix test files** that reference tagged Object expressions

Key test files to fix:
- `expr_test.mbt` — creates tagged Object expressions for eval tests
- `eval_test.mbt` — uses HCLValue for eval_binary/eval_unary tests
- `for_test.mbt` — creates tagged Object for_expr tests
- `spec_test.mbt` — may reference HCLValue patterns
- `simplify_test.mbt` — tests simplify_body with HCLValue expectations
- `funcs_test.mbt` — may need adjustments
- `template_test.mbt` — may reference tagged Object patterns
- `ser_decor_test.mbt`, `body_decor_test.mbt`, etc. — decor tests with Attr/Block

Tests that construct parsers output (like `Object({"type": ...})`) need updating to construct Expression directly.

Tests that check `eval_expr` output need updating (eval_expr now takes Expression instead of HCLValue).

- [ ] **6.3 Run all tests: `moon test`**
- [ ] **6.4 Run: `moon check && moon test && moon info && moon fmt`**

---

### Key Design Decisions

1. **Expression carries no decor** — decor is stored at Attr/Block level in the body types, matching hcl-rs design. Parser-created values always use `Decor::empty()`, which is already the case for all tagged Object expressions.

2. **Bridge pattern for serializers** — `expr_to_hcl_value` converts Expression → HCLValue for the existing serializer code. This minimizes changes to ser/de/json modules.

3. **Eval still returns HCLValue** — functions and expression evaluation results produce HCLValue. Only the *unevaluated* expression AST uses Expression. Consumers of eval results (functions, templates) work with HCLValue as before.

4. **Uniform op handling** — `parse_negative` now produces `UnaryOp(Negate, operand)` for any operand (not just Number). The old special casing was wrong for expressions like `-foo()`.
