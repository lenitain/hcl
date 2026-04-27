///|
/// HCL Body - top-level container for attributes and blocks with decoration
pub struct Body {
  items : Array[BodyItem]
  decor : Decor
  span : Span?
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
/// HCL Attribute - key-value pair with decoration
pub struct Attr {
  key : Decorated[String]
  value : Spanned[Expression]
  decor : Decor
} derive(Debug, Eq)

///|
/// HCL Block - named container with optional labels and decoration
pub struct Block {
  type_name : Decorated[String]
  labels : Array[Decorated[String]]
  body : Body
  decor : Decor
  span : Span?
} derive(Debug, Eq)

///|
/// Create a new empty Body with decoration
pub fn Body::new() -> Body {
  { items: [], decor: Decor::empty(), span: None }
}

///|
/// Create a Body from items with decoration
pub fn Body::from_items(items : Array[BodyItem]) -> Body {
  { items, decor: Decor::empty(), span: None }
}

///|
/// Create a Body with full decoration
pub fn Body::with_decor(items : Array[BodyItem], decor : Decor) -> Body {
  { items, decor, span: None }
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
/// Get body decoration
pub fn Body::get_decor(self : Body) -> Decor {
  self.decor
}

///|
/// Set span on body
pub fn Body::set_span(self : Body, span : Span) -> Body {
  { items: self.items, decor: self.decor, span: Some(span) }
}

///|
/// Get body span
pub fn Body::get_span(self : Body) -> Span? {
  self.span
}

///|
/// Add an attribute to the body (returns new body)
pub fn Body::add_attr(self : Body, key : String, value : Expression) -> Body {
  let new_items = self.items.copy()
  new_items.push(
    Attribute({
      key: Decorated::bare(key),
      value: Spanned::bare(value),
      decor: Decor::empty(),
    }),
  )
  { items: new_items, decor: self.decor, span: self.span }
}

///|
/// Add a block to the body (returns new body)
pub fn Body::add_block(self : Body, block : Block) -> Body {
  let new_items = self.items.copy()
  new_items.push(Block(block))
  { items: new_items, decor: self.decor, span: self.span }
}

///|
/// Find an attribute by key
pub fn Body::find_attr(self : Body, key : String) -> Attr? {
  for item in self.items {
    match item {
      Attribute(attr) if attr.key.get_value() == key => return Some(attr)
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
      Block(block) if block.type_name.get_value() == type_name =>
        result.push(block)
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
      Block(block) if block.type_name.get_value() == type_name =>
        return Some(block)
      _ => ()
    }
  }
  None
}

///|
/// Create a new attribute with decoration
pub fn Attr::new(key : String, value : Expression) -> Attr {
  {
    key: Decorated::bare(key),
    value: Spanned::bare(value),
    decor: Decor::empty(),
  }
}

///|
/// Create a new attribute with full decoration
pub fn Attr::with_decor(
  key : Decorated[String],
  value : Spanned[Expression],
  decor : Decor,
) -> Attr {
  { key, value, decor }
}

///|
/// Get attribute key
pub fn Attr::get_key(self : Attr) -> String {
  self.key.get_value()
}

///|
/// Get attribute key with decoration
pub fn Attr::get_decorated_key(self : Attr) -> Decorated[String] {
  self.key
}

///|
/// Get attribute decoration
pub fn Attr::get_decor(self : Attr) -> Decor {
  self.decor
}

///|
/// Get attribute value
pub fn Attr::get_value(self : Attr) -> Expression {
  self.value.unwrap()
}

///|
/// Get attribute spanned value
pub fn Attr::get_spanned_value(self : Attr) -> Spanned[Expression] {
  self.value
}

///|
/// Set span on attribute value
pub fn Attr::set_span(self : Attr, span : Span) -> Attr {
  {
    key: self.key,
    value: Spanned::new(self.value.unwrap(), span),
    decor: self.decor,
  }
}

///|
/// Create a new block with decoration
pub fn Block::new(
  type_name : String,
  labels : Array[String],
  body : Body,
) -> Block {
  {
    type_name: Decorated::bare(type_name),
    labels: labels.map(Decorated::bare),
    body,
    decor: Decor::empty(),
    span: None,
  }
}

///|
/// Create a new block with full decoration
pub fn Block::with_decor(
  type_name : Decorated[String],
  labels : Array[Decorated[String]],
  body : Body,
  decor : Decor,
) -> Block {
  { type_name, labels, body, decor, span: None }
}

///|
/// Create a block without labels
pub fn Block::simple(type_name : String, body : Body) -> Block {
  {
    type_name: Decorated::bare(type_name),
    labels: [],
    body,
    decor: Decor::empty(),
    span: None,
  }
}

///|
/// Get block type name
pub fn Block::get_type_name(self : Block) -> String {
  self.type_name.get_value()
}

///|
/// Get block type name with decoration
pub fn Block::get_decorated_type_name(self : Block) -> Decorated[String] {
  self.type_name
}

///|
/// Get block decoration
pub fn Block::get_decor(self : Block) -> Decor {
  self.decor
}

///|
/// Set span on block
pub fn Block::set_span(self : Block, span : Span) -> Block {
  {
    type_name: self.type_name,
    labels: self.labels,
    body: self.body,
    decor: self.decor,
    span: Some(span),
  }
}

///|
/// Get block span
pub fn Block::get_span(self : Block) -> Span? {
  self.span
}

///|
/// Get block labels
pub fn Block::get_labels(self : Block) -> Array[String] {
  self.labels.map(fn(l) { l.get_value() })
}

///|
/// Get block labels with decoration
pub fn Block::get_decorated_labels(self : Block) -> Array[Decorated[String]] {
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
