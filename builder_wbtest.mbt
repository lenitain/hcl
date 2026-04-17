///|
test "Body::builder basic" {
  let body = Body::builder()
    .attr("name", String("test", Decor::empty()))
    .attr("port", Int(8080, Decor::empty()))
    .build()
  assert_eq(body.len(), 2)
  let name_attr = body.find_attr("name")
  assert_true(name_attr is Some(_))
  assert_eq(name_attr.unwrap().get_value().is_string(), true)
  assert_eq(name_attr.unwrap().get_value().as_string(), Some("test"))
}

///|
test "Body::builder attr_hcl" {
  let body = Body::builder().attr_hcl("count", 42).build()
  let attr = body.find_attr("count")
  assert_true(attr is Some(_))
  assert_eq(attr.unwrap().get_value().as_int(), Some(42))
}

///|
test "Body::builder attr_if true" {
  let body = Body::builder()
    .attr_if("key", String("value", Decor::empty()), true)
    .build()
  assert_eq(body.len(), 1)
}

///|
test "Body::builder attr_if false" {
  let body = Body::builder()
    .attr_if("key", String("value", Decor::empty()), false)
    .build()
  assert_eq(body.len(), 0)
}

///|
test "Body::builder attr_option Some" {
  let body = Body::builder().attr_option("key", Some("value")).build()
  assert_eq(body.len(), 1)
}

///|
test "Body::builder attr_option None" {
  let body = Body::builder().attr_option("key", (None : String?)).build()
  assert_eq(body.len(), 0)
}

///|
test "Body::builder with block" {
  let inner = Block::builder("server")
    .attr("host", String("localhost", Decor::empty()))
    .build()
  let body = Body::builder()
    .attr("name", String("app", Decor::empty()))
    .block(inner)
    .build()
  assert_eq(body.len(), 2)
}

///|
test "Block::builder basic" {
  let blk = Block::builder("resource")
    .label("aws_s3_bucket")
    .label("my_bucket")
    .attr("bucket", String("my-bucket", Decor::empty()))
    .build()
  assert_eq(blk.get_type_name(), "resource")
  assert_eq(blk.get_labels().length(), 2)
  assert_eq(blk.get_labels()[0], "aws_s3_bucket")
  assert_eq(blk.get_labels()[1], "my_bucket")
  let attr = blk.find_attr("bucket")
  assert_true(attr is Some(_))
}

///|
test "Block::builder no labels" {
  let blk = Block::builder("server")
    .attr("port", Int(8080, Decor::empty()))
    .build()
  assert_eq(blk.get_type_name(), "server")
  assert_eq(blk.get_labels().length(), 0)
}

///|
test "Block::builder attr_hcl" {
  let blk = Block::builder("config").attr_hcl("timeout", 30).build()
  let attr = blk.find_attr("timeout")
  assert_true(attr is Some(_))
  assert_eq(attr.unwrap().get_value().as_int(), Some(30))
}

///|
test "Block::builder with body" {
  let inner_body = Body::builder()
    .attr("a", Int(1, Decor::empty()))
    .attr("b", Int(2, Decor::empty()))
    .build()
  let blk = Block::builder("config").body(inner_body).build()
  assert_eq(blk.get_body().len(), 2)
}

///|
test "builder chain" {
  let builder = Body::builder()
  let b1 = builder.attr("a", Int(1, Decor::empty()))
  let b2 = b1.attr("b", Int(2, Decor::empty()))
  let body = b2.build()
  assert_eq(body.len(), 2)
}
