///|
/// Tests for HCLObject type, builder, and utility functions
test "new_hcl_object creates empty object" {
  let obj = new_hcl_object()
  assert_true(obj.is_empty())
  assert_eq(obj.length(), 0)
}

///|
test "hcl_object_from_pairs creates ordered object" {
  let obj = hcl_object_from_pairs([
    ("z", HCLValue::int(1)),
    ("a", HCLValue::int(2)),
    ("m", HCLValue::int(3)),
  ])
  assert_eq(obj.length(), 3)
  assert_true(obj["z"] == HCLValue::int(1))
  assert_true(obj["a"] == HCLValue::int(2))
  assert_true(obj["m"] == HCLValue::int(3))
}

///|
test "hcl_object_from_pairs preserves insertion order" {
  let obj = hcl_object_from_pairs([
    ("third", HCLValue::int(3)),
    ("first", HCLValue::int(1)),
    ("second", HCLValue::int(2)),
  ])
  let keys = hcl_object_keys(obj)
  assert_eq(keys, ["third", "first", "second"])
}

///|
test "hcl_object_keys returns keys in order" {
  let obj = hcl_object_from_pairs([
    ("c", HCLValue::string("gamma")),
    ("a", HCLValue::string("alpha")),
    ("b", HCLValue::string("beta")),
  ])
  assert_eq(hcl_object_keys(obj), ["c", "a", "b"])
}

///|
test "hcl_object_values returns values in order" {
  let obj = hcl_object_from_pairs([
    ("x", HCLValue::int(10)),
    ("y", HCLValue::int(20)),
    ("z", HCLValue::int(30)),
  ])
  let values = hcl_object_values(obj)
  assert_eq(values.length(), 3)
  assert_true(values[0] == HCLValue::int(10))
  assert_true(values[1] == HCLValue::int(20))
  assert_true(values[2] == HCLValue::int(30))
}

///|
test "hcl_object_entries returns pairs in order" {
  let obj = hcl_object_from_pairs([
    ("b", HCLValue::bool(true)),
    ("a", HCLValue::bool(false)),
  ])
  let entries = hcl_object_entries(obj)
  assert_eq(entries.length(), 2)
  assert_eq(entries[0].0, "b")
  assert_true(entries[0].1 == HCLValue::bool(true))
  assert_eq(entries[1].0, "a")
  assert_true(entries[1].1 == HCLValue::bool(false))
}

///|
test "hcl_object_merge merges two objects" {
  let lhs = hcl_object_from_pairs([
    ("a", HCLValue::int(1)),
    ("b", HCLValue::int(2)),
  ])
  let rhs = hcl_object_from_pairs([
    ("b", HCLValue::int(99)),
    ("c", HCLValue::int(3)),
  ])
  let merged = hcl_object_merge(lhs, rhs)
  assert_eq(merged.length(), 3)
  assert_true(merged["a"] == HCLValue::int(1))
  assert_true(merged["b"] == HCLValue::int(99))
  assert_true(merged["c"] == HCLValue::int(3))
}

///|
test "hcl_object_merge preserves lhs order then adds rhs" {
  let lhs = hcl_object_from_pairs([
    ("z", HCLValue::int(1)),
    ("a", HCLValue::int(2)),
  ])
  let rhs = hcl_object_from_pairs([("m", HCLValue::int(3))])
  let merged = hcl_object_merge(lhs, rhs)
  assert_eq(hcl_object_keys(merged), ["z", "a", "m"])
}

///|
test "hcl_object_merge with empty objects" {
  let empty = new_hcl_object()
  let obj = hcl_object_from_pairs([("x", HCLValue::int(1))])

  let r1 = hcl_object_merge(empty, obj)
  assert_true(r1["x"] == HCLValue::int(1))

  let r2 = hcl_object_merge(obj, empty)
  assert_true(r2["x"] == HCLValue::int(1))
}

///|
test "hcl_object_extend mutates object" {
  let obj = hcl_object_from_pairs([("a", HCLValue::int(1))])
  let other = hcl_object_from_pairs([("b", HCLValue::int(2))])
  hcl_object_extend(obj, other)
  assert_eq(obj.length(), 2)
  assert_true(obj["a"] == HCLValue::int(1))
  assert_true(obj["b"] == HCLValue::int(2))
}

///|
test "hcl_object_extend overrides existing keys" {
  let obj = hcl_object_from_pairs([("a", HCLValue::int(1))])
  let other = hcl_object_from_pairs([("a", HCLValue::int(99))])
  hcl_object_extend(obj, other)
  assert_eq(obj.length(), 1)
  assert_true(obj["a"] == HCLValue::int(99))
}

///|
test "HCLObjectBuilder builds object with entries" {
  let obj = HCLObjectBuilder::new()
    .entry("name", HCLValue::string("Alice"))
    .entry("age", HCLValue::int(30))
    .build()
  assert_eq(obj.length(), 2)
  assert_true(obj["name"] == HCLValue::string("Alice"))
  assert_true(obj["age"] == HCLValue::int(30))
}

///|
test "HCLObjectBuilder preserves insertion order" {
  let obj = HCLObjectBuilder::new()
    .entry("z", HCLValue::int(1))
    .entry("a", HCLValue::int(2))
    .entry("m", HCLValue::int(3))
    .build()
  assert_eq(hcl_object_keys(obj), ["z", "a", "m"])
}

///|
test "HCLObjectBuilder entry_if adds conditionally" {
  let obj = HCLObjectBuilder::new()
    .entry("always", HCLValue::int(1))
    .entry_if("yes", HCLValue::int(2), true)
    .entry_if("no", HCLValue::int(3), false)
    .build()
  assert_eq(obj.length(), 2)
  assert_true(obj["yes"] == HCLValue::int(2))
}

///|
test "HCLObjectBuilder entry_hcl adds from ToHCL value" {
  let obj = HCLObjectBuilder::new()
    .entry("name", HCLValue::string("test"))
    .entry_hcl("count", 42)
    .build()
  assert_eq(obj.length(), 2)
  assert_true(obj["count"] == HCLValue::int(42))
}

///|
test "HCLObjectBuilder entry_option adds from option" {
  let some_val : Int? = Some(42)
  let none_val : Int? = None
  let obj = HCLObjectBuilder::new()
    .entry_option("present", some_val)
    .entry_option("missing", none_val)
    .build()
  assert_eq(obj.length(), 1)
  assert_true(obj["present"] == HCLValue::int(42))
}

///|
test "HCLObjectBuilder extend merges objects" {
  let base = hcl_object_from_pairs([("a", HCLValue::int(1))])
  let obj = HCLObjectBuilder::new()
    .extend(base)
    .entry("b", HCLValue::int(2))
    .build()
  assert_eq(obj.length(), 2)
  assert_true(obj["a"] == HCLValue::int(1))
  assert_true(obj["b"] == HCLValue::int(2))
}

///|
test "HCLObject works with HCLValue::object constructor" {
  let obj = hcl_object_from_pairs([("key", HCLValue::string("value"))])
  let val = HCLValue::object(obj)
  assert_true(val.is_object())
  match val {
    Object(o, _) => assert_true(o["key"] == HCLValue::string("value"))
    _ => panic()
  }
}

///|
test "HCLObject roundtrip with serialization" {
  let obj = hcl_object_from_pairs([
    ("name", HCLValue::string("test")),
    ("count", HCLValue::int(42)),
  ])
  let val = HCLValue::object(obj)
  let formatted = to_hcl_value(val)
  assert_true(formatted.length() > 0)
}

///|
test "HCLObject with nested objects" {
  let inner = hcl_object_from_pairs([("x", HCLValue::int(1))])
  let outer = hcl_object_from_pairs([
    ("inner", HCLValue::object(inner)),
    ("top", HCLValue::string("level")),
  ])
  assert_eq(outer.length(), 2)
  match outer["inner"] {
    Object(o, _) => assert_true(o["x"] == HCLValue::int(1))
    _ => panic()
  }
}

///|
test "HCLObject with empty object serializes to {}" {
  let empty = new_hcl_object()
  let val = HCLValue::object(empty)
  let formatted = to_hcl_value(val)
  assert_eq(formatted, "{}")
}

///|
test "HCLObject empty keys and values" {
  let obj = new_hcl_object()
  let keys = hcl_object_keys(obj)
  let values = hcl_object_values(obj)
  let entries = hcl_object_entries(obj)
  assert_eq(keys.length(), 0)
  assert_eq(values.length(), 0)
  assert_eq(entries.length(), 0)
}
