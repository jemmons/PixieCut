import XCTest
import PixieCut



class CredentialsJSONTests: XCTestCase {
  func testFull() {
    let json = Data("""
    {
      "access_token": "access123",
      "refresh_token": "refresh123",
      "token_type": "bearer",
      "expires_in": "3600",
      "scope": "read write"
    }
    """.utf8)
    let credentials = try! JSONDecoder().decode(Credentials.self, from: json)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.refreshToken, "refresh123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertEqual(credentials.expiresInSeconds, 3600)
    XCTAssertEqual(credentials.scope, ["read", "write"])
  }
  
  
  func testMinimum() {
    let json = Data("""
    {
      "access_token": "access123",
      "token_type": "bearer"
    }
    """.utf8)
    let credentials = try! JSONDecoder().decode(Credentials.self, from: json)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertNil(credentials.refreshToken)
    XCTAssertNil(credentials.expiresInSeconds)
    XCTAssert(credentials.scope.isEmpty)
  }
  
  
  func testMissingRequiredAccessToken() {
    let keyWasNotFound = expectation(description: "Waiting for error")
    
    let json = Data("""
    {
      "token_type": "bearer"
    }
    """.utf8)
    do {
      _ = try JSONDecoder().decode(Credentials.self, from: json)
    } catch Swift.DecodingError.keyNotFound {
      keyWasNotFound.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [keyWasNotFound], timeout: 0)
  }
  
  
  func testMissingRequiredTokenType() {
    let keyWasNotFound = expectation(description: "Waiting for error")
    
    let json = Data("""
    {
      "access_token": "access123"
    }
    """.utf8)
    do {
      _ = try JSONDecoder().decode(Credentials.self, from: json)
    } catch Swift.DecodingError.keyNotFound {
      keyWasNotFound.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [keyWasNotFound], timeout: 0)
  }
}
