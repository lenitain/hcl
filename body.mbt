///|
/// HCL Body - top-level container for attributes and blocks
pub struct Body {
  items : Array[BodyItem]
} derive(Debug, Eq)

///|
/// Body item can be either an attribute or a block
pub(all) enum BodyItem {
  /// Key-value attribute
  Attribute(Attr)
  /// Named block with labels
  Block(Block)
} derive(Debug, Eq)

///|
/// HCL Attribute - key-value pair
pub struct Attr {
  key : String
  value : HCLValue
} derive(Debug, Eq)

///|
/// HCL Block - named container with optional labels
pub struct Block {
  type_name : String
  labels : Array[String]
  body : Body
} derive(Debug, Eq)

///|
/// Create a new empty Body
pub fn Body::new() -> Body {
  { items: [] }
}

///|
/// Create a Body from items
pub fn Body::from_items(items : Array[BodyItem]) -> Body {
  { items: items }
}

///|
/// Get the items of the body
pub fn Body::get_items(self : Body) -> Array[BodyItem] {
  self.items
}

///|
/// Get the number of items in the body
pub fn Body::len(self : Body) -> Int {
  self.items.length()
}

///|
/// Check if body is empty
pub fn Body::is_empty(self : Body) -> Bool {
  self.items.is_empty()
}

///|
/// Add an attribute to the body (returns new body)
pub fn Body::add_attr(self : Body, key : String, value : HCLValue) -> Body {
  let new_items = self.items.copy()
  new_items.push(Attribute({ key: key, value: value }))
  { items: new_items }
}

///|
/// Add a block to the body (returns new body)
pub fn Body::add_block(self : Body, block : Block) -> Body {
  let new_items = self.items.copy()
  new_items.push(Block(block))
  { items: new_items }
}

///|
/// Find an attribute by key
pub fn Body::find_attr(self : Body, key : String) -> Attr? {
  for item in self.items {
    match item {
      Attribute(attr) if attr.key == key => return Some(attr)
      _ => ()
    }
  }
  None
}

///|
/// Find all blocks of a given type
pub fn Body::find_blocks(self : Body, type_name : String) -> Array[Block] {
  let result = []
  for item in self.items {
    match item {
      Block(block) if block.type_name == type_name => result.push(block)
      _ => ()
    }
  }
  result
}

///|
/// Find first block of a given type
pub fn Body::find_block(self : Body, type_name : String) -> Block? {
  for item in self.items {
    match item {
      Block(block) if block.type_name == type_name => return Some(block)
      _ => ()
    }
  }
  None
}

///|
/// Create a new attribute
pub fn Attr::new(key : String, value : HCLValue) -> Attr {
  { key: key, value: value }
}

///|
/// Get attribute key
pub fn Attr::get_key(self : Attr) -> String {
  self.key
}

///|
/// Get attribute value
pub fn Attr::get_value(self : Attr) -> HCLValue {
  self.value
}

///|
/// Create a new block
pub fn Block::new(type_name : String, labels : Array[String], body : Body) -> Block {
  { type_name: type_name, labels: labels, body: body }
}

///|
/// Create a block without labels
pub fn Block::simple(type_name : String, body : Body) -> Block {
  { type_name: type_name, labels: [], body: body }
}

///|
/// Get block type name
pub fn Block::get_type_name(self : Block) -> String {
  self.type_name
}

///|
/// Get block labels
pub fn Block::get_labels(self : Block) -> Array[String] {
  self.labels
}

///|
/// Get block body
pub fn Block::get_body(self : Block) -> Body {
  self.body
}

///|
/// Find an attribute in block body
pub fn Block::find_attr(self : Block, key : String) -> Attr? {
  self.body.find_attr(key)
}
