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
    let credentials = try! Credentials(json: json)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.refreshToken, "refresh123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertEqual(credentials.expiresIn, 3600)
    XCTAssertEqual(credentials.scope, ["read", "write"])
  }
  
  
  func testExpiresIsSometimesAnInt() {
    let json = Data("""
    {
      "access_token": "access123",
      "token_type": "bearer",
      "expires_in": 3600
    }
    """.utf8)
    let credentials = try! Credentials(json: json)
    XCTAssertEqual(3600, credentials.expiresIn)
  }
  
  
  func testIGuessExpiresCouldBeAFloatToo() {
    let json = Data("""
    {
      "access_token": "access123",
      "token_type": "bearer",
      "expires_in": 3600.5
    }
    """.utf8)
    let credentials = try! Credentials(json: json)
    XCTAssertEqual(3600.5, credentials.expiresIn)
  }
  
  
  func testMinimum() {
    let json = Data("""
    {
      "access_token": "access123",
      "token_type": "bearer"
    }
    """.utf8)
    let credentials = try! Credentials(json: json)
    XCTAssertEqual(Date().timeIntervalSince1970, credentials.created.timeIntervalSince1970, accuracy: 1.0)
    XCTAssertEqual(credentials.accessToken, "access123")
    XCTAssertEqual(credentials.tokenType, "bearer")
    XCTAssertNil(credentials.refreshToken)
    XCTAssertNil(credentials.expiresIn)
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
  
  
  func testBadJSON() {
    let catchCorruptedJSON = expectation(description: "waiting for error")
    let json = Data(capacity: 0)

    do {
      _ = try Credentials(json: json)
    } catch Swift.DecodingError.dataCorrupted {
      catchCorruptedJSON.fulfill()
    } catch {
      XCTFail()
    }
    
    wait(for: [catchCorruptedJSON], timeout: 0)
  }
}
