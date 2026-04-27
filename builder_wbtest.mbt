///|
test "Body::builder basic" {
  let body = Body::builder()
    .attr("name", ExprString("test"))
    .attr("port", ExprInt(8080))
    .build()
  assert_eq(body.len(), 2)
  let name_attr = body.find_attr("name")
  assert_true(name_attr is Some(_))
  assert_true(name_attr.unwrap().get_value() is ExprString(_))
  match name_attr.unwrap().get_value() {
    ExprString(s) => assert_eq(s, "test")
    _ => panic()
  }
}

///|
test "Body::builder attr_hcl" {
  let body = Body::builder().attr_hcl("count", 42).build()
  let attr = body.find_attr("count")
  assert_true(attr is Some(_))
  match attr.unwrap().get_value() {
    ExprInt(i) => assert_eq(i, 42)
    _ => panic()
  }
}

///|
test "Body::builder attr_if true" {
  let body = Body::builder().attr_if("key", ExprString("value"), true).build()
  assert_eq(body.len(), 1)
}

///|
test "Body::builder attr_if false" {
  let body = Body::builder().attr_if("key", ExprString("value"), false).build()
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
    .attr("host", ExprString("localhost"))
    .build()
  let body = Body::builder()
    .attr("name", ExprString("app"))
    .block(inner)
    .build()
  assert_eq(body.len(), 2)
}

///|
test "Block::builder basic" {
  let blk = Block::builder("resource")
    .label("aws_s3_bucket")
    .label("my_bucket")
    .attr("bucket", ExprString("my-bucket"))
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
  let blk = Block::builder("server").attr("port", ExprInt(8080)).build()
  assert_eq(blk.get_type_name(), "server")
  assert_eq(blk.get_labels().length(), 0)
}

///|
test "Block::builder attr_hcl" {
  let blk = Block::builder("config").attr_hcl("timeout", 30).build()
  let attr = blk.find_attr("timeout")
  assert_true(attr is Some(_))
  match attr.unwrap().get_value() {
    ExprInt(i) => assert_eq(i, 30)
    _ => panic()
  }
}

///|
test "Block::builder with body" {
  let inner_body = Body::builder()
    .attr("a", ExprInt(1))
    .attr("b", ExprInt(2))
    .build()
  let blk = Block::builder("config").body(inner_body).build()
  assert_eq(blk.get_body().len(), 2)
}

///|
test "builder chain" {
  let builder = Body::builder()
  let b1 = builder.attr("a", ExprInt(1))
  let b2 = b1.attr("b", ExprInt(2))
  let body = b2.build()
  assert_eq(body.len(), 2)
}
