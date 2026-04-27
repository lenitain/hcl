# Type Unification (#12) Implementation Plan

> **For agentic workers:** Use subagent-driven-development to implement task-by-task.

**Goal:** Implement HCL-compliant type unification for conditional expressions, ensuring branch type compatibility per the HCL spec.

**Architecture:** Add a `unify.mbt` module with a type unification lattice. Modify `eval_conditional` in `eval.mbt` to evaluate both branches, unify their types, and convert values to the common type. Follow the HCL spec rules: Number/String unify to String, Bool/String unify to String, Number/Bool cannot unify (error), Null unifies with anything, Unknown propagates.

**Branch:** `lenitain/feat/type-unification`

---

## HCL Spec Type Unification Rules

From spec.md lines 577-617:
1. Number and Bool both unify with String by preferring String
2. Two collection types of same kind unify by element type
3. List and Set unify by preferring List
4. Map and Object unify by preferring Object
5. Dynamic pseudo-type unifies with any type
6. Null unifies with any type (converts to null of target type)
7. Unification fails if types have no conversion path (e.g., Number + Bool without String)

## Files to Create/Modify

| File | Changes |
|------|---------|
| New: `unify.mbt` | Type unification lattice: `unify_types`, `convert_value` |
| `eval.mbt` | Modify `eval_conditional` + `ExprConditional` handler to unify branch types |
| New: `unify_test.mbt` | Unit tests for unification logic |
| `eval_test.mbt` | Integration tests for conditional type checking |

---

### Task 1: Create `unify.mbt` — Type Unification Lattice

**Files:** Create `unify.mbt`

- [ ] Define `TypeName` enum: `TNull, TBool, TNumber, TString, TArray, TObject, TUnknown`
- [ ] Implement `type_of(v: HCLValue) -> TypeName`
- [ ] Implement `unify_types(a: TypeName, b: TypeName) -> HCLResult[TypeName]` following HCL spec rules
- [ ] Implement `convert_value(v: HCLValue, target: TypeName) -> HCLResult[HCLValue]` for safe conversion
- [ ] Run `moon check`

### Task 2: Modify `eval.mbt` — Conditional Type Unification

**Files:** Modify `eval.mbt:344-356` and `eval.mbt:490-500`

- [ ] In `eval_conditional`: evaluate both branches, call `unify_types`, convert selected branch
- [ ] In `eval_expr ExprConditional`: same logic with lazy evaluation consideration
- [ ] Handle Unknown propagation (if either branch is Unknown, result is Unknown)
- [ ] Handle Null branch (null converts to type of other branch)
- [ ] Run `moon check && moon test`

### Task 3: Write Tests

**Files:** Create `unify_test.mbt`

- [ ] Test `unify_types` for all valid combinations
- [ ] Test `unify_types` for invalid combinations (Number+Bool → error)
- [ ] Test `convert_value` for Number→String, String→Number, Bool→String, etc.
- [ ] Test conditional: `true ? 1 : "hello"` → String("1")
- [ ] Test conditional: `true ? 1 : 2` → Number (same type, no conversion)
- [ ] Test conditional: `true ? 1 : true` → error (Number/Bool incompatible)
- [ ] Test conditional with null: `true ? null : "hello"` → String
- [ ] Test conditional with Unknown: `true ? unknown : 1` → Unknown
- [ ] Run `moon test`

### Task 4: Final Verification

- [ ] `moon check` — 0 errors
- [ ] `moon test` — all tests pass (including new + existing 734)
- [ ] `moon fmt` — passes
- [ ] `moon info` — passes
- [ ] Update PROGRESS.md
