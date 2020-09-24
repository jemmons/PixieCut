import XCTest
import PixieCut



class CredentialConvenienceTests: XCTestCase {
  func testQuery() {
    let query = Data("access_token=access123&refresh_token=refresh123&token_type=bearer&expires_in=3600&scope=read write".utf8)
    let credentials = try! Credentials(mimeType: "application/x-www-form-urlencoded", data: query)
    
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.refreshToken, "refresh123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertEqual(credentials.expiresIn, 3600)
    XCTAssertEqual(credentials.scope, ["read", "write"])
  }
  
  
  func testJSON() {
    let json = Data("""
    {
      "access_token": "access123",
      "refresh_token": "refresh123",
      "token_type": "bearer",
      "expires_in": "3600",
      "scope": "read write"
    }
    """.utf8)
    let credentials = try! Credentials(mimeType: "application/json", data: json)
    
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.refreshToken, "refresh123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertEqual(credentials.expiresIn, 3600)
    XCTAssertEqual(credentials.scope, ["read", "write"])
  }
  
  
  func testInvalidMIME() {
    let catchUnexpectedMIME = expectation(description: "waiting for error")
    
    let json = Data("""
    {
      "access_token": "access123",
      "refresh_token": "refresh123",
      "token_type": "bearer",
      "expires_in": "3600",
      "scope": "read write"
    }
    """.utf8)
    
    do {
      _ = try Credentials(mimeType: "chip/dale", data: json)
    } catch {
      switch error {
      case Credentials.Error.unexpectedMIMEType("chip/dale"):
        XCTAssert(error.localizedDescription.contains("chip/dale"))
        XCTAssertEqual((error as NSError).localizedFailureReason, "Credential Error")
        catchUnexpectedMIME.fulfill()
      default:
        XCTFail()
      }
    }
    
    wait(for: [catchUnexpectedMIME], timeout: 0)
  }
  
  
  func testBadJSON() {
    let catchCorruptedJSON = expectation(description: "waiting for error")
    let json = Data(capacity: 0)

    do {
      _ = try Credentials(mimeType: "application/json", data: json)
    } catch Swift.DecodingError.dataCorrupted {
      catchCorruptedJSON.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [catchCorruptedJSON], timeout: 0)
  }
  
  
  func testBadQuery() {
    let catchBadQuery = expectation(description: "waiting for error")
    let query = Data(capacity: 0)
    
    do {
      _ = try Credentials(mimeType: "application/x-www-form-urlencoded", data: query)
    } catch {
      switch error {
      case Credentials.Error.missingRequiredQueryParameter:
        XCTAssert(error.localizedDescription.hasPrefix("The required parameter"))
        XCTAssertEqual((error as NSError).localizedFailureReason, "Credential Error")
        catchBadQuery.fulfill()
      default:
        XCTFail()
      }
    }
    
    wait(for: [catchBadQuery], timeout: 0)
  }
}
