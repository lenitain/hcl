///|
/// Builder for constructing Body incrementally
pub struct BodyBuilder {
  items : Array[BodyItem]
}

///|
/// Create a new BodyBuilder
pub fn Body::builder() -> BodyBuilder {
  { items: [] }
}

///|
/// Add an attribute with Expression
pub fn BodyBuilder::attr(
  self : BodyBuilder,
  key : String,
  value : Expression,
) -> BodyBuilder {
  self.items.push(
    Attribute({ key: Decorated::bare(key), value, decor: Decor::empty() }),
  )
  self
}

///|
/// Add an attribute from ToHCL value
pub fn[T : ToHCL] BodyBuilder::attr_hcl(
  self : BodyBuilder,
  key : String,
  value : T,
) -> BodyBuilder {
  self.items.push(
    Attribute({
      key: Decorated::bare(key),
      value: hcl_value_to_expression(value.to_hcl()),
      decor: Decor::empty(),
    }),
  )
  self
}

///|
/// Add an attribute conditionally
pub fn BodyBuilder::attr_if(
  self : BodyBuilder,
  key : String,
  value : Expression,
  cond : Bool,
) -> BodyBuilder {
  if cond {
    self.items.push(
      Attribute({ key: Decorated::bare(key), value, decor: Decor::empty() }),
    )
  }
  self
}

///|
/// Add an attribute from Option (skip if None)
pub fn[T : ToHCL] BodyBuilder::attr_option(
  self : BodyBuilder,
  key : String,
  value : T?,
) -> BodyBuilder {
  match value {
    Some(v) =>
      self.items.push(
        Attribute({
          key: Decorated::bare(key),
          value: hcl_value_to_expression(v.to_hcl()),
          decor: Decor::empty(),
        }),
      )
    None => ()
  }
  self
}

///|
/// Add a block
pub fn BodyBuilder::block(self : BodyBuilder, blk : Block) -> BodyBuilder {
  self.items.push(Block(blk))
  self
}

///|
/// Build the Body
pub fn BodyBuilder::build(self : BodyBuilder) -> Body {
  { items: self.items, decor: Decor::empty() }
}

///|
/// Builder for constructing Block incrementally
pub struct BlockBuilder {
  type_name : String
  labels : Array[String]
  items : Array[BodyItem]
}

///|
/// Create a new BlockBuilder
pub fn Block::builder(type_name : String) -> BlockBuilder {
  { type_name, labels: [], items: [] }
}

///|
/// Add a label
pub fn BlockBuilder::label(self : BlockBuilder, lbl : String) -> BlockBuilder {
  self.labels.push(lbl)
  self
}

///|
/// Add an attribute with Expression
pub fn BlockBuilder::attr(
  self : BlockBuilder,
  key : String,
  value : Expression,
) -> BlockBuilder {
  self.items.push(
    Attribute({ key: Decorated::bare(key), value, decor: Decor::empty() }),
  )
  self
}

///|
/// Add an attribute from ToHCL value
pub fn[T : ToHCL] BlockBuilder::attr_hcl(
  self : BlockBuilder,
  key : String,
  value : T,
) -> BlockBuilder {
  self.items.push(
    Attribute({
      key: Decorated::bare(key),
      value: hcl_value_to_expression(value.to_hcl()),
      decor: Decor::empty(),
    }),
  )
  self
}

///|
/// Add an attribute conditionally
pub fn BlockBuilder::attr_if(
  self : BlockBuilder,
  key : String,
  value : Expression,
  cond : Bool,
) -> BlockBuilder {
  if cond {
    self.items.push(
      Attribute({ key: Decorated::bare(key), value, decor: Decor::empty() }),
    )
  }
  self
}

///|
/// Set the body from an existing Body
pub fn BlockBuilder::body(self : BlockBuilder, b : Body) -> BlockBuilder {
  for item in b.get_items() {
    self.items.push(item)
  }
  self
}

///|
/// Build the Block
pub fn BlockBuilder::build(self : BlockBuilder) -> Block {
  {
    type_name: Decorated::bare(self.type_name),
    labels: self.labels.map(Decorated::bare),
    body: { items: self.items, decor: Decor::empty() },
    decor: Decor::empty(),
  }
}
