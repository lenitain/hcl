///|
/// HCL Object type - ordered map of string keys to HCL values.
///
/// Preserves insertion order (like indexmap::IndexMap in hcl-rs).
pub type HCLObject = Map[String, HCLValue]

///|
/// Create an empty HCLObject
pub fn new_hcl_object() -> HCLObject {
  {}
}

///|
/// Create HCLObject from array of key-value pairs
pub fn hcl_object_from_pairs(pairs : Array[(String, HCLValue)]) -> HCLObject {
  let obj : HCLObject = {}
  for pair in pairs {
    obj[pair.0] = pair.1
  }
  obj
}

///|
/// Get keys in insertion order
pub fn hcl_object_keys(obj : HCLObject) -> Array[String] {
  let result = []
  for k, _ in obj {
    result.push(k)
  }
  result
}

///|
/// Get values in insertion order
pub fn hcl_object_values(obj : HCLObject) -> Array[HCLValue] {
  let result = []
  for _, v in obj {
    result.push(v)
  }
  result
}

///|
/// Get key-value pairs in insertion order
pub fn hcl_object_entries(obj : HCLObject) -> Array[(String, HCLValue)] {
  let result = []
  for k, v in obj {
    result.push((k, v))
  }
  result
}

///|
/// Merge two objects. Keys from rhs override keys from lhs.
pub fn hcl_object_merge(lhs : HCLObject, rhs : HCLObject) -> HCLObject {
  let result : HCLObject = {}
  for k, v in lhs {
    result[k] = v
  }
  for k, v in rhs {
    result[k] = v
  }
  result
}

///|
/// Extend obj with entries from another object (mutates obj)
pub fn hcl_object_extend(obj : HCLObject, other : HCLObject) -> Unit {
  for k, v in other {
    obj[k] = v
  }
}

///|
/// Builder for constructing HCLObject incrementally
pub struct HCLObjectBuilder {
  obj : HCLObject
}

///|
/// Create a new HCLObjectBuilder
pub fn HCLObjectBuilder::new() -> HCLObjectBuilder {
  { obj: {} }
}

///|
/// Add a key-value pair
pub fn HCLObjectBuilder::entry(
  self : HCLObjectBuilder,
  key : String,
  value : HCLValue,
) -> HCLObjectBuilder {
  self.obj[key] = value
  self
}

///|
/// Add a key-value pair from ToHCL value
pub fn[T : ToHCL] HCLObjectBuilder::entry_hcl(
  self : HCLObjectBuilder,
  key : String,
  value : T,
) -> HCLObjectBuilder {
  self.obj[key] = value.to_hcl()
  self
}

///|
/// Add a key-value pair conditionally
pub fn HCLObjectBuilder::entry_if(
  self : HCLObjectBuilder,
  key : String,
  value : HCLValue,
  cond : Bool,
) -> HCLObjectBuilder {
  if cond {
    self.obj[key] = value
  }
  self
}

///|
/// Add a key-value pair from Option (skip if None)
pub fn[T : ToHCL] HCLObjectBuilder::entry_option(
  self : HCLObjectBuilder,
  key : String,
  value : T?,
) -> HCLObjectBuilder {
  match value {
    Some(v) => self.obj[key] = v.to_hcl()
    None => ()
  }
  self
}

///|
/// Add all entries from another HCLObject
pub fn HCLObjectBuilder::extend(
  self : HCLObjectBuilder,
  other : HCLObject,
) -> HCLObjectBuilder {
  for k, v in other {
    self.obj[k] = v
  }
  self
}

///|
/// Build the HCLObject
pub fn HCLObjectBuilder::build(self : HCLObjectBuilder) -> HCLObject {
  self.obj
}
