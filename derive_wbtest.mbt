///|
test "config serialization via builder" {
  let body = Body::builder()
    .attr_hcl("host", "localhost")
    .attr_hcl("port", 8080)
    .attr_hcl("debug", true)
    .build()
  let hcl = to_hcl_body(body)
  assert_true(hcl.contains("host"))
  assert_true(hcl.contains("8080"))
  assert_true(hcl.contains("true"))
}

///|
test "nested block serialization" {
  let server_block = Block::builder("server")
    .attr("host", String("localhost"))
    .attr("port", Int(8080))
    .build()
  let body = Body::builder()
    .attr("app_name", String("myapp"))
    .block(server_block)
    .build()
  let hcl = to_hcl_body(body)
  assert_true(hcl.contains("app_name"))
  assert_true(hcl.contains("server"))
  assert_true(hcl.contains("host"))
}

///|
test "to_hcl_str with Map" {
  let config : Map[String, HCLValue] = {
    "host": String("localhost"),
    "port": Int(8080),
    "debug": Bool(false),
  }
  let hcl = to_hcl_str(config)
  assert_true(hcl.contains("host"))
  assert_true(hcl.contains("8080"))
}

///|
test "from_hcl_str to Map" {
  let input = "host = \"localhost\"\nport = 8080"
  let result : HCLResult[Map[String, HCLValue]] = from_hcl_str(input)
  assert_true(result is Ok)
  let m = result.unwrap()
  assert_true(m["host"] == String("localhost"))
  assert_true(m["port"] == Int(8080))
}

///|
test "optional fields in builder" {
  let debug : Bool? = None
  let timeout : Int? = Some(30)
  let body = Body::builder()
    .attr("host", String("localhost"))
    .attr_option("debug", debug)
    .attr_option("timeout", timeout)
    .build()
  assert_eq(body.len(), 2)
  assert_true(body.find_attr("debug") is None)
  assert_true(body.find_attr("timeout") is Some(_))
}

///|
test "complex nested structure" {
  let db_block = Block::builder("database")
    .label("primary")
    .attr("host", String("db.example.com"))
    .attr("port", Int(5432))
    .build()
  let cache_block = Block::builder("cache")
    .attr("driver", String("redis"))
    .attr("ttl", Int(3600))
    .build()
  let body = Body::builder()
    .attr("app_name", String("myapp"))
    .attr("version", String("1.0.0"))
    .block(db_block)
    .block(cache_block)
    .build()
  assert_eq(body.len(), 4)
  let hcl = to_hcl_body(body)
  assert_true(hcl.contains("database"))
  assert_true(hcl.contains("cache"))
  assert_true(hcl.contains("primary"))
}

///|
test "roundtrip Body serialization" {
  let original = Body::builder()
    .attr("name", String("test"))
    .attr("count", Int(42))
    .build()
  let hcl = to_hcl_body(original)
  let parsed = from_hcl_body(hcl)
  assert_true(parsed is Ok)
  let body = parsed.unwrap()
  assert_eq(body.len(), 2)
  assert_true(body.find_attr("name").unwrap().get_value() == String("test"))
  assert_true(body.find_attr("count").unwrap().get_value() == Int(42))
}

///|
test "Array of objects serialization" {
  let items : Array[HCLValue] = [
    Object({ "name": String("a"), "value": Int(1) }),
    Object({ "name": String("b"), "value": Int(2) }),
  ]
  let body = Body::builder().attr("items", Array(items)).build()
  let hcl = to_hcl_body(body)
  assert_true(hcl.contains("items"))
}

///|
test "nested blocks via block body" {
  let inner = Block::builder("inner").attr("key", String("value")).build()
  let inner_body = inner.get_body()
  let middle = Block::builder("middle").body(inner_body).build()
  let body = Body::builder().block(middle).build()
  let hcl = to_hcl_body(body)
  assert_true(hcl.contains("middle"))
  assert_true(hcl.contains("key"))
}

///|
test "empty builder" {
  let body = Body::builder().build()
  assert_eq(body.len(), 0)
  assert_true(body.is_empty())
}

///|
test "Block::builder attr_if conditional" {
  let blk = Block::builder("config")
    .attr("required", String("yes"))
    .attr_if("optional", String("maybe"), true)
    .attr_if("skipped", String("no"), false)
    .build()
  assert_true(blk.find_attr("required") is Some(_))
  assert_true(blk.find_attr("optional") is Some(_))
  assert_true(blk.find_attr("skipped") is None)
}

///|
test "block with multiple labels" {
  let blk = Block::builder("resource")
    .label("aws_instance")
    .label("web")
    .attr("ami", String("ami-12345"))
    .attr("type", String("t2.micro"))
    .build()
  assert_eq(blk.get_type_name(), "resource")
  assert_eq(blk.get_labels().length(), 2)
  assert_eq(blk.get_labels()[0], "aws_instance")
  assert_eq(blk.get_labels()[1], "web")
  let hcl = to_hcl_body(Body::builder().block(blk).build())
  assert_true(hcl.contains("resource"))
  assert_true(hcl.contains("aws_instance"))
  assert_true(hcl.contains("ami-12345"))
}

///|
test "builder with mixed attr types" {
  let body = Body::builder()
    .attr_hcl("name", "myapp")
    .attr_hcl("count", 42)
    .attr_hcl("enabled", true)
    .attr_hcl("ratio", 3.14)
    .attr("null_val", Null)
    .build()
  assert_eq(body.len(), 5)
  let hcl = to_hcl_body(body)
  assert_true(hcl.contains("name"))
  assert_true(hcl.contains("42"))
  assert_true(hcl.contains("true"))
  assert_true(hcl.contains("null"))
}

///|
test "roundtrip body serialization" {
  let original = Body::builder()
    .attr("host", String("localhost"))
    .attr("port", Int(8080))
    .build()
  let hcl = to_hcl_body(original)
  let parsed = from_hcl_body(hcl)
  assert_true(parsed is Ok)
  let body = parsed.unwrap()
  assert_eq(body.len(), 2)
  let host_attr = body.find_attr("host")
  assert_true(host_attr is Some(_))
  assert_eq(host_attr.unwrap().get_value().as_string(), Some("localhost"))
  let port_attr = body.find_attr("port")
  assert_true(port_attr is Some(_))
  assert_eq(port_attr.unwrap().get_value().as_int(), Some(8080))
}

///|
test "block with merged body" {
  let source_body = Body::builder()
    .attr("key", String("value"))
    .attr("count", Int(10))
    .build()
  let blk = Block::builder("config")
    .body(source_body)
    .attr("extra", String("data"))
    .build()
  assert_eq(blk.get_body().len(), 3)
  let hcl = to_hcl_body(Body::builder().block(blk).build())
  assert_true(hcl.contains("config"))
  assert_true(hcl.contains("key"))
  assert_true(hcl.contains("extra"))
}

///|
test "Body::find_blocks multiple" {
  let blk1 = Block::builder("server").attr("port", Int(8080)).build()
  let blk2 = Block::builder("server").attr("port", Int(8081)).build()
  let body = Body::builder().block(blk1).block(blk2).build()
  let servers = body.find_blocks("server")
  assert_eq(servers.length(), 2)
}

///|
test "attr_if on BodyBuilder" {
  let body = Body::builder()
    .attr_if("a", Int(1), true)
    .attr_if("b", Int(2), false)
    .attr_if("c", Int(3), true)
    .build()
  assert_eq(body.len(), 2)
  assert_true(body.find_attr("a") is Some(_))
  assert_true(body.find_attr("b") is None)
  assert_true(body.find_attr("c") is Some(_))
}

///|
test "roundtrip with nested block" {
  let blk = Block::builder("database")
    .label("primary")
    .attr("host", String("db.local"))
    .attr("port", Int(5432))
    .build()
  let original = Body::builder().attr("app", String("myapp")).block(blk).build()
  let hcl = to_hcl_body(original)
  let parsed = from_hcl_body(hcl)
  assert_true(parsed is Ok)
  let body = parsed.unwrap()
  assert_true(body.find_attr("app") is Some(_))
  let db_blocks = body.find_blocks("database")
  assert_eq(db_blocks.length(), 1)
}
