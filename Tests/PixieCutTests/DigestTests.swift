import XCTest
import PixieCut


private var comps = URLComponents()

class DigestTests: XCTestCase {
  let codeDigestPairs = [
    ("oneringtorulethemall", "OJObhU8WALlodzofAP9Q06yP-_XLhVVn9hchGPHO7jk"),
    ("Chip ka Dale nii song pii nong khai khong nai khlong. Nai gong rao mii tae thua di dii peung det sod sod ma kin hai mod.", "FQkjVfuUxBQlibCfetVlFv6_9Rdwfi-X8ZTOFe4qs94"),
    ("I remember you was conflicted, misusing your influence", "8K8uaulT38FfXIVd9xNEj1ObNYKF93NhH9FMDB7MUTw"),
    ("cdePf3jQWJlQEOUQHAAj2rvJIPzuqNSNGbtAEdGNWvxni1s95LAXuLa4clD6aYQ4JdLkEKOVpLXmuURyju3UCYb71r11RQINUz0lQRDmhjeu21fhBMtUcvPIpTZQDX5x", "c7vFcoMwLsoK3nyXlLaz0yzorQVyNiaE8E8AKxbOlZA"),
    ("UnmTB5cfNnDkIZnYAre6q7LwwDfhNAiOQUc6TFFR4KUGaBsyw2T8LPBLo1OFy1FEjwEp6oVgZq0BG4rwj9nzc17QBUU7gG5xPJmsNIS7jcmzbdHUPaSqaKsRYnVaTXX6", "fc5R7Zk700pke6UJKixDfpRvCU5LxXk9bUspdXmg1dk"),
    ("hrjTiTD69iqnI9SLJjBBa0kLJLxo9VaSDIEp4Q3uMJ5sXVnkDdcIxg7m5Dw0124e6VnFdzEyfPU29AUTM8YY4bfQw5mJlXGGd1F0VBYRGvYAErZFFYhUePvfZSYyRNVD", "q_iHVx6Dd-06_5D2qVQTuZkuH8LNyQi9lcGcy0vPCNk"),
  ]

  
  func testDigestPairs() {
    XCTAssert(!codeDigestPairs.isEmpty)
    codeDigestPairs.forEach { code, digest in
      XCTAssertEqual(DigestHelper.base64SHA256(from: code), digest)
    }
  }
}
