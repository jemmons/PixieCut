import XCTest
import Foundation
import PixieCut



class FormURLEncodedTests: XCTestCase {
  // MARK: - OAuth Example
  // Characters specifically called out in the OAuth docs: https://tools.ietf.org/html/rfc6749#appendix-B
  func testOAuthExampleString() {
    let subject = try! FormURLEncoded(encodedString: "+%25%26%2B%C2%A3%E2%82%AC")
    XCTAssertEqual(subject.encoded, "+%25%26%2B%C2%A3%E2%82%AC")
    XCTAssertEqual(subject.decodeString(), " %&+£€")
    XCTAssertEqual(subject.decodeItems(), [URLQueryItem(name:" %&+£€", value: nil)])
  }
  
  
  func testOAuthExampleData() {
    let subject = try! FormURLEncoded(encodedData: Data("+%25%26%2B%C2%A3%E2%82%AC".utf8))
    XCTAssertEqual(subject.encoded, "+%25%26%2B%C2%A3%E2%82%AC")
    XCTAssertEqual(subject.decodeString(), " %&+£€")
    XCTAssertEqual(subject.decodeItems(), [URLQueryItem(name:" %&+£€", value: nil)])
  }

  
  func testOAuthExampleQuery() {
    let subject = FormURLEncoded(items: [URLQueryItem(name:" %&+£€", value: " %&+£€")])
    XCTAssertEqual(subject.encoded, "+%25%26%2B%C2%A3%E2%82%AC=+%25%26%2B%C2%A3%E2%82%AC")
    XCTAssertEqual(subject.decodeString(), " %&+£€= %&+£€", "Invalid query. Don’t do this.")
    XCTAssertEqual(subject.decodeItems(), [URLQueryItem(name:" %&+£€", value: " %&+£€")])
  }

  
  // MARK: - Query format stuff
  func testQueryDelimiterEncoding() {
    let subject = FormURLEncoded(items: [
      URLQueryItem(name: "1&=", value: "2&="),
      URLQueryItem(name: "3&=", value: "4&="),
    ])
    XCTAssertEqual(subject.encoded, "1%26%3D=2%26%3D&3%26%3D=4%26%3D")
    XCTAssertEqual(subject.decodeString(), "1&==2&=&3&==4&=", "Invalid query. Don’t do this.")
    XCTAssertEqual(subject.decodeItems(), [
      URLQueryItem(name: "1&=", value: "2&="),
      URLQueryItem(name: "3&=", value: "4&="),
    ])
  }
  
  
  func testValueOnly() {
    let subject = FormURLEncoded(items: [
      URLQueryItem(name: "1 %&+£€", value: nil),
      URLQueryItem(name: "2 %&+£€", value: nil),
    ])
    XCTAssertEqual(subject.encoded, "1+%25%26%2B%C2%A3%E2%82%AC&2+%25%26%2B%C2%A3%E2%82%AC")
    XCTAssertEqual(subject.decodeString(), "1 %&+£€&2 %&+£€", "Invalid query. Don’t do this.")
    XCTAssertEqual(subject.decodeItems(), [
      URLQueryItem(name: "1 %&+£€", value: nil),
      URLQueryItem(name: "2 %&+£€", value: nil),
    ])
  }
  

  
  // MARK: - Empty encodings
  func testEmptyString() {
    let subject = try! FormURLEncoded(encodedString: "")
    XCTAssert(subject.encoded.isEmpty)
    XCTAssert(subject.decodeString().isEmpty)
    XCTAssert(subject.decodeItems().isEmpty)
  }
  
  
  func testEmptyData() {
    let subject = try! FormURLEncoded(encodedData: Data(capacity: 0))
    XCTAssert(subject.encoded.isEmpty)
    XCTAssert(subject.decodeString().isEmpty)
    XCTAssert(subject.decodeItems().isEmpty)
  }
  
  
  func testEmptyQuery() {
    let subject = FormURLEncoded(items: [])
    XCTAssert(subject.encoded.isEmpty)
    XCTAssert(subject.decodeString().isEmpty)
    XCTAssert(subject.decodeItems().isEmpty)
  }
  
  
  // MARK: - Errors
  func testInvalidPercentEncoding() {
    let shouldThrow = expectation(description: "Waiting for error.")
    let invalidPercentEncoding = "%%"
    do {
      _ = try FormURLEncoded(encodedString: invalidPercentEncoding)
    } catch {
      switch error {
      case FormURLEncoded.Error.invalidPercentEncoding:
        XCTAssertEqual(error.localizedDescription, "The content is not in x-www-form-urlencoded format.")
        XCTAssertEqual((error as NSError).localizedFailureReason, "Encoding Error")
        shouldThrow.fulfill()
      default:
        XCTFail()
      }
    }
    wait(for: [shouldThrow], timeout: 0)
  }
  
  
  func testInvalidUTF8Encoding() {
    let shouldThrow = expectation(description: "Waiting for error.")
    let invalidUTF8 = Data([0xC3])
    do {
      _ = try FormURLEncoded(encodedData: invalidUTF8)
    } catch {
      switch error {
      case FormURLEncoded.Error.invalidUTF8Encoding:
        XCTAssertEqual(error.localizedDescription, "The content is not UTF-8.")
        XCTAssertEqual((error as NSError).localizedFailureReason, "Encoding Error")
        shouldThrow.fulfill()
      default:
        XCTFail()
      }
    }
    wait(for: [shouldThrow], timeout: 0)
  }
  
  
  // MARK: - Encoding Failures
  func testUnencodableName(){
    let unencodable = String(bytes: [0xD8, 0x00], encoding: .utf16)!
    let subject = FormURLEncoded(items: [
      URLQueryItem(name: "foo", value: "bar"),
      URLQueryItem(name: unencodable, value: "unseen"),
      URLQueryItem(name: "baz", value: "thud"),
    ])
    XCTAssertEqual(subject.encoded, "foo=bar&baz=thud")
  }
  
  
  func testUnencodableValue() {
    let unencodable = String(bytes: [0xD8, 0x00], encoding: .utf16)
    let subject = FormURLEncoded(items: [
      URLQueryItem(name: "foo", value: "bar"),
      URLQueryItem(name: "baz", value: unencodable),
      URLQueryItem(name: "thud", value: "quux"),
    ])
    XCTAssertEqual(subject.encoded, "foo=bar&baz&thud=quux")
  }
}
